# Modelers - ADNLPModeler and ExaModeler

**Files**:
- `src/Modelers/abstract_modeler.jl`
- `src/Modelers/adnlp_modeler.jl`
- `src/Modelers/exa_modeler.jl`
- `src/Modelers/validation.jl`

**Priority**: 🟡 MEDIUM - Public API  
**Complexity**: Medium

## Why This Needs Review

- Main user-facing types for model building
- Integration with ADNLPModels.jl and ExaModels.jl
- Need clear usage examples

## Required Documentation

### AbstractModeler Type
- [ ] Purpose: interface for model builders
- [ ] Contract requirements
- [ ] Available API
- [ ] Link to concrete modelers

### ADNLPModeler Type
- [ ] Purpose: ADNLPModels integration
- [ ] Available options (backend, show_time, etc.)
- [ ] Constructor usage
- [ ] Example: simple OCP modeling
- [ ] Link to ADNLPModels.jl docs

### ExaModeler Type
- [ ] Purpose: ExaModels integration (GPU support)
- [ ] Available options (base_type, backend, etc.)
- [ ] Constructor usage
- [ ] Example: GPU-accelerated modeling
- [ ] Link to ExaModels.jl docs

### Validation Functions
- [ ] validate_modeler() purpose
- [ ] Exception cases
- [ ] Skip trivial helpers

## Quality Checks

- [ ] Examples show typical OCP use case
- [ ] Option lists are accurate
- [ ] External package links correct
- [ ] No performance claims without evidence

## Estimated Time

60-75 minutes
