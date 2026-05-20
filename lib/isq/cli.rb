# frozen_string_literal: true

require "isq"
require "thor"

module Isq
  class Cli < Thor
    def self.exit_on_failure?
      true
    end

    desc "export", "Generate TTL and JSON-LD exports from YAML source data"
    method_option :dataset_dir,
                  aliases: "-d",
                  type: :string,
                  desc: "YAML dataset directory"
    method_option :export_dir,
                  aliases: "-o",
                  type: :string,
                  desc: "Output directory"
    method_option :format,
                  aliases: "-f",
                  type: :string,
                  enum: %w[ttl jsonld both],
                  default: "both",
                  desc: "Output format: ttl, jsonld, or both"
    def export
      dataset_dir = options[:dataset_dir] || ENV.fetch("ISQ_DATASET_DIR", default_dataset_dir)
      export_dir = options[:export_dir] || ENV.fetch("ISQ_EXPORT_DIR", default_export_dir)

      dataset = Isq::Dataset.load(dataset_dir)
      Isq::Export.new(dataset: dataset, export_dir: export_dir,
                      format: options[:format].to_sym).run

      say "Generated exports in #{export_dir}:"
      say "  #{dataset.total_count} entries across #{dataset.part_keys.length} parts"
    end

    private

    def default_dataset_dir
      File.expand_path("../../../iso-iec-80000/sources/dataset", __dir__)
    end

    def default_export_dir
      File.expand_path("../../../browser/public/exports", __dir__)
    end
  end
end
