# mutiverse

This project is a language-agnostic mutation testing framework designed around a plug-in architecture, where support for each programming language is provided through independently developed extensions.

At its core, the system separates responsibilities into a host application and a set of language-specific plug-ins.

## Architecture Overview

<img width="1536" height="1024" alt="Mutation testing framework diagram" src="https://raw.githubusercontent.com/devarops/mutiverse/refs/heads/develop/assets/mutation-testing-framework-diagram.png" />

### Core Host Application

The core system is responsible for:

* Orchestrating the mutation testing workflow
* Applying mutations defined by plug-ins
* Executing the test suite using a user-provided command (e.g., `make test`)
* Determining whether mutants survive or are killed
* Producing outputs (diffs of surviving mutants)

The core remains agnostic to programming languages and parsing strategies, and operates only on raw source code and mutation candidates provided by plug-ins.

### Plug-in System

Each plug-in is an independent repository that provides:

* A catalog of mutation operators specific to a programming language
* Definitions of how source code can be transformed (e.g., `== → !=`, `> → <`, `+ → -`)
* A mechanism to analyze source code and produce mutation candidates

Plug-ins are expected to perform syntax-aware analysis.
In practice, most plug-ins rely on Tree-sitter grammars for syntax-aware analysis.

A shared Tree-sitter environment may be provided to simplify plug-in development.
However, this is optional infrastructure and not a responsibility of the host application.

Key properties:

* Plug-ins are decoupled from the core and from each other
* Users are responsible for discovering and selecting plug-ins
* The system is extensible to any language, regardless of the parsing technology used

## Mutation Model

* A small set of universal mutation operators (2–3) may be required across all languages
* Most mutations are language-specific, defined entirely within each plug-in
* Mutations are expected to be syntax-aware, avoiding fragile text-based approaches such as regex or line-based parsing

This enables precise and structurally valid transformations of source code.

## Execution Workflow

1. User provides:

   * Source code
   * A test command (e.g., `make test`)
   * One or more language plug-ins

2. The core:

   * Delegates mutation discovery to the selected plug-in(s)
   * Receives mutation candidates (text ranges + replacements)
   * Applies mutations and generates mutants
   * Runs the test suite for each mutant

3. Results:

   * Mutants that fail tests are discarded (killed)
   * Mutants that pass tests are retained (survived)

## Plug-in Contract

Plug-ins communicate with the host through a minimal, language-agnostic interface.

### Input (from host)

```json
{
  "file_path": "path/to/file",
  "source": "...raw source code..."
}
```

### Output (to host)

```json
{
  "mutations": [
    {
      "file": "path/to/file",
      "start_byte": 11,
      "end_byte": 12,
      "original": "1",
      "replacement": "0",
      "operator": "CONSTANT_NUMERIC_FLIP"
    }
  ]
}
```

The host does not interpret syntax trees and does not depend on any parsing technology. It consumes mutation candidates blindly.

### Contract Invariants

- The contract is strictly text-based
- No ASTs or parser-specific structures are exchanged
- Mutation locations must be expressed as byte ranges over the original source
- The host applies mutations without interpreting their semantics

## Architectural Constraints

The following constraints define the boundaries of the system:

- The host must not depend on Tree-sitter or any parsing library
- The host must not inspect or manipulate syntax trees
- The host operates only on raw source code and byte ranges
- Plug-ins fully own parsing and syntax analysis
- Plug-ins must not rely on host-provided parsing results
- The only shared contract between host and plug-ins is mutation candidates

## Output

The framework produces:

* A list of surviving mutants, represented as diffs (similar to `git diff`)
* These diffs highlight weaknesses in the test suite by showing undetected behavioral changes

## Versioning and Compatibility

* Plug-ins and the core follow semantic versioning
* Compatibility is enforced at the major version level
* This allows independent evolution of plug-ins while maintaining a stable contract with the core

## Design Principles

* Language independence via plug-in isolation
* Extensibility without modifying the core
* Syntax-aware transformations implemented within plug-ins
* Minimal core responsibilities, delegating all language knowledge to plug-ins
* Implementation flexibility, allowing plug-ins to choose their parsing strategy (Tree-sitter recommended)

## Core Mutation Operators

The following table defines a minimal, language-agnostic set of mutation operators used as a baseline across plug-ins. These operators target fundamental programming constructs (constants, arithmetic, comparisons, and boolean logic) and are designed to provide high signal with low redundancy. Additional, language-specific operators can be defined within each plug-in.

| id                    | operator       | description                      |
| --------------------- | -------------- | -------------------------------- |
| CONSTANT_NUMERIC_FLIP | `0 ↔ 1`        | Flip basic numeric constants     |
| CONSTANT_BOOLEAN_FLIP | `true ↔ false` | Invert boolean literals          |
| EQUALITY_OPERATOR     | `== ↔ !=`      | Invert equality comparison       |
| RELATIONAL_GT         | `> ↔ <=`       | Invert greater-than boundary     |
| RELATIONAL_LT         | `< ↔ >=`       | Invert less-than boundary        |
| ARITHMETIC_ADD_SUB    | `+ ↔ -`        | Swap addition and subtraction    |
| ARITHMETIC_MUL_DIV    | `* ↔ /`        | Swap multiplication and division |
| LOGICAL_NEGATION      | `expr → !expr` | Negate boolean expression        |

## Summary

The project defines a mutation testing framework where:

* The core system orchestrates execution and evaluation
* Plug-ins define how code is mutated per language
* Plug-ins are responsible for syntax-aware analysis (commonly using Tree-sitter)

This architecture enables scalable support for multiple languages while maintaining a small, stable, and focused core.
