# frozen_string_literal: true

module Legion
  module Extensions
    module Language
      module Helpers
        module Constants
          # Maximum traces to consider in a single summarization
          MAX_TRACES_PER_SUMMARY = 50

          # Minimum strength threshold for including a trace in a summary
          MIN_SUMMARY_STRENGTH = 0.1

          # Summary depth levels
          DEPTHS = %i[brief standard detailed].freeze

          # Trace type priority for summary ordering
          TYPE_PRIORITY = {
            firmware:   0,
            identity:   1,
            procedural: 2,
            semantic:   3,
            trust:      4,
            episodic:   5,
            sensory:    6
          }.freeze

          # Knowledge quality thresholds
          KNOWLEDGE_RICH     = 10  # traces for "rich knowledge"
          KNOWLEDGE_MODERATE = 5   # traces for "moderate knowledge"
          KNOWLEDGE_SPARSE   = 1   # traces for "sparse knowledge"

          # Wonder resolution: minimum traces to consider a domain "known"
          RESOLUTION_THRESHOLD = 3
        end
      end
    end
  end
end
