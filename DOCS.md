# DOCS.md

## Public API — `mutator` module

### mutator.apply_mutation(mutation, source)

Applies a single mutation to source text.

- **Parameters:**
  - `mutation` (table): Mutation object with required fields.
    - `original` (string): The text to replace.
    - `replacement` (string): The replacement text.
    - `start_row` (integer, optional): 0-based starting row. When present, enables location-aware replacement.
    - `start_col` (integer, optional): 0-based starting column (required if `start_row` is present).
    - `end_col` (integer, optional): 0-based exclusive ending column (required if `start_row` is present).
  - `source` (string): The source text to mutate.
- **Returns:** (string) The mutated source text.
- **Errors:** When `start_row` is provided and `mutation.original` does not match the text at that location, an error is raised.
- **Notes:** Without location fields, performs a global text replacement (escapes Lua pattern characters).

---

### mutator.apply_mutation_to_file(mutation, input_path, output_path)

Applies a single mutation to a file and writes the result.

- **Parameters:**
  - `mutation` (table): Mutation object (see `apply_mutation`).
  - `input_path` (string): Path to the source file.
  - `output_path` (string): Path to write the mutated output.
- **Returns:** Nothing.
- **Errors:** If `input_path` does not exist, an error is raised (delegates to `file_io.read`).

---

### mutator.is_mutation_killed(command)

Executes a shell command and determines whether the mutation was killed.

- **Parameters:**
  - `command` (string): Shell command to execute (e.g., `"make tests"`, `"pytest tests/"`).
- **Returns:** (boolean) `true` if the command exits with a non-zero status (killed), `false` if it exits with 0 (survived).

---

### mutator.run_test(command)

Executes a test command and prints the mutation outcome.

- **Parameters:**
  - `command` (string): Shell command to execute.
- **Returns:** (boolean) `false` if the command exits with 0 (survived), `true` if it exits non-zero (killed).
- **Side effects:** Prints `"👾 survived"` to stdout when the command exits 0. Prints `"🏹 killed"` to stdout when the command exits non-zero.

---

### mutator.apply_mutations_from_plan(plan_path, test_command, report_path)

Reads a mutation plan from a JSON file and applies each mutation.

- **Parameters:**
  - `plan_path` (string): Path to the mutation plan JSON file.
  - `test_command` (string, optional): Shell command to run after each mutation. When provided, the mutation is applied to the source file in place, the test is executed, and the source is restored.
  - `report_path` (string, optional): Path to write a JSON report. The report contains all mutation fields plus a `"killed": false` entry per mutation.
- **Returns:** (array of strings) Mutated source text for each mutation, in plan order.
- **Errors:** If the plan file does not exist or is malformed, an error is raised. If a mutation references a source file that does not exist, an error is raised.

---

### mutator.SURVIVED_MESSAGE

Constant string `"👾 survived"`. Used for consistent output formatting.

- **Type:** string

---

### mutator.KILLED_MESSAGE

Constant string `"🏹 killed"`. Used for consistent output formatting.

- **Type:** string

---

## Public API — `file_io` module

### file_io.read(path)

Reads the entire contents of a file.

- **Parameters:**
  - `path` (string): Path to the file.
- **Returns:** (string) The file contents.
- **Errors:** Raises an error if the file cannot be opened.

---

### file_io.write(path, content)

Writes content to a file, overwriting if it exists.

- **Parameters:**
  - `path` (string): Path to the output file.
  - `content` (string): The content to write.
- **Returns:** Nothing.
- **Errors:** Raises an error if the file cannot be opened for writing.

---

## Mutation plan schema

Mutaters are defined in JSON documents following the schema at `schema/mutation-plan.schema.json`.

### Top-level structure

```
{
  "mutations": [ ... ]
}
```

### Mutation object

| Field         | Type    | Required | Description                                         |
|---------------|---------|----------|-----------------------------------------------------|
| `file_path`   | string  | yes      | Path to the source file                             |
| `start_row`   | integer | yes      | 0-based starting row                                |
| `end_row`     | integer | yes      | 0-based ending row                                  |
| `start_col`   | integer | yes      | 0-based starting column                             |
| `end_col`     | integer | yes      | 0-based exclusive ending column                     |
| `original`    | string  | yes      | Text expected at the specified location              |
| `replacement` | string  | yes      | Text to insert in place of original                  |
| `operator`    | string  | yes      | One of the core mutation operators (see below)       |

### Core mutation operators

| id                    | operator       | description                      |
|-----------------------|----------------|----------------------------------|
| CONSTANT_NUMERIC_FLIP | `0 ↔ 1`        | Flip basic numeric constants     |
| CONSTANT_BOOLEAN_FLIP | `true ↔ false` | Invert boolean literals           |
| EQUALITY_OPERATOR     | `== ↔ !=`      | Invert equality comparison       |
| RELATIONAL_GT         | `> ↔ <=`       | Invert greater-than boundary     |
| RELATIONAL_LT         | `< ↔ >=`       | Invert less-than boundary        |
| ARITHMETIC_ADD_SUB    | `+ ↔ -`        | Swap addition and subtraction    |
| ARITHMETIC_MUL_DIV    | `* ↔ /`        | Swap multiplication and division |
| LOGICAL_NEGATION      | `expr → !expr` | Negate boolean expression        |
