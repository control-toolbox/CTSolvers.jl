# 06 — Write `guides/implementing_an_optimization_problem.md`

**Priority**: 🟠 High
**Depends on**: `05_implementing_a_modeler_md`
**Ref**: `reference/02_revised_structure.md` §3.7, `reference/04_mermaid_diagrams.md` §2.6

## Description

Guide for implementing an optimization problem type compatible with modelers. Covers the `AbstractOptimizationProblem` contract and the Builder pattern.

## Sections to Write (4 sections)

### Section 1 — The AbstractOptimizationProblem Contract

- The 4 getter methods (builders)
- The pattern: each problem provides builders, modelers use them
- Mermaid erDiagram: DOCP + Builders structure and relations (ref: `04_mermaid_diagrams.md` §2.6)

### Section 2 — The Builders

- `AbstractModelBuilder`: callable that constructs an NLP model
- `AbstractSolutionBuilder`: callable that constructs a solution
- Concrete types: `ADNLPModelBuilder`, `ExaModelBuilder`, `ADNLPSolutionBuilder`, `ExaSolutionBuilder`
- The callable pattern with specific signatures
- `@repl` displays of builder construction and properties

### Section 3 — Step-by-Step Implementation

- Define the problem struct
- Create concrete builders (callables)
- Implement the 4 getters
- Example: `DiscretizedOptimalControlProblem` as reference
- `@repl` display of `NotImplemented` errors for missing getters

### Section 4 — Tests

- Test getters
- Test builders
- Integration test with a modeler

## Checklist

- [ ] Write all 4 sections in English
- [ ] Use `@setup`/`@example`/`@repl` blocks
- [ ] Include Mermaid erDiagram for DOCP + Builders
- [ ] Show `NotImplemented` errors for missing getters (via `@repl`)
- [ ] Add `@ref` links to API pages, `architecture.md`, and modeler guide
- [ ] Verify `makedocs` passes
- [ ] Target: 200–300 lines

## Acceptance Criteria

- A developer can follow this guide to implement a new optimization problem type
- The Builder pattern is clearly explained
- Integration with modelers is documented
