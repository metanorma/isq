# 05 — Dataset model and Export API

## Goal

Create `Isq::Dataset` (data loading, grouping, unit extraction) and
`Isq::Export` (file writing) — the orchestration layer that composes the
domain models into a full export pipeline.

These replace the procedural methods in `export.rake`:
`load_entries`, `generate_part_turtle`, `generate_unit_turtle`, `entry_jsonld`,
`generate_part_turtle`, and the 100-line `task :all` body.

## Rationale

The domain classes handle per-instance serialization (`quantity.to_turtle`,
`unit.to_yaml`). But the export pipeline has cross-cutting concerns:

- **Loading**: reading `quantities.yaml` + `math.yaml`, deserializing to model
  instances
- **Grouping**: entries by part number
- **Unit extraction**: deduplicating units across entries in the same part
- **Composition**: assembling PartDocument + Units + Entries into per-part
  Turtle/JSON-LD
- **File output**: per-part directories, per-entry files, bulk exports, manifest

These concerns don't belong in domain classes. They belong in a coordination
layer that composes domain models without owning serialization logic.

### Why separate Dataset and Export?

- **Dataset**: reads and structures data (loading, grouping, indexing). Pure
  data transformation, no I/O.
- **Export**: writes data to disk (file output). I/O only.

This separation enables:
- Loading data without writing files (testing, CLI preview, in-memory use)
- Writing different output formats without changing the data pipeline
- Testing grouping/deduplication without file I/O

### MECE analysis

| Concern | Owner | NOT in |
|---|---|---|
| Parse YAML → Quantity instances | `Dataset` | Domain classes |
| Group entries by part | `Dataset` | Domain classes |
| Extract + deduplicate units | `Dataset` | Unit model |
| Generate per-part Turtle | Composition of domain `.to_turtle` | Export |
| Write files to disk | `Export` | Dataset |
| Generate manifest | `Export` (from Dataset metadata) | Domain classes |

## Implementation

### File: `lib/isq/dataset.rb`

```ruby
module Isq
  class Dataset
    attr_reader :entries, :units_by_part, :part_keys

    def initialize(entries:, math_entries: [])
      @entries = entries
      @math_entries = math_entries
      @all_entries = entries + math_entries
      index!
    end

    def self.load(dataset_dir)
      quantities_yaml = File.read(File.join(dataset_dir, "quantities.yaml"))
      math_yaml = File.read(File.join(dataset_dir, "math.yaml"))

      entries = Isq::Quantity.from_yaml(quantities_yaml)
      math_entries = Isq::MathConcept.from_yaml(math_yaml)

      new(entries: entries, math_entries: math_entries)
    end

    def entries_for_part(part_key)
      by_part[part_key] || []
    end

    def unique_units_for_part(part_key)
      part_entries = entries_for_part(part_key)
      part_entries.each_with_object([]) do |entry, acc|
        entry.has_unit.each do |unit_ref|
          acc << unit_ref unless acc.include?(unit_ref)
        end
      end
    end

    def total_count
      @all_entries.length
    end

    def counts_by_part
      by_part.transform_values(&:length)
    end

    private

    def by_part
      @by_part
    end

    def index!
      @by_part = @all_entries.group_by(&:part)
      @part_keys = @by_part.keys.sort
    end
  end
end
```

### File: `lib/isq/export.rb`

