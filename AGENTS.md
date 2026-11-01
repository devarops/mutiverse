# AGENTS.md

## Setup & commands

- `make tests` runs `busted tests/test.lua` inside Docker.
- `make check` runs `luacheck src` for linting.
- `docker exec mutiverse_ci make tests` to run tests in the container.
- Container name follows the pattern `${PWD##*/}_ci`.
- `docker compose up -d` to start the container in the background.

## Lua environment

- **Module path**: `package.path = 'src/?.lua;' .. package.path` is required before `require("mutator")` or `require("file_io")`.
- **Lua version**: Lua 5.1. `os.execute` returns a numeric exit code (0 for success, non-zero for failure), not a boolean.
- **Host/container Lua must match**: `cmd_run.lua` and `mutator.lua` run on the **host** system, not inside the Docker container. `os.execute` in Lua 5.2+ returns `ok, reason, code` (boolean/nil + string + number) instead of a plain numeric exit code. If the host's Lua version differs from the container's, `is_mutation_killed` breaks silently — always returning `true`. Use `lua -v` on both host and container to verify alignment.
- **Python3** is required at runtime. The module writes a Python script to a temp file and executes it with `python3` to extract mutation fields from a JSON plan.
- **jsonschema** CLI (from `python3-jsonschema` package) is required at runtime for `validate_plan_file`.
- **Capturing stdout**: Use `io.popen` for subprocess output:
  ```lua
  local handle = io.popen("lua -e \"...\"")
  local output = handle:read("*a")
  handle:close()
  ```
- **File I/O**: `io.open` is wrapped with `assert()` in `file_io.lua` — throws on missing files.

## Mutation data model

- Mutation plan follows `schema/mutation-plan.schema.json` (JSON Schema).
- Row/col fields are **0-based**. `end_col` is **exclusive**.
- A mutation can have `start_row`/`start_col`/`end_col` for location-aware replacement, or omit them for global replacement.
- When `original` does not match the text at the specified location, the function errors.

## Test framework

- **Busted** is the test runner. Tests live in `tests/test.lua`.
- `describe` / `it` blocks. `assert.*` matchers (e.g., `assert.is_true`, `assert.equals`, `assert.is_falsy`).
- `teardown` blocks for cleanup.
- Tests exercise both Lua source strings and file-based I/O.
- Tests for subprocess output use `io.popen` with inline Lua scripts.

## Git workflow

- Commit messages use gitmoji + imperative verb (e.g., `♻ 🧪 Rename Variable`).
- Messages start with gitmoji, have a blank line after the summary, then explanation.
- No Conventional Commits prefixes (`feat:`, `fix:`, etc.).
- `acceptance.json` and `log.txt` are gitignored.

## CI/CD

- GitHub Actions: `docker build` → `make check` → `make tests`.
- Pushes only to `develop` branch trigger CI.

## Makefile targets

| Target   | Command                                    |
|----------|--------------------------------------------|
| `check`  | `luacheck src`                             |
| `tests`  | `busted tests/test.lua`                    |
| `verify` | `qed verify specs/mutiverse.spec.json`     |
| `init`   | `parse tests` (first-time setup)           |

## TDD workflow

- Red: Write failing test. Green: Minimal implementation. Refactor: Improve without changing behavior.
- Task tracking via `specs/mutiverse.spec.json` (qed spec format).
- Each criterion has a `description`, `verify` block (type + command), and optional `schedule`/`skip`.
- Completed criteria use `skip: "Task completed"`; active criteria have no skip.
- Run `make verify` to check all criteria via qed.

## ATDD four-layer separation

Acceptance Test Driven Development separates concerns into four layers:

1. **Test Cases** — written in problem-domain language from an external user perspective.
2. **Domain Specific Language** — shared between test cases, translates domain language into test steps.
3. **Protocol Drivers** — translate DSL commands into interactions with the System Under Test.
4. **System Under Test** — deployed in production-like environments via infrastructure-as-code.

Unit tests and acceptance tests verify different concerns:
- **Unit tests** validate internal behavior from a developer perspective. They exercise individual functions in isolation from infrastructure. They answer *does the code work correctly?*
- **Acceptance tests** validate external behavior from a user perspective. They exercise the full system through public interfaces in realistic environments. They answer *does the system solve the right problem?*

## Project structure

```
src/              Lua source modules
  mutator.lua     Core mutation logic + test runner
  file_io.lua     File read/write helpers
tests/            Busted test suite
  test.lua        All tests
  data/           Fixture files (Python, R)
specs/            QED spec (acceptance criteria)
  mutiverse.spec.json  All 19 criteria
schemas/          JSON Schema for mutation plan
assets/           Diagrams and images
```

## Key constraints

1. The core operates only on raw source code and byte ranges.
2. Plug-ins fully own parsing and syntax analysis.
3. The only shared contract between host and plug-ins is mutation candidates (JSON).
