# frozen_string_literal: true

require "spec_helper"

RSpec.describe "MathConcept round-trip" do
  let(:fixture_dir) { File.join(__dir__, "..", "..", "fixtures") }

  def load_fixture(filename)
    path = File.join(fixture_dir, filename)
    Isq::MathConcept.from_yaml(File.read(path)).first
  end

  describe "YAML -> Ruby -> Turtle" do
    let(:concept) { load_fixture("math_entry.yaml") }

    it "preserves id and identifier" do
      expect(concept.id).to eq("t2-5.1")
      expect(concept.identifier).to eq("2-5.1")
    end

    it "preserves part and edition" do
      expect(concept.part).to eq("2-5")
      expect(concept.edition).to eq("2019")
    end

    it "preserves designation" do
      expect(concept.designations.length).to eq(1)
      expect(concept.designations.first.text).to eq("conjunction")
      expect(concept.pref_label).to eq("conjunction")
    end

    it "preserves special characters in symbols" do
      expect(concept.symbols.length).to eq(1)
      expect(concept.symbols.first.text).to eq("p ^^ q")
      expect(concept.notation).to eq(["p ^^ q"])
    end

    it "preserves definition" do
      expect(concept.definition).to eq("conjunction of p and q")
    end

    it "generates Turtle with MathConcept type" do
      turtle = concept.to_turtle

      expect(turtle).to include("a isq:MathConcept")
      expect(turtle).to include('dcterms:identifier "2-5.1"')
      expect(turtle).to include('skos:definition "conjunction of p and q"@en')
    end

    it "generates Turtle with member Terms" do
      turtle = concept.to_turtle

      expect(turtle).to include("a skosxl:Label")
      expect(turtle).to include('skosxl:literalForm "conjunction"@en')
      expect(turtle).to include('skosxl:literalForm "p ^^ q"@en')
      expect(turtle).to include("smart:hasTermFormType smart:fullForm")
      expect(turtle).to include("smart:hasTermFormType smart:symbol")
    end

    it "generates JSON-LD" do
      jsonld = concept.to_jsonld

      expect(jsonld).to include("isq:MathConcept")
      expect(jsonld).to include("definition")
    end
  end

  describe "special characters in symbols" do
    let(:concept) { load_fixture("math_special_chars.yaml") }

    it "preserves complex symbol notation" do
      expect(concept.symbols.first.text).to eq("AA x in A p(x)")
      expect(concept.notation).to eq(["AA x in A p(x)"])
    end

    it "generates Turtle with special character symbols" do
      turtle = concept.to_turtle
      expect(turtle).to include('skosxl:literalForm "AA x in A p(x)"@en')
    end
  end

  describe "edge cases" do
    it "handles entry with no symbols" do
      yaml = <<~YAML
        ---
        - part: 2-1
          id: t2-1.1
          num: 2-1.1
          designations:
          - designation:
              en:
                text: number
          def:
            en: object of thought
      YAML

      mc = Isq::MathConcept.from_yaml(yaml).first
      expect(mc.symbols).to be_empty
      expect(mc.notation).to be_empty
    end
  end
end
