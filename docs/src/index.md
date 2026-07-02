# CTSolvers.jl

`CTSolvers.jl` is the **resolution layer** of the [control-toolbox](https://github.com/control-toolbox) ecosystem. It provides the infrastructure — solvers, modelers, integrators, and abstract problem types — used by upstream packages to solve optimal control problems.

!!! info "CTSolvers and its consumers"
    **CTSolvers** provides the *resolution infrastructure*; it does not call it directly.
    Two packages build on top of it:

    - [CTDirect.jl](https://github.com/control-toolbox/CTDirect.jl) — **direct methods**:
      discretizes continuous-time OCPs (defined in [CTModels.jl](https://github.com/control-toolbox/CTModels.jl))
      into finite-dimensional NLPs, then uses CTSolvers' `Solvers` and `Modelers` to solve them.
    - [CTFlows.jl](https://github.com/control-toolbox/CTFlows.jl) — **flows for indirect methods**:
      builds Hamiltonian flows from ODE systems and integrates them with CTSolvers' `Integrators`.

!!! note
    The root package is [OptimalControl.jl](https://github.com/control-toolbox/OptimalControl.jl) which aims
    to provide tools to model and solve optimal control problems with ordinary differential equations
    by direct and indirect methods, both on CPU and GPU.

!!! warning "Qualified Module Access"
    CTSolvers does **not** export functions directly. All functions and types are accessed
    via qualified module paths:

    ```julia
    using CTSolvers
    CTBase.Strategies.id(CTSolvers.Solvers.Ipopt)   # ✓ Qualified
    CTSolvers.Optimization.build_model(prob, x0, m)  # ✓ Qualified
    ```

## Module overview

| Module | Responsibility |
|--------|---------------|
| `Optimization` | Abstract problem types (`AbstractOptimizationProblem`, `BuiltModel`, `NoCache`), `build_model`/`build_solution` generic functions |
| `Modelers` | `Modelers.ADNLP`, `Modelers.Exa` — NLP backend adapters |
| `DOCP` | `DiscretizedModel` — concrete problem type, pairs OCP with its discretizer (from [CTDirect.jl](https://github.com/control-toolbox/CTDirect.jl)) |
| `Solvers` | `Solvers.Ipopt`, `Solvers.MadNLP`, `Solvers.MadNCL`, `Solvers.Knitro`, `Solvers.Uno` — NLP solver wrappers |
| `Integrators` | `Integrators.SciML` — ODE integrator wrapper |

## How this documentation is organized

- **Getting Started** — installation and a quick-start walkthrough.
- **Architecture** — module overview, type hierarchies, data flow, and design patterns.
- **Developer Guides** — step-by-step tutorials for implementing each component type:
  - [Implementing a Solver](@ref) — tag dispatch, extension pattern, CommonSolve integration
  - [Implementing an Integrator](@ref) — SciML wrapper, integration result types
  - [Implementing a Modeler](@ref) — strategy options, `build_model`/`build_solution` dispatch
  - [Implementing an Optimization Problem](@ref) — `AbstractOptimizationProblem` contract, `DiscretizedModel`
  - [Error Messages Reference](@ref) — all exception types with examples and fixes
- **API Reference** — auto-generated documentation for all public and private symbols.

!!! tip "Ask DeepWiki"
    [![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/control-toolbox/CTSolvers.jl) offers an interactive, AI-generated overview of this codebase. Answers may be inaccurate — use this reference documentation as the source of truth.
