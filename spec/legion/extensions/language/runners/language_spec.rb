# frozen_string_literal: true

RSpec.describe Legion::Extensions::Language::Runners::Language do
  let(:lexicon) { Legion::Extensions::Language::Helpers::Lexicon.new }
  let(:client) { Legion::Extensions::Language::Client.new(lexicon: lexicon) }

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

  def make_traces(count, domain: :networking)
    count.times.map do |i|
      base_trace.merge(
        trace_id:    "trace-#{i}",
        domain_tags: [domain],
        strength:    0.3 + (rand * 0.5)
      )
    end
  end

  describe '#summarize' do
    it 'returns a summary hash for the domain' do
      traces = make_traces(5)
      result = client.summarize(domain: :networking, traces: traces)
      expect(result[:domain]).to eq(:networking)
      expect(result[:knowledge_level]).to eq(:moderate)
    end

    it 'stores the summary in the lexicon' do
      traces = make_traces(5)
      client.summarize(domain: :networking, traces: traces)
      expect(lexicon.get_summary(:networking)).not_to be_nil
    end

    it 'filters traces by domain' do
      traces = make_traces(5, domain: :networking) + make_traces(3, domain: :security)
      result = client.summarize(domain: :networking, traces: traces)
      expect(result[:trace_count]).to eq(5)
    end

    it 'respects minimum strength threshold' do
      weak_traces = make_traces(3).map { |t| t.merge(strength: 0.05) }
      strong_traces = make_traces(2)
      result = client.summarize(domain: :networking, traces: weak_traces + strong_traces)
      expect(result[:trace_count]).to eq(2)
    end

    it 'accepts string domain and converts to symbol' do
      traces = make_traces(3)
      result = client.summarize(domain: 'networking', traces: traces)
      expect(result[:domain]).to eq(:networking)
    end
  end

  describe '#what_do_i_know' do
    it 'returns structured knowledge with prose' do
      traces = make_traces(5)
      result = client.what_do_i_know(domain: :networking, traces: traces)
      expect(result[:domain]).to eq(:networking)
      expect(result[:knowledge_level]).to be_a(Symbol)
      expect(result[:prose]).to be_a(String)
      expect(result[:fact_count]).to be >= 0
      expect(result).to have_key(:summary)
    end

    it 'uses cached summary when not stale' do
      traces = make_traces(5)
      client.summarize(domain: :networking, traces: traces)

      result = client.what_do_i_know(domain: :networking, traces: [])
      expect(result[:knowledge_level]).to eq(:moderate)
    end

    it 're-summarizes when cache is stale' do
      traces = make_traces(5)
      client.summarize(domain: :networking, traces: traces)

      stored = lexicon.get_summary(:networking)
      stored[:cached_at] = Time.now.utc - 600

      new_traces = make_traces(12)
      result = client.what_do_i_know(domain: :networking, traces: new_traces)
      expect(result[:knowledge_level]).to eq(:rich)
    end

    it 'includes key facts in prose when available' do
      traces = make_traces(5)
      result = client.what_do_i_know(domain: :networking, traces: traces)
      expect(result[:prose]).to include('Key facts')
    end

    it 'handles no-facts prose' do
      result = client.what_do_i_know(domain: :empty, traces: [])
      expect(result[:prose]).to include('No specific facts')
    end
  end

  describe '#can_answer_wonder?' do
    it 'returns answerable when enough traces exist' do
      traces = make_traces(5)
      result = client.can_answer_wonder?(wonder: { domain: :networking }, traces: traces)
      expect(result[:answerable]).to be true
      expect(result[:confidence]).to be > 0.0
    end

    it 'returns not answerable when traces below threshold' do
      traces = make_traces(2)
      result = client.can_answer_wonder?(wonder: { domain: :networking }, traces: traces)
      expect(result[:answerable]).to be false
      expect(result[:confidence]).to eq(0.0)
    end

    it 'extracts domain from wonder hash' do
      traces = make_traces(5, domain: :security)
      result = client.can_answer_wonder?(wonder: { domain: :security }, traces: traces)
      expect(result[:domain]).to eq(:security)
    end

    it 'defaults to :general when wonder is not a hash' do
      result = client.can_answer_wonder?(wonder: 'what is life?', traces: [])
      expect(result[:domain]).to eq(:general)
    end

    it 'includes trace_count and threshold' do
      traces = make_traces(4)
      result = client.can_answer_wonder?(wonder: { domain: :networking }, traces: traces)
      expect(result[:trace_count]).to eq(4)
      expect(result[:threshold]).to eq(3)
    end
  end

  describe '#knowledge_map' do
    it 'returns domains, known_domains, and total_domains' do
      traces = make_traces(5)
      client.summarize(domain: :networking, traces: traces)
      result = client.knowledge_map
      expect(result[:known_domains]).to include(:networking)
      expect(result[:total_domains]).to eq(1)
      expect(result[:domains]).to have_key(:networking)
    end

    it 'returns empty map with no summaries' do
      result = client.knowledge_map
      expect(result[:total_domains]).to eq(0)
      expect(result[:known_domains]).to eq([])
    end
  end

  describe '#language_stats' do
    it 'returns cached_domains, known_domains, knowledge_map' do
      result = client.language_stats
      expect(result).to have_key(:cached_domains)
      expect(result).to have_key(:known_domains)
      expect(result).to have_key(:knowledge_map)
    end
  end
end
