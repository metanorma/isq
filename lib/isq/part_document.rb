# frozen_string_literal: true

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
      "9" => "Physical Chemistry and Molecular Physics",
      "10" => "Atomic and Nuclear Physics",
      "11" => "Characteristic Numbers",
      "12" => "Condensed Matter Physics",
      "13" => "Information Science",
    }.freeze

    attribute :part_number, :string
    attribute :title, :string
    attribute :bindingness_type, :string

    rdf do
      namespace SduSmart::Rdf::Namespaces::SmartNamespace,
                Lutaml::Rdf::Namespaces::DctermsNamespace

      subject { |m| "https://w3id.org/standards/isq/ontologies/core/part-#{m.part_number}" }

      type "smart:PublicationDocument"

      predicate :title,
                namespace: Lutaml::Rdf::Namespaces::DctermsNamespace,
                to: :title

      predicate :identifier,
                namespace: Lutaml::Rdf::Namespaces::DctermsNamespace,
                to: :part_number

      predicate :hasPublicationType,
                namespace: SduSmart::Rdf::Namespaces::SmartNamespace,
                to: :publication_type

      predicate :hasBindingnessType,
                namespace: SduSmart::Rdf::Namespaces::SmartNamespace,
                to: :bindingness_type
    end

    def self.for_part(part_number)
      new(
        id: "part-#{part_number}",
        part_number: "ISO 80000-#{part_number}",
        title: PART_TITLES.fetch(part_number, "Part #{part_number}"),
        publication_type: "smart:internationalStandard",
        bindingness_type: "smart:normative",
      )
    end

    def self.all_parts
      PART_TITLES.keys.map { |p| for_part(p) }
    end
  end
end
