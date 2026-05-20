# 02 — Term instance models (Designation, SymbolTerm)

## Goal

Create `Isq::Designation` and `Isq::SymbolTerm` — sub-models that represent
`smart:Term, skosxl:Label` instances in the RDF graph. Each has bidirectional
YAML and Turtle mappings.

These are the "member" objects referenced by Quantity and MathConcept entries
via `skosxl:prefLabel` and `skosxl:altLabel`.

## Rationale

In YAML, designations are deeply nested:
```yaml
designations:
- designation:
    en:
      text: length
      index_as: [length]
```

In Turtle, each designation becomes a separate graph node:
```turtle
isoiec80000:term-t3-1.1-0 a smart:Term, skosxl:Label ;
  skosxl:literalForm "length"@en ;
  smart:hasTermFormType smart:fullForm .
```

These models bridge the structural gap via lutaml-model multi-format mappings.
The `members` mechanism in `rdf do` handles the separate graph nodes.

## Design decisions

- **Inheritance**: Both inherit from `SduSmart::Term` since they ARE `smart:Term`
  instances with additional `skosxl:Label` typing and `skosxl:literalForm`.
  The `rdf do` block adds the extra type and predicate.

- **ID generation**: Each instance has an `id` like `"term-t3-1.1-0"` (for
  designations) or `"sym-t3-1.1-0"` (for symbols). These are first-class
  attributes, not structural metadata.

- **YAML mapping**: Uses `with: { from:, to: }` custom methods to handle the
  deeply nested `designation.en.text` structure. The YAML shape doesn't match
  the flat attribute model, so custom methods are the cleanest adapter.

- **Language**: Uses `Lutaml::Rdf::Literal` for `text` attribute to carry the
  language tag bidirectionally. The `lang_tagged: true` on the predicate
  extracts it during Turtle serialization.

## Implementation

### File: `lib/isq/term_instance.rb`

Common base for Designation and SymbolTerm. Extracts shared `smart:Term`
predicate mappings to avoid duplication (DRY).

```ruby
module Isq
  class TermInstance < SduSmart::Term
    attribute :text, :string
    attribute :lang, :string, default: "en"

    rdf do
      type "skosxl:Label"
      predicate :literalForm,
                namespace: Isq::Rdf::Namespaces::SkosxlNamespace,
                to: :text,
                lang_tagged: true
    end
  end
end
```

### File: `lib/isq/designation.rb`

```ruby
module Isq
  class Designation < TermInstance
    attribute :index_as, :string, collection: true

    rdf do
      # Inherits smart:Term + skosxl:Label from TermInstance
      predicate :hasTermFormType,
                namespace: SduSmart::Rdf::Namespaces::SmartNamespace,
                to: :term_form_type
    end
  end
end
```

`term_form_type` defaults to `"smart:fullForm"` — set in the factory method or
via Quantity's custom YAML mapping.

### File: `lib/isq/symbol_term.rb`

```ruby
module Isq
  class SymbolTerm < TermInstance
    # text is the symbol string (e.g., "l", "L")
    # term_form_type defaults to "smart:symbol"
  end
```

### Quantity yaml mapping integration (sketch)

```ruby
# In Isq::Quantity
attribute :designations, Isq::Designation, collection: true
attribute :symbols, Isq::SymbolTerm, collection: true

yaml do
  map :designations,
      with: { from: :designations_from_yaml, to: :designations_to_yaml }
  map :symbols,
      with: { from: :symbols_from_yaml, to: :symbols_to_yaml }
end

rdf do
  members :designations
  members :symbols
end
```

The `designations_from_yaml` / `symbols_from_yaml` methods handle the
structural adaptation from nested YAML to flat model objects.

## Spec

### File: `spec/isq/term_instance_spec.rb`

- **YAML → Designation**: nested hash parses to Designation with text, lang,
  index_as
- **Designation → YAML**: round-trips back to nested hash structure
- **Designation → Turtle**: produces `smart:Term, skosxl:Label` with
  `skosxl:literalForm "text"@en` and `smart:hasTermFormType smart:fullForm`
- **Turtle → Designation**: parses Turtle back to Designation instance
- **SymbolTerm YAML**: flat string `"l"` → SymbolTerm → Turtle → back
- **Round-trip**: YAML → Ruby → Turtle → Ruby → YAML preserves data

### Edge cases

- Empty designations array
- Multiple designations (prefLabel vs altLabel)
- Multilingual designations (en + fr)
- Symbols with special characters (e.g., `"p ^^ q"`)

## Acceptance

- `TermInstance`, `Designation`, `SymbolTerm` classes defined and autoloaded
- Bidirectional YAML ⇄ Turtle for both model types
- All specs pass, no `send`, no `respond_to?`
- MECE: each class maps to exactly one RDF structural role
