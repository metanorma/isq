# frozen_string_literal: true

require_relative "lib/isq/version"

Gem::Specification.new do |spec|
  spec.name = "isq"
  spec.version = Isq::VERSION
  spec.authors = ["Ribose"]
  spec.email = ["open.source@ribose.com"]

  spec.summary = "ISO/IEC 80000 International System of Quantities — Ruby domain classes and RDF export."
  spec.description = "Ruby gem extending the SmartSDU Core Ontology with ISO/IEC 80000-specific " \
                     "domain classes: Quantity, Unit, and MathConcept. " \
                     "Includes a Rake task for generating per-part Turtle and JSON-LD exports " \
                     "from YAML source data."

  spec.homepage = "https://github.com/metanorma/isq"
  spec.license = "BSD-2-Clause"
  spec.required_ruby_version = Gem::Requirement.new(">= 3.0.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/releases"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.glob("lib/**/*.rb") + Dir.glob("lib/tasks/*.rake")
  spec.require_paths = ["lib"]

  spec.add_dependency "sdu_smart", "~> 0.1.0"
  spec.add_dependency "lutaml-model", "~> 0.8.0"
end
