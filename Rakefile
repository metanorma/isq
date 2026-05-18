# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

Dir.glob("lib/tasks/*.rake").each { |f| import f }

RSpec::Core::RakeTask.new(:spec)

task default: :spec