```ruby
module Isq
  class Export
    def initialize(dataset:, export_dir:)
      @dataset = dataset
      @export_dir = export_dir
    end

    def run
      prepare_output_dir
      write_per_part
      write_bulk
      write_manifest
    end

    private

    def prepare_output_dir
      FileUtils.rm_rf(@export_dir)
      FileUtils.mkdir_p(@export_dir)
    end

    def write_per_part
      @dataset.part_keys.each do |part_key|
        part_dir = File.join(@export_dir, "part-#{part_key}")
        FileUtils.mkdir_p(part_dir)

        part_doc = Isq::PartDocument.for_part(part_key)
        entries = @dataset.entries_for_part(part_key)
        units = build_unit_instances(@dataset.unique_units_for_part(part_key))

        # Per-part index
        part_ttl = compose_part_turtle(part_doc, units, entries)
        File.write(File.join(part_dir, "index.ttl"), part_ttl)

        part_jsonld = compose_part_jsonld(part_doc, units, entries)
        File.write(File.join(part_dir, "index.jsonld"), part_jsonld)

        # Per-entry files
        entries.each do |entry|
          File.write(File.join(part_dir, "#{entry.id}.ttl"), entry.to_turtle)
          File.write(File.join(part_dir, "#{entry.id}.jsonld"), entry.to_jsonld)
        end
      end
    end

    def write_bulk
      all_turtle = @dataset.part_keys.map do |part_key|
        part_doc = Isq::PartDocument.for_part(part_key)
        entries = @dataset.entries_for_part(part_key)
        units = build_unit_instances(@dataset.unique_units_for_part(part_key))
        compose_part_turtle(part_doc, units, entries)
      end.join("\n")
      File.write(File.join(@export_dir, "iso80000-all.ttl"), all_turtle)

      # JSON-LD bulk similarly
    end

    def write_manifest
      manifest = {
        generated: Time.now.utc.iso8601,
        total_entries: @dataset.total_count,
        parts: @dataset.counts_by_part,
        namespaces: namespace_registry,
      }
      File.write(File.join(@export_dir, "manifest.json"),
                 JSON.pretty_generate(manifest))
    end

    def build_unit_instances(unit_refs)
      # Resolve unit refs to Unit model instances
      # Requires unit name/symbol lookup from the dataset
    end

    def compose_part_turtle(part_doc, units, entries)
      lines = [part_doc.to_turtle]
      units.each { |u| lines << u.to_turtle }
      entries.each { |e| lines << e.to_turtle }
      lines.join("\n")
    end

    def namespace_registry
      {
        smart: "https://w3id.org/standards/smart/ontologies/core/",
        isoiec80000: "https://w3id.org/standards/isoiec80000/ontologies/core/",
        dcterms: "http://purl.org/dc/terms/",
        skos: "http://www.w3.org/2004/02/skos/core#",
        skosxl: "http://www.w3.org/2008/05/skos-xl#",
      }
    end
  end
end
```

### Unit name resolution

The YAML has unit data embedded in quantity entries:
```yaml
units:
- en: metre
  symbol: [m]
```

The `Dataset` extracts unique unit references, but building `Isq::Unit`
instances from `{en: "metre", symbol: ["m"]}` requires a name → Unit factory.

Option: `Isq::Unit.from_unit_ref(ref_string, entry_units)` where
`entry_units` is the raw unit hash from the YAML entry.

This factory method lives on `Unit`, not on `Dataset` (OCP: Unit knows how to
build itself from its own data).

## Spec

### File: `spec/isq/dataset_spec.rb`

- `Dataset.load(dataset_dir)` parses both YAML files
- `dataset.entries` returns Quantity + MathConcept instances
- `dataset.entries_for_part("3")` returns only Part 3 entries
- `dataset.unique_units_for_part("3")` deduplicates units
- `dataset.total_count` matches expected count (~550 entries)
- `dataset.counts_by_part` has correct counts per part
- Empty dataset edge case
- Skips if YAML files not found (like existing export_validation_spec)

### File: `spec/isq/export_spec.rb`

- `Export.new(dataset:, export_dir:).run` creates output directory structure
- Per-part directories exist with `index.ttl`, `index.jsonld`
- Per-entry `.ttl` and `.jsonld` files exist
- Bulk `iso80000-all.ttl` contains entries from all parts
- `manifest.json` has correct metadata
- Output Turtle content matches expected structure (spot-check a few entries)
- Cleans export dir before writing (idempotent)

### Skip behavior

Both specs skip if YAML data not present (mirrors existing
`export_validation_spec.rb` pattern):
```ruby
before { skip "Dataset not found" unless Dir.exist?(dataset_dir) }
```

## Acceptance

- `Dataset.load` + `Export.new(...).run` replaces the entire `rake export:all`
  body
- No file I/O in `Dataset` (testable without files)
- No data parsing in `Export` (only I/O)
- All specs pass, no `send`, no `respond_to?`
- Output matches current procedural rake task output (validation spec should pass)
