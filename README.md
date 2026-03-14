# lex-language

Symbolic-to-linguistic grounding for LegionIO agents. Part of the LegionIO cognitive architecture extension ecosystem (LEX).

## What It Does

`lex-language` bridges raw memory traces and meaningful knowledge expression. Given a set of memory traces for a domain, it aggregates them by type priority, extracts key facts at configurable depth, assesses knowledge level, and returns a structured summary or prose narrative. A TTL-based lexicon cache avoids reprocessing unchanged trace sets. Also determines whether the agent's knowledge is sufficient to answer specific queries.

Key capabilities:

- **Domain summarization**: brief (3 facts), standard (7 facts), detailed (all traces above minimum strength)
- **Knowledge assessment**: rich (>=10 traces), moderate (>=5), sparse (<5)
- **Wonder resolution**: checks if a query domain has enough traces to answer
- **Lexicon cache**: 5-minute TTL per domain to avoid repeated processing
- **Knowledge map**: snapshot of all cached domain summaries

## Installation

Add to your Gemfile:

```ruby
gem 'lex-language'
```

Or install directly:

```
gem install lex-language
```

## Usage

```ruby
require 'legion/extensions/language'

# Fetch traces from lex-memory first, then summarize
client = Legion::Extensions::Language::Client.new

summary = client.summarize(domain: :networking, traces: traces, depth: :standard)
# => { domain: :networking, trace_count: 12, knowledge_level: :rich,
#      key_facts: ['...', '...', ...], strength_stats: { min: 0.3, max: 0.9, avg: 0.65 } }

# Assess knowledge in a domain
knowledge = client.what_do_i_know(domain: :networking, traces: traces)

# Check if a wonder can be answered
result = client.can_answer_wonder?(wonder: { domain: :networking }, traces: traces)
# => { can_answer: true, trace_count: 12, threshold: 3 }

# View all cached knowledge
map = client.knowledge_map
```

## Runner Methods

| Method | Description |
|---|---|
| `summarize` | Summarize domain traces at specified depth (brief/standard/detailed) |
| `what_do_i_know` | Detailed knowledge assessment for a domain |
| `can_answer_wonder?` | Check if trace count meets the resolution threshold |
| `knowledge_map` | All cached domain summaries |
| `language_stats` | Cached domain count, total traces processed |

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
