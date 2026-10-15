# Getting Started

```@meta
CurrentModule = CTSolvers
```

## Installation

CTSolvers.jl is typically installed as a dependency of another package in the ecosystem
(e.g. [OptimalControl.jl](https://github.com/control-toolbox/OptimalControl.jl)).
To install it directly:

```julia
using Pkg: Pkg
Pkg.add("CTSolvers")
```

**Requires Julia ≥ 1.10.**

## Mental Model

CTSolvers provides the **resolution infrastructure** of the control-toolbox ecosystem,
consumed by upstream packages:

- [CTDirect.jl](https://github.com/control-toolbox/CTDirect.jl) discretizes OCPs
  (defined in [CTModels.jl](https://github.com/control-toolbox/CTModels.jl)) and uses
  CTSolvers' `Solvers` and `Modelers` to solve them.
- [CTFlows.jl](https://github.com/control-toolbox/CTFlows.jl) uses CTSolvers'
  `Integrators` to build Hamiltonian flows for indirect methods.

The resolution pipeline once CTDirect has discretized the problem:

```text
DiscretizedModel    CTSolvers.Modelers     NLP backend      CTSolvers.Solvers
(docp)          →  (build NLP model)  →  (NLP problem)  →  (solve)  →  solution
```

All symbols are accessed via **qualified module paths** — `using CTSolvers` brings
nothing into scope directly.

## Extension Loading

CTSolvers loads no backend at startup. Each constructor throws `ExtensionError` until
the corresponding package is loaded:

```@eval
Main.CTBase.DevTools.repl_without_extensions(:CTSolvers, "CTSolvers.Solvers.Ipopt()")
```

```@eval
Main.CTBase.DevTools.repl_without_extensions(:CTSolvers, "CTSolvers.Integrators.SciML()")
```

Strategy identifiers and type information are always available, without any extension:

```@repl gs
using CTSolvers
using CTBase
CTBase.Strategies.id(CTSolvers.Solvers.Ipopt)
CTBase.Strategies.id(CTSolvers.Modelers.ADNLP)
CTBase.Strategies.id(CTSolvers.Integrators.SciML)
```

Load a backend to unlock its constructor:

```julia
# CTSolversIpopt → Solvers.Ipopt
using NLPModelsIpopt
# CTSolversADNLPModels → Modelers.ADNLP
using ADNLPModels
# CTSolversSciMLIntegrator (+ default Tsit5) → Integrators.SciML
using OrdinaryDiffEqTsit5
```

## Configuring Options

```@setup co
using CTSolvers
using NLPModelsIpopt
using CTBase
nothing
```

Options are validated at construction. Unknown options are rejected with a Levenshtein
suggestion; wrong types raise `IncorrectArgument`.

Without `NLPModelsIpopt` loaded, all constructor calls raise `ExtensionError` before
option validation runs. A valid construction with the extension loaded:

```@example co
using NLPModelsIpopt
CTSolvers.Solvers.Ipopt(max_iter = 1000, tol = 1e-8)
```

An unknown option name — with the extension loaded this raises `IncorrectArgument` with
a Levenshtein suggestion (`Did you mean: :max_iter?`):

```@repl co
CTSolvers.Solvers.Ipopt(max_itr = 1000)
```

Pass `mode = :permissive` to warn rather than error on unknown options. Introspect the
full option schema and read back values with provenance:

```@example co
# inspect all option definitions
CTBase.Strategies.metadata(CTSolvers.Solvers.Ipopt)
```

```@example co
# actual values with provenance
CTBase.Strategies.options(CTSolvers.Solvers.Ipopt())
```

## Next Steps

| Topic | Where |
| :------ | :------ |
| Module dependencies, type hierarchies, data flow | [Architecture](@ref) |
| Available solvers, modelers, integrators | [Strategies Catalogue](@ref) |
| Reading integration results | [Integration Results](@ref) |
| Running on GPU | [GPU Execution](@ref) |
| Wrapping a new NLP solver | [Implementing a Solver](@ref) |
| Wrapping a new ODE integrator | [Implementing an Integrator](@ref) |
| Adapting a new NLP backend | [Implementing a Modeler](@ref) |
| Connecting a new problem type | [Implementing an Optimization Problem](@ref) |
| All exception types with examples | [Error Messages Reference](@ref) |
| Complete API reference | API Reference (left sidebar) |
