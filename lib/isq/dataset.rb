# frozen_string_literal: true

module Isq
  class Dataset
    attr_reader :entries, :math_entries, :part_keys

    def initialize(entries: [], math_entries: [])
      @entries = Array(entries)
      @math_entries = Array(math_entries)
      index!
    end

    def self.load(dataset_dir)
      entries = load_yaml_file(dataset_dir, "quantities.yaml") { |yaml| Isq::Quantity.from_yaml(yaml) }
      math_entries = load_yaml_file(dataset_dir, "math.yaml") { |yaml| Isq::MathConcept.from_yaml(yaml) }

      new(entries: entries, math_entries: math_entries)
    end

    def entries_for_part(part_key)
      by_part[part_key] || []
    end

    def unique_units_for_part(part_key)
      part_entries = entries_for_part(part_key)
      seen = Set.new
      part_entries.each_with_object([]) do |entry, acc|
        next unless entry.is_a?(Isq::Quantity)
        next unless entry.has_unit

        Array(entry.has_unit).each do |unit_ref|
          next if seen.include?(unit_ref)

          seen << unit_ref
          acc << unit_ref
        end
      end
    end

    def total_count
      @entries.length + @math_entries.length
    end

    def counts_by_part
      by_part.transform_values(&:length)
    end

    private

    def by_part
      @by_part
    end

    def index!
      all_entries = @entries + @math_entries
      @by_part = all_entries.group_by(&:part)
      @part_keys = @by_part.keys.sort
    end

    def self.load_yaml_file(dir, filename)
      path = File.join(dir, filename)
      return [] unless File.exist?(path)

      yaml = File.read(path)
      yield yaml
    end
  end
end
