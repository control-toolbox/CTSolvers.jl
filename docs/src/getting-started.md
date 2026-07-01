# Getting Started

```@meta
CurrentModule = CTSolvers
```

## Installation

CTSolvers.jl is typically installed as a dependency of another package in the ecosystem
(e.g. [OptimalControl.jl](https://github.com/control-toolbox/OptimalControl.jl)).
To install it directly:

```julia
import Pkg
Pkg.add("CTSolvers")
```

**Requires Julia ≥ 1.10.**

## Mental Model

CTSolvers is the **resolution layer** of the control-toolbox ecosystem. It sits between
[CTModels.jl](https://github.com/control-toolbox/CTModels.jl) (which defines the problem)
and the NLP backends (Ipopt, MadNLP, Knitro, …) that do the heavy lifting.

The resolution pipeline has three stages:

```text
CTModels.Model              CTSolvers                    NLP backend
(problem definition)  →  (discretize + model)  →  (solve)  →  solution
```

Two things to keep in mind:

1. **No top-level exports.** `using CTSolvers` loads the package but brings no symbols
   into scope. Every symbol is accessed via its qualified path:
   ```julia
   CTSolvers.Solvers.Ipopt(max_iter = 1000)
   CTSolvers.Modelers.ADNLP(backend = :optimized)
   CTBase.Strategies.id(CTSolvers.Solvers.Ipopt)
   ```

2. **Strategy pattern throughout.** Modelers and solvers are *strategies* — configurable
   components with validated options and provenance tracking.
   Options are passed as keyword arguments and rejected with clear errors if unknown.

## Quick Start

Solve a discretized optimal control problem with Ipopt and ADNLPModels:

```julia
using CTSolvers
using NLPModelsIpopt       # loads CTSolversIpopt extension → enables Solvers.Ipopt
using OrdinaryDiffEqTsit5  # loads CTSolversSciMLIntegrator → enables Integrators.SciML
using CommonSolve

# Build a solver with validated options
solver = CTSolvers.Solvers.Ipopt(max_iter = 500, tol = 1e-8)

# Build a modeler (NLP backend adapter)
modeler = CTSolvers.Modelers.ADNLP(backend = :optimized)

# Build an integrator
integrator = CTSolvers.Integrators.SciML()

# Solve (docp is a CTSolvers.DOCP.DiscretizedModel, x0 is an initial guess)
solution = solve(docp, x0, modeler, solver)
```

Extension loading is the key step: nothing from `Solvers.Ipopt`, `Integrators.SciML`,
or similar requires `NLPModelsIpopt`/`OrdinaryDiffEqTsit5` to be loaded at package load
time — they are loaded on demand when you `using` the backend package.

## Configuring Options

Every strategy constructor accepts keyword arguments for its options.
Unknown options are rejected with a Levenshtein suggestion:

```julia
# Valid option
solver = CTSolvers.Solvers.Ipopt(max_iter = 1000, tol = 1e-8)

# Typo → error with suggestion
solver = CTSolvers.Solvers.Ipopt(max_itr = 1000)
# ERROR: IncorrectArgument: Unknown option :max_itr
#   Did you mean: :max_iter?

# Permissive mode: accepts unknown options with a warning
solver = CTSolvers.Solvers.Ipopt(max_itr = 1000; mode = :permissive)
```

Inspect all available options via `metadata`:

```julia
CTBase.Strategies.metadata(CTSolvers.Solvers.Ipopt)
```

## Checking an Installed Instance

```julia
solver = CTSolvers.Solvers.Ipopt(max_iter = 500)
CTBase.Strategies.options(solver)      # StrategyOptions with provenance
CTBase.Strategies.id(CTSolvers.Solvers.Ipopt)  # :ipopt
```

## Next Steps

| Topic | Where |
|:------|:------|
| Module dependencies, type hierarchies, data flow | [Architecture](@ref) |
| Wrapping a new NLP solver | [Implementing a Solver](@ref) |
| Wrapping a new ODE integrator | [Implementing an Integrator](@ref) |
| Adapting a new NLP backend | [Implementing a Modeler](@ref) |
| Connecting a new problem type | [Implementing an Optimization Problem](@ref) |
| All exception types with examples | [Error Messages Reference](@ref) |
| Complete API reference | API Reference (left sidebar) |
