# Module-Level Docstrings

**Files**:
- `src/CTSolvers.jl` - Main module
- `src/*/[Module].jl` - All submodule files

**Priority**: 🟢 LOW - But important for docs  
**Complexity**: Low

## Why This Needs Review

- Module docstrings are first thing users see in docs
- Should give overview and guide users to main types/functions
- Many may be missing or outdated

## Required Documentation

### Main Module (CTSolvers.jl)
- [ ] Package purpose and scope
- [ ] Main concepts (Strategies, Options, Orchestration)
- [ ] Quick start example
- [ ] Link to key types

### Submodules
- [ ] **Strategies**: Framework for modelers/solvers/builders
- [ ] **Options**: Option definition and validation system
- [ ] **Modelers**: Model building (ADNLPModels, ExaModels)
- [ ] **Solvers**: NLP solvers (Ipopt, Knitro, MadNLP, MadNCL)
- [ ] **Orchestration**: High-level solve routing
- [ ] **Optimization**: Optimization abstractions
- [ ] **DOCP**: Discrete OCP representation

## Quality Checks

- [ ] Each module has clear purpose statement
- [ ] Cross-references to main types
- [ ] Consistent terminology
- [ ] No overpromising

## Estimated Time

30-45 minutes
