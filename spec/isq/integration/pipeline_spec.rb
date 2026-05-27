# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

RSpec.describe "Full pipeline" do
  let(:dataset_dir) { File.join(__dir__, "..", "..", "..", "..", "iso-iec-80000", "sources", "dataset") }

  before { skip "Dataset not found at #{dataset_dir}" unless Dir.exist?(dataset_dir) }

  it "loads dataset and produces export output" do
    Dir.mktmpdir("isq-export-") do |export_dir|
      dataset = Isq::Dataset.load(dataset_dir)
      Isq::Export.new(dataset: dataset, export_dir: export_dir).run

      expect(Dir.glob(File.join(export_dir, "part-*"))).not_to be_empty
      expect(File.exist?(File.join(export_dir, "iso80000-all.ttl"))).to be true
      expect(File.exist?(File.join(export_dir, "iso80000-all.jsonld"))).to be true
      expect(File.exist?(File.join(export_dir, "manifest.json"))).to be true
    end
  end

  it "loads dataset with correct entry counts" do
    dataset = Isq::Dataset.load(dataset_dir)

    expect(dataset.total_count).to be > 0
    expect(dataset.part_keys).not_to be_empty
  end

  it "groups entries by part" do
    dataset = Isq::Dataset.load(dataset_dir)

    dataset.part_keys.each do |part_key|
      entries = dataset.entries_for_part(part_key)
      expect(entries).not_to be_empty
      entries.each do |entry|
        expect(entry.part).to eq(part_key)
      end
    end
  end

  it "generates per-part output files" do
    Dir.mktmpdir("isq-export-") do |export_dir|
      dataset = Isq::Dataset.load(dataset_dir)
      Isq::Export.new(dataset: dataset, export_dir: export_dir).run

      dataset.part_keys.each do |part_key|
        part_dir = File.join(export_dir, "part-#{part_key}")
        expect(File.exist?(File.join(part_dir, "index.ttl"))).to be true
        expect(File.exist?(File.join(part_dir, "index.jsonld"))).to be true
      end
    end
  end

  it "generates per-entry Turtle files" do
    Dir.mktmpdir("isq-export-") do |export_dir|
      dataset = Isq::Dataset.load(dataset_dir)
      Isq::Export.new(dataset: dataset, export_dir: export_dir).run

      first_part = dataset.part_keys.first
      part_dir = File.join(export_dir, "part-#{first_part}")
      entry_files = Dir.glob(File.join(part_dir, "*.ttl")).reject { |f| File.basename(f) == "index.ttl" }
      expect(entry_files).not_to be_empty
    end
  end

  it "supports TTL-only format" do
    Dir.mktmpdir("isq-export-") do |export_dir|
      dataset = Isq::Dataset.load(dataset_dir)
      Isq::Export.new(dataset: dataset, export_dir: export_dir, format: :ttl).run

      expect(File.exist?(File.join(export_dir, "iso80000-all.ttl"))).to be true
      expect(File.exist?(File.join(export_dir, "iso80000-all.jsonld"))).to be false
    end
  end

  it "supports JSON-LD-only format" do
    Dir.mktmpdir("isq-export-") do |export_dir|
      dataset = Isq::Dataset.load(dataset_dir)
      Isq::Export.new(dataset: dataset, export_dir: export_dir, format: :jsonld).run

      expect(File.exist?(File.join(export_dir, "iso80000-all.ttl"))).to be false
      expect(File.exist?(File.join(export_dir, "iso80000-all.jsonld"))).to be true
    end
  end

  it "generates valid manifest" do
    Dir.mktmpdir("isq-export-") do |export_dir|
      dataset = Isq::Dataset.load(dataset_dir)
      Isq::Export.new(dataset: dataset, export_dir: export_dir).run

      manifest = JSON.parse(File.read(File.join(export_dir, "manifest.json")))
      expect(manifest["total_entries"]).to eq(dataset.total_count)
      expect(manifest["generated"]).to match(/\d{4}-\d{2}-\d{2}T/)
      expect(manifest["namespaces"]).to include("smart", "isq", "dcterms", "skos", "skosxl")
    end
  end
end
