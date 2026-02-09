# Strategies - StrategyMetadata

**File**: `src/Strategies/contract/metadata.jl`  
**Priority**: 🔴 HIGH - Recently refactored (Phase 2)  
**Complexity**: High

## Why This Needs Review

- Phase 2 refactoring removed direct `.specs` field access
- Now uses public interface: `keys()`, `values()`, `pairs()`, `getindex()`, `haskey()`
- Main type docstring needs update to reflect iteration interface

## Required Documentation

### StrategyMetadata Type
- [ ] Purpose: holds OptionDefinition specs for a strategy
- [ ] Field description: `specs::NamedTuple` (internal, use interface)
- [ ] Iteration interface documentation
- [ ] Constructor validation behavior
- [ ] Example of accessing metadata

### Collection Interface Methods
- [ ] `Base.keys(::StrategyMetadata)` - option names
- [ ] `Base.values(::StrategyMetadata)` - OptionDefinition objects
- [ ] `Base.pairs(::StrategyMetadata)` - (name => def) pairs
- [ ] `Base.iterate(::StrategyMetadata)` - iteration protocol
- [ ] `Base.length(::StrategyMetadata)` - number of options
- [ ] `Base.haskey(::StrategyMetadata, ::Symbol)` - check for option
- [ ] `Base.getindex(::StrategyMetadata, ::Symbol)` - get OptionDefinition
- [ ] `Base.isempty(::StrategyMetadata)` - check if empty

### metadata() Function
- [ ] Purpose: retrieve metadata for strategy type
- [ ] Example usage
- [ ] Link to StrategyMetadata type

### Builder Functions (@option, @metadata)
- [ ] Clear macro usage examples
- [ ] Validation behavior
- [ ] Error cases

## Quality Checks

- [ ] Emphasize public interface over field access
- [ ] No direct `.specs` access in examples
- [ ] Clear contract for strategy types
- [ ] Cross-references complete

## Estimated Time

60-75 minutes
