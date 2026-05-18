# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Export validation" do
  let(:export_dir) { File.join(__dir__, "..", "..", "..", "browser", "public", "exports") }
  let(:ttl_file) { File.join(export_dir, "iso80000-all.ttl") }
  let(:jsonld_file) { File.join(export_dir, "iso80000-all.jsonld") }

  before do
    skip "Export files not found — run `bundle exec rake export:all` first" unless File.exist?(ttl_file)
  end

  # === Invented property audit ===
  {
    "smart:hasSymbol" => "use skosxl:altLabel with smart:Term (termFormType: symbol) instead",
    "smart:hasDefinition" => "use skos:definition instead",
    "smart:hasUnit" => "use isoiec80000:hasUnit instead",
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

  # === Object properties must be URI references, not string literals ===
  it "TTL hasBindingnessType uses URI reference, not string literal" do
    content = File.read(ttl_file)
    expect(content).not_to match(/smart:hasBindingnessType\s+"/),
      "hasBindingnessType must be a URI reference (smart:normative), not a string literal"
  end

  it "TTL hasUnit uses URI reference, not string literal" do
    content = File.read(ttl_file)
    expect(content).not_to match(/isoiec80000:hasUnit\s+"/),
      "hasUnit must be a URI reference (isoiec80000:unit-m), not a string literal"
  end

  # === SmartSDU type hierarchy ===
  it "TTL entries are typed as both domain class and smart:TermEntry" do
    content = File.read(ttl_file)
    expect(content).to match(/a isoiec80000:Quantity,\s*smart:TermEntry/),
      "Quantity entries must be dual-typed: isoiec80000:Quantity, smart:TermEntry"
    expect(content).to match(/a isoiec80000:MathConcept,\s*smart:TermEntry/),
      "MathConcept entries must be dual-typed: isoiec80000:MathConcept, smart:TermEntry"
  end

  # === Term instances (skosxl) ===
  it "TTL has smart:Term instances for designations" do
    content = File.read(ttl_file)
    expect(content).to include("a smart:Term, skosxl:Label"),
      "Each designation must be a smart:Term with skosxl:Label"
    expect(content).to include("skosxl:literalForm"),
      "Term instances must have skosxl:literalForm"
    expect(content).to include("smart:hasTermFormType smart:fullForm"),
      "Designation terms must have smart:hasTermFormType smart:fullForm"
  end

  it "TTL has smart:Term instances for symbols" do
    content = File.read(ttl_file)
    expect(content).to include("smart:hasTermFormType smart:symbol"),
      "Symbol terms must have smart:hasTermFormType smart:symbol"
  end

  it "TTL entries use skosxl:prefLabel and skosxl:altLabel, not flat skos:prefLabel for entries" do
    content = File.read(ttl_file)
    expect(content).to include("skosxl:prefLabel"),
      "Entries must use skosxl:prefLabel (not flat skos:prefLabel)"
    expect(content).to include("skosxl:altLabel"),
      "Alt designations and symbols must use skosxl:altLabel"
  end

  # === Required predicates ===
  it "TTL Quantity entries have required predicates" do
    content = File.read(ttl_file)
    quantities = content.scan(/isoiec80000:\S+ a isoiec80000:Quantity/)
    expect(quantities.length).to be > 0

    expect(content).to include("skos:definition")
    expect(content).to include("dcterms:identifier")
    expect(content).to include("smart:hasBindingnessType smart:normative")
    expect(content).to include("dcterms:isPartOf")
  end

  it "TTL Unit entries have required predicates" do
    content = File.read(ttl_file)
    expect(content).to include("isoiec80000:Unit")
    expect(content).to match(/a isoiec80000:Unit.*skos:prefLabel/m)
    expect(content).to match(/a isoiec80000:Unit.*skos:notation/m)
  end

  it "TTL MathConcept entries have required predicates" do
    content = File.read(ttl_file)
    expect(content).to include("isoiec80000:MathConcept")
    expect(content).to include("skos:definition")
  end

  # === PublicationDocument instances ===
  it "TTL PublicationDocument instances use correct type and properties" do
    content = File.read(ttl_file)
    expect(content).to include("a smart:PublicationDocument")
    expect(content).to include("smart:hasPublicationType smart:internationalStandard")
    expect(content).to include("smart:hasBindingnessType smart:normative")
  end

  # === JSON-LD validation ===
  it "JSON-LD object properties use @id references, not string values" do
    json = JSON.parse(File.read(jsonld_file))
    graph = json["@graph"] || [json]

    graph.each do |node|
      if node.key?("smart:hasBindingnessType")
        expect(node["smart:hasBindingnessType"]).to include("@id"),
          "hasBindingnessType in #{node['@id']} must be an @id reference"
      end

      if node.key?("dcterms:isPartOf")
        expect(node["dcterms:isPartOf"]).to include("@id"),
          "isPartOf in #{node['@id']} must be an @id reference"
      end

      if node.key?("isoiec80000:hasUnit")
        units = node["isoiec80000:hasUnit"]
        units = [units] unless units.is_a?(Array)
        units.each do |u|
          expect(u).to include("@id"),
            "hasUnit in #{node['@id']} must be @id references"
        end
      end
    end
  end

  it "JSON-LD entries are dual-typed as domain class and smart:TermEntry" do
    json = JSON.parse(File.read(jsonld_file))
    graph = json["@graph"] || [json]

    entry_nodes = graph.select { |n| n["@type"].is_a?(Array) && n["@type"].include?("smart:TermEntry") }
    expect(entry_nodes.length).to be > 0,
      "Should have entries typed as smart:TermEntry"

    entry_nodes.each do |node|
      types = node["@type"]
      expect(types).to include("smart:TermEntry")
      expect(types).to satisfy("has a domain type") { |t| (t & ["isoiec80000:Quantity", "isoiec80000:MathConcept"]).any? }
    end
  end

  it "JSON-LD has smart:Term instances with proper structure" do
    json = JSON.parse(File.read(jsonld_file))
    graph = json["@graph"] || [json]

    term_nodes = graph.select { |n| n["@type"].is_a?(Array) && n["@type"].include?("smart:Term") }
    expect(term_nodes.length).to be > 0,
      "Should have smart:Term instances"

    term_nodes.each do |node|
      expect(node).to include("skosxl:literalForm"),
        "Term #{node['@id']} must have skosxl:literalForm"
      expect(node).to include("smart:hasTermFormType"),
        "Term #{node['@id']} must have smart:hasTermFormType"
    end
  end

  it "JSON-LD entries use skosxl:prefLabel with @id references to Terms" do
    json = JSON.parse(File.read(jsonld_file))
    graph = json["@graph"] || [json]

    entry_nodes = graph.select { |n| n["@type"].is_a?(Array) && n["@type"].include?("smart:TermEntry") }
    entry_nodes.each do |node|
      if node.key?("skosxl:prefLabel")
        expect(node["skosxl:prefLabel"]).to include("@id"),
          "skosxl:prefLabel in #{node['@id']} must be @id reference to Term"
      end
    end
  end

  it "JSON-LD has proper context with all namespace prefixes" do
    json = JSON.parse(File.read(jsonld_file))
    ctx = json["@context"]

    expect(ctx).to include("smart" => "https://w3id.org/standards/smart/ontologies/core/")
    expect(ctx).to include("isoiec80000" => "https://w3id.org/standards/isoiec80000/ontologies/core/")
    expect(ctx).to include("dcterms")
    expect(ctx).to include("skos")
    expect(ctx).to include("skosxl" => "http://www.w3.org/2008/05/skos-xl#"),
      "JSON-LD context must include skosxl namespace"
  end
end
