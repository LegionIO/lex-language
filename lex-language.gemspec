# frozen_string_literal: true

require_relative 'lib/legion/extensions/language/version'

Gem::Specification.new do |spec|
  spec.name          = 'lex-language'
  spec.version       = Legion::Extensions::Language::VERSION
  spec.authors       = ['Esity']
  spec.email         = ['matthewdiverson@gmail.com']

  spec.summary       = 'LEX Language'
  spec.description   = 'Symbolic-to-linguistic grounding layer for brain-modeled agentic AI'
  spec.homepage      = 'https://github.com/LegionIO/lex-language'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.4'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/LegionIO/lex-language'
  spec.metadata['documentation_uri'] = 'https://github.com/LegionIO/lex-language'
  spec.metadata['changelog_uri'] = 'https://github.com/LegionIO/lex-language'
  spec.metadata['bug_tracker_uri'] = 'https://github.com/LegionIO/lex-language/issues'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir.glob('{lib,spec}/**/*') + %w[lex-language.gemspec Gemfile LICENSE README.md]
  end
  spec.require_paths = ['lib']
  spec.add_development_dependency 'legion-gaia'
end
