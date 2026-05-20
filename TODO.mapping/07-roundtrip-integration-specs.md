# 07 — Round-trip and integration specs

## Goal

Write comprehensive round-trip and integration specs that validate the full
model-driven pipeline end-to-end, replacing the procedural validation in
`export_validation_spec.rb`.

## Rationale

The existing `export_validation_spec.rb` validates the procedural output by
reading generated files and checking for specific Turtle strings. It works but
is tightly coupled to the output format and hard to extend.

The new specs should validate the model-driven pipeline at three levels:

1. **Unit level**: per-model round-trip (YAML ⇄ Ruby ⇄ Turtle)
2. **Integration level**: full pipeline (YAML files → Dataset → Export → output files)
3. **Contract level**: output matches the RDF contracts (dual-typing, URI refs,
   skosxl structure, JSON-LD context)

### No `send`, no `respond_to?`

All specs use public API only. Type checks use `is_a?` where needed. No
dynamic dispatch.

## Spec files

### File: `spec/isq/roundtrip/quantity_roundtrip_spec.rb`

Tests full round-trip for Quantity entries:

- Load a single YAML entry → Quantity instance
- Verify all attributes populated correctly
- `quantity.to_turtle` produces valid Turtle
- Turtle contains expected predicates and types
- `quantity.to_yaml` round-trips back to equivalent YAML structure
- `from_yaml → to_turtle → from_turtle → to_yaml` preserves all data

Data fixture: extract a few representative entries from quantities.yaml into
spec fixtures (one simple, one with multiple designations, one with special
characters).

### File: `spec/isq/roundtrip/math_concept_roundtrip_spec.rb`

Same round-trip structure for MathConcept:

- Verify `isoiec80000:MathConcept` type in Turtle output
- Test entries from Part 2 sub-parts (2-5, 2-6, etc.)
- Special characters in symbols (`"p ^^ q"`, `"p => q"`, `"AA x in A p(x)"`)

### File: `spec/isq/roundtrip/designation_roundtrip_spec.rb`

- Designation YAML → Ruby → Turtle → Ruby → YAML
- Verifies `smart:Term, skosxl:Label` dual typing
- Verifies `skosxl:literalForm` with language tag
- Verifies `smart:hasTermFormType smart:fullForm`

### File: `spec/isq/roundtrip/symbol_term_roundtrip_spec.rb`

- SymbolTerm from flat string → Ruby → Turtle → Ruby → flat string
- Verifies `smart:hasTermFormType smart:symbol`

### File: `spec/isq/roundtrip/unit_roundtrip_spec.rb`

- Unit from YAML hash → Ruby → Turtle → Ruby → YAML
- Verifies `isoiec80000:Unit` type, `skos:prefLabel`, `skos:notation`

## Integration spec

### File: `spec/isq/integration/pipeline_spec.rb`

Tests the full pipeline against actual YAML data (skips if not available):

```ruby
RSpec.describe "Full pipeline" do
  let(:dataset_dir) { File.join(__dir__, "..", "..", "..", "..",
                                 "iso-iec-80000", "sources", "dataset") }
  let(:export_dir) { Dir.mktmpdir("isq-export-") }

  before { skip "Dataset not found" unless Dir.exist?(dataset_dir) }

  it "loads, exports, and produces valid output" do
    dataset = Isq::Dataset.load(dataset_dir)
    Isq::Export.new(dataset: dataset, export_dir: export_dir).run

    # Structure checks
    expect(Dir.glob(File.join(export_dir, "part-*"))).not_to be_empty
    expect(File.exist?(File.join(export_dir, "iso80000-all.ttl"))).to be true
    expect(File.exist?(File.join(export_dir, "iso80000-all.jsonld"))).to be true
    expect(File.exist?(File.join(export_dir, "manifest.json"))).to be true
  end
end
```

### Contract validation

These replace the existing `export_validation_spec.rb` with model-aware checks:

```ruby
RSpec.describe "RDF contract" do
  # Loaded from the actual pipeline output

  it "entries are dual-typed as domain class and smart:TermEntry" do
    # Check Quantity entries have both isoiec80000:Quantity and smart:TermEntry
  end

  it "object properties use URI references, not string literals" do
    # hasBindingnessType is URI ref, not string
    # hasUnit is URI ref, not string
  end

  it "Term instances have skosxl:literalForm and hasTermFormType" do
    # Each designation/symbol produces a Term instance
  end

  it "uses skosxl:prefLabel/altLabel, not flat skos:prefLabel" do
    # Entries use skosxl, not plain skos
  end

  it "PublicationDocument instances use correct type and properties" do
    # Per-part PublicationDocument with correct predicates
  end

  it "JSON-LD has proper context with all namespace prefixes" do
    # Context includes smart, isoiec80000, dcterms, skos, skosxl
  end

  it "JSON-LD object properties use @id references" do
    # hasBindingnessType, isPartOf, hasUnit are @id references
  end

  it "JSON-LD entries are dual-typed" do
    # Each entry has both domain type and smart:TermEntry
  end
end
```

### File: `spec/isq/integration/manifest_spec.rb`

- `manifest.json` has correct `generated` timestamp
- `total_entries` matches actual entry count
- `parts` hash has correct counts per part
- `namespaces` includes all required prefixes

## Spec fixtures

### Directory: `spec/fixtures/`

Extract representative YAML entries for deterministic unit tests:

- `spec/fixtures/quantity_entry.yaml` — a single Quantity entry (Part 3, length)
- `spec/fixtures/quantity_multi_designation.yaml` — entry with multiple
  designations (Part 3, width/breadth)
- `spec/fixtures/quantity_with_units.yaml` — entry with units
- `spec/fixtures/math_entry.yaml` — a MathConcept entry (Part 2-5)
- `spec/fixtures/expected_length.ttl` — expected Turtle for length entry
- `spec/fixtures/expected_length.jsonld` — expected JSON-LD for length entry

These fixtures anchor the round-trip specs and catch regressions.

## Update existing specs

### File: `spec/isq/isoiec80000_spec.rb`

- Update to use new attribute names where changed
- Keep inheritance tests (`Quantity < SduSmart::TermEntry`)
- Keep interop tests with SduSmart core classes
- Remove Turtle string-matching where round-trip specs cover it better

### File: `spec/isq/export_validation_spec.rb`

- Replace with contract validation from integration spec
- Or keep as a smoke test that runs against generated exports
- Must work with new model-driven output format

## Acceptance

- Full round-trip YAML ⇄ Turtle for Quantity, Unit, MathConcept, Designation,
  SymbolTerm
- Integration spec validates full pipeline against real YAML data
- Contract specs validate all RDF requirements from the existing
  `export_validation_spec.rb`
- No `send`, no `respond_to?`
- Spec fixtures are minimal and deterministic
- All existing test coverage preserved or improved
