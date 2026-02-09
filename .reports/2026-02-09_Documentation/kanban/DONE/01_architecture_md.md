# 01 — Write `architecture.md`

**Priority**: 🔴 Critical
**Depends on**: `00_setup_docs_infrastructure`
**Ref**: `reference/02_revised_structure.md` §3.2, `reference/04_mermaid_diagrams.md` §1

## Description

Write the central architecture page — the first real content page. This is the pivot that every other guide links back to.

## Sections to Write

### Section 1 — Abstract Type Hierarchies

- Mermaid `classDiagram` for the Strategy branch (ref: `04_mermaid_diagrams.md` §1.1):
  - `AbstractStrategy` → `AbstractOptimizationModeler`, `AbstractOptimizationSolver`, `AbstractOptimalControlDiscretizer` (CTDirect)
  - Concrete types: ADNLPModeler, ExaModeler, IpoptSolver, MadNLPSolver, etc.
  - Collocation, DirectShooting (CTDirect, shown as external)
- Mermaid `classDiagram` for the Optimization/Builder branch (ref: `04_mermaid_diagrams.md` §1.2):
  - `AbstractOptimizationProblem`, `AbstractBuilder`, `AbstractModelBuilder`, `AbstractSolutionBuilder`
- Explain the role of each branch and relationships between them

### Section 2 — Module Dependency Graph

- Mermaid `flowchart` (ref: `04_mermaid_diagrams.md` §1.3):
  - Options → Strategies → Orchestration
  - Strategies → Optimization, Modelers, DOCP, Solvers
- Explain loading order in `CTSolvers.jl` and why it matters

### Section 3 — Data Flow

- Mermaid `sequenceDiagram` (ref: `04_mermaid_diagrams.md` §1.4):
  - OCP → DOCP → NLP Model → Solver → ExecutionStats → OCP Solution
- Show the complete resolution pipeline with method calls

### Section 4 — Architectural Patterns

- **Two-level contract**: type-level introspection vs instance-level execution
  - Mermaid `flowchart` (ref: `04_mermaid_diagrams.md` §2.1)
- **NotImplemented pattern**: default methods throw helpful errors
- **Tag Dispatch**: extensions use tag types for dispatch
- **Qualified access**: why CTSolvers doesn't export at top-level

### Section 5 — Conventions

- Naming: types, modules, functions
- Constructor pattern with `build_strategy_options`
- `OptionDefinition` with aliases and validators

## Checklist

- [ ] Write all 5 sections in English
- [ ] Include at least 4 Mermaid diagrams (type hierarchy ×2, module deps, data flow)
- [ ] Use `@example`/`@repl` blocks where appropriate (e.g., showing the type hierarchy via `subtypes`)
- [ ] Add `@ref` links to API pages and other guides
- [ ] Verify `makedocs` passes with this page
- [ ] Target: 200–300 lines

## Acceptance Criteria

- Page renders correctly with all Mermaid diagrams
- Every module is mentioned and linked
- A developer reading only this page understands the overall design
