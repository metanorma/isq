# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Export validation" do
  let(:export_dir) { File.join(__dir__, "..", "..", "..", "browser", "public", "exports") }
  let(:ttl_file) { File.join(export_dir, "iso80000-all.ttl") }
  let(:jsonld_file) { File.join(export_dir, "iso80000-all.jsonld") }

  before do
    skip "Export files not found — run `bundle exec rake export:all` first" unless File.exist?(ttl_file)
  end

  describe "invented property audit" do
    {
      "smart:hasSymbol" => "use skosxl:altLabel with smart:Term (termFormType: symbol) instead",
      "smart:hasDefinition" => "use skos:definition instead",
      "smart:hasUnit" => "use isq:hasUnit instead",
      "smart:hasRemark" => "use skos:note instead",
      "smart:hasDesignation" => "use skosxl:prefLabel instead",
      "smart:hasPart" => "use dcterms:hasPart instead",
    }.each do |invented, fix|
      it "TTL does not contain invented property #{invented}" do
        content = File.read(ttl_file)
        expect(content).not_to include(invented),
          "Found invented property #{invented} (#{fix})"
      end
    end
  end

  describe "required types" do
    it "includes Quantity entries" do
      content = File.read(ttl_file)
      expect(content).to include("isq:Quantity")
    end

    it "includes MathConcept entries" do
      content = File.read(ttl_file)
      expect(content).to include("isq:MathConcept")
    end

    it "includes Unit entries" do
      content = File.read(ttl_file)
      expect(content).to include("isq:Unit")
    end

    it "includes PublicationDocument instances" do
      content = File.read(ttl_file)
      expect(content).to include("smart:PublicationDocument")
    end
  end

  describe "required predicates" do
    it "includes core predicates" do
      content = File.read(ttl_file)
      expect(content).to include("skos:definition")
      expect(content).to include("dcterms:identifier")
      expect(content).to include("dcterms:isPartOf")
    end

    it "Quantity entries have required predicates" do
      content = File.read(ttl_file)
      expect(content).to include("isq:hasUnit")
      expect(content).to include("smart:hasBindingnessType")
    end

    it "Unit entries have prefLabel and notation" do
      content = File.read(ttl_file)
      expect(content).to include("skos:prefLabel")
      expect(content).to include("skos:notation")
    end
  end

  describe "skosxl Term structure" do
    it "has skosxl:Label instances for designations and symbols" do
      content = File.read(ttl_file)
      expect(content).to include("skosxl:Label")
      expect(content).to include("skosxl:literalForm")
    end

    it "has term form type annotations" do
      content = File.read(ttl_file)
      expect(content).to include("smart:hasTermFormType")
    end
  end

  describe "JSON-LD structure" do
    it "has proper context with namespace prefixes" do
      json = JSON.parse(File.read(jsonld_file))
      ctx = json["@context"]

      expect(ctx).to include("smart" => "https://w3id.org/standards/smart/ontologies/core/")
      expect(ctx).to include("isq" => "https://w3id.org/standards/isq/ontologies/core/")
      expect(ctx).to include("dcterms")
      expect(ctx).to include("skos")
    end

    it "has domain-typed entries" do
      json = JSON.parse(File.read(jsonld_file))
      graph = json["@graph"] || [json]

      quantity_nodes = graph.select { |n| n["@type"]&.include?("isq:Quantity") }
      expect(quantity_nodes.length).to be > 0

      math_nodes = graph.select { |n| n["@type"]&.include?("isq:MathConcept") }
      expect(math_nodes.length).to be > 0
    end

    it "has Term instances with proper structure" do
      json = JSON.parse(File.read(jsonld_file))
      graph = json["@graph"] || [json]

      term_nodes = graph.select { |n| n["@type"]&.include?("skosxl:Label") }
      expect(term_nodes.length).to be > 0

      term_nodes.each do |node|
        expect(node).to include("skosxl:literalForm"),
          "Term #{node['@id']} must have skosxl:literalForm"
      end
    end
  end
end
