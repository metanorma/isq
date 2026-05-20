# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Quantity round-trip" do
  let(:fixture_dir) { File.join(__dir__, "..", "..", "fixtures") }

  def load_fixture(filename)
    path = File.join(fixture_dir, filename)
    Isq::Quantity.from_yaml(File.read(path)).first
  end

  describe "YAML -> Ruby -> Turtle" do
    let(:quantity) { load_fixture("quantity_entry.yaml") }

    it "preserves id and identifier" do
      expect(quantity.id).to eq("t3-1.1")
      expect(quantity.identifier).to eq("3-1.1")
    end

    it "preserves part and edition metadata" do
      expect(quantity.part).to eq("3")
      expect(quantity.edition).to eq("2019")
    end

    it "preserves designation text and structure" do
      expect(quantity.designations.length).to eq(1)
      expect(quantity.designations.first.text).to eq("length")
      expect(quantity.designations.first.lang).to eq("en")
      expect(quantity.designations.first.index_as).to eq(["length"])
    end

    it "preserves symbol texts" do
      expect(quantity.symbols.length).to eq(2)
      expect(quantity.symbols.map(&:text)).to eq(%w[l L])
      expect(quantity.notation).to eq(%w[l L])
    end

    it "preserves definition and note" do
      expect(quantity.definition).to eq("linear extent in space between any two points")
      expect(quantity.note).to eq("Length does not need to be measured along a straight line.")
    end

    it "preserves unit references" do
      expect(quantity.has_unit).to eq(["isoiec80000:unit-m"])
    end

    it "generates Turtle with Quantity type and predicates" do
      turtle = quantity.to_turtle

      expect(turtle).to include("a isoiec80000:Quantity")
      expect(turtle).to include('dcterms:identifier "3-1.1"')
      expect(turtle).to include('skos:definition "linear extent in space between any two points"@en')
      expect(turtle).to include('skos:note "Length does not need to be measured along a straight line."@en')
    end

    it "generates Turtle with member designation Terms" do
      turtle = quantity.to_turtle

      expect(turtle).to include("a skosxl:Label")
      expect(turtle).to include('skosxl:literalForm "length"@en')
      expect(turtle).to include("smart:hasTermFormType smart:fullForm")
    end

    it "generates Turtle with member symbol Terms" do
      turtle = quantity.to_turtle

      expect(turtle).to include('skosxl:literalForm "l"@en')
      expect(turtle).to include('skosxl:literalForm "L"@en')
      expect(turtle).to include("smart:hasTermFormType smart:symbol")
    end

    it "generates JSON-LD" do
      jsonld = quantity.to_jsonld

      expect(jsonld).to include("isoiec80000:Quantity")
      expect(jsonld).to include("prefLabel")
      expect(jsonld).to include("definition")
    end
  end

  describe "multiple designations" do
    let(:quantity) { load_fixture("quantity_multi_designation.yaml") }

    it "preserves multiple designations" do
      expect(quantity.designations.length).to eq(2)
      expect(quantity.designations.first.text).to eq("width")
      expect(quantity.designations.last.text).to eq("breadth")
      expect(quantity.pref_label).to eq("width")
    end

    it "generates Turtle with all designation Terms" do
      turtle = quantity.to_turtle

      expect(turtle).to include('skosxl:literalForm "width"@en')
      expect(turtle).to include('skosxl:literalForm "breadth"@en')
    end
  end

  describe "quantity with units" do
    let(:quantity) { load_fixture("quantity_with_units.yaml") }

    it "preserves unit reference with compound symbol" do
      expect(quantity.has_unit).to eq(["isoiec80000:unit-m/s"])
    end

    it "preserves single symbol" do
      expect(quantity.symbols.length).to eq(1)
      expect(quantity.symbols.first.text).to eq("v")
    end
  end

  describe "edge cases" do
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
  end
end
