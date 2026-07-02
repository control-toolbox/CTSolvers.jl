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

```@example gs
using CTSolvers
try # hide
CTSolvers.Solvers.Ipopt()
catch e # hide
showerror(IOContext(stdout, :color => true), e) # hide
end # hide
```

```@example gs
try # hide
CTSolvers.Integrators.SciML()
catch e # hide
showerror(IOContext(stdout, :color => true), e) # hide
end # hide
```

Strategy identifiers and type information are always available, without any extension:

```@repl gs
using CTBase
CTBase.Strategies.id(CTSolvers.Solvers.Ipopt)
CTBase.Strategies.id(CTSolvers.Modelers.ADNLP)
CTBase.Strategies.id(CTSolvers.Integrators.SciML)
```

Load a backend to unlock its constructor:

```julia
using NLPModelsIpopt       # loads CTSolversIpopt       → enables Solvers.Ipopt
using ADNLPModels          # loads CTSolversADNLPModels  → enables Modelers.ADNLP
using OrdinaryDiffEqTsit5  # loads CTSolversSciMLIntegrator → enables Integrators.SciML
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

```@example co
try # hide
CTSolvers.Solvers.Ipopt(max_itr = 1000)
catch e # hide
showerror(IOContext(stdout, :color => true), e) # hide
end # hide
```

Pass `mode = :permissive` to warn rather than error on unknown options. Introspect the
full option schema and read back values with provenance:

```@example co
CTBase.Strategies.metadata(CTSolvers.Solvers.Ipopt)    # inspect all option definitions
```

```@example co
CTBase.Strategies.options(CTSolvers.Solvers.Ipopt())   # actual values with provenance
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
