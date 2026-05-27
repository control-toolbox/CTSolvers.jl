# 09 — Write `guides/error_messages.md`

**Priority**: 🟡 Medium
**Depends on**: `03_implementing_a_strategy_md`, `08_options_system_md`
**Ref**: `reference/05_display_strategy.md` §4.2, §3.2

## Description

Reference page grouping all CTSolvers error messages with their explanation and recommended solution. Not a tutorial — a consultable reference when encountering an error.

## Sections to Write

### NotImplemented — Contract Not Implemented

For each contract method that has a default `NotImplemented` fallback:

- **Strategy contract**: `id`, `metadata`, `options`
- **Solver contract**: callable `(solver)(nlp; display)`
- **Modeler contract**: callable `(modeler)(prob, x0)`, `(modeler)(prob, sol)`
- **OptimizationProblem contract**: `get_adnlp_model_builder`, `get_exa_model_builder`, `get_adnlp_solution_builder`, `get_exa_solution_builder`

For each: `@repl` block showing the error, **Cause**, **Solution**.

### IncorrectArgument — Invalid Arguments

- **Unknown option (strict mode)**: with Levenshtein suggestion
- **Type mismatch**: wrong type for a known option
- **Validator failure**: option doesn't pass custom validator
- **Duplicate option names**: in StrategyMetadata
- **Ambiguous option (routing)**: option belongs to 2+ families
- **Unknown option (routing)**: option belongs to no family
- **Unknown strategy ID**: in registry lookup

For each: `@repl` block showing the error, **Cause**, **Solution**.

### Warnings (Permissive Mode)

- **Unknown option accepted with warning**: permissive mode behavior

## Checklist

- [ ] Write all sections in English
- [ ] Use `@setup`/`@repl` blocks exclusively (all errors must be shown live)
- [ ] Each error has: `@repl` block, **Cause** paragraph, **Solution** paragraph
- [ ] Verify all `@repl` blocks execute without crashing the build
- [ ] Add `@ref` links to the relevant guide for each error
- [ ] Verify `makedocs` passes
- [ ] Target: ~150 lines

## Acceptance Criteria

- A developer encountering any CTSolvers error can find it on this page
- Each error has a clear cause and actionable solution
- All error messages are generated live (not copy-pasted)
