# frozen_string_literal: true

require "spec_helper"

RSpec.describe "SymbolTerm round-trip" do
  it "creates a SymbolTerm with correct attributes" do
    s = Isq::SymbolTerm.new(
      id: "sym-t3-1.1-0",
      text: "l",
      lang: "en",
      term_form_type: "smart:symbol",
    )

    expect(s.text).to eq("l")
    expect(s.lang).to eq("en")
    expect(s.term_form_type).to eq("smart:symbol")
  end

  it "generates Turtle as skosxl:Label with symbol type" do
    s = Isq::SymbolTerm.new(
      id: "sym-t3-1.1-0",
      text: "l",
      lang: "en",
      term_form_type: "smart:symbol",
    )

    turtle = s.to_turtle
    expect(turtle).to include("a skosxl:Label")
    expect(turtle).to include('skosxl:literalForm "l"')
    expect(turtle).to include('smart:hasTermFormType smart:symbol')
  end

  it "generates JSON-LD" do
    s = Isq::SymbolTerm.new(
      id: "sym-t3-1.1-0",
      text: "L",
      lang: "en",
      term_form_type: "smart:symbol",
    )

    jsonld = s.to_jsonld
    expect(jsonld).to include("skosxl:Label")
    expect(jsonld).to include("L")
  end

  it "handles special characters in symbol text" do
    s = Isq::SymbolTerm.new(
      id: "sym-t2-5.1-0",
      text: "p ^^ q",
      lang: "en",
      term_form_type: "smart:symbol",
    )

    expect(s.text).to eq("p ^^ q")
    turtle = s.to_turtle
    expect(turtle).to include('skosxl:literalForm "p ^^ q"')
  end

  it "inherits from TermInstance" do
    expect(Isq::SymbolTerm < Isq::TermInstance).to be true
  end
end
