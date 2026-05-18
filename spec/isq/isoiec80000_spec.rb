# frozen_string_literal: true

require "spec_helper"

RSpec.describe Isq do
  describe "Quantity" do
    it "inherits from SduSmart::TermEntry" do
      expect(Isq::Quantity < SduSmart::TermEntry).to be true
    end

    it "generates Turtle with isoiec80000:Quantity type" do
      q = Isq::Quantity.new(
        id: "t3-1.1",
        identifier: "3-1.1",
        pref_label: "length",
        notation: %w[l L],
        definition: "linear extent in space between any two points",
        bindingness_type: "normative",
        is_part_of: "isoiec80000:part-3",
        has_unit: ["isoiec80000:unit-m"],
      )
      turtle = q.to_turtle
      expect(turtle).to include("a isoiec80000:Quantity")
      expect(turtle).to include("dcterms:identifier")
      expect(turtle).to include("skos:prefLabel")
      expect(turtle).to include("skos:notation")
      expect(turtle).to include("skos:definition")
      expect(turtle).to include("smart:hasBindingnessType")
      expect(turtle).to include("isoiec80000:hasUnit")
      expect(turtle).to include("dcterms:isPartOf")
    end

    it "generates JSON-LD" do
      q = Isq::Quantity.new(
        id: "t3-1.1",
        identifier: "3-1.1",
        pref_label: "length",
        definition: "linear extent in space between any two points",
        bindingness_type: "normative",
        is_part_of: "isoiec80000:part-3",
      )
      jsonld = q.to_jsonld
      expect(jsonld).to include("isoiec80000:Quantity")
      expect(jsonld).to include("prefLabel")
      expect(jsonld).to include("definition")
    end
  end

  describe "Unit" do
    it "inherits from SduSmart::TermEntry" do
      expect(Isq::Unit < SduSmart::TermEntry).to be true
    end

    it "generates Turtle with isoiec80000:Unit type" do
      u = Isq::Unit.new(
        id: "unit-m",
        pref_label: "metre",
        notation: ["m"],
        bindingness_type: "normative",
      )
      turtle = u.to_turtle
      expect(turtle).to include("a isoiec80000:Unit")
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
      expect(jsonld).to include("isoiec80000:Unit")
      expect(jsonld).to include("metre")
    end
  end

  describe "MathConcept" do
    it "inherits from SduSmart::TermEntry" do
      expect(Isq::MathConcept < SduSmart::TermEntry).to be true
    end

    it "generates Turtle with isoiec80000:MathConcept type" do
      mc = Isq::MathConcept.new(
        id: "t2-1.1",
        identifier: "2-1.1",
        pref_label: "number",
        definition: "object of thought",
        bindingness_type: "normative",
        is_part_of: "isoiec80000:part-2",
      )
      turtle = mc.to_turtle
      expect(turtle).to include("a isoiec80000:MathConcept")
      expect(turtle).to include("skos:definition")
    end

    it "generates JSON-LD" do
      mc = Isq::MathConcept.new(
        id: "t2-1.1",
        pref_label: "number",
        definition: "object of thought",
      )
      jsonld = mc.to_jsonld
      expect(jsonld).to include("isoiec80000:MathConcept")
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
