# The Gold

- After the main loop in apply_mutations_from_plan is done, print a summary line with the total killed/survived counts and the report path:
  E.g. 3 killed, 1 survived. Report written to /path/report.json.
  It gives the user a quick overview without reading the report file.
---

# Backlog not part of the current Gold

The items listed below are not part of the current Gold. They are backlog items kept for future cycles.

## CLI design (from 2026-06-21 design session)

### Layout in target project

```
templater/
  .mutiverse/             # cloned from github.com/devarops/mutiverse
    mutiverse             # shell wrapper entry point
    schemas/
      mutation-plan.schema.json
    plugins/              # installed via mutiverse install
      yyy/
        init.lua          # Lua module, exports plan(source, plan_path)
    src/
      mutator.lua         # core library (existing)
      file_io.lua         # file helpers (existing)
      cmd_plan.lua        # CLI driver for plan
      cmd_run.lua         # CLI driver for run
```

### Shell wrapper (`.mutiverse/mutiverse`)

- Resolves its own location via `$(dirname "$0")`.
- Project root is `$(dirname "$0")/..`.
- `install` subcommand handled in shell (git clone into `plugins/`).
- `plan` and `run` dispatch to `src/cmd_*.lua` via `lua`.

### Verbs

```
mutiverse install xxx/yyy
  → git clone github.com/xxx/yyy into .mutiverse/plugins/yyy/

mutiverse plan --plugin yyy --path src/ --plan mutation-plan.json
  → requires .mutiverse/plugins/yyy/init.lua
  → calls plugin.plan(source_path, plan_path)
  → validates output against schema
  → writes mutation-plan.json

mutiverse run --plan mutation-plan.json --report report.json --test-command "make tests" --fail fast
  → reads plan, applies mutations, runs tests, writes report
  --fail fast:  abort on first error, write partial report, exit 1
  --fail slow: skip errors, process all, write report, exit 1 if any failed
```

### Rules

- All flags are long flags (`--flag`), nothing positional (except `install`).
- All flags are required — no defaults, no implicit behaviour.
- The `install` verb takes two positional arguments: `org/repo`.
- The `--fail` flag is required for `run` (fast/slow).

### Plugin contract

- A Lua module at `.mutiverse/plugins/yyy/init.lua`.
- Exports one function: `plan(source_path, plan_path)`.
  - `source_path`: file or directory to scan.
  - `plan_path`: where to write the JSON plan.
  - Returns: nothing (writes file directly).
- Mutiverse validates the written plan against the schema after the plugin returns.

### Internal architecture

- `mutator.lua`: library (Level 1-2: pure functions + artifact production).
- `cmd_plan.lua` / `cmd_run.lua`: thin CLI drivers that parse flags and call `mutator.*`.
- `install` is handled entirely by the shell wrapper.
