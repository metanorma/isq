# frozen_string_literal: true

require "sdu_smart"

module Isq
  autoload :LangString, "#{__dir__}/isq/lang_string"
  autoload :YamlAdapters, "#{__dir__}/isq/yaml_adapters"
  autoload :TermInstance, "#{__dir__}/isq/term_instance"
  autoload :Designation, "#{__dir__}/isq/designation"
  autoload :SymbolTerm, "#{__dir__}/isq/symbol_term"
  autoload :Quantity, "#{__dir__}/isq/quantity"
  autoload :Unit, "#{__dir__}/isq/unit"
  autoload :MathConcept, "#{__dir__}/isq/math_concept"
  autoload :PartDocument, "#{__dir__}/isq/part_document"
  autoload :Dataset, "#{__dir__}/isq/dataset"
  autoload :Export, "#{__dir__}/isq/export"
  autoload :VERSION, "#{__dir__}/isq/version"
end
