# TODO.mapping — Model-driven architecture migration

Replacing the procedural `export.rake` with a fully model-driven pipeline
using lutaml-model multi-format mappings (YAML + Turtle).

## Tasks (in order)

1. [01-skosxl-namespace](01-skosxl-namespace.md) — Create `Isq::Rdf::Namespaces::SkosxlNamespace`
2. [02-term-instance-models](02-term-instance-models.md) — `Designation` and `SymbolTerm` models with bidirectional YAML + RDF
3. [03-quantity-unit-mathconcept-yaml-rdf](03-quantity-unit-mathconcept-yaml-rdf.md) — Domain classes with full `yaml do` + `rdf do` mappings
4. [04-part-document-model](04-part-document-model.md) — `PartDocument` model replaces hardcoded `PART_TITLES`
5. [05-dataset-export-api](05-dataset-export-api.md) — `Dataset` loading + `Export` service
6. [06-cli-rake](06-cli-rake.md) — Thor CLI + thin rake wrapper
7. [07-roundtrip-integration-specs](07-roundtrip-integration-specs.md) — Round-trip and integration specs

## Architecture

```
YAML source ──from_yaml──▶ Isq::Quantity (domain model) ──to_turtle──▶ Turtle
                     ◀──to_yaml──                            ◀──from_turtle──
```

Single domain model with multi-format lutaml-model mappings.
No separate source/target models. No procedural transformation.

## Design principles

- **OOP**: each model encapsulates its own serialization
- **MECE**: each model maps to exactly one RDF structural role
- **OCP**: new formats/parts/entry types require new classes, not modified ones
- **DRY**: common RDF predicates inherited from `SduSmart::TermEntry`; shared adapters in modules
- **Performance**: autoload for lazy loading; no unnecessary object allocation
- **No `send`**: break encapsulation — use public API
- **No `respond_to?`**: poor typing — use `is_a?` or proper interfaces
