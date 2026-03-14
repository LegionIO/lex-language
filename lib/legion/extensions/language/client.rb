# frozen_string_literal: true

require 'legion/extensions/language/helpers/constants'
require 'legion/extensions/language/helpers/summarizer'
require 'legion/extensions/language/helpers/lexicon'
require 'legion/extensions/language/runners/language'

module Legion
  module Extensions
    module Language
      class Client
        include Runners::Language

        attr_reader :lexicon

        def initialize(lexicon: nil, **)
          @lexicon = lexicon || Helpers::Lexicon.new
        end
      end
    end
  end
end
