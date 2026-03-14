# frozen_string_literal: true

RSpec.describe Legion::Extensions::Language::Helpers::Lexicon do
  subject(:lexicon) { described_class.new }

  let(:summary) do
    {
      domain:          :networking,
      knowledge_level: :moderate,
      trace_count:     7,
      key_facts:       [{ content: 'fact 1' }]
    }
  end

  describe '#store_summary' do
    it 'stores a summary keyed by domain symbol' do
      lexicon.store_summary(:networking, summary)
      expect(lexicon.get_summary(:networking)).to include(domain: :networking)
    end

    it 'adds a cached_at timestamp' do
      lexicon.store_summary('networking', summary)
      stored = lexicon.get_summary(:networking)
      expect(stored[:cached_at]).to be_a(Time)
    end

    it 'converts string domain to symbol' do
      lexicon.store_summary('security', summary)
      expect(lexicon.get_summary(:security)).not_to be_nil
    end
  end

  describe '#get_summary' do
    it 'returns nil for unknown domain' do
      expect(lexicon.get_summary(:unknown)).to be_nil
    end

    it 'returns stored summary' do
      lexicon.store_summary(:networking, summary)
      result = lexicon.get_summary(:networking)
      expect(result[:knowledge_level]).to eq(:moderate)
    end
  end

  describe '#known_domains' do
    it 'returns empty array initially' do
      expect(lexicon.known_domains).to eq([])
    end

    it 'returns stored domain keys' do
      lexicon.store_summary(:networking, summary)
      lexicon.store_summary(:security, summary)
      expect(lexicon.known_domains).to contain_exactly(:networking, :security)
    end
  end

  describe '#knowledge_map' do
    it 'returns empty hash initially' do
      expect(lexicon.knowledge_map).to eq({})
    end

    it 'returns condensed view of all summaries' do
      lexicon.store_summary(:networking, summary)
      map = lexicon.knowledge_map
      expect(map[:networking]).to include(knowledge_level: :moderate, trace_count: 7)
      expect(map[:networking]).to have_key(:cached_at)
    end
  end

  describe '#stale?' do
    it 'returns true for unknown domain' do
      expect(lexicon.stale?(:unknown)).to be true
    end

    it 'returns false for recently stored summary' do
      lexicon.store_summary(:networking, summary)
      expect(lexicon.stale?(:networking)).to be false
    end

    it 'returns true when max_age exceeded' do
      lexicon.store_summary(:networking, summary)
      stored = lexicon.get_summary(:networking)
      stored[:cached_at] = Time.now.utc - 600
      expect(lexicon.stale?(:networking, max_age: 300)).to be true
    end
  end

  describe '#clear' do
    before do
      lexicon.store_summary(:networking, summary)
      lexicon.store_summary(:security, summary)
    end

    it 'clears a specific domain' do
      lexicon.clear(:networking)
      expect(lexicon.get_summary(:networking)).to be_nil
      expect(lexicon.get_summary(:security)).not_to be_nil
    end

    it 'clears all domains when called without argument' do
      lexicon.clear
      expect(lexicon.size).to eq(0)
    end
  end

  describe '#size' do
    it 'returns 0 initially' do
      expect(lexicon.size).to eq(0)
    end

    it 'reflects stored summary count' do
      lexicon.store_summary(:networking, summary)
      expect(lexicon.size).to eq(1)
    end
  end
end
