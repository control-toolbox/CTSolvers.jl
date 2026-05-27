# 07 — Write `guides/orchestration_and_routing.md`

**Priority**: 🟠 High
**Depends on**: `03_implementing_a_strategy_md`
**Ref**: `reference/02_revised_structure.md` §3.8, `reference/04_mermaid_diagrams.md` §2.7–2.8

## Description

Guide for understanding and using the multi-strategy option routing system. This is a transversal system that ties together all strategy families.

## Sections to Write (6 sections)

### Section 1 — The Method Tuple Concept

- `(:collocation, :adnlp, :ipopt)`: each symbol identifies a strategy
- Families: mapping between roles (discretizer, modeler, solver) and abstract types

### Section 2 — Automatic Routing

- `route_all_options`: the entry point
- The ownership map: which family owns which option
- Auto-routing for unambiguous options
- `@repl` display of `route_all_options` result
- Mermaid flowchart: routing decision flow (ref: `04_mermaid_diagrams.md` §2.7)

### Section 3 — Disambiguation

- When an option belongs to 2+ families
- `route_to()` and `RoutedOption`: disambiguation syntax
- Single strategy vs multi-strategy routing
- `@repl` display of ambiguity error
- Mermaid sequenceDiagram: disambiguation flow (ref: `04_mermaid_diagrams.md` §2.8)

### Section 4 — Strict/Permissive Modes

- At orchestration level (different from strategy level)
- Behavior with unknown options
- `@repl` display of unknown option error and warning

### Section 5 — Helpers

- `extract_strategy_ids`: disambiguation syntax detection
- `build_strategy_to_family_map`: reverse mapping
- `build_option_ownership_map`: ambiguity detection

### Section 6 — Complete Example

End-to-end example with 3 strategies, auto-routed and disambiguated options.

## Checklist

- [ ] Write all 6 sections in English
- [ ] Use `@setup`/`@example`/`@repl` blocks
- [ ] Include Mermaid diagrams: routing flowchart, disambiguation sequence
- [ ] Show error messages via `@repl` (ambiguity, unknown option)
- [ ] Add `@ref` links to API pages, `architecture.md`, and strategy guide
- [ ] Verify `makedocs` passes
- [ ] Target: 200–300 lines

## Acceptance Criteria

- A developer understands how option routing works with multiple strategies
- Disambiguation syntax is clearly explained with examples
- Error messages for ambiguous/unknown options are shown
