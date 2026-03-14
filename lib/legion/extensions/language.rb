# frozen_string_literal: true

require 'legion/extensions/language/version'
require 'legion/extensions/language/helpers/constants'
require 'legion/extensions/language/helpers/summarizer'
require 'legion/extensions/language/helpers/lexicon'
require 'legion/extensions/language/runners/language'
require 'legion/extensions/language/client'

module Legion
  module Extensions
    module Language
      extend Legion::Extensions::Core if Legion::Extensions.const_defined? :Core
    end
  end
end
