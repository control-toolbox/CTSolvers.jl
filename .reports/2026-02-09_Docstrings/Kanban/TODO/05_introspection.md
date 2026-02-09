# Strategies - Introspection API

**File**: `src/Strategies/api/introspection.jl`  
**Priority**: 🟡 MEDIUM-HIGH - Uses refactored interfaces  
**Complexity**: Medium

## Why This Needs Review

- Phase 3: Now uses `source(opts, key)` and `haskey(opts, key)`
- Removed direct `opts.options[key]` access
- Many introspection utilities

## Required Documentation

### option_source()
- [ ] Purpose: get source of option value
- [ ] Returns `:user`, `:default`, or `:computed`
- [ ] Exception if key doesn't exist
- [ ] Example usage

### has_option()
- [ ] Purpose: check if option exists
- [ ] Returns boolean
- [ ] Example usage

### option_type(), option_description(), option_default()
- [ ] Document each or group similar ones
- [ ] Clear purpose
- [ ] Exception cases

### option_names()
- [ ] Purpose: get tuple of all option names
- [ ] Example usage

## Quality Checks

- [ ] No `opts.options` references in examples
- [ ] Consistent with metadata introspection
- [ ] Cross-references to related functions

## Estimated Time

45-60 minutes
