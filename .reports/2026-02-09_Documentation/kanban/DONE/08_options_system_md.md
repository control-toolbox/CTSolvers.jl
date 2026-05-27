# 08 — Write `guides/options_system.md`

**Priority**: 🟡 Medium
**Depends on**: `03_implementing_a_strategy_md`
**Ref**: `reference/02_revised_structure.md` §3.3, `reference/05_display_strategy.md` §3

## Description

Document the options system for developers implementing strategies. Merges and replaces the existing `options_validation.md` and `migration_guide.md`.

## Sections to Write (6 sections)

### Section 1 — OptionDefinition

- Creating an option definition: name, type, default, description, aliases, validator
- Concrete examples with different types and validators
- `@repl` display of OptionDefinition (compact and pretty)

### Section 2 — OptionValue and Provenance

- The 3 sources: `:user`, `:default`, `:computed`
- How provenance is tracked and why it's useful
- `@repl` display of OptionValue with different sources

### Section 3 — StrategyMetadata

- Assembling `OptionDefinition` into `StrategyMetadata`
- The Collection interface (keys, values, pairs, getindex)
- `@repl` display of StrategyMetadata

### Section 4 — StrategyOptions

- Construction via `build_strategy_options`
- Value access: `opts[:key]` (value), `opts.key` (OptionValue), `get(opts, Val(:key))` (type-stable)
- Introspection: `source`, `is_user`, `is_default`, `is_computed`
- `@repl` display of StrategyOptions (compact and pretty)

### Section 5 — Validation Modes

- Strict mode: reject unknown options, Levenshtein suggestions
- Permissive mode: accept with warning
- When to use each mode
- `@repl` display of errors (unknown option, type mismatch, validator failure) and warnings

### Section 6 — extract_options and extract_raw_options

- Extracting options from kwargs
- Difference between the two functions

## Checklist

- [ ] Write all 6 sections in English
- [ ] Use `@setup`/`@example`/`@repl` blocks
- [ ] Show sentinel types (`NotProvided`, `NotStored`) via `@repl`
- [ ] Show error messages via `@repl` (unknown option with Levenshtein, type mismatch, validator failure)
- [ ] Show warning in permissive mode via `@repl`
- [ ] Add `@ref` links to API pages and strategy guide
- [ ] Verify `makedocs` passes
- [ ] Target: 200–250 lines

## Acceptance Criteria

- A developer understands the full options lifecycle: definition → metadata → construction → access → validation
- All display formats (compact, pretty) are shown
- Error messages and warnings are documented with explanations
