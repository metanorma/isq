# frozen_string_literal: true

require "spec_helper"

RSpec.describe Isq::PartDocument do
  it "inherits from SduSmart::PublicationDocument" do
    expect(described_class < SduSmart::PublicationDocument).to be true
  end

  describe ".for_part" do
    it "returns a PartDocument with correct metadata" do
      doc = described_class.for_part("3")

      expect(doc.id).to eq("part-3")
      expect(doc.part_number).to eq("ISO 80000-3")
      expect(doc.title).to eq("Space and Time")
      expect(doc.publication_type).to eq("smart:internationalStandard")
      expect(doc.bindingness_type).to eq("smart:normative")
    end

    it "falls back to generic title for unknown parts" do
      doc = described_class.for_part("99")

      expect(doc.title).to eq("Part 99")
    end
  end

  describe ".all_parts" do
    it "returns 12 instances" do
      expect(described_class.all_parts.length).to eq(12)
    end
  end

  describe "PART_TITLES" do
    it "is frozen" do
      expect(described_class::PART_TITLES).to be_frozen
    end
  end

  describe "#to_turtle" do
    it "produces PublicationDocument triples" do
      doc = described_class.for_part("3")
      turtle = doc.to_turtle

      expect(turtle).to include("a smart:PublicationDocument")
      expect(turtle).to include("Space and Time")
      expect(turtle).to include("ISO 80000-3")
      expect(turtle).to include("smart:hasPublicationType")
      expect(turtle).to include("smart:hasBindingnessType")
    end
  end

  describe "#to_jsonld" do
    it "produces JSON-LD" do
      doc = described_class.for_part("4")
      jsonld = doc.to_jsonld

      expect(jsonld).to include("smart:PublicationDocument")
      expect(jsonld).to include("Mechanics")
    end
  end
end
