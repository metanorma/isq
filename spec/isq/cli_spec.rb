# frozen_string_literal: true

require "spec_helper"
require "isq/cli"
require "tmpdir"

RSpec.describe Isq::Cli do
  describe "help" do
    it "shows help for export command" do
      expect { Isq::Cli.start(["help", "export"]) }.to output(/Generate TTL and JSON-LD/).to_stdout
    end
  end

  describe "export command" do
    let(:dataset_dir) { ENV.fetch("ISQ_DATASET_DIR", File.join(__dir__, "..", "..", "..", "..", "iso-iec-80000", "sources", "dataset")) }

    before { skip "Dataset not found at #{dataset_dir}" unless Dir.exist?(dataset_dir) }

    it "generates exports via CLI" do
      Dir.mktmpdir do |tmpdir|
        Isq::Cli.start(["export", "-d", dataset_dir, "-o", tmpdir, "-f", "ttl"])

        expect(File).to exist(File.join(tmpdir, "iso80000-all.ttl"))
        expect(File).to exist(File.join(tmpdir, "manifest.json"))
      end
    end
  end
end
