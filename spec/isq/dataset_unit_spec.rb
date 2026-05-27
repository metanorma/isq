# frozen_string_literal: true

require "spec_helper"

RSpec.describe Isq::Dataset do
  describe "in-memory operations" do
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
            en: Length does not need to be measured along a straight line.
        - part: '3'
          edition: '2019'
          id: t3-4.1
          num: 3-4.1
          designations:
          - designation:
              en:
                text: velocity
                index_as:
                - velocity
          symbols:
          - v
          def:
            en: distance divided by time
          units:
          - en: metre per second
            symbol:
            - m/s
      YAML
    end

    let(:math_yaml) do
      <<~YAML
        ---
        - part: 2-5
          edition: '2019'
          id: t2-5.1
          num: 2-5.1
          designations:
          - designation:
              en:
                text: conjunction
                index_as:
                - conjunction
          def:
            en: conjunction of p and q
          symbols:
          - p ^^ q
      YAML
    end

    let(:entries) { Isq::Quantity.from_yaml(quantity_yaml) }
    let(:math_entries) { Isq::MathConcept.from_yaml(math_yaml) }
    let(:dataset) { Isq::Dataset.new(entries: entries, math_entries: math_entries) }

    describe "#total_count" do
      it "returns sum of entries and math entries" do
        expect(dataset.total_count).to eq(3)
      end
    end

    describe "#part_keys" do
      it "returns sorted part keys" do
        expect(dataset.part_keys).to eq(%w[2-5 3])
      end
    end

    describe "#entries_for_part" do
      it "returns entries for a specific part" do
        part3 = dataset.entries_for_part("3")
        expect(part3.length).to eq(2)
        part3.each { |e| expect(e.part).to eq("3") }
      end

      it "returns math entries for their part" do
        part25 = dataset.entries_for_part("2-5")
        expect(part25.length).to eq(1)
        expect(part25.first).to be_a(Isq::MathConcept)
      end

      it "returns empty array for unknown part" do
        expect(dataset.entries_for_part("999")).to eq([])
      end
    end

    describe "#unique_units_for_part" do
      it "deduplicates units within a part" do
        units = dataset.unique_units_for_part("3")
        expect(units).to eq(%w[isq:unit-m isq:unit-m/s])
      end

      it "returns empty array for part with no units" do
        units = dataset.unique_units_for_part("2-5")
        expect(units).to be_empty
      end
    end

    describe "#counts_by_part" do
      it "returns hash with correct counts" do
        counts = dataset.counts_by_part
        expect(counts["3"]).to eq(2)
        expect(counts["2-5"]).to eq(1)
      end
    end

    describe "unit_data preservation" do
      it "stores unit name and symbols from YAML" do
        length_entry = entries.first
        expect(length_entry.unit_data).to include(
          "isq:unit-m" => { name: "metre", symbols: ["m"] },
        )
      end

      it "stores data for multiple units" do
        all_unit_data = entries.each_with_object({}) do |e, map|
          next unless e.unit_data
          map.merge!(e.unit_data)
        end
        expect(all_unit_data).to include(
          "isq:unit-m" => { name: "metre", symbols: ["m"] },
          "isq:unit-m/s" => { name: "metre per second", symbols: ["m/s"] },
        )
      end
    end
  end
end
