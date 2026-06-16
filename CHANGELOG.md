# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [v0.2.0] - 2026-06-15

### Added

- `mutator.apply_mutations_from_plan(plan_path, test_command, report_path)` — full orchestrator: reads a JSON plan, applies mutations, runs tests, prints outcomes, and writes a JSON report
- JSON report includes all mutation fields (`file_path`, `start_row`, `start_col`, `end_col`, `original`, `replacement`, `operator`) plus a `killed` status per mutation
- `json_escape` and `build_mutation_report` internal functions for safe JSON serialization
- `mutate_and_test_file` internal function for in-place mutation with file restoration

### Changed

- Mutation extraction script generated dynamically from `FIELD_SPECS` instead of hardcoded field list

### Removed

- `mutator.apply_plan(plan, source)` — replaced by `apply_mutations_from_plan`
- `mutator.plan_has_mutations(plan)` — superseded by `validate_plan_file`
- Report encoding pipeline (`encode_report`, `encode_report_entry`, `encode_json_value`, `escape_json`)
- Git-based source restoration pipeline (`restore_source_via_git`, `apply_single_mutation`, `build_report_entry`)

## [v0.1.0] - 2026-06-12

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

[Unreleased]: https://github.com/devarops/mutiverse/compare/v0.2.0...HEAD
[v0.2.0]: https://github.com/devarops/mutiverse/compare/v0.1.0...v0.2.0
[v0.1.0]: https://github.com/devarops/mutiverse/releases/tag/v0.1.0
