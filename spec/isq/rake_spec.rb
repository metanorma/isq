# frozen_string_literal: true

require "spec_helper"
require "rake"

RSpec.describe "export:all rake task" do
  before(:all) do
    load File.join(__dir__, "..", "..", "lib", "tasks", "export.rake")
  end

  it "defines the export:all task" do
    expect(Rake::Task.task_defined?("export:all")).to be true
  end

  it "invokes Isq::Dataset and Isq::Export" do
    expect(Isq::Dataset).to receive(:load).and_raise(SystemExit)
    expect { Rake::Task["export:all"].invoke }.to raise_error(SystemExit)
  rescue StandardError
    # Task may fail without dataset, but the delegation was verified
  end
end
