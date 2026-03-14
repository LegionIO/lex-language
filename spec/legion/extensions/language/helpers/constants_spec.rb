# frozen_string_literal: true

RSpec.describe Legion::Extensions::Language::Helpers::Constants do
  it 'defines MAX_TRACES_PER_SUMMARY' do
    expect(described_class::MAX_TRACES_PER_SUMMARY).to eq(50)
  end

  it 'defines MIN_SUMMARY_STRENGTH' do
    expect(described_class::MIN_SUMMARY_STRENGTH).to eq(0.1)
  end

  it 'defines DEPTHS as frozen array of symbols' do
    expect(described_class::DEPTHS).to eq(%i[brief standard detailed])
    expect(described_class::DEPTHS).to be_frozen
  end

  it 'defines TYPE_PRIORITY as frozen hash' do
    expect(described_class::TYPE_PRIORITY).to include(firmware: 0, sensory: 6)
    expect(described_class::TYPE_PRIORITY).to be_frozen
  end

  it 'defines knowledge thresholds' do
    expect(described_class::KNOWLEDGE_RICH).to eq(10)
    expect(described_class::KNOWLEDGE_MODERATE).to eq(5)
    expect(described_class::KNOWLEDGE_SPARSE).to eq(1)
  end

  it 'defines RESOLUTION_THRESHOLD' do
    expect(described_class::RESOLUTION_THRESHOLD).to eq(3)
  end
end
