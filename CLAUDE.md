# lex-language

**Level 3 Leaf Documentation**
- **Parent**: `/Users/miverso2/rubymine/legion/extensions-agentic/CLAUDE.md`
- **Gem**: `lex-language`
- **Version**: `0.1.0`
- **Namespace**: `Legion::Extensions::Language`

## Purpose

Symbolic-to-linguistic grounding for LegionIO agents. Reads lex-memory traces for a given domain, aggregates them by type priority, extracts key facts and emotional tone, assesses knowledge depth, and returns a structured or prose summary. Maintains a lexicon cache (5-minute TTL) to avoid reprocessing. Determines whether the agent's knowledge is sufficient to answer a specific query ("wonder").

## Gem Info

- **Require path**: `legion/extensions/language`
- **Ruby**: >= 3.4
- **License**: MIT
- **Registers with**: `Legion::Extensions::Core`

## File Structure

```
lib/legion/extensions/language/
  version.rb
  helpers/
    constants.rb      # Depth levels, type priority, knowledge thresholds
    lexicon.rb        # TTL-based domain summary cache
    summarizer.rb     # Module for domain trace aggregation logic
  runners/
    language.rb       # Runner module

spec/
  legion/extensions/language/
    helpers/
      constants_spec.rb
      lexicon_spec.rb
      summarizer_spec.rb
    runners/language_spec.rb
  spec_helper.rb
```

## Key Constants

```ruby
MAX_TRACES_PER_SUMMARY = 50
MIN_SUMMARY_STRENGTH   = 0.1    # traces below this are excluded

DEPTHS = %i[brief standard detailed]

TYPE_PRIORITY = {
  firmware:    0,
  identity:    1,
  procedural:  2,
  semantic:    3,
  episodic:    4,
  working:     5,
  sensory:     6
}

KNOWLEDGE_RICH     = 10   # traces >= this -> rich knowledge level
KNOWLEDGE_MODERATE = 5    # traces >= this -> moderate knowledge level

RESOLUTION_THRESHOLD = 3  # minimum traces to potentially answer a wonder
```

## Helpers

### `Helpers::Lexicon` (class)

TTL-based cache of domain summaries.

| Method | Description |
|---|---|
| `store_summary(domain, summary)` | stores summary with 300-second TTL |
| `get_summary(domain)` | retrieves cached summary; returns nil if expired |
| `stale?(domain, max_age: 300)` | true if summary is absent or older than max_age seconds |
| `knowledge_map` | all cached domains with their cached summary metadata |

### `Helpers::Summarizer` (module)

Stateless module for aggregating and scoring trace sets.

| Method | Description |
|---|---|
| `summarize_domain(domain:, traces:, depth:)` | full summary pipeline: filter, sort by type priority, extract facts, compute stats |
| `group_by_type(traces)` | organizes traces by type using TYPE_PRIORITY order |
| `extract_key_facts(traces, depth)` | selects top traces by strength; depth controls count (brief:3, standard:7, detailed:all) |
| `strength_stats(traces)` | min/max/avg strength of trace set |
| `emotional_tone(traces)` | average emotional_intensity across traces |
| `freshness_assessment(traces)` | ratio of traces accessed within last 24 hours |

### Return Structure for `summarize_domain`

```ruby
{
  domain:          Symbol,
  trace_count:     Integer,
  knowledge_level: :rich | :moderate | :sparse,
  key_facts:       Array<String>,      # trace content strings
  type_breakdown:  Hash<Symbol,Integer>,
  strength_stats:  { min:, max:, avg: },
  emotional_tone:  Float,
  freshness:       Float,
  depth:           Symbol
}
```

## Runners

Module: `Legion::Extensions::Language::Runners::Language`

Private state: `@lexicon` (memoized `Lexicon` instance).

| Runner Method | Parameters | Description |
|---|---|---|
| `summarize` | `domain:, traces:, depth: :standard` | Summarize domain traces; caches result in lexicon |
| `what_do_i_know` | `domain:, traces:` | Detailed knowledge assessment for a domain |
| `can_answer_wonder?` | `wonder:, traces:` | Boolean: is trace count >= RESOLUTION_THRESHOLD? |
| `knowledge_map` | (none) | All cached domain summaries from lexicon |
| `language_stats` | (none) | Cached domain count, total traces processed, freshness avg |

## Integration Points

- **lex-memory**: `summarize` takes a `traces:` array; callers retrieve traces from lex-memory via `retrieve_and_reinforce` before calling language.
- **lex-curiosity**: `can_answer_wonder?` is the resolution check — when a wonder is proposed, language determines if enough knowledge exists to satisfy it without new retrieval.
- **lex-coldstart**: Claude context ingestion stores traces into lex-memory; language can then summarize those traces immediately after ingest.
- **lex-narrator**: language summaries are the raw material for narrator prose generation.
- **lex-metacognition**: `Language` is listed under `:introspection` capability category.

## Development Notes

- Traces passed to `summarize` must already be fetched from lex-memory — language does not call lex-memory directly. This keeps the gem free of lex-memory as a hard dependency.
- `depth` controls how many key facts are extracted: `:brief` = top 3 by strength, `:standard` = top 7, `:detailed` = all traces above MIN_SUMMARY_STRENGTH.
- Lexicon TTL is hardcoded at 300 seconds in `store_summary`. There is no way to configure a different TTL per domain.
- `freshness_assessment` is the fraction of traces whose `last_accessed` timestamp is within 86,400 seconds of now. If traces lack timestamps, freshness returns 0.0.
- `knowledge_map` returns only cached summaries — domains not yet summarized or with expired TTL do not appear.
- No actor defined; summaries are generated on-demand and cached.
