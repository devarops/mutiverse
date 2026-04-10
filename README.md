# mutiverse

This project is a **language-agnostic mutation testing framework** designed around a **plug-in architecture**, where support for each programming language is provided through independently developed extensions.

At its core, the system separates responsibilities into a **host application** and a set of **language-specific plug-ins**, following principles similar to the extension model used by Neovim.

---

## Architecture Overview

### Core Host Application

The core system is responsible for:

* Orchestrating the mutation testing workflow
* Applying mutations defined by plug-ins
* Executing the test suite using a **user-provided command** (e.g., `make test`)
* Determining whether mutants survive or are killed
* Producing outputs (diffs of surviving mutants)

The core remains **agnostic to programming languages**, relying entirely on plug-ins for mutation definitions.

---

### Plug-in System

Each plug-in is an independent repository that provides:

* A **catalog of mutation operators** specific to a programming language
* Definitions of how source code can be transformed (e.g., `== → !=`, `> → <`, `+ → -`)
* Use of pre-existing grammars from Tree-sitter

Key properties:

* Plug-ins are **decoupled** from the core and from each other
* Users are responsible for **discovering and selecting** plug-ins
* The system is **extensible to any language** with a compatible plug-in

---

## Mutation Model

* A small set of **universal mutation operators** (2–3) may be required across all languages
* Most mutations are **language-specific**, defined entirely within each plug-in
* Mutations are applied in a **syntax-aware manner** using Tree-sitter, avoiding fragile text-based approaches such as regex or line-based parsing

This enables precise and structurally valid transformations of source code.

---

## Execution Workflow

1. User provides:

   * Source code
   * A test command (e.g., `make test`)
   * One or more language plug-ins

2. The core:

   * Parses code using Tree-sitter-based structures
   * Applies mutations from the selected plug-in(s)
   * Runs the test suite for each mutant

3. Results:

   * Mutants that **fail tests** are discarded (killed)
   * Mutants that **pass tests** are retained (survived)

---

## Output

The framework produces:

* A **list of surviving mutants**, represented as diffs (similar to `git diff`)
* These diffs highlight weaknesses in the test suite by showing undetected behavioral changes

---

## Versioning and Compatibility

* Plug-ins and the core follow **semantic versioning**
* Compatibility is enforced at the **major version level**
* This allows independent evolution of plug-ins while maintaining a stable contract with the core

---

## Design Principles

* **Language independence** via plug-in isolation
* **Extensibility** without modifying the core
* **Syntax-aware transformations** using Tree-sitter
* **User-controlled environment** (test execution and plug-in selection)
* **Minimal core responsibilities**, delegating domain knowledge to plug-ins

---

## Summary

The project defines a mutation testing framework where:

* The **core system orchestrates execution and evaluation**
* **Plug-ins define how code is mutated per language**
* **Tree-sitter enables precise, structure-aware transformations**

This architecture enables scalable support for multiple languages while maintaining a small, stable, and focused core.
