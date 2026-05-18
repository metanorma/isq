# frozen_string_literal: true

require "yaml"
require "json"
require "fileutils"

namespace :export do
  ROOT = File.join(__dir__, "..", "..", "..")
  EXPORT_DIR = ENV.fetch("ISQ_EXPORT_DIR", File.join(ROOT, "browser", "public", "exports"))
  DATASET_DIR = ENV.fetch("ISQ_DATASET_DIR", File.join(ROOT, "iso-iec-80000", "sources", "dataset"))

  PART_TITLES = {
    "3" => "Space and Time", "4" => "Mechanics", "5" => "Thermodynamics",
    "6" => "Electromagnetism", "7" => "Light and Radiation", "8" => "Acoustics",
    "9" => "Physical Chemistry", "10" => "Atomic and Nuclear", "11" => "Characteristic Numbers",
    "12" => "Condensed Matter", "13" => "Information Science", "2" => "Mathematics",
  }.freeze

  SMART = "https://w3id.org/standards/smart/ontologies/core/"
  ISO = "https://w3id.org/standards/isoiec80000/ontologies/core/"
  DCTERMS = "http://purl.org/dc/terms/"
  SKOS = "http://www.w3.org/2004/02/skos/core#"
  SKOSXL = "http://www.w3.org/2008/05/skos-xl#"

  JSONLD_CONTEXT = {
    "@context" => {
      "smart" => SMART,
      "isoiec80000" => ISO,
      "dcterms" => DCTERMS,
      "skos" => SKOS,
      "skosxl" => SKOSXL,
      "rdf" => "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
      "rdfs" => "http://www.w3.org/2000/01/rdf-schema#",
      "owl" => "http://www.w3.org/2002/07/owl#",
      "xsd" => "http://www.w3.org/2001/XMLSchema#",
    },
  }.freeze

  def load_entries
    quantities = YAML.load_file(File.join(DATASET_DIR, "quantities.yaml"))
    math = YAML.load_file(File.join(DATASET_DIR, "math.yaml"))
    quantities + math
  end

  def math?(entry)
    entry["part"].to_s.start_with?("2")
  end

  def entry_rdf_type(entry)
    math?(entry) ? "isoiec80000:MathConcept" : "isoiec80000:Quantity"
  end

  def unit_uri(unit)
    sym = unit["symbol"]&.first
    sym ? "isoiec80000:unit-#{sym}" : "isoiec80000:unit-#{unit['en']&.downcase&.gsub(/\s+/, '-')}"
  end

  def escape_literal(s)
    s.gsub("\\", "\\\\\\\\").gsub('"', '\\"')
  end

  def generate_turtle(entry)
    id = entry["id"]
    rdf_type = entry_rdf_type(entry)
    lines = []

    # Term instances for designations
    entry["designations"]&.each_with_index do |des, i|
      tid = "term-#{id}-#{i}"
      text = des.dig("designation", "en", "text")
      next unless text

      lines << "isoiec80000:#{tid} a smart:Term, skosxl:Label ;"
      lines << "  skosxl:literalForm \"#{escape_literal(text)}\"@en ;"
      lines << "  smart:hasTermFormType smart:fullForm ."
      lines << ""
    end

    # Term instances for symbols
    entry["symbols"]&.each_with_index do |sym, i|
      tid = "sym-#{id}-#{i}"
      lines << "isoiec80000:#{tid} a smart:Term, skosxl:Label ;"
      lines << "  skosxl:literalForm \"#{escape_literal(sym)}\"@en ;"
      lines << "  smart:hasTermFormType smart:symbol ."
      lines << ""
    end

    # Main entry
    lines << "isoiec80000:#{id} a #{rdf_type}, smart:TermEntry ;"
    lines << "  dcterms:identifier \"#{entry['num']}\" ;"

    # skosxl:prefLabel for first designation
    if entry["designations"]&.any?
      lines << "  skosxl:prefLabel isoiec80000:term-#{id}-0 ;"
    end

    # skosxl:altLabel for remaining designations
    entry["designations"]&.each_with_index do |_des, i|
      next if i == 0
      lines << "  skosxl:altLabel isoiec80000:term-#{id}-#{i} ;"
    end

    # skosxl:altLabel for symbol terms
    entry["symbols"]&.each_with_index do |_sym, i|
      lines << "  skosxl:altLabel isoiec80000:sym-#{id}-#{i} ;"
    end

    if entry["def"]&.dig("en")
      lines << "  skos:definition \"\"\"#{escape_literal(entry['def']['en'])}\"\"\"@en ;"
    end

    if entry["remarks"]&.dig("en")
      lines << "  skos:note \"\"\"#{escape_literal(entry['remarks']['en'])}\"\"\"@en ;"
    end

    if entry["units"]&.any?
      for unit in entry["units"]
        lines << "  isoiec80000:hasUnit #{unit_uri(unit)} ;"
      end
    end

    lines << "  smart:hasBindingnessType smart:normative ;"
    lines << "  dcterms:isPartOf isoiec80000:part-#{entry['part']} ."

    lines.join("\n")
  end

  def generate_unit_turtle(unit)
    uri = unit_uri(unit)
    name = unit["en"]
    lines = ["#{uri} a isoiec80000:Unit, smart:TermEntry ;"]
    lines << "  skos:prefLabel \"#{name}\"@en ;"
    if unit["symbol"]&.any?
      for sym in unit["symbol"]
        lines << "  skos:notation \"#{sym}\" ;"
      end
    end
    lines << "  smart:hasBindingnessType smart:normative ."
    lines.join("\n")
  end

  def entry_jsonld(entry)
    id = entry["id"]
    part = entry["part"]

    # Term instances for designations
    terms = entry["designations"]&.each_with_index&.map do |des, i|
      text = des.dig("designation", "en", "text")
      next unless text

      {
        "@id" => "#{ISO}term-#{id}-#{i}",
        "@type" => ["smart:Term", "skosxl:Label"],
        "skosxl:literalForm" => { "@value" => text, "@language" => "en" },
        "smart:hasTermFormType" => { "@id" => "smart:fullForm" },
      }
    end&.compact || []

    # Term instances for symbols
    symbol_terms = entry["symbols"]&.each_with_index&.map do |sym, i|
      {
        "@id" => "#{ISO}sym-#{id}-#{i}",
        "@type" => ["smart:Term", "skosxl:Label"],
        "skosxl:literalForm" => { "@value" => sym, "@language" => "en" },
        "smart:hasTermFormType" => { "@id" => "smart:symbol" },
      }
    end || []

    all_terms = terms + symbol_terms

    entry_obj = {
      "@id" => "#{ISO}#{id}",
      "@type" => [entry_rdf_type(entry), "smart:TermEntry"],
      "dcterms:identifier" => entry["num"],
    }

    if terms.any?
      entry_obj["skosxl:prefLabel"] = { "@id" => "#{ISO}term-#{id}-0" }
    end

    alt_labels = []
    entry["designations"]&.each_with_index do |_des, i|
      next if i == 0
      alt_labels << { "@id" => "#{ISO}term-#{id}-#{i}" }
    end
    entry["symbols"]&.each_with_index do |_sym, i|
      alt_labels << { "@id" => "#{ISO}sym-#{id}-#{i}" }
    end
    entry_obj["skosxl:altLabel"] = alt_labels if alt_labels.any?

    if entry["def"]&.dig("en")
      entry_obj["skos:definition"] = { "@value" => entry["def"]["en"], "@language" => "en" }
    end

    if entry["remarks"]&.dig("en")
      entry_obj["skos:note"] = { "@value" => entry["remarks"]["en"], "@language" => "en" }
    end

    if entry["units"]&.any?
      entry_obj["isoiec80000:hasUnit"] = entry["units"].map { |u| { "@id" => unit_uri(u) } }
    end

    entry_obj["smart:hasBindingnessType"] = { "@id" => "smart:normative" }
    entry_obj["dcterms:isPartOf"] = { "@id" => "#{ISO}part-#{part}" }

    { "@graph" => all_terms + [entry_obj] }
  end

  def generate_part_turtle(part_key, part_entries)
    lines = [
      "@prefix isoiec80000: <#{ISO}> .",
      "@prefix smart: <#{SMART}> .",
      "@prefix dcterms: <#{DCTERMS}> .",
      "@prefix skos: <#{SKOS}> .",
      "@prefix skosxl: <#{SKOSXL}> .",
      "",
    ]

    # PublicationDocument instance
    lines << "isoiec80000:part-#{part_key} a smart:PublicationDocument ;"
    lines << "  dcterms:title \"#{PART_TITLES[part_key] || "Part #{part_key}"}\"@en ;"
    lines << "  dcterms:identifier \"ISO 80000-#{part_key}\" ;"
    lines << "  smart:hasPublicationType smart:internationalStandard ;"
    lines << "  smart:hasBindingnessType smart:normative ."
    lines << ""

    # Collect unique units
    units = part_entries.each_with_object([]) do |entry, acc|
      entry["units"]&.each do |u|
        key = unit_uri(u)
        acc << u unless acc.any? { |existing| unit_uri(existing) == key }
      end
    end

    units.each do |u|
      lines << generate_unit_turtle(u)
      lines << ""
    end

    part_entries.each do |entry|
      lines << generate_turtle(entry)
      lines << ""
    end

    lines.join("\n")
  end

  desc "Generate TTL and JSON-LD exports for all entries"
  task :all do
    require "sdu_smart"

    FileUtils.rm_rf(EXPORT_DIR)
    FileUtils.mkdir_p(EXPORT_DIR)

    entries = load_entries
    by_part = entries.group_by { |e| e["part"].to_s }

    all_turtle = []
    all_jsonld = []

    by_part.each do |part_key, part_entries|
      part_dir = File.join(EXPORT_DIR, "part-#{part_key}")
      FileUtils.mkdir_p(part_dir)

      # Per-part Turtle
      part_ttl = generate_part_turtle(part_key, part_entries)
      File.write(File.join(part_dir, "index.ttl"), part_ttl)

      # Per-part JSON-LD
      part_graphs = part_entries.map { |e| entry_jsonld(e) }
      part_jsonld = { **JSONLD_CONTEXT, "@graph" => part_graphs.flat_map { |g| g["@graph"] } }
      File.write(File.join(part_dir, "index.jsonld"), JSON.pretty_generate(part_jsonld))

      all_turtle << part_ttl
      all_jsonld.concat(part_graphs.flat_map { |g| g["@graph"] })

      # Per-entry files
      part_entries.each do |entry|
        base = entry["id"]
        entry_json = entry_jsonld(entry)
        File.write(File.join(part_dir, "#{base}.ttl"), generate_turtle(entry))
        File.write(File.join(part_dir, "#{base}.jsonld"), JSON.pretty_generate({ **JSONLD_CONTEXT, **entry_json }))
      end
    end

    # Full bulk exports
    File.write(File.join(EXPORT_DIR, "iso80000-all.ttl"), all_turtle.join("\n"))
    bulk_jsonld = { **JSONLD_CONTEXT, "@graph" => all_jsonld }
    File.write(File.join(EXPORT_DIR, "iso80000-all.jsonld"), JSON.pretty_generate(bulk_jsonld))

    # Manifest
    manifest = {
      generated: Time.now.utc.iso8601,
      total_entries: entries.length,
      parts: by_part.transform_values(&:length),
      namespaces: {
        smart: SMART,
        isoiec80000: ISO,
        dcterms: DCTERMS,
        skos: SKOS,
        skosxl: SKOSXL,
      },
    }
    File.write(File.join(EXPORT_DIR, "manifest.json"), JSON.pretty_generate(manifest))

    puts "Generated exports in #{EXPORT_DIR}:"
    puts "  #{entries.length} entries across #{by_part.length} parts"
  end
end
