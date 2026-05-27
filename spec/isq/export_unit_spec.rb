# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "json"

RSpec.describe Isq::Export do
  let(:quantity_yaml) do
    <<~YAML
      ---
      - part: '3'
        edition: '2019'
        id: t3-1.1
        num: 3-1.1
        designations:
        - designation:
            en:
              text: length
              index_as:
              - length
        symbols:
        - l
        - L
        def:
          en: linear extent in space between any two points
        units:
        - en: metre
          symbol:
          - m
        remarks:
          en: Length remark.
    YAML
  end

  let(:entries) { Isq::Quantity.from_yaml(quantity_yaml) }
  let(:dataset) { Isq::Dataset.new(entries: entries) }

  describe "#run with in-memory data" do
    it "creates per-part directories with index files" do
      Dir.mktmpdir do |tmpdir|
        described_class.new(dataset: dataset, export_dir: tmpdir).run

        part_dir = File.join(tmpdir, "part-3")
        expect(Dir).to exist(part_dir)
        expect(File).to exist(File.join(part_dir, "index.ttl"))
        expect(File).to exist(File.join(part_dir, "index.jsonld"))
      end
    end

    it "creates per-entry files" do
      Dir.mktmpdir do |tmpdir|
        described_class.new(dataset: dataset, export_dir: tmpdir).run

        expect(File).to exist(File.join(tmpdir, "part-3", "t3-1.1.ttl"))
        expect(File).to exist(File.join(tmpdir, "part-3", "t3-1.1.jsonld"))
      end
    end

    it "creates bulk export files" do
      Dir.mktmpdir do |tmpdir|
        described_class.new(dataset: dataset, export_dir: tmpdir).run

        expect(File).to exist(File.join(tmpdir, "iso80000-all.ttl"))
        expect(File).to exist(File.join(tmpdir, "iso80000-all.jsonld"))
      end
    end

    it "creates manifest with correct metadata" do
      Dir.mktmpdir do |tmpdir|
        described_class.new(dataset: dataset, export_dir: tmpdir).run

        manifest = JSON.parse(File.read(File.join(tmpdir, "manifest.json")))
        expect(manifest["total_entries"]).to eq(1)
        expect(manifest["parts"]["3"]).to eq(1)
        expect(manifest["namespaces"]).to include("smart", "isq")
      end
    end

    it "produces Turtle with domain class types" do
      Dir.mktmpdir do |tmpdir|
        described_class.new(dataset: dataset, export_dir: tmpdir).run

        ttl = File.read(File.join(tmpdir, "iso80000-all.ttl"))
        expect(ttl).to include("a isq:Quantity")
        expect(ttl).to include("a smart:PublicationDocument")
        expect(ttl).to include("a skosxl:Label")
      end
    end

    it "builds Unit instances with real names from unit_data" do
      Dir.mktmpdir do |tmpdir|
        described_class.new(dataset: dataset, export_dir: tmpdir).run

        ttl = File.read(File.join(tmpdir, "iso80000-all.ttl"))
        expect(ttl).to include("a isq:Unit")
        expect(ttl).to include("metre")
        expect(ttl).to include('"m"')
      end
    end

    it "supports TTL-only format" do
      Dir.mktmpdir do |tmpdir|
        described_class.new(dataset: dataset, export_dir: tmpdir, format: :ttl).run

        expect(File).to exist(File.join(tmpdir, "iso80000-all.ttl"))
        expect(File).not_to exist(File.join(tmpdir, "iso80000-all.jsonld"))
      end
    end

    it "supports JSON-LD-only format" do
      Dir.mktmpdir do |tmpdir|
        described_class.new(dataset: dataset, export_dir: tmpdir, format: :jsonld).run

        expect(File).not_to exist(File.join(tmpdir, "iso80000-all.ttl"))
        expect(File).to exist(File.join(tmpdir, "iso80000-all.jsonld"))
      end
    end

    it "is idempotent (cleans before writing)" do
      Dir.mktmpdir do |tmpdir|
        stale_file = File.join(tmpdir, "stale.txt")
        File.write(stale_file, "old data")

        described_class.new(dataset: dataset, export_dir: tmpdir).run

        expect(File).not_to exist(stale_file)
        expect(File).to exist(File.join(tmpdir, "manifest.json"))
      end
    end
  end
end
