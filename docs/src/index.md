# CTSolvers.jl

`CTSolvers.jl` is the **resolution layer** of the [control-toolbox](https://github.com/control-toolbox)
ecosystem. It provides the strategies — NLP modelers, NLP solvers, ODE integrators — and the
abstract problem types that upstream packages use to solve optimal control problems.

!!! info "Who is this documentation for?"
    This is a reference for **developers and experienced users** of the ecosystem.
    To model and solve optimal control problems, start with
    [OptimalControl.jl](https://control-toolbox.org/OptimalControl.jl), which builds on
    CTSolvers and exposes its strategies through `solve`.

CTSolvers does not solve optimal control problems by itself. Two packages build on it:

- [CTDirect.jl](https://github.com/control-toolbox/CTDirect.jl) — **direct methods**:
  discretizes continuous-time OCPs (defined in [CTModels.jl](https://github.com/control-toolbox/CTModels.jl))
  into finite-dimensional NLPs, then uses CTSolvers' `Modelers` and `Solvers` to solve them.
- [CTFlows.jl](https://github.com/control-toolbox/CTFlows.jl) — **flows for indirect methods**:
  builds Hamiltonian flows from ODE systems and integrates them with CTSolvers' `Integrators`.

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
|:-------|:--------------|
| `Optimization` | Abstract problem type (`AbstractOptimizationProblem`), `BuiltModel`, `NoCache`, generic `build_model`/`build_solution` |
| `Modelers` | `Modelers.ADNLP`, `Modelers.Exa` — NLP backend selection |
| `DOCP` | `AbstractDiscretizer`, `DiscretizedModel` — an OCP paired with its discretizer; `discretize` |
| `Solvers` | `Solvers.Ipopt`, `Solvers.MadNLP`, `Solvers.MadNCL`, `Solvers.Knitro`, `Solvers.Uno` — NLP solvers |
| `Integrators` | `Integrators.SciML` — ODE integrator, and integration results |

## How this documentation is organized

- **Getting Started** — installation, extension loading, options.
- **Architecture** — modules, type hierarchies, data flow, and design patterns.
- **Using CTSolvers** — for experienced users:
  - [Strategies Catalogue](@ref) — every solver, modeler and integrator, with its package and devices
  - [Integration Results](@ref) — reading results, `saveat`, `regrid`, multi-phase merge
  - [GPU Execution](@ref) — the `GPU` parameter and its requirements
- **Developer Guides** — implementing new components:
  - [Implementing a Solver](@ref) — tag dispatch, extension pattern, CommonSolve integration
  - [Implementing an Integrator](@ref) — SciML wrapper, integration result types
  - [Implementing a Modeler](@ref) — strategy options, `build_model`/`build_solution` dispatch
  - [Implementing an Optimization Problem](@ref) — `AbstractOptimizationProblem` contract, `DiscretizedModel`
  - [Performance & Type Stability](@ref) — hot path vs setup path, JET and allocation checks
  - [Error Messages Reference](@ref) — all exception types with examples and fixes
- **API Reference** — auto-generated documentation for all public and private symbols.

!!! tip "Ask DeepWiki"
    [![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/control-toolbox/CTSolvers.jl) offers an interactive, AI-generated overview of this codebase. Answers may be inaccurate — use this reference documentation as the source of truth.
