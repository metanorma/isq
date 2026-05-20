# frozen_string_literal: true

namespace :export do
  desc "Generate TTL and JSON-LD exports for all entries"
  task :all do
    require "isq"

    root = File.join(__dir__, "..", "..", "..")
    dataset_dir = ENV.fetch("ISQ_DATASET_DIR", File.join(root, "iso-iec-80000", "sources", "dataset"))
    export_dir = ENV.fetch("ISQ_EXPORT_DIR", File.join(root, "browser", "public", "exports"))

    dataset = Isq::Dataset.load(dataset_dir)
    Isq::Export.new(dataset: dataset, export_dir: export_dir).run

    puts "Generated exports in #{export_dir}:"
    puts "  #{dataset.total_count} entries across #{dataset.part_keys.length} parts"
  end
end
