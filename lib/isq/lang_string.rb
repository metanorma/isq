# frozen_string_literal: true

require "lutaml/rdf/language_tagged"

module Isq
  class LangString < String
    include Lutaml::Rdf::LanguageTagged

    attr_reader :language

    def initialize(text, language: "en")
      super(text.to_s)
      @language = language
    end
  end
end
