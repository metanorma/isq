# 06 — CLI (Thor) and Rake refactor

## Goal

Add a Thor-based CLI (`exe/isq`) with an `export` command, and refactor
`lib/tasks/export.rake` to a thin one-liner that delegates to `Isq::Export`.

## Rationale

The canon gem uses Thor for its CLI (`exe/canon`). We follow the same pattern:

- **CLI**: thin Thor layer that parses options and calls the Ruby API
- **Rake**: thin wrapper that calls the same API with env var defaults
- **Ruby API**: `Isq::Export` does the actual work

This gives three entry points (CLI, rake, Ruby) all going through one code path.

## Design decisions

### Why Thor?

- Standard Ruby CLI framework (rails, rspec, bundler all use it)
- Declarative option parsing with type checking
- Built-in help generation
- Consistent with the canon gem pattern

### Rake backward compatibility

The existing `rake export:all` task must continue to work with the same
`ISQ_DATASET_DIR` and `ISQ_EXPORT_DIR` environment variables. The refactor
only changes the implementation, not the interface.

### Gem dependency

Add `thor` to the gemspec (runtime dependency, not just dev dependency).

## Implementation

### File: `exe/isq`

```ruby
#!/usr/bin/env ruby
# frozen_string_literal: true

require "isq/cli"

Isq::Cli.start(ARGV)
```

Make executable: `chmod +x exe/isq`

### File: `lib/isq/cli.rb`

```ruby
# frozen_string_literal: true

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
                  desc: "YAML dataset directory (default: ../iso-iec-80000/sources/dataset)"
    method_option :export_dir,
                  aliases: "-o",
                  type: :string,
                  desc: "Output directory (default: ../browser/public/exports)"
    method_option :format,
                  aliases: "-f",
                  type: :string,
                  enum: %w[ttl jsonld both],
                  default: "both",
                  desc: "Output format: ttl, jsonld, or both"
    def export
      dataset_dir = options[:dataset_dir] || ENV.fetch("ISQ_DATASET_DIR",
                                                        default_dataset_dir)
      export_dir = options[:export_dir] || ENV.fetch("ISQ_EXPORT_DIR",
                                                      default_export_dir)

      dataset = Isq::Dataset.load(dataset_dir)
      Isq::Export.new(dataset: dataset, export_dir: export_dir,
                      format: options[:format].to_sym).run

      say "Generated exports in #{export_dir}:"
      say "  #{dataset.total_count} entries across #{dataset.part_keys.length} parts"
    end

    private

    def default_dataset_dir
      File.join(__dir__, "..", "..", "..", "iso-iec-80000", "sources", "dataset")
    end

    def default_export_dir
      File.join(__dir__, "..", "..", "..", "browser", "public", "exports")
    end
  end
end
```

### File: `lib/tasks/export.rake` (rewrite)

```ruby
# frozen_string_literal: true

namespace :export do
  desc "Generate TTL and JSON-LD exports for all entries"
  task :all do
    require "isq"

    dataset_dir = ENV.fetch("ISQ_DATASET_DIR",
                            File.join(__dir__, "..", "..", "..", "iso-iec-80000", "sources", "dataset"))
    export_dir = ENV.fetch("ISQ_EXPORT_DIR",
                           File.join(__dir__, "..", "..", "..", "browser", "public", "exports"))

    dataset = Isq::Dataset.load(dataset_dir)
    Isq::Export.new(dataset: dataset, export_dir: export_dir).run
  end
end
```

### File: `isq.gemspec` (update)

Add `thor` dependency:
```ruby
spec.add_dependency "thor", "~> 1.3"
spec.executables = ["isq"]
```

Create `exe/` directory.

## Spec

### File: `spec/isq/cli_spec.rb`

- `isq export` with default paths loads dataset and runs export
- `isq export -d /custom/path` uses custom dataset_dir
- `isq export -o /custom/path` uses custom export_dir
- `isq export --format ttl` generates only Turtle
- `isq help export` shows usage information
- Error handling: missing dataset dir shows clear error message
- Uses `Cli.start(["export", "-d", ...])` for testing (no shell exec)

### File: `spec/isq/rake_spec.rb`

- `Rake::Task["export:all"].invoke` delegates to `Isq::Export`
- Respects `ISQ_DATASET_DIR` and `ISQ_EXPORT_DIR` env vars
- Backward compatible with existing CI workflow

## Acceptance

- `exe/isq export` works as CLI command
- `bundle exec rake export:all` still works identically
- `thor` added to gemspec dependencies
- `exe/isq` is executable
- All specs pass, no `send`, no `respond_to?`
