# Strategies - StrategyOptions

**File**: `src/Strategies/contract/strategy_options.jl`  
**Priority**: 🔴 HIGH - Recently refactored (Phase 3)  
**Complexity**: High

## Why This Needs Review

- Phase 3 refactoring added `_raw_options()` private helper
- Removed direct `.options` field access in public code
- Iteration interface needs clear documentation
- Private helper needs warning documentation

## Required Documentation

### StrategyOptions Type
- [ ] Purpose: validated option values with source tracking
- [ ] Field description: `options::NamedTuple` (internal, use interface)
- [ ] Iteration interface (returns values, not OptionValue wrappers)
- [ ] Constructor validation
- [ ] Example of creating and accessing options

### Collection Interface Methods
- [ ] `Base.keys(::StrategyOptions)` - option names
- [ ] `Base.values(::StrategyOptions)` - unwrapped values
- [ ] `Base.pairs(::StrategyOptions)` - (name => value) pairs
- [ ] `Base.iterate(::StrategyOptions)` - iteration protocol
- [ ] `Base.length(::StrategyOptions)` - number of options
- [ ] `Base.haskey(::StrategyOptions, ::Symbol)` - check for option
- [ ] `Base.getindex(::StrategyOptions, ::Symbol)` - get unwrapped value
- [ ] `Base.isempty(::StrategyOptions)` - check if empty

### Source Tracking Methods
- [ ] `source(::StrategyOptions, ::Symbol)` - get option source (:user/:default/:computed)
- [ ] `is_user()`, `is_default()`, `is_computed()` - convenience checks

### Private Helpers
- [x] `_raw_options()` - ALREADY documented with warning, verify

### show() Methods
- [ ] Compact display format
- [ ] Detailed display format

## Quality Checks

- [ ] Clear that public interface returns unwrapped values
- [ ] Private helper clearly marked as internal
- [ ] No direct `.options` access in examples
- [ ] Source tracking well explained

## Estimated Time

60-75 minutes
