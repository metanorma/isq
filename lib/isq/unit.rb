# frozen_string_literal: true

module Isq
  class Unit < SduSmart::TermEntry
    attribute :pref_label, :string
    attribute :notation, :string, collection: true, initialize_empty: true

    yaml do
      map "en", to: :pref_label
      map "symbol", to: :notation
    end

    rdf do
      namespace SduSmart::Rdf::Namespaces::IsoIec80000Namespace,
                SduSmart::Rdf::Namespaces::SmartNamespace,
                Lutaml::Rdf::Namespaces::DctermsNamespace,
                Lutaml::Rdf::Namespaces::SkosNamespace

      subject { |m| "https://w3id.org/standards/isoiec80000/ontologies/core/#{m.id}" }

      type ["isoiec80000:Unit", "smart:TermEntry"]

      predicate :prefLabel,
                namespace: Lutaml::Rdf::Namespaces::SkosNamespace,
                to: :pref_label

      predicate :notation,
                namespace: Lutaml::Rdf::Namespaces::SkosNamespace,
                to: :notation

      predicate :hasBindingnessType,
                namespace: SduSmart::Rdf::Namespaces::SmartNamespace,
                to: :bindingness_type

      predicate :isPartOf,
                namespace: Lutaml::Rdf::Namespaces::DctermsNamespace,
                to: :is_part_of
    end
  end
end
