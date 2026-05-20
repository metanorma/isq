# frozen_string_literal: true

module Isq
  class Quantity < SduSmart::TermEntry
    include Isq::YamlAdapters

    attribute :identifier, :string
    attribute :pref_label, :string
    attribute :notation, :string, collection: true, initialize_empty: true
    attribute :definition, :string
    attribute :note, :string
    attribute :has_unit, :string, collection: true, initialize_empty: true
    attribute :part, :string
    attribute :edition, :string
    attribute :designations, Isq::Designation, collection: true, initialize_empty: true
    attribute :symbols, Isq::SymbolTerm, collection: true, initialize_empty: true

    attr_accessor :unit_data

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
      map "units", with: { from: :units_from_yaml, to: :units_to_yaml }
    end

    rdf do
      namespace SduSmart::Rdf::Namespaces::IsoIec80000Namespace,
                SduSmart::Rdf::Namespaces::SmartNamespace,
                Lutaml::Rdf::Namespaces::DctermsNamespace,
                Lutaml::Rdf::Namespaces::SkosNamespace,
                SduSmart::Rdf::Namespaces::SkosXlNamespace

      subject { |m| "https://w3id.org/standards/isoiec80000/ontologies/core/#{m.id}" }

      type ["isoiec80000:Quantity", "smart:TermEntry"]

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

      predicate :hasUnit,
                namespace: SduSmart::Rdf::Namespaces::IsoIec80000Namespace,
                to: :has_unit,
                uri_reference: true

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

    def units_from_yaml(model, value)
      unless value.is_a?(Array)
        model.has_unit = []
        model.unit_data = {}
        return []
      end

      data = {}
      refs = value.map do |u|
        sym = Array(u["symbol"]).first
        ref = if sym
                "isoiec80000:unit-#{sym}"
              else
                name = u["en"]&.downcase&.gsub(/\s+/, "-")
                "isoiec80000:unit-#{name}" if name
              end
        data[ref] = { name: u["en"], symbols: Array(u["symbol"]) } if ref
        ref
      end.compact

      model.has_unit = refs
      model.unit_data = data
      refs
    end

    def units_to_yaml(model, doc)
      # Unit YAML round-trip requires Dataset lookup
    end
  end
end
