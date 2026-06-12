# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `mutator.apply_mutation(mutation, source)` — apply a single mutation to source text
- `mutator.apply_plan(plan, source)` — apply all mutations from a plan sequentially
- `mutator.apply_mutation_to_file(mutation, input_path, output_path)` — apply mutation to a file
- `mutator.run_test(command)` — execute a test command and print outcome emoji
- `mutator.is_mutation_killed(command)` — determine whether a mutation was killed
- `mutator.SURVIVED_MESSAGE` and `mutator.KILLED_MESSAGE` — output message constants
- Location-aware mutation via `start_row`, `start_col`, `end_col` fields
- Error reporting when `original` does not match text at the specified mutation location
- Validation function `mutator.has_mutations(plan)` to check plan structure
- `file_io.read(path)` and `file_io.write(path, content)` — file read/write helpers
