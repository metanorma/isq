# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Unit round-trip" do
  it "parses from YAML" do
    yaml = <<~YAML
      ---
      en: metre
      symbol:
      - m
    YAML

    unit = Isq::Unit.from_yaml(yaml)
    expect(unit.pref_label).to eq("metre")
    expect(unit.notation).to eq(["m"])
  end

  it "generates Turtle with Unit type" do
    unit = Isq::Unit.new(
      id: "unit-m",
      pref_label: "metre",
      notation: ["m"],
      bindingness_type: "smart:normative",
    )

    turtle = unit.to_turtle
    expect(turtle).to include("a isq:Unit")
    expect(turtle).to include('skos:prefLabel "metre"')
    expect(turtle).to include('skos:notation "m"')
  end

  it "generates JSON-LD" do
    unit = Isq::Unit.new(
      id: "unit-m",
      pref_label: "metre",
      notation: ["m"],
    )

    jsonld = unit.to_jsonld
    expect(jsonld).to include("isq:Unit")
    expect(jsonld).to include("metre")
  end

  it "handles unit with multiple notation values" do
    unit = Isq::Unit.new(
      id: "unit-deg",
      pref_label: "degree",
      notation: ["°", "deg"],
    )

    turtle = unit.to_turtle
    expect(turtle).to include('"°"')
    expect(turtle).to include('"deg"')
  end

  it "inherits from SduSmart::TermEntry" do
    expect(Isq::Unit < SduSmart::TermEntry).to be true
  end
end
