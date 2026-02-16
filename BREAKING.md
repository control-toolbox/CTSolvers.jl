# Breaking Changes

This document describes all breaking changes introduced in CTSolvers.jl releases
and provides migration guides for users upgrading between versions.

---

## v0.3.1-beta (2026-02-14)

**No breaking changes** — This release only adds enhancements:

- Backend override options now accept both `Type{<:ADBackend}` and `ADBackend` instances
- Improved validation and error messages
- Better test coverage and documentation

---

## Breaking Changes — v0.3.0-beta

This document describes all breaking changes introduced in CTSolvers.jl v0.3.0-beta
and provides a migration guide for users upgrading from v0.2.x.

---

## Summary

All public types have been renamed to use shorter, module-qualified names.
This aligns with Julia conventions (`Module.Type`) and improves readability.

---

## Type Renaming

### Modelers

| v0.2.x | v0.3.0 |
|--------|--------|
| `ADNLPModeler` | `Modelers.ADNLP` |
| `ExaModeler` | `Modelers.Exa` |
| `AbstractOptimizationModeler` | `AbstractNLPModeler` |

### Solvers

| v0.2.x | v0.3.0 |
|--------|--------|
| `IpoptSolver` | `Solvers.Ipopt` |
| `MadNLPSolver` | `Solvers.MadNLP` |
| `MadNCLSolver` | `Solvers.MadNCL` |
| `KnitroSolver` | `Solvers.Knitro` |

### DOCP

| v0.2.x | v0.3.0 |
|--------|--------|
| `DiscretizedOptimalControlProblem` | `DiscretizedModel` |

---

## Migration Guide

### Search-and-replace

The simplest migration is a global search-and-replace in your codebase:

```
ADNLPModeler                      →  Modelers.ADNLP
ExaModeler                        →  Modelers.Exa
AbstractOptimizationModeler       →  AbstractNLPModeler
IpoptSolver                       →  Solvers.Ipopt
MadNLPSolver                      →  Solvers.MadNLP
MadNCLSolver                      →  Solvers.MadNCL
KnitroSolver                      →  Solvers.Knitro
DiscretizedOptimalControlProblem  →  DiscretizedModel
```

### Code examples

**Before (v0.2.x):**

```julia
using CTSolvers

# Create modeler and solver
modeler = ADNLPModeler(backend=:sparse)
solver = IpoptSolver(max_iter=1000, tol=1e-6)

# Create DOCP
docp = DiscretizedOptimalControlProblem(ocp, builder)
```

**After (v0.3.0):**

```julia
using CTSolvers

# Create modeler and solver
modeler = Modelers.ADNLP(backend=:sparse)
solver = Solvers.Ipopt(max_iter=1000, tol=1e-6)

# Create DOCP
docp = DiscretizedModel(ocp, builder)
```

### Registry creation

**Before:**

```julia
registry = create_registry(
    AbstractOptimizationModeler => (ADNLPModeler, ExaModeler),
    AbstractNLPSolver => (IpoptSolver, MadNLPSolver)
)
```

**After:**

```julia
registry = create_registry(
    AbstractNLPModeler => (Modelers.ADNLP, Modelers.Exa),
    AbstractNLPSolver => (Solvers.Ipopt, Solvers.MadNLP)
)
```

---

## Other Changes

- **`src/Solvers/validation.jl`** has been removed. Validation is now handled
  entirely by the strategy framework (`Strategies.build_strategy_options`).
- **CTModels 0.9 compatibility** — this version requires CTModels v0.9.0-beta or later.
