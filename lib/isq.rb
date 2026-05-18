# frozen_string_literal: true

require "sdu_smart"

module Isq
  autoload :Quantity, "#{__dir__}/isq/quantity"
  autoload :Unit, "#{__dir__}/isq/unit"
  autoload :MathConcept, "#{__dir__}/isq/math_concept"
  autoload :VERSION, "#{__dir__}/isq/version"
end
