# frozen_string_literal: true

RSpec.describe Legion::Extensions::Language::Helpers::Summarizer do
  let(:now) { Time.now.utc }

  let(:base_trace) do
    {
      trace_id:            'trace-1',
      trace_type:          :semantic,
      content_payload:     'Networking uses TCP/IP',
      strength:            0.7,
      confidence:          0.8,
      domain_tags:         [:networking],
      emotional_valence:   0.2,
      emotional_intensity: 0.3,
      last_reinforced:     now,
      created_at:          now
    }
  end

  def make_traces(count, overrides = {})
    count.times.map do |i|
      base_trace.merge(trace_id: "trace-#{i}").merge(overrides)
    end
  end

  describe '.summarize_domain' do
    it 'returns empty summary for no traces' do
      result = described_class.summarize_domain([], domain: :networking)
      expect(result[:knowledge_level]).to eq(:none)
      expect(result[:trace_count]).to eq(0)
      expect(result[:key_facts]).to eq([])
    end

    it 'summarizes traces into structured result' do
      traces = make_traces(3)
      result = described_class.summarize_domain(traces, domain: :networking)

      expect(result[:domain]).to eq(:networking)
      expect(result[:knowledge_level]).to eq(:sparse)
      expect(result[:trace_count]).to eq(3)
      expect(result).to have_key(:type_breakdown)
      expect(result).to have_key(:key_facts)
      expect(result).to have_key(:strength_stats)
      expect(result).to have_key(:emotional_tone)
      expect(result).to have_key(:freshness)
    end

    it 'classifies rich knowledge at 10+ traces' do
      traces = make_traces(12)
      result = described_class.summarize_domain(traces, domain: :networking)
      expect(result[:knowledge_level]).to eq(:rich)
    end

    it 'classifies moderate knowledge at 5-9 traces' do
      traces = make_traces(7)
      result = described_class.summarize_domain(traces, domain: :networking)
      expect(result[:knowledge_level]).to eq(:moderate)
    end

    it 'classifies sparse knowledge at 1-4 traces' do
      traces = make_traces(2)
      result = described_class.summarize_domain(traces, domain: :networking)
      expect(result[:knowledge_level]).to eq(:sparse)
    end
  end

  describe '.group_by_type' do
    it 'groups traces by trace_type' do
      traces = [
        base_trace.merge(trace_type: :firmware),
        base_trace.merge(trace_type: :semantic),
        base_trace.merge(trace_type: :firmware)
      ]
      grouped = described_class.group_by_type(traces)
      expect(grouped[:firmware].size).to eq(2)
      expect(grouped[:semantic].size).to eq(1)
    end

    it 'orders by TYPE_PRIORITY' do
      traces = [
        base_trace.merge(trace_type: :sensory),
        base_trace.merge(trace_type: :firmware)
      ]
      grouped = described_class.group_by_type(traces)
      expect(grouped.keys.first).to eq(:firmware)
    end
  end

  describe '.extract_key_facts' do
    let(:grouped) do
      { semantic: make_traces(10) }
    end

    it 'limits facts by depth :brief' do
      facts = described_class.extract_key_facts(grouped, depth: :brief)
      expect(facts.size).to be <= 3
    end

    it 'limits facts by depth :standard' do
      facts = described_class.extract_key_facts(grouped, depth: :standard)
      expect(facts.size).to be <= 7
    end

    it 'limits facts by depth :detailed' do
      facts = described_class.extract_key_facts(grouped, depth: :detailed)
      expect(facts.size).to be <= 15
    end

    it 'returns structured fact hashes' do
      facts = described_class.extract_key_facts(grouped)
      fact = facts.first
      expect(fact).to include(:trace_id, :type, :content, :strength, :confidence, :domain_tags)
    end
  end

  describe '.extract_content_text' do
    it 'handles String payload' do
      expect(described_class.extract_content_text('hello')).to eq('hello')
    end

    it 'handles Hash with :text key' do
      expect(described_class.extract_content_text({ text: 'hello' })).to eq('hello')
    end

    it 'handles Hash with :content key' do
      expect(described_class.extract_content_text({ content: 'world' })).to eq('world')
    end

    it 'handles Hash with :summary key' do
      expect(described_class.extract_content_text({ summary: 'sum' })).to eq('sum')
    end

    it 'handles Array payload' do
      expect(described_class.extract_content_text(%w[first second])).to eq('first')
    end

    it 'converts other types to string' do
      expect(described_class.extract_content_text(42)).to eq('42')
    end
  end

  describe '.strength_stats' do
    it 'computes mean, max, min, strong, weak counts' do
      traces = [
        base_trace.merge(strength: 0.8),
        base_trace.merge(strength: 0.2),
        base_trace.merge(strength: 0.5)
      ]
      stats = described_class.strength_stats(traces)
      expect(stats[:mean]).to eq(0.5)
      expect(stats[:max]).to eq(0.8)
      expect(stats[:min]).to eq(0.2)
      expect(stats[:strong]).to eq(2) # 0.8 and 0.5
      expect(stats[:weak]).to eq(1)   # 0.2
    end
  end

  describe '.emotional_tone' do
    it 'computes average valence and intensity' do
      traces = [
        base_trace.merge(emotional_valence: 0.5, emotional_intensity: 0.6),
        base_trace.merge(emotional_valence: 0.3, emotional_intensity: 0.4)
      ]
      tone = described_class.emotional_tone(traces)
      expect(tone[:avg_valence]).to eq(0.4)
      expect(tone[:avg_intensity]).to eq(0.5)
    end

    it 'classifies neutral tone for low intensity' do
      traces = [base_trace.merge(emotional_valence: 0.5, emotional_intensity: 0.1)]
      tone = described_class.emotional_tone(traces)
      expect(tone[:tone]).to eq(:neutral)
    end

    it 'classifies positive tone for high valence' do
      traces = [base_trace.merge(emotional_valence: 0.5, emotional_intensity: 0.5)]
      tone = described_class.emotional_tone(traces)
      expect(tone[:tone]).to eq(:positive)
    end

    it 'classifies negative tone for low valence' do
      traces = [base_trace.merge(emotional_valence: -0.5, emotional_intensity: 0.5)]
      tone = described_class.emotional_tone(traces)
      expect(tone[:tone]).to eq(:negative)
    end

    it 'classifies mixed tone for moderate valence' do
      traces = [base_trace.merge(emotional_valence: 0.0, emotional_intensity: 0.5)]
      tone = described_class.emotional_tone(traces)
      expect(tone[:tone]).to eq(:mixed)
    end
  end

  describe '.freshness_assessment' do
    it 'classifies very_fresh traces' do
      traces = [base_trace.merge(last_reinforced: Time.now.utc)]
      result = described_class.freshness_assessment(traces)
      expect(result[:label]).to eq(:very_fresh)
    end

    it 'classifies stale traces' do
      traces = [base_trace.merge(last_reinforced: Time.now.utc - 100_000)]
      result = described_class.freshness_assessment(traces)
      expect(result[:label]).to eq(:stale)
    end

    it 'returns avg_age_seconds, freshest, stalest' do
      result = described_class.freshness_assessment([base_trace])
      expect(result).to have_key(:avg_age_seconds)
      expect(result).to have_key(:freshest)
      expect(result).to have_key(:stalest)
    end
  end

  describe '.empty_summary' do
    it 'returns zeroed-out summary for domain' do
      result = described_class.empty_summary(:networking)
      expect(result[:domain]).to eq(:networking)
      expect(result[:knowledge_level]).to eq(:none)
      expect(result[:trace_count]).to eq(0)
    end
  end
end
