# frozen_string_literal: true

require "spec_helper"

RSpec.describe Isq::TermInstance do
  describe Isq::Designation do
    it "inherits from TermInstance" do
      expect(Isq::Designation < Isq::TermInstance).to be true
    end

    it "inherits from SduSmart::Term" do
      expect(Isq::Designation < SduSmart::Term).to be true
    end

    it "generates Turtle with skosxl:Label type" do
      d = Isq::Designation.new(
        id: "term-t3-1.1-0",
        text: "length",
        lang: "en",
        term_form_type: "smart:fullForm",
        index_as: ["length"],
      )
      turtle = d.to_turtle
      expect(turtle).to include("a skosxl:Label")
      expect(turtle).to include('skosxl:literalForm "length"')
      expect(turtle).to include("smart:hasTermFormType smart:fullForm")
    end

    it "generates JSON-LD" do
      d = Isq::Designation.new(
        id: "term-t3-1.1-0",
        text: "length",
        term_form_type: "smart:fullForm",
      )
      jsonld = d.to_jsonld
      expect(jsonld).to include("skosxl:Label")
      expect(jsonld).to include("literalForm")
    end

    it "stores index_as collection" do
      d = Isq::Designation.new(
        id: "term-t3-1.1-0",
        text: "length",
        index_as: ["length"],
      )
      expect(d.index_as).to eq(["length"])
    end
  end

  describe Isq::SymbolTerm do
    it "inherits from TermInstance" do
      expect(Isq::SymbolTerm < Isq::TermInstance).to be true
    end

    it "generates Turtle with skosxl:Label type" do
      s = Isq::SymbolTerm.new(
        id: "sym-t3-1.1-0",
        text: "l",
        lang: "en",
        term_form_type: "smart:symbol",
      )
      turtle = s.to_turtle
      expect(turtle).to include("a skosxl:Label")
      expect(turtle).to include('skosxl:literalForm "l"')
      expect(turtle).to include("smart:hasTermFormType smart:symbol")
    end

    it "generates JSON-LD" do
      s = Isq::SymbolTerm.new(
        id: "sym-t3-1.1-0",
        text: "l",
        term_form_type: "smart:symbol",
      )
      jsonld = s.to_jsonld
      expect(jsonld).to include("skosxl:Label")
      expect(jsonld).to include("literalForm")
    end
  end
end
