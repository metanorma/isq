# frozen_string_literal: true

require "spec_helper"

RSpec.describe SduSmart::Rdf::Namespaces::SkosXlNamespace do
  it "has correct URI" do
    expect(described_class.uri).to eq("http://www.w3.org/2008/05/skos-xl#")
  end

  it "has correct prefix" do
    expect(described_class.prefix).to eq("skosxl")
  end

  it "resolves local names to full IRIs" do
    expect(described_class["literalForm"]).to eq("http://www.w3.org/2008/05/skos-xl#literalForm")
  end

  it "produces compact prefixed names" do
    expect(described_class.prefixed("prefLabel")).to eq("skosxl:prefLabel")
  end
end
