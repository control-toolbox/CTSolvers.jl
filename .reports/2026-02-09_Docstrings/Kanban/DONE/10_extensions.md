# Extensions - Solver Option Definitions

**Files**:
- `ext/CTSolversIpopt.jl` (24.5 KB)
- `ext/CTSolversKnitro.jl` (9.4 KB)
- `ext/CTSolversMadNLP.jl` (16.5 KB)
- `ext/CTSolversMadNCL.jl` (16.3 KB)

**Priority**: 🟢 LOW-MEDIUM - Internal definitions  
**Complexity**: Low-Medium

## Why This Needs Review

- Extensions define solver-specific option metadata
- Mostly @option macro calls with definitions
- Need accurate option descriptions matching solver docs

## Required Documentation

### Module-level Docstrings
- [ ] Each extension: purpose and solver integration
- [ ] Link to main solver type in src/

### Option Definitions
- [ ] Review each @option for accurate description
- [ ] Verify default values match solver defaults
- [ ] Check type specifications
- [ ] Validators documented where present
- [ ] **No need for examples** (internal definitions)

### Helper Functions
- [ ] Document if non-trivial
- [ ] Skip simple validators

## Quality Checks

- [ ] Descriptions match upstream solver docs
- [ ] Default values accurate
- [ ] Type constraints correct
- [ ] Aliases listed if any

## Notes

- These are mostly data definitions, not algorithms
- Focus on accuracy over examples
- Cross-check with solver documentation

## Estimated Time

45-60 minutes per extension = ~3 hours total
