# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Designation round-trip" do
  it "creates a Designation with correct attributes" do
    d = Isq::Designation.new(
      id: "term-t3-1.1-0",
      text: "length",
      lang: "en",
      term_form_type: "smart:fullForm",
      index_as: ["length"],
    )

    expect(d.text).to eq("length")
    expect(d.lang).to eq("en")
    expect(d.term_form_type).to eq("smart:fullForm")
    expect(d.index_as).to eq(["length"])
  end

  it "generates Turtle as skosxl:Label" do
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
    expect(turtle).to include('smart:hasTermFormType smart:fullForm')
  end

  it "generates JSON-LD" do
    d = Isq::Designation.new(
      id: "term-t3-1.1-0",
      text: "length",
      lang: "en",
      term_form_type: "smart:fullForm",
    )

    jsonld = d.to_jsonld
    expect(jsonld).to include("skosxl:Label")
    expect(jsonld).to include("length")
  end

  it "supports multiple index_as values" do
    d = Isq::Designation.new(
      id: "term-test-0",
      text: "area",
      index_as: ["area", "surface area"],
    )

    expect(d.index_as).to eq(["area", "surface area"])
  end
end
