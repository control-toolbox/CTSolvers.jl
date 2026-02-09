# 03 — Write `guides/implementing_a_strategy.md`

**Priority**: 🔴 Critical
**Depends on**: `01_architecture_md`
**Ref**: `reference/02_revised_structure.md` §3.4, `reference/06_discretizer_tutorial.md`

## Description

The most fundamental guide. Uses `Collocation` and `DirectShooting` as concrete examples instead of an abstract `MyStrategy`. This is the reference tutorial for anyone implementing a new strategy in the CTSolvers ecosystem.

## Sections to Write (8 sections)

### Section 1 — The Two-Level Contract

- Type-level: `id(::Type)`, `metadata(::Type)` — introspection without instantiation
- Instance-level: `options(strategy)` — configured state
- Mermaid flowchart (ref: `04_mermaid_diagrams.md` §2.1)
- Why this separation exists (routing, validation before construction)

### Section 2 — Defining a Strategy Family

- `abstract type AbstractOptimalControlDiscretizer <: AbstractStrategy end`
- Role: registry grouping, family dispatch, common methods
- Mermaid classDiagram showing the family branch

### Section 3 — Implementing Collocation (step by step)

Full walkthrough with `@repl` displays at each step:

- Step 1: Struct with `options::StrategyOptions` (single field)
- Step 2: `id(::Type{<:Collocation}) = :collocation`
- Step 3: Default values (`__collocation_grid_size`, `__collocation_scheme`)
- Step 4: `metadata` with `OptionDefinition` for `:grid_size` and `:scheme` → `@repl` display
- Step 5: Constructor with `build_strategy_options` → `@repl` displays: default, custom, permissive, typo error (Levenshtein)
- Step 6: `validate_strategy_contract(Collocation)`
- Step 7: Options access: `option_value`, `option_source`, `is_user`, `is_default`

### Section 4 — Adding DirectShooting

- Same pattern, different options (`:grid_size` only)
- Pedagogical point: `grid_size` exists in both with different defaults/descriptions

### Section 5 — Registering the Family

- `create_registry(AbstractOptimalControlDiscretizer => (Collocation, DirectShooting))`
- `strategy_ids`, `type_from_id`, `build_strategy`
- `@repl` display of the registry

### Section 6 — Integration with Method Tuples

- `(:collocation, :adnlp, :ipopt)` with 3 families
- `extract_id_from_method`, `build_strategy_from_method`
- Link to `orchestration_and_routing.md`

### Section 7 — Introspection

- `option_names`, `option_defaults` for both strategies side by side

### Section 8 — Advanced Patterns

- Option aliases
- Custom validators
- Permissive mode for backend options

## Checklist

- [ ] Write all 8 sections in English
- [ ] Use `@setup`/`@example`/`@repl` blocks (ref: `05_display_strategy.md` §5)
- [ ] Include Mermaid diagrams: two-level contract, strategy lifecycle
- [ ] Show error messages via `@repl` (typo, NotImplemented)
- [ ] Add `@ref` links to API pages and `architecture.md`
- [ ] Verify `makedocs` passes
- [ ] Target: 400–500 lines

## Acceptance Criteria

- A developer can follow this guide and implement a complete strategy family
- All code blocks are executable (`@example`/`@repl`)
- Error messages are shown and explained
- Both Collocation and DirectShooting are fully functional in the doc build
