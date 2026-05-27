# frozen_string_literal: true

require "spec_helper"

RSpec.describe Isq do
  describe "Quantity" do
    it "inherits from SduSmart::TermEntry" do
      expect(Isq::Quantity < SduSmart::TermEntry).to be true
    end

    it "generates Turtle with isq:Quantity type" do
      q = Isq::Quantity.new(
        id: "t3-1.1",
        identifier: "3-1.1",
        pref_label: "length",
        notation: %w[l L],
        definition: "linear extent in space between any two points",
        bindingness_type: "normative",
        is_part_of: "isq:part-3",
        has_unit: ["isq:unit-m"],
      )
      turtle = q.to_turtle
      expect(turtle).to include("a isq:Quantity")
      expect(turtle).to include("dcterms:identifier")
      expect(turtle).to include("skos:prefLabel")
      expect(turtle).to include("skos:notation")
      expect(turtle).to include("skos:definition")
      expect(turtle).to include("smart:hasBindingnessType")
      expect(turtle).to include("isq:hasUnit")
      expect(turtle).to include("dcterms:isPartOf")
    end

    it "generates JSON-LD" do
      q = Isq::Quantity.new(
        id: "t3-1.1",
        identifier: "3-1.1",
        pref_label: "length",
        definition: "linear extent in space between any two points",
        bindingness_type: "normative",
        is_part_of: "isq:part-3",
      )
      jsonld = q.to_jsonld
      expect(jsonld).to include("isq:Quantity")
      expect(jsonld).to include("prefLabel")
      expect(jsonld).to include("definition")
    end

    it "parses from YAML" do
      yaml = <<~YAML
        ---
        - part: '3'
          edition: '2019'
          id: t3-1.1
          num: 3-1.1
          designations:
          - designation:
              en:
                text: length
                index_as:
                - length
          symbols:
          - l
          - L
          def:
            en: linear extent in space between any two points
          units:
          - en: metre
            symbol:
            - m
          remarks:
            en: Length remark.
      YAML

      entries = Isq::Quantity.from_yaml(yaml)
      q = entries.first

      expect(q.id).to eq("t3-1.1")
      expect(q.identifier).to eq("3-1.1")
      expect(q.part).to eq("3")
      expect(q.edition).to eq("2019")
      expect(q.pref_label).to eq("length")
      expect(q.definition).to eq("linear extent in space between any two points")
      expect(q.note).to eq("Length remark.")
      expect(q.has_unit).to eq(["isq:unit-m"])
      expect(q.designations.length).to eq(1)
      expect(q.designations.first.text).to eq("length")
      expect(q.symbols.length).to eq(2)
      expect(q.symbols.map(&:text)).to eq(%w[l L])
      expect(q.notation).to eq(%w[l L])
    end

    it "generates Turtle with member Term instances from YAML" do
      yaml = <<~YAML
        ---
        - part: '3'
          edition: '2019'
          id: t3-1.1
          num: 3-1.1
          designations:
          - designation:
              en:
                text: length
                index_as:
                - length
          symbols:
          - l
          def:
            en: linear extent in space
      YAML

      q = Isq::Quantity.from_yaml(yaml).first
      turtle = q.to_turtle

      expect(turtle).to include("a isq:Quantity")
      expect(turtle).to include("a skosxl:Label")
      expect(turtle).to include('skosxl:literalForm "length"@en')
      expect(turtle).to include('skosxl:literalForm "l"@en')
      expect(turtle).to include("smart:hasTermFormType smart:fullForm")
      expect(turtle).to include("smart:hasTermFormType smart:symbol")
    end

    it "handles entry with no units" do
      yaml = <<~YAML
        ---
        - part: '3'
          id: t3-2
          num: 3-2
          designations:
          - designation:
              en:
                text: area
          def:
            en: extent of a surface
      YAML

      q = Isq::Quantity.from_yaml(yaml).first
      expect(q.has_unit).to be_empty
    end

    it "handles entry with no remarks" do
      yaml = <<~YAML
        ---
        - part: '3'
          id: t3-1.1
          num: 3-1.1
          designations:
          - designation:
              en:
                text: length
          def:
            en: linear extent in space
      YAML

      q = Isq::Quantity.from_yaml(yaml).first
      expect(q.note).to be_nil
    end

    it "handles entry with no symbols" do
      yaml = <<~YAML
        ---
        - part: '3'
          id: t3-99
          num: 3-99
          designations:
          - designation:
              en:
                text: something
          def:
            en: some definition
      YAML

      q = Isq::Quantity.from_yaml(yaml).first
      expect(q.symbols).to be_empty
      expect(q.notation).to be_empty
    end

    it "handles multiple designations" do
      yaml = <<~YAML
        ---
        - part: '3'
          id: t3-1.2
          num: 3-1.2
          designations:
          - designation:
              en:
                text: width
                index_as:
                - width
          - designation:
              en:
                text: breadth
                index_as:
                - breadth
          def:
            en: a distance
      YAML

      q = Isq::Quantity.from_yaml(yaml).first
      expect(q.designations.length).to eq(2)
      expect(q.pref_label).to eq("width")
      expect(q.designations.last.text).to eq("breadth")
    end
  end

  describe "Unit" do
    it "inherits from SduSmart::TermEntry" do
      expect(Isq::Unit < SduSmart::TermEntry).to be true
    end

    it "generates Turtle with isq:Unit type" do
      u = Isq::Unit.new(
        id: "unit-m",
        pref_label: "metre",
        notation: ["m"],
        bindingness_type: "normative",
      )
      turtle = u.to_turtle
      expect(turtle).to include("a isq:Unit")
      expect(turtle).to include("skos:prefLabel")
      expect(turtle).to include("skos:notation")
    end

    it "generates JSON-LD" do
      u = Isq::Unit.new(
        id: "unit-m",
        pref_label: "metre",
        notation: ["m"],
      )
      jsonld = u.to_jsonld
      expect(jsonld).to include("isq:Unit")
      expect(jsonld).to include("metre")
    end

    it "parses from YAML" do
      yaml = <<~YAML
        ---
        en: metre
        symbol:
        - m
      YAML

      u = Isq::Unit.from_yaml(yaml)
      expect(u.pref_label).to eq("metre")
      expect(u.notation).to eq(["m"])
    end
  end

  describe "MathConcept" do
    it "inherits from SduSmart::TermEntry" do
      expect(Isq::MathConcept < SduSmart::TermEntry).to be true
    end

    it "generates Turtle with isq:MathConcept type" do
      mc = Isq::MathConcept.new(
        id: "t2-1.1",
        identifier: "2-1.1",
        pref_label: "number",
        definition: "object of thought",
        bindingness_type: "normative",
        is_part_of: "isq:part-2",
      )
      turtle = mc.to_turtle
      expect(turtle).to include("a isq:MathConcept")
      expect(turtle).to include("skos:definition")
    end

    it "generates JSON-LD" do
      mc = Isq::MathConcept.new(
        id: "t2-1.1",
        pref_label: "number",
        definition: "object of thought",
      )
      jsonld = mc.to_jsonld
      expect(jsonld).to include("isq:MathConcept")
    end

    it "parses from YAML" do
      yaml = <<~YAML
        ---
        - part: 2-5
          edition: '2019'
          id: t2-5.1
          num: 2-5.1
          designations:
          - designation:
              en:
                text: conjunction
                index_as:
                - conjunction
          def:
            en: conjunction of p and q
          symbols:
          - p ^^ q
      YAML

      entries = Isq::MathConcept.from_yaml(yaml)
      mc = entries.first

      expect(mc.id).to eq("t2-5.1")
      expect(mc.identifier).to eq("2-5.1")
      expect(mc.part).to eq("2-5")
      expect(mc.pref_label).to eq("conjunction")
      expect(mc.definition).to eq("conjunction of p and q")
      expect(mc.symbols.length).to eq(1)
      expect(mc.symbols.first.text).to eq("p ^^ q")
      expect(mc.notation).to eq(["p ^^ q"])
    end

    it "generates Turtle with member Term instances from YAML" do
      yaml = <<~YAML
        ---
        - part: 2-5
          id: t2-5.1
          num: 2-5.1
          designations:
          - designation:
              en:
                text: conjunction
          def:
            en: conjunction of p and q
          symbols:
          - p ^^ q
      YAML

      mc = Isq::MathConcept.from_yaml(yaml).first
      turtle = mc.to_turtle

      expect(turtle).to include("a isq:MathConcept")
      expect(turtle).to include("a skosxl:Label")
      expect(turtle).to include('skosxl:literalForm "conjunction"@en')
      expect(turtle).to include('skosxl:literalForm "p ^^ q"@en')
    end
  end

  describe "JSON-LD interop with SduSmart core" do
    it "PublicationDocument generates JSON-LD" do
      doc = SduSmart::PublicationDocument.new(
        id: "iso-80000-1",
        publication_type: "internationalStandard",
      )
      jsonld = doc.to_jsonld
      expect(jsonld).to include("smart:PublicationDocument")
      expect(jsonld).to include("hasPublicationType")
    end

    it "Requirement generates JSON-LD" do
      SduSmart::Provision
      req = SduSmart::Requirement.new(
        id: "req-1",
        bindingness_type: "normative",
        is_part_of: "clause-4",
      )
      jsonld = req.to_jsonld
      expect(jsonld).to include("smart:Requirement")
    end

    it "TermEntry generates JSON-LD" do
      entry = SduSmart::TermEntry.new(
        id: "term-entry-3-1-1",
        bindingness_type: "normative",
      )
      jsonld = entry.to_jsonld
      expect(jsonld).to include("smart:TermEntry")
    end
  end
end
