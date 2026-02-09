# Solvers - Concrete Implementations

**Files**:
- `src/Solvers/abstract_solver.jl`
- `src/Solvers/ipopt_solver.jl`
- `src/Solvers/knitro_solver.jl`
- `src/Solvers/madnlp_solver.jl`
- `src/Solvers/madncl_solver.jl`
- `src/Solvers/common_solve_api.jl`

**Priority**: 🟡 MEDIUM - Public API  
**Complexity**: Medium

## Why This Needs Review

- Main user-facing solver types
- Integration with external solver packages
- Need clear option documentation

## Required Documentation

### AbstractSolver Type
- [ ] Purpose: interface for NLP solvers
- [ ] Contract requirements
- [ ] Available API
- [ ] Link to concrete solvers

### IpoptSolver Type
- [ ] Purpose: Ipopt integration
- [ ] Key options (tol, max_iter, print_level, etc.)
- [ ] Constructor usage
- [ ] Example: solving NLP
- [ ] Link to Ipopt docs

### KnitroSolver Type
- [ ] Purpose: Knitro integration
- [ ] Key options
- [ ] Constructor usage
- [ ] Commercial license note
- [ ] Link to Knitro docs

### MadNLPSolver Type
- [ ] Purpose: MadNLP integration
- [ ] Key options (linear_solver, lapack_algorithm, etc.)
- [ ] GPU support mention
- [ ] Constructor usage
- [ ] Link to MadNLP docs

### MadNCLSolver Type
- [ ] Purpose: MadNCL integration (NCL problems)
- [ ] Key differences from MadNLP
- [ ] Link to MadNCL docs

### CommonSolve API
- [ ] solve() interface
- [ ] SolverInfo return type
- [ ] Example usage

## Quality Checks

- [ ] All major options documented
- [ ] External package links correct
- [ ] License notes where relevant
- [ ] No false performance comparisons

## Estimated Time

75-90 minutes
