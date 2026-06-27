# Backlog

## `os.execute` exit code mangling with `docker exec`

When `--test-command` wraps a command in `docker exec`, Lua's
`os.execute` may misinterpret the exit code because `docker exec`
adds its own encoding on top of the container process's exit status.
This can cause tests that pass inside the container (exit 0) to be
reported as killed, or vice versa.

**Status:** Not yet addressed. Needs a cross-container execution
strategy — either run tests from within the target container where
`os.execute` sees the raw exit code, or parse `docker exec`'s exit
code encoding explicitly.

## `split_lines` skips blank lines, misaligning `start_row` with source

`gmatch("[^\n]+")` in `split_lines` silently drops blank lines, so
the `lines` table has fewer entries than the actual line count. Any
mutation targeting a line after a blank line gets an off-by-N error
on `start_row`, manifesting as `"original text does not match at
specified location"`.

**Status:** Not yet addressed. Fix is a straightforward replacement
of `split_lines` with a version that preserves blank lines (e.g.,
iterate via `find("\n")` and `sub`). Existing test fixtures happen
not to trigger the bug because their targets precede blank lines.

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

---

## qed installation in Dockerfile

Steps to bake qed into the Docker image (no Nix dependency):

```dockerfile
# Install elan (Lean version manager)
RUN apt install --yes curl
RUN curl https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh -sSf | sh -s -- -y

# Install the Lean toolchain used by qed
RUN . "$HOME/.elan/env" && elan toolchain install leanprover/lean4:v4.28.0

# Clone and build qed
RUN git clone https://github.com/tskovlund/qed.git /opt/qed
RUN . "$HOME/.elan/env" && cd /opt/qed && lake build

# Add qed to PATH
RUN ln -sf /opt/qed/.lake/build/bin/qed /usr/local/bin/qed
```

**Notes:**
- `lake build` compiles 68 targets including all formal proofs (~2–5 minutes).
- Lean toolchain is ~500MB download.
- No devbox, no Nix — only `curl` and `git` as build dependencies.
- qed has no releases yet, so building from source is the only option.
- Keep this layer after `apt install` and before `COPY . /workdir` to leverage Docker caching.
