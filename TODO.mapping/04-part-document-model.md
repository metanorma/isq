# 04 — PartDocument model

## Goal

Create `Isq::PartDocument` — a model that represents `smart:PublicationDocument`
instances for each ISO/IEC 80000 part. Replaces the hardcoded `PART_TITLES`
hash in the procedural rake task.

## Rationale

The export task currently generates one `PublicationDocument` per part with
hardcoded titles:

```ruby
PART_TITLES = {
  "3" => "Space and Time", "4" => "Mechanics", ...
}.freeze
```

This should be a proper lutaml-model class with RDF mapping. It serves two
purposes:

1. Generates `smart:PublicationDocument` triples in the per-part Turtle output
2. Provides part metadata (title, identifier) to the Dataset for manifest
   generation and UI rendering

Making it a model class (rather than a hash) enables:
- Bidirectional serialization (Turtle ⇄ Ruby)
- Extension without modifying export code (OCP)
- Testability of part metadata independently

## Design decisions

### Data source

Part titles are a fixed mapping (ISO standard part numbers → titles). They are
domain knowledge, not YAML data. Model as a registry class that provides
`PartDocument` instances.

Alternative: store part metadata in a YAML file in the gem. Overkill for 12
entries but extensible. Start with a constant and extract later if needed.

### Inheritance

`Isq::PartDocument < SduSmart::PublicationDocument` — it IS a PublicationDocument
with ISO/IEC 80000-specific metadata (part number, title).

## Implementation

### File: `lib/isq/part_document.rb`

```ruby
module Isq
  class PartDocument < SduSmart::PublicationDocument
    PART_TITLES = {
      "2" => "Mathematics",
      "3" => "Space and Time",
      "4" => "Mechanics",
      "5" => "Thermodynamics",
      "6" => "Electromagnetism",
      "7" => "Light and Radiation",
      "8" => "Acoustics",
      "9" => "Physical Chemistry",
      "10" => "Atomic and Nuclear",
      "11" => "Characteristic Numbers",
      "12" => "Condensed Matter",
      "13" => "Information Science",
    }.freeze

    attribute :part_number, :string
    attribute :title, :string

    rdf do
      namespace SduSmart::Rdf::Namespaces::SmartNamespace,
                Lutaml::Rdf::Namespaces::DctermsNamespace

      subject { |m| "isoiec80000:part-#{m.part_number}" }
      type "smart:PublicationDocument"

      predicate :title, namespace: DctermsNamespace, to: :title
      predicate :identifier, namespace: DctermsNamespace, to: :part_number
      predicate :hasPublicationType, namespace: SmartNamespace,
                to: :publication_type
      predicate :hasBindingnessType, namespace: SmartNamespace,
                to: :bindingness_type
    end

    def self.for_part(part_number)
      new(
        id: "part-#{part_number}",
        part_number: "ISO 80000-#{part_number}",
        title: PART_TITLES[part_number] || "Part #{part_number}",
        publication_type: "smart:internationalStandard",
        bindingness_type: "smart:normative",
      )
    end

    def self.all_parts
      PART_TITLES.keys.map { |p| for_part(p) }
    end
  end
end
```

## Spec

### File: `spec/isq/part_document_spec.rb`

- `PartDocument.for_part("3")` returns a PartDocument with correct metadata
- `PartDocument.for_part("3").to_turtle` produces:
  - `a smart:PublicationDocument`
  - `dcterms:title "Space and Time"@en`
  - `dcterms:identifier "ISO 80000-3"`
  - `smart:hasPublicationType smart:internationalStandard`
  - `smart:hasBindingnessType smart:normative`
- `PartDocument.all_parts` returns 12 instances
- Round-trip: `for_part("4").to_turtle` → `from_turtle` preserves data
- `PartDocument.for_part("99")` falls back to `"Part 99"` title
- `PART_TITLES` is frozen (immutability)

## Acceptance

- `PartDocument` class replaces hardcoded `PART_TITLES` hash in rake task
- Factory method `for_part` is the only constructor (OCP)
- Bidirectional Turtle serialization
- All specs pass, no `send`, no `respond_to?`
