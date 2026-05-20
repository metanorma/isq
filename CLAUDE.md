# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**isq** is a Ruby gem providing ISO/IEC 80000 (International System of Quantities) domain classes and RDF export. It extends the `sdu_smart` gem (SmartSDU Core Ontology) with ISQ-specific classes and generates Turtle/JSON-LD exports from YAML source data.

## Commands

```sh
bundle install              # install dependencies
bundle exec rake spec       # run all tests
bundle exec rspec spec/isq/isoiec80000_spec.rb           # run single test file
bundle exec rspec spec/isq/isoiec80000_spec.rb:12         # run single test by line number
bundle exec rake export:all # generate TTL/JSON-LD exports (requires YAML datasets at $ISQ_DATASET_DIR)
bundle exec exe/isq export  # CLI export (same as rake, with options)
bundle exec rake build      # build the gem
```

The export reads YAML from `ISQ_DATASET_DIR` (defaults to `../iso-iec-80000/sources/dataset`) and writes to `ISQ_EXPORT_DIR` (defaults to `../browser/public/exports`). CLI supports `-d`, `-o`, `-f` (ttl/jsonld/both) options.

## Architecture

Model-driven pipeline: YAML → lutaml-model domain classes → RDF (Turtle/JSON-LD).

### Domain classes (`lib/isq/`)

All extend `SduSmart::TermEntry` via `lutaml-model` with `yaml do` + `rdf do` mapping blocks:

- **Quantity** — physical quantities with designations, symbols, definition, units
- **Unit** — measurement units (metre, kilogram, etc.)
- **MathConcept** — mathematical concepts from Part 2 (no units)
- **TermInstance** / **Designation** / **SymbolTerm** — `skosxl:Label` members representing term/symbol nodes in RDF

Each class declares its own complete `rdf do` block (child replaces parent, doesn't extend). The `members` mechanism in `rdf do` generates separate graph nodes for Designation and SymbolTerm collections, with optional linking predicates (`predicate_name:` + `namespace:`) that generate triples from parent to member URIs (e.g., `skosxl:prefLabel`, `skosxl:altLabel`).

### Infrastructure (`lib/isq/`)

- **PartDocument** — `PublicationDocument` subclass with `PART_TITLES` registry and `.for_part` factory
- **Dataset** — loads YAML files, groups entries by part, deduplicates units
- **Export** — writes per-part/per-entry files, bulk exports, and manifest
- **Cli** — Thor-based CLI (`exe/isq`)

### Rake task (`lib/tasks/export.rake`)

Thin wrapper that delegates to `Isq::Dataset.load` + `Isq::Export.new(...).run`.

### RDF namespaces

- `smart:` — SmartSDU core (SduSmart::Rdf::Namespaces::SmartNamespace)
- `isoiec80000:` — ISQ domain (SduSmart::Rdf::Namespaces::IsoIec80000Namespace)
- `skosxl:` — SKOS-XL (SduSmart::Rdf::Namespaces::SkosXlNamespace)
- `dcterms:`, `skos:` — from lutaml-model

### YAML custom methods

Quantity and MathConcept share YAML adapter methods via the `Isq::YamlAdapters` module (definition, note, designations, symbols). Quantity additionally has `units_from_yaml`/`units_to_yaml`. The adapters use `with: { from:, to: }` in `yaml do` for structural adaptation of deeply nested YAML (multilingual `def.en`, `remarks.en`, nested `designations[].designation.en.text`).

### Language-tagged text (`Isq::LangString`)

`Isq::LangString` is a String subclass that includes `Lutaml::Rdf::LanguageTagged`, enabling `lang_tagged: true` predicates in `rdf do` to produce `@en` language tags in Turtle. Used for `definition`, `note` (Quantity/MathConcept), and `text` (Designation/SymbolTerm). The `:string` attribute setter is overridden in Quantity, MathConcept, and TermInstance to store LangString directly (bypassing lutaml-model type casting and `ensure_utf8`). Text values must be set *after* construction (not via constructor kwargs) because `initialize_attributes` calls `ensure_utf8` which strips the LangString subclass.

## Key Dependencies

- `sdu_smart` (~> 0.1.0) — `TermEntry`, `Term`, `PublicationDocument`, RDF namespace constants
- `lutaml-model` (~> 0.8.0) — attribute DSL, `yaml do` / `rdf do` mappings, `to_turtle` / `to_jsonld`
- `thor` (~> 1.3) — CLI framework

## Known lutaml-model limitations

- `from_turtle` converts single-element collections to scalars; language tags are lost on deserialization
- `from_turtle` for `uri_reference` predicates returns full URIs (not compact IRIs)

## Test Structure

- `spec/isq/isoiec80000_spec.rb` — domain class instantiation, YAML parsing, inheritance, Turtle/JSON-LD output
- `spec/isq/term_instance_spec.rb` — Designation and SymbolTerm RDF output
- `spec/isq/part_document_spec.rb` — PartDocument factory and Turtle
- `spec/isq/dataset_spec.rb` — Dataset loading, grouping, unit deduplication (skips without YAML data)
- `spec/isq/dataset_unit_spec.rb` — deterministic Dataset tests using in-memory data (always runs)
- `spec/isq/export_spec.rb` — Export pipeline file output (skips without YAML data)
- `spec/isq/export_unit_spec.rb` — deterministic Export tests using in-memory data (always runs)
- `spec/isq/cli_spec.rb` — Thor CLI help + export (export skips without YAML data)
- `spec/isq/rake_spec.rb` — Rake task wiring
- `spec/isq/from_turtle_spec.rb` — `from_turtle` round-trip for all domain classes
- `spec/isq/roundtrip/` — per-model YAML → Ruby → Turtle round-trip specs (quantity, math_concept, designation, symbol_term, unit)
- `spec/isq/integration/pipeline_spec.rb` — full Dataset → Export pipeline (skips without YAML data)
- `spec/isq/rdf/skosxl_namespace_spec.rb` — SKOS-XL namespace
- `spec/isq/export_validation_spec.rb` — validates generated exports for RDF correctness (skips without exports)
- `spec/fixtures/` — YAML test data fixtures for deterministic unit tests
