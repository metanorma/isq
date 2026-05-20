# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

RSpec.describe Isq::Dataset do
  let(:dataset_dir) { ENV.fetch("ISQ_DATASET_DIR", File.join(__dir__, "..", "..", "..", "..", "iso-iec-80000", "sources", "dataset")) }

  before { skip "Dataset not found at #{dataset_dir}" unless Dir.exist?(dataset_dir) }

  describe ".load" do
    it "parses both YAML files" do
      dataset = described_class.load(dataset_dir)

      expect(dataset.entries).not_to be_empty
      expect(dataset.math_entries).not_to be_empty
    end

    it "returns Quantity instances" do
      dataset = described_class.load(dataset_dir)

      expect(dataset.entries.first).to be_a(Isq::Quantity)
    end

    it "returns MathConcept instances" do
      dataset = described_class.load(dataset_dir)

      expect(dataset.math_entries.first).to be_a(Isq::MathConcept)
    end
  end

  describe "#entries_for_part" do
    it "returns only entries for the specified part" do
      dataset = described_class.load(dataset_dir)

      part3 = dataset.entries_for_part("3")
      expect(part3).not_to be_empty
      part3.each { |e| expect(e.part).to eq("3") }
    end

    it "returns empty array for unknown part" do
      dataset = described_class.load(dataset_dir)

      expect(dataset.entries_for_part("999")).to eq([])
    end
  end

  describe "#unique_units_for_part" do
    it "deduplicates units across entries" do
      dataset = described_class.load(dataset_dir)

      units = dataset.unique_units_for_part("3")
      expect(units).not_to be_empty
      expect(units.uniq).to eq(units)
    end
  end

  describe "#total_count" do
    it "matches the sum of entries and math entries" do
      dataset = described_class.load(dataset_dir)

      expect(dataset.total_count).to eq(dataset.entries.length + dataset.math_entries.length)
    end
  end

  describe "#counts_by_part" do
    it "has counts for each part key" do
      dataset = described_class.load(dataset_dir)

      counts = dataset.counts_by_part
      dataset.part_keys.each do |key|
        expect(counts).to have_key(key)
        expect(counts[key]).to be_positive
      end
    end
  end
end
