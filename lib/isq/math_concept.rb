# frozen_string_literal: true

module Isq
  class MathConcept < SduSmart::TermEntry
    attribute :identifier, :string
    attribute :pref_label, :string
    attribute :notation, :string, collection: true
    attribute :definition, :string
    attribute :note, :string

    rdf do
      namespace SduSmart::Rdf::Namespaces::IsoIec80000Namespace,
                SduSmart::Rdf::Namespaces::SmartNamespace,
                Lutaml::Rdf::Namespaces::DctermsNamespace,
                Lutaml::Rdf::Namespaces::SkosNamespace

      subject { |m| "https://w3id.org/standards/isoiec80000/ontologies/core/#{m.id}" }

      type "isoiec80000:MathConcept"

      predicate :identifier,
                namespace: Lutaml::Rdf::Namespaces::DctermsNamespace,
                to: :identifier

      predicate :prefLabel,
                namespace: Lutaml::Rdf::Namespaces::SkosNamespace,
                to: :pref_label

      predicate :notation,
                namespace: Lutaml::Rdf::Namespaces::SkosNamespace,
                to: :notation

      predicate :definition,
                namespace: Lutaml::Rdf::Namespaces::SkosNamespace,
                to: :definition

      predicate :note,
                namespace: Lutaml::Rdf::Namespaces::SkosNamespace,
                to: :note

      predicate :hasBindingnessType,
                namespace: SduSmart::Rdf::Namespaces::SmartNamespace,
                to: :bindingness_type

      predicate :isPartOf,
                namespace: Lutaml::Rdf::Namespaces::DctermsNamespace,
                to: :is_part_of
    end
  end
end
