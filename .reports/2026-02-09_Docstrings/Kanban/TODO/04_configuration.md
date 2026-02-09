# Strategies - Configuration API

**File**: `src/Strategies/api/configuration.jl`  
**Priority**: 🟡 MEDIUM-HIGH - Uses refactored interfaces  
**Complexity**: Medium

## Why This Needs Review

- Phase 2: Now uses `meta` interface instead of `meta.specs`
- Key functions: `build_strategy_options()`, `resolve_alias()`
- Validation mode integration

## Required Documentation

### build_strategy_options()
- [ ] Purpose: construct validated StrategyOptions from kwargs
- [ ] Mode parameter (:strict, :permissive)
- [ ] Validation behavior by mode
- [ ] Exception cases
- [ ] Example with and without mode

### resolve_alias()
- [ ] Purpose: find primary name from alias
- [ ] Returns `nothing` if not found
- [ ] Example usage

### Internal Helpers
- [ ] Document or skip trivial helpers (decide per function)

## Quality Checks

- [ ] No `meta.specs` references in examples
- [ ] Clear mode behavior explanation
- [ ] Exception documentation complete

## Estimated Time

30-45 minutes
