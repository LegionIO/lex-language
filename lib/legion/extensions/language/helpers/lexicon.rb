# frozen_string_literal: true

module Legion
  module Extensions
    module Language
      module Helpers
        class Lexicon
          attr_reader :domain_summaries

          def initialize
            @domain_summaries = {}
          end

          def store_summary(domain, summary)
            domain = domain.to_sym
            @domain_summaries[domain] = summary.merge(cached_at: Time.now.utc)
          end

          def get_summary(domain)
            @domain_summaries[domain.to_sym]
          end

          def known_domains
            @domain_summaries.keys
          end

          def knowledge_map
            @domain_summaries.transform_values do |summary|
              {
                knowledge_level: summary[:knowledge_level],
                trace_count:     summary[:trace_count],
                cached_at:       summary[:cached_at]
              }
            end
          end

          def stale?(domain, max_age: 300)
            summary = get_summary(domain)
            return true unless summary

            (Time.now.utc - summary[:cached_at]) > max_age
          end

          def clear(domain = nil)
            if domain
              @domain_summaries.delete(domain.to_sym)
            else
              @domain_summaries.clear
            end
          end

          def size
            @domain_summaries.size
          end
        end
      end
    end
  end
end
