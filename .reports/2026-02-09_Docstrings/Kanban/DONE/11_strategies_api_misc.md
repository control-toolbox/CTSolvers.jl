# Remaining Strategies API Files

**Files**:
- `src/Strategies/api/utilities.jl`
- `src/Strategies/api/validation.jl`
- `src/Strategies/api/validation_helpers.jl`
- `src/Strategies/api/builders.jl`
- `src/Strategies/api/registry.jl`

**Priority**: 🟡 MEDIUM  
**Complexity**: Medium

## Why This Needs Review

- Utilities: helper functions for working with strategies
- Validation: option validation logic (strict/permissive modes)
- Builders: strategy builder pattern helpers
- Registry: strategy registration and lookup

## Required Documentation

### utilities.jl
- [ ] options_dict() - convert to Dict for external APIs
- [ ] filter_options() - filter by keys
- [ ] suggest_options() - spelling suggestions
- [ ] levenshtein_distance() - skip or minimal doc

### validation.jl
- [ ] validate_strategy_contract() - main validation
- [ ] Mode-specific behavior
- [ ] Exception cases

### validation_helpers.jl
- [ ] Helper functions (assess if worth documenting individually)

### builders.jl
- [ ] Strategy builder utilities
- [ ] Registration helpers

### registry.jl
- [ ] register_strategy!()
- [ ] lookup functions
- [ ] Example of registration

## Quality Checks

- [ ] Validation mode behavior clear
- [ ] Registry usage examples
- [ ] No internal implementation details in public docs

## Estimated Time

60-75 minutes
