# CTSolvers.jl

`CTSolvers.jl` is the **resolution layer** of the [control-toolbox](https://github.com/control-toolbox) ecosystem. It transforms optimal control problems (defined in [CTModels.jl](https://github.com/control-toolbox/CTModels.jl)) into NLP models, solves them, and converts the results back into optimal control solutions.

!!! info "CTSolvers vs CTModels"
    **CTSolvers** focuses on **solving** optimal control problems (discretization, NLP backends, optimization strategies).
    For **defining** these problems and representing their solutions,
    see [CTModels.jl](https://github.com/control-toolbox/CTModels.jl).

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
| `CTBase.Options` | Option definition, extraction, validation, provenance tracking |
| `CTBase.Strategies` | Abstract strategy contract, metadata, options, registry |
| `CTBase.Orchestration` | Option routing, disambiguation, method tuple handling |
| `Optimization` | Abstract problem types, builder pattern, build/solve API |
| `Modelers` | `Modelers.ADNLP`, `Modelers.Exa` — NLP backend adapters |
| `DOCP` | `DiscretizedModel` — concrete problem type bridging CTModels and CTSolvers |
| `Solvers` | `Solvers.Ipopt`, `Solvers.MadNLP`, `Solvers.MadNCL`, `Solvers.Knitro`, `Solvers.Uno` — NLP solver wrappers |
| `Integrators` | `Integrators.SciML` — ODE integrator wrapper |

## How this documentation is organized

- **Getting Started** — installation and a quick-start walkthrough.
- **Architecture** — module overview, type hierarchies, data flow, and design patterns.
- **Developer Guides** — step-by-step tutorials for implementing each component type:
  - [Implementing a Solver](@ref) — tag dispatch, extension pattern, CommonSolve integration
  - [Implementing an Integrator](@ref) — SciML wrapper, integration result types
  - [Implementing a Modeler](@ref) — callable contracts, builder interaction
  - [Implementing an Optimization Problem](@ref) — builder pattern, DOCP example
  - [Error Messages Reference](@ref) — all exception types with examples and fixes
- **API Reference** — auto-generated documentation for all public and private symbols.

!!! tip "Ask DeepWiki"
    [![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/control-toolbox/CTSolvers.jl) offers an interactive, AI-generated overview of this codebase. Answers may be inaccurate — use this reference documentation as the source of truth.
