# frozen_string_literal: true

require "fileutils"
require "json"

module Isq
  class Export
    def initialize(dataset:, export_dir:, format: :both)
      @dataset = dataset
      @export_dir = export_dir
      @format = format
    end

    def run
      prepare_output_dir
      write_per_part
      write_bulk
      write_manifest
    end

    private

    def prepare_output_dir
      FileUtils.rm_rf(@export_dir)
      FileUtils.mkdir_p(@export_dir)
    end

    def write_per_part
      @dataset.part_keys.each do |part_key|
        part_dir = File.join(@export_dir, "part-#{part_key}")
        FileUtils.mkdir_p(part_dir)

        part_doc = Isq::PartDocument.for_part(part_key)
        entries = @dataset.entries_for_part(part_key)
        units = build_unit_instances(@dataset.unique_units_for_part(part_key), entries)

        if write_turtle?
          part_ttl = compose_part_turtle(part_doc, units, entries)
          File.write(File.join(part_dir, "index.ttl"), part_ttl)
        end

        if write_jsonld?
          part_jsonld = compose_part_jsonld(part_doc, units, entries)
          File.write(File.join(part_dir, "index.jsonld"), part_jsonld)
        end

        write_per_entry_files(part_dir, entries)
      end
    end

    def write_per_entry_files(part_dir, entries)
      entries.each do |entry|
        if write_turtle?
          File.write(File.join(part_dir, "#{entry.id}.ttl"), entry.to_turtle)
        end

        if write_jsonld?
          File.write(File.join(part_dir, "#{entry.id}.jsonld"), entry.to_jsonld)
        end
      end
    end

    def write_bulk
      if write_turtle?
        all_turtle = @dataset.part_keys.map do |part_key|
          part_doc = Isq::PartDocument.for_part(part_key)
          entries = @dataset.entries_for_part(part_key)
          units = build_unit_instances(@dataset.unique_units_for_part(part_key), entries)
          compose_part_turtle(part_doc, units, entries)
        end.join("\n")
        File.write(File.join(@export_dir, "iso80000-all.ttl"), all_turtle)
      end

      if write_jsonld?
        all_jsonld = @dataset.part_keys.map do |part_key|
          part_doc = Isq::PartDocument.for_part(part_key)
          entries = @dataset.entries_for_part(part_key)
          units = build_unit_instances(@dataset.unique_units_for_part(part_key), entries)
          compose_part_jsonld(part_doc, units, entries)
        end.join("\n")
        File.write(File.join(@export_dir, "iso80000-all.jsonld"), all_jsonld)
      end
    end

    def write_manifest
      manifest = {
        generated: Time.now.utc.iso8601,
        total_entries: @dataset.total_count,
        parts: @dataset.counts_by_part,
        namespaces: namespace_registry,
      }
      File.write(File.join(@export_dir, "manifest.json"), JSON.pretty_generate(manifest))
    end

    def build_unit_instances(unit_refs, entries)
      unit_map = collect_unit_data(entries)
      unit_refs.filter_map do |ref|
        data = unit_map[ref]
        next unless data

        Isq::Unit.new(
          id: ref.sub("isq:", ""),
          pref_label: data[:name],
          notation: data[:symbols],
          bindingness_type: "smart:normative",
        )
      end
    end

    def collect_unit_data(entries)
      entries.each_with_object({}) do |entry, map|
        next unless entry.is_a?(Isq::Quantity)
        next unless entry.unit_data

        map.merge!(entry.unit_data) { |_key, old, _new| old }
      end
    end

    def compose_part_turtle(part_doc, units, entries)
      lines = []
      lines << part_doc.to_turtle
      units.each { |u| lines << u.to_turtle }
      entries.each { |e| lines << e.to_turtle }
      lines.join("\n")
    end

    def compose_part_jsonld(part_doc, units, entries)
      lines = []
      lines << part_doc.to_jsonld
      units.each { |u| lines << u.to_jsonld }
      entries.each { |e| lines << e.to_jsonld }
      lines.join("\n")
    end

    def namespace_registry
      {
        smart: "https://w3id.org/standards/smart/ontologies/core/",
        isq: "https://w3id.org/standards/isq/ontologies/core/",
        dcterms: "http://purl.org/dc/terms/",
        skos: "http://www.w3.org/2004/02/skos/core#",
        skosxl: "http://www.w3.org/2008/05/skos-xl#",
      }
    end

    def write_turtle?
      @format == :both || @format == :ttl
    end

    def write_jsonld?
      @format == :both || @format == :jsonld
    end
  end
end
