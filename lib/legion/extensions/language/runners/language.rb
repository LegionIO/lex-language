# frozen_string_literal: true

module Legion
  module Extensions
    module Language
      module Runners
        module Language
          include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                      Legion::Extensions::Helpers.const_defined?(:Lex)

          def summarize(domain:, depth: :standard, traces: [], **)
            traces = filter_traces(traces, domain)
            summary = Helpers::Summarizer.summarize_domain(traces, domain: domain.to_sym, depth: depth.to_sym)
            lexicon.store_summary(domain, summary)

            Legion::Logging.debug "[language] summarize domain=#{domain} traces=#{traces.size} " \
                                  "knowledge=#{summary[:knowledge_level]}"
            summary
          end

          def what_do_i_know(domain:, depth: :standard, traces: [], **)
            summary = if lexicon.stale?(domain)
                        summarize(domain: domain, depth: depth, traces: traces)
                      else
                        lexicon.get_summary(domain)
                      end

            prose = generate_knowledge_prose(summary)

            {
              domain:          domain.to_sym,
              knowledge_level: summary[:knowledge_level],
              prose:           prose,
              fact_count:      summary[:key_facts]&.size || 0,
              summary:         summary
            }
          end

          def can_answer_wonder?(wonder:, traces: [], **)
            domain = wonder.is_a?(Hash) ? wonder[:domain] : :general
            relevant = filter_traces(traces, domain)

            answerable = relevant.size >= Helpers::Constants::RESOLUTION_THRESHOLD
            confidence = answerable ? compute_answer_confidence(relevant) : 0.0

            {
              answerable:  answerable,
              confidence:  confidence.round(3),
              domain:      domain,
              trace_count: relevant.size,
              threshold:   Helpers::Constants::RESOLUTION_THRESHOLD
            }
          end

          def knowledge_map(**)
            {
              domains:       lexicon.knowledge_map,
              known_domains: lexicon.known_domains,
              total_domains: lexicon.size
            }
          end

          def language_stats(**)
            {
              cached_domains: lexicon.size,
              known_domains:  lexicon.known_domains,
              knowledge_map:  lexicon.knowledge_map
            }
          end

          private

          def lexicon
            @lexicon ||= Helpers::Lexicon.new
          end

          def filter_traces(traces, domain)
            return [] unless traces.is_a?(Array)

            domain_sym = domain.to_sym
            domain_str = domain.to_s

            matching = traces.select do |t|
              tags = t[:domain_tags] || []
              tags.any? { |tag| tag.to_s == domain_str || tag.to_sym == domain_sym }
            end

            matching
              .select { |t| (t[:strength] || 0) >= Helpers::Constants::MIN_SUMMARY_STRENGTH }
              .sort_by { |t| -(t[:strength] || 0) }
              .first(Helpers::Constants::MAX_TRACES_PER_SUMMARY)
          end

          def generate_knowledge_prose(summary)
            domain = summary[:domain]
            level = summary[:knowledge_level]
            count = summary[:trace_count]
            facts = summary[:key_facts] || []

            base = "About #{domain}: I have #{level} knowledge (#{count} traces)."

            if facts.empty?
              "#{base} No specific facts available."
            else
              fact_lines = facts.first(5).map { |f| "- #{truncate(f[:content], 120)}" }
              "#{base}\nKey facts:\n#{fact_lines.join("\n")}"
            end
          end

          def compute_answer_confidence(traces)
            return 0.0 if traces.empty?

            strengths = traces.map { |t| t[:strength] || 0.0 }
            confidences = traces.map { |t| t[:confidence] || 0.5 }

            avg_strength = strengths.sum / strengths.size
            avg_confidence = confidences.sum / confidences.size

            ((avg_strength * 0.5) + (avg_confidence * 0.5)).clamp(0.0, 1.0)
          end

          def truncate(text, max_length)
            text = text.to_s
            text.length > max_length ? "#{text[0...max_length]}..." : text
          end
        end
      end
    end
  end
end
