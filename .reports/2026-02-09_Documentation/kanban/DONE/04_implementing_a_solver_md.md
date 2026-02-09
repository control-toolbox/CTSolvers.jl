# 04 — Write `guides/implementing_a_solver.md`

**Priority**: 🟠 High
**Depends on**: `03_implementing_a_strategy_md`
**Ref**: `reference/02_revised_structure.md` §3.5, `reference/04_mermaid_diagrams.md` §2.3–2.4

## Description

Guide for implementing a complete solver with conditional extension loading. The most concrete use case — shows the Tag Dispatch pattern and the CommonSolve multi-level API.

## Sections to Write (6 sections)

### Section 1 — The AbstractOptimizationSolver Contract

- Inheritance: `AbstractOptimizationSolver <: AbstractStrategy`
- Inherited Strategy contract (id, metadata, options, constructor)
- Additional callable contract: `(solver)(nlp; display)` → `AbstractExecutionStats`

### Section 2 — Implementing the Solver Type

Step by step in `src/Solvers/`:
- Struct with `options::StrategyOptions`
- `id`, `metadata`, constructor
- The callable that delegates to the backend

### Section 3 — The Tag Dispatch Pattern

- Why: separate logic (in `src/`) from backend implementation (in `ext/`)
- How: `AbstractTag` and dispatch on tag type
- Mermaid flowchart (ref: `04_mermaid_diagrams.md` §2.3)
- Concrete example with an existing solver (e.g., IpoptSolver)

### Section 4 — Creating the Extension

- File structure: `ext/CTSolversMyBackend.jl`
- Declaration in `Project.toml` (weakdeps, extensions)
- Implementing the callable method in the extension
- Mermaid flowchart: src/ext separation

### Section 5 — CommonSolve Integration

- Mermaid flowchart (ref: `04_mermaid_diagrams.md` §2.4)
- 3 levels:
  - High-level: `solve(problem, x0, modeler, solver)` — full pipeline
  - Mid-level: `solve(nlp, solver)` — direct NLP
  - Low-level: `solve(any, solver)` — flexible

### Section 6 — Tests

- Strategy contract test
- Callable test (with mock NLP)
- Extension test (if backend available)
- CommonSolve test

## Checklist

- [ ] Write all 6 sections in English
- [ ] Use `@example`/`@repl` blocks with `@setup` for imports
- [ ] Include Mermaid diagrams: Tag Dispatch, CommonSolve multi-level
- [ ] Show `NotImplemented` error when callable is missing (via `@repl`)
- [ ] Add `@ref` links to API pages and `architecture.md`
- [ ] Verify `makedocs` passes
- [ ] Target: 300–400 lines

## Acceptance Criteria

- A developer can follow this guide to add a new solver backend
- Tag Dispatch pattern is clearly explained with diagrams
- CommonSolve 3-level API is documented
