# frozen_string_literal: true

module Isq
  class MathConcept < SduSmart::TermEntry
    include Isq::YamlAdapters

    attribute :identifier, :string
    attribute :pref_label, :string
    attribute :notation, :string, collection: true, initialize_empty: true
    attribute :definition, :string
    attribute :note, :string
    attribute :part, :string
    attribute :edition, :string
    attribute :designations, Isq::Designation, collection: true, initialize_empty: true
    attribute :symbols, Isq::SymbolTerm, collection: true, initialize_empty: true

    def definition=(value)
      value_set_for(:definition)
      @definition = value
    end

    def note=(value)
      value_set_for(:note)
      @note = value
    end

    yaml do
      map "id", to: :id
      map "num", to: :identifier
      map "part", to: :part
      map "edition", to: :edition
      map "def", with: { from: :definition_from_yaml, to: :definition_to_yaml }
      map "remarks", with: { from: :note_from_yaml, to: :note_to_yaml }
      map "designations", with: { from: :designations_from_yaml, to: :designations_to_yaml }
      map "symbols", with: { from: :symbols_from_yaml, to: :symbols_to_yaml }
    end

    rdf do
      namespace SduSmart::Rdf::Namespaces::IsqNamespace,
                SduSmart::Rdf::Namespaces::SmartNamespace,
                Lutaml::Rdf::Namespaces::DctermsNamespace,
                Lutaml::Rdf::Namespaces::SkosNamespace,
                SduSmart::Rdf::Namespaces::SkosXlNamespace

      subject { |m| "https://w3id.org/standards/isq/ontologies/core/#{m.id}" }

      type ["isq:MathConcept", "smart:TermEntry"]

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
                to: :definition,
                lang_tagged: true

      predicate :note,
                namespace: Lutaml::Rdf::Namespaces::SkosNamespace,
                to: :note,
                lang_tagged: true

      predicate :hasBindingnessType,
                namespace: SduSmart::Rdf::Namespaces::SmartNamespace,
                to: :bindingness_type

      predicate :isPartOf,
                namespace: Lutaml::Rdf::Namespaces::DctermsNamespace,
                to: :is_part_of

      members :designations,
              predicate_name: :prefLabel,
              namespace: SduSmart::Rdf::Namespaces::SkosXlNamespace
      members :symbols,
              predicate_name: :altLabel,
              namespace: SduSmart::Rdf::Namespaces::SkosXlNamespace
    end
  end
end
