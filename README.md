# lex-language

Symbolic-to-linguistic grounding layer for LegionIO's brain-modeled agentic AI.

## Overview

lex-language bridges the gap between raw memory traces and meaningful knowledge expression. It summarizes domain-specific traces into structured knowledge assessments, maintains a cached lexicon of domain summaries, and determines whether the agent can answer questions ("wonders") about a given domain.

## Features

- **Domain Summarization**: Aggregates memory traces by domain with configurable depth (brief/standard/detailed)
- **Lexicon Cache**: In-memory domain summary cache with TTL-based staleness detection
- **Wonder Resolution**: Evaluates whether accumulated traces are sufficient to answer domain questions
- **Knowledge Mapping**: Provides a bird's-eye view of all known domains and their knowledge levels
- **Prose Generation**: Converts structured summaries into natural language descriptions

## Installation

```ruby
gem 'lex-language'
```

## Usage

```ruby
client = Legion::Extensions::Language::Client.new

# Summarize a domain from memory traces
summary = client.summarize(domain: :networking, traces: traces)

# Ask what the agent knows
knowledge = client.what_do_i_know(domain: :networking, traces: traces)

# Check if a wonder can be answered
result = client.can_answer_wonder?(wonder: { domain: :networking }, traces: traces)

# Get the full knowledge map
map = client.knowledge_map
```

## License

MIT
