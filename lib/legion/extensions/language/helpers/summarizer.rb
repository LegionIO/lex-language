# frozen_string_literal: true

module Legion
  module Extensions
    module Language
      module Helpers
        module Summarizer
          module_function

          def summarize_domain(traces, domain:, depth: :standard)
            return empty_summary(domain) if traces.empty?

            grouped = group_by_type(traces)
            knowledge_level = classify_knowledge(traces.size)

            {
              domain:          domain,
              knowledge_level: knowledge_level,
              trace_count:     traces.size,
              type_breakdown:  type_breakdown(grouped),
              key_facts:       extract_key_facts(grouped, depth: depth),
              strength_stats:  strength_stats(traces),
              emotional_tone:  emotional_tone(traces),
              freshness:       freshness_assessment(traces)
            }
          end

          def group_by_type(traces)
            grouped = traces.group_by { |t| t[:trace_type] || :unknown }
            grouped.sort_by { |type, _| Constants::TYPE_PRIORITY[type] || 99 }.to_h
          end

          def type_breakdown(grouped)
            grouped.transform_values(&:size)
          end

          def extract_key_facts(grouped, depth: :standard)
            limit = case depth
                    when :brief    then 3
                    when :detailed then 15
                    else 7
                    end

            facts = []
            grouped.each do |type, traces|
              sorted = traces.sort_by { |t| -(t[:strength] || 0) }
              count = [sorted.size, limit_per_type(type, limit)].min
              sorted.first(count).each do |trace|
                facts << format_fact(trace, type)
              end
            end

            facts.first(limit)
          end

          def format_fact(trace, type)
            content = extract_content_text(trace[:content_payload])
            {
              trace_id:    trace[:trace_id],
              type:        type,
              content:     content,
              strength:    (trace[:strength] || 0).round(3),
              confidence:  (trace[:confidence] || 0.5).round(3),
              domain_tags: trace[:domain_tags] || []
            }
          end

          def extract_content_text(payload)
            case payload
            when String then payload
            when Hash   then payload[:text] || payload[:content] || payload[:summary] || payload.to_s
            when Array  then payload.first.to_s
            else payload.to_s
            end
          end

          def classify_knowledge(count)
            if count >= Constants::KNOWLEDGE_RICH then :rich
            elsif count >= Constants::KNOWLEDGE_MODERATE then :moderate
            elsif count >= Constants::KNOWLEDGE_SPARSE   then :sparse
            else :none
            end
          end

          def strength_stats(traces)
            strengths = traces.map { |t| t[:strength] || 0 }
            {
              mean:   (strengths.sum / strengths.size).round(3),
              max:    strengths.max.round(3),
              min:    strengths.min.round(3),
              strong: strengths.count { |s| s >= 0.5 },
              weak:   strengths.count { |s| s < 0.3 }
            }
          end

          def emotional_tone(traces)
            valences = traces.map { |t| t[:emotional_valence] || 0.0 }
            intensities = traces.map { |t| t[:emotional_intensity] || 0.0 }

            avg_valence = valences.sum / valences.size
            avg_intensity = intensities.sum / intensities.size

            {
              avg_valence:   avg_valence.round(3),
              avg_intensity: avg_intensity.round(3),
              tone:          tone_label(avg_valence, avg_intensity)
            }
          end

          def tone_label(valence, intensity)
            if intensity < 0.2      then :neutral
            elsif valence > 0.3     then :positive
            elsif valence < -0.3    then :negative
            else :mixed
            end
          end

          def freshness_assessment(traces)
            now = Time.now.utc
            ages = traces.map { |t| now - (t[:last_reinforced] || t[:created_at] || now) }
            avg_age = ages.sum / ages.size

            {
              avg_age_seconds: avg_age.round(1),
              freshest:        ages.min.round(1),
              stalest:         ages.max.round(1),
              label:           freshness_label(avg_age)
            }
          end

          def freshness_label(avg_age)
            if avg_age < 60       then :very_fresh
            elsif avg_age < 3600  then :fresh
            elsif avg_age < 86_400 then :aging
            else :stale
            end
          end

          def empty_summary(domain)
            {
              domain:          domain,
              knowledge_level: :none,
              trace_count:     0,
              type_breakdown:  {},
              key_facts:       [],
              strength_stats:  { mean: 0.0, max: 0.0, min: 0.0, strong: 0, weak: 0 },
              emotional_tone:  { avg_valence: 0.0, avg_intensity: 0.0, tone: :neutral },
              freshness:       { avg_age_seconds: 0.0, freshest: 0.0, stalest: 0.0, label: :stale }
            }
          end

          def limit_per_type(type, total_limit)
            case type
            when :firmware, :identity then [total_limit, 3].min
            when :procedural          then [total_limit, 2].min
            else [total_limit, 5].min
            end
          end
        end
      end
    end
  end
end
