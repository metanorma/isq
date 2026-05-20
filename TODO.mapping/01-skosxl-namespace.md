# 01 — SkosxlNamespace

## Goal

Create the `Lutaml::Rdf::Namespaces::SkosxlNamespace` class that the isq gem
needs for `skosxl:prefLabel`, `skosxl:altLabel`, and `skosxl:literalForm`
predicates. Currently missing from both `lutaml-model` and `sdu_smart`.

## Rationale

The ISO/IEC 80000 ontology uses SKOS-XL extensively:
- `skosxl:prefLabel` / `skosxl:altLabel` on Quantity and MathConcept entries
- `skosxl:literalForm` on Term instances
- The type `skosxl:Label` for Term instances

Every downstream model (Designation, SymbolTerm, Quantity, MathConcept) depends
on this namespace. It must exist first.

## Implementation

### File: `lib/isq/rdf/namespaces/skosxl_namespace.rb`

```ruby
# frozen_string_literal: true

module Isq
  module Rdf
    module Namespaces
      class SkosxlNamespace < Lutaml::Rdf::Namespace
        uri "http://www.w3.org/2008/05/skos-xl#"
        prefix "skosxl"
      end
    end
  end
end
```

### File: `lib/isq/rdf/namespaces.rb`

```ruby
# frozen_string_literal: true

module Isq
  module Rdf
    module Namespaces
      autoload :SkosxlNamespace, "#{__dir__}/namespaces/skosxl_namespace"
    end
  end
end
```

Wire into `lib/isq.rb` autoload.

## Spec

### File: `spec/isq/rdf/skosxl_namespace_spec.rb`

- `SkosxlNamespace.uri` returns the correct IRI
- `SkosxlNamespace.prefix` returns `"skosxl"`
- `SkosxlNamespace["literalForm"]` resolves to the full IRI
- `SkosxlNamespace.prefixed("prefLabel")` returns `"skosxl:prefLabel"`

## Acceptance

- Namespace class defined and autoloaded
- All specs pass
- No `send`, no `respond_to?`
