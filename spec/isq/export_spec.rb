# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "json"

RSpec.describe Isq::Export do
  let(:dataset_dir) { ENV.fetch("ISQ_DATASET_DIR", File.join(__dir__, "..", "..", "..", "..", "iso-iec-80000", "sources", "dataset")) }

  before { skip "Dataset not found at #{dataset_dir}" unless Dir.exist?(dataset_dir) }

  let(:dataset) { Isq::Dataset.load(dataset_dir) }
  let(:export_dir) { Dir.mktmpdir }

  after { FileUtils.rm_rf(export_dir) if Dir.exist?(export_dir) }

  describe "#run" do
    it "creates per-part directories with index files" do
      described_class.new(dataset: dataset, export_dir: export_dir).run

      dataset.part_keys.each do |part_key|
        part_dir = File.join(export_dir, "part-#{part_key}")
        expect(Dir).to exist(part_dir)
        expect(File).to exist(File.join(part_dir, "index.ttl"))
        expect(File).to exist(File.join(part_dir, "index.jsonld"))
      end
    end

    it "creates per-entry files" do
      described_class.new(dataset: dataset, export_dir: export_dir).run

      part3_entries = dataset.entries_for_part("3")
      part3_entries.first(3).each do |entry|
        expect(File).to exist(File.join(export_dir, "part-3", "#{entry.id}.ttl"))
        expect(File).to exist(File.join(export_dir, "part-3", "#{entry.id}.jsonld"))
      end
    end

    it "creates bulk export files" do
      described_class.new(dataset: dataset, export_dir: export_dir).run

      expect(File).to exist(File.join(export_dir, "iso80000-all.ttl"))
      expect(File).to exist(File.join(export_dir, "iso80000-all.jsonld"))
    end

    it "creates manifest with correct metadata" do
      described_class.new(dataset: dataset, export_dir: export_dir).run

      manifest_path = File.join(export_dir, "manifest.json")
      expect(File).to exist(manifest_path)

      manifest = JSON.parse(File.read(manifest_path))
      expect(manifest["total_entries"]).to eq(dataset.total_count)
      expect(manifest["parts"]).to be_a(Hash)
      expect(manifest["generated"]).to be_a(String)
      expect(manifest["namespaces"]).to include("smart", "isoiec80000")
    end

    it "produces Turtle with domain class types" do
      described_class.new(dataset: dataset, export_dir: export_dir).run

      ttl = File.read(File.join(export_dir, "iso80000-all.ttl"))
      expect(ttl).to include("a isoiec80000:Quantity")
      expect(ttl).to include("a skosxl:Label")
    end

    it "is idempotent (cleans before writing)" do
      stale_file = File.join(export_dir, "stale.txt")
      File.write(stale_file, "old data")

      described_class.new(dataset: dataset, export_dir: export_dir).run

      expect(File).not_to exist(stale_file)
      expect(File).to exist(File.join(export_dir, "manifest.json"))
    end

    it "supports TTL-only format" do
      described_class.new(dataset: dataset, export_dir: export_dir, format: :ttl).run

      expect(File).to exist(File.join(export_dir, "iso80000-all.ttl"))
      expect(File).not_to exist(File.join(export_dir, "iso80000-all.jsonld"))
    end

    it "supports JSON-LD-only format" do
      described_class.new(dataset: dataset, export_dir: export_dir, format: :jsonld).run

      expect(File).not_to exist(File.join(export_dir, "iso80000-all.ttl"))
      expect(File).to exist(File.join(export_dir, "iso80000-all.jsonld"))
    end
  end
end
