# frozen_string_literal: true

require "spec_helper"

RSpec.describe "from_turtle round-trip" do
  describe "Quantity" do
    let(:yaml) { File.read(File.join(__dir__, "..", "fixtures", "quantity_entry.yaml")) }
    let(:quantity) { Isq::Quantity.from_yaml(yaml).first }
    let(:turtle) { quantity.to_turtle }
    let(:parsed) { Isq::Quantity.from_turtle(turtle) }

    it "parses back to a Quantity instance" do
      expect(parsed).to be_a(Isq::Quantity)
    end

    it "preserves identifier" do
      expect(parsed.identifier).to eq("3-1.1")
    end

    it "preserves pref_label" do
      expect(parsed.pref_label).to eq("length")
    end

    it "preserves definition text" do
      expect(parsed.definition).to eq("linear extent in space between any two points")
    end

    it "preserves note text" do
      expect(parsed.note).to eq("Length does not need to be measured along a straight line.")
    end

    it "preserves notation" do
      expect(parsed.notation).to eq(%w[l L])
    end

    it "preserves has_unit" do
      # from_turtle returns scalar for single-element collections; uri_reference predicates compact URIs back
      expect(parsed.has_unit).to eq("isq:unit-m")
    end

    it "round-trips scalar attributes back to Turtle" do
      ttl2 = parsed.to_turtle
      expect(ttl2).to include("a isq:Quantity")
      expect(ttl2).to include('dcterms:identifier "3-1.1"')
      expect(ttl2).to include('skos:definition "linear extent in space between any two points"')
      expect(ttl2).to include('skos:note "Length does not need to be measured along a straight line."')
    end
  end

  describe "MathConcept" do
    let(:yaml) { File.read(File.join(__dir__, "..", "fixtures", "math_entry.yaml")) }
    let(:concept) { Isq::MathConcept.from_yaml(yaml).first }
    let(:turtle) { concept.to_turtle }
    let(:parsed) { Isq::MathConcept.from_turtle(turtle) }

    it "parses back to a MathConcept instance" do
      expect(parsed).to be_a(Isq::MathConcept)
    end

    it "preserves identifier" do
      expect(parsed.identifier).to eq("2-5.1")
    end

    it "preserves definition" do
      expect(parsed.definition).to eq("conjunction of p and q")
    end

    it "preserves notation" do
      # from_turtle returns scalar for single-element collections
      expect(parsed.notation).to eq("p ^^ q")
    end

    it "round-trips back to Turtle" do
      ttl2 = parsed.to_turtle
      expect(ttl2).to include("a isq:MathConcept")
      expect(ttl2).to include('skos:definition "conjunction of p and q"')
    end
  end

  describe "Unit" do
    let(:unit) do
      Isq::Unit.new(
        id: "unit-m",
        pref_label: "metre",
        notation: ["m"],
      )
    end
    let(:parsed) { Isq::Unit.from_turtle(unit.to_turtle) }

    it "parses back to a Unit instance" do
      expect(parsed).to be_a(Isq::Unit)
    end

    it "preserves pref_label" do
      expect(parsed.pref_label).to eq("metre")
    end

    it "preserves notation" do
      # from_turtle returns scalar for single-element collections
      expect(parsed.notation).to eq("m")
    end
  end

  describe "Designation" do
    let(:designation) do
      d = Isq::Designation.new(
        id: "term-t3-1.1-0",
        lang: "en",
        term_form_type: "smart:fullForm",
      )
      d.text = Isq::LangString.new("length", language: "en")
      d
    end
    let(:parsed) { Isq::Designation.from_turtle(designation.to_turtle) }

    it "parses back to a Designation instance" do
      expect(parsed).to be_a(Isq::Designation)
    end

    it "preserves text" do
      expect(parsed.text).to eq("length")
    end

    it "preserves term_form_type" do
      expect(parsed.term_form_type).to eq("smart:fullForm")
    end
  end

  describe "SymbolTerm" do
    let(:symbol_term) do
      s = Isq::SymbolTerm.new(
        id: "sym-t3-1.1-0",
        lang: "en",
        term_form_type: "smart:symbol",
      )
      s.text = Isq::LangString.new("l", language: "en")
      s
    end
    let(:parsed) { Isq::SymbolTerm.from_turtle(symbol_term.to_turtle) }

    it "parses back to a SymbolTerm instance" do
      expect(parsed).to be_a(Isq::SymbolTerm)
    end

    it "preserves text" do
      expect(parsed.text).to eq("l")
    end

    it "preserves term_form_type" do
      expect(parsed.term_form_type).to eq("smart:symbol")
    end
  end
end
