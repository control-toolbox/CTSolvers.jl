# Strategies Catalogue

```@meta
CurrentModule = CTSolvers
```

This page lists every strategy CTSolvers provides: what it wraps, which package activates
it, and on which device it runs. Most users reach these strategies through
[OptimalControl.jl](https://github.com/control-toolbox/OptimalControl.jl) (e.g.
`solve(ocp, :adnlp, :ipopt)`); the symbols used there are the strategy `id`s below.

```@setup cat
using CTSolvers
using CTBase: CTBase
using NLPModelsIpopt, MadNLP, MadNCL, NLPModelsKnitro, UnoSolver
using ADNLPModels, ExaModels
using OrdinaryDiffEqTsit5
```

## NLP solvers — `CTSolvers.Solvers`

| Strategy | `id` | Load | Parameters | Backend |
|:---------|:-----|:-----|:-----------|:--------|
| `Solvers.Ipopt` | `:ipopt` | `NLPModelsIpopt` | `CPU` | Interior point (COIN-OR Ipopt) |
| `Solvers.MadNLP` | `:madnlp` | `MadNLP` | `CPU`, `GPU` | Pure-Julia interior point |
| `Solvers.MadNCL` | `:madncl` | `MadNCL`, `MadNLP` | `CPU`, `GPU` | Augmented Lagrangian (NCL) on top of MadNLP |
| `Solvers.Knitro` | `:knitro` | `NLPModelsKnitro` | `CPU` | Commercial solver by Artelys (license required) |
| `Solvers.Uno` | `:uno` | `UnoSolver` | `CPU` | Unified Lagrange-Newton solver (interior point, SQP, …) |

Every solver solves an `NLPModels.AbstractNLPModel` through `CommonSolve.solve` and
returns a `SolverCore.AbstractExecutionStats`:

```julia
using ADNLPModels, NLPModelsIpopt
using CommonSolve: solve

nlp = ADNLPModel(x -> sum(x .^ 2), ones(10))
stats = solve(nlp, CTSolvers.Solvers.Ipopt(max_iter = 100); display = false)
```

`display = false` silences the backend's output.
[`Solvers.extract_solver_infos`](@ref) turns the stats into the
`(objective, iterations, constraints_violation, message, status, successful)` tuple used
to build an optimal control solution.

## NLP modelers — `CTSolvers.Modelers`

A modeler chooses the NLP backend used to transcribe a discretized problem and carries
its options. It does not build anything itself: the package providing the problem (e.g.
CTDirect) builds the NLP model for each `(problem, modeler)` pair.

| Strategy | `id` | Load | Parameters | Backend |
|:---------|:-----|:-----|:-----------|:--------|
| `Modelers.ADNLP` | `:adnlp` | `ADNLPModels` | `CPU` | [ADNLPModels](https://jso.dev/ADNLPModels.jl) — automatic differentiation |
| `Modelers.Exa` | `:exa` | `ExaModels` | `CPU`, `GPU` | [ExaModels](https://exanauts.github.io/ExaModels.jl) — SIMD abstraction, GPU-ready |

ADNLP backends based on `Enzyme` or `Zygote` additionally require that package to be loaded.

## ODE integrators — `CTSolvers.Integrators`

| Strategy | `id` | Load | Parameters | Backend |
|:---------|:-----|:-----|:-----------|:--------|
| `Integrators.SciML` | `:sciml` | `OrdinaryDiffEqTsit5` (or `OrdinaryDiffEq`, `DifferentialEquations`) | `CPU`, `GPU` | Any SciML ODE algorithm |

`Tsit5()` is the default algorithm when `OrdinaryDiffEqTsit5` is loaded; any other
algorithm is passed through `alg` (e.g. `alg = Vern9()` after `using OrdinaryDiffEqVerner`).
See [Integration Results](@ref) for what `solve` returns.

## Options

Options are validated when the strategy is built. Each name, type, default and
description is available from the strategy type:

```@repl cat
CTBase.Strategies.metadata(CTSolvers.Solvers.Knitro)
```

An instance shows its actual values, with their provenance (`user` or `default`):

```@repl cat
CTSolvers.Integrators.SciML(reltol = 1e-10, abstol = 1e-10)
```

Unknown options are rejected with a suggestion; `mode = :permissive` accepts them with a
warning and passes them to the backend unchanged, which gives access to backend options
CTSolvers does not declare:

```@repl cat
CTSolvers.Solvers.Ipopt(max_itr = 100)
CTSolvers.Solvers.Ipopt(bound_relax_factor = 1e-10; mode = :permissive)
```

To skip validation for a single option only, wrap its value:
`Solvers.Ipopt(bound_relax_factor = CTBase.Strategies.bypass(1e-10))`.

Several options have aliases (e.g. `maxiter` for Ipopt's `max_iter`, `rtol` for SciML's
`reltol`); `metadata` lists them.

## Choosing a parameter

`CPU` is the default for every strategy: `Solvers.MadNLP()` is `Solvers.MadNLP{CPU}()`.
Pass the parameter explicitly to target the GPU — see [GPU](@ref "GPU Execution").
