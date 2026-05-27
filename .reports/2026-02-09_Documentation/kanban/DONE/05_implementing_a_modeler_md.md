# 05 — Write `guides/implementing_a_modeler.md`

**Priority**: 🟠 High
**Depends on**: `03_implementing_a_strategy_md`
**Ref**: `reference/02_revised_structure.md` §3.6, `reference/04_mermaid_diagrams.md` §2.5

## Description

Guide for implementing a modeler that converts an optimization problem into an NLP model. Depends on both the Strategy contract and the Optimization module (builders).

## Sections to Write (4 sections)

### Section 1 — The AbstractOptimizationModeler Contract

- Inheritance: `AbstractOptimizationModeler <: AbstractStrategy`
- Two mandatory callables:
  - `(modeler)(prob, initial_guess)` → NLP model
  - `(modeler)(prob, nlp_solution)` → OCP Solution
- Interaction with `AbstractOptimizationProblem` and its builders
- Mermaid sequenceDiagram: modeler/problem/builders interaction (ref: `04_mermaid_diagrams.md` §2.5)

### Section 2 — Step-by-Step Implementation

- Struct, id, metadata, constructor (same pattern as Strategy guide)
- Callable for model building: get builder via `get_adnlp_model_builder(prob)` or `get_exa_model_builder(prob)`, then call it
- Callable for solution building: same with `get_adnlp_solution_builder(prob)`
- `@repl` displays of ADNLPModeler and ExaModeler

### Section 3 — Validation

- `validate_strategy_contract`
- Tests with a `FakeOptimizationProblem`
- `@repl` display of `NotImplemented` errors

### Section 4 — Integration with build_model / build_solution

- How `Optimization.build_model` dispatches to the right modeler
- The complete flow: problem → modeler → NLP → solver → solution

## Checklist

- [ ] Write all 4 sections in English
- [ ] Use `@setup`/`@example`/`@repl` blocks
- [ ] Include Mermaid sequenceDiagram for modeler flow
- [ ] Show `NotImplemented` error for missing callable (via `@repl`)
- [ ] Add `@ref` links to API pages, `architecture.md`, and solver guide
- [ ] Verify `makedocs` passes
- [ ] Target: 200–300 lines

## Acceptance Criteria

- A developer can follow this guide to implement a new modeler
- The two callables (model building, solution building) are clearly explained
- Integration with builders and the optimization pipeline is documented
