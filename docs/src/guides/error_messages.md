# Error Messages Reference

```@meta
CurrentModule = CTSolvers
```

This page catalogues all exception types used in CTSolvers, with live examples and recommended fixes. CTSolvers uses enriched exceptions from `CTBase.Exceptions` that carry structured fields (`got`, `expected`, `suggestion`, `context`) for actionable error messages.

## Exception Types

CTSolvers uses five exception types from `CTBase.Exceptions`:

| Type | Purpose |
|------|---------|
| `NotImplemented` | Contract method not implemented by a concrete type |
| `IncorrectArgument` | Invalid argument value, type, or routing |
| `ExtensionError` | Required package extension not loaded |
| `PreconditionError` | A required precondition is not met (e.g. no ODE algorithm available) |
| `SolverFailure` | A backend reported a failure (e.g. unsuccessful ODE retcode) |

A type parameter outside a strategy's bound (e.g. `Solvers.Ipopt{GPU}` for a CPU-only
solver) is rejected by Julia itself with a `TypeError`, before any CTSolvers code runs.

All CTSolvers exceptions accept keyword arguments for structured messages:

```@example errors
using CTSolvers
using CTBase: CTBase
const Exceptions = CTBase.Exceptions
nothing # hide
```

## NotImplemented — Contract Not Implemented

Thrown when a concrete type doesn't implement a required contract method.

### Strategy contract — missing `id`

```@example errors
abstract type IncompleteStrategy <: CTBase.Strategies.AbstractStrategy end
nothing # hide
```

```@repl errors
CTBase.Strategies.id(IncompleteStrategy)
```

**Fix**: Implement the missing method:

```julia
CTBase.Strategies.id(::Type{<:IncompleteStrategy}) = :my_strategy
```

### Strategy contract — missing `metadata`

```@repl errors
CTBase.Strategies.metadata(IncompleteStrategy)
```

### Optimization problem contract — missing build_model

Define a problem type and a modeler, but no `(problem, modeler)` method. A dedicated block
label (`optprob`) keeps these throwaway types out of the shared `errors` scope:

```@example optprob
using CTSolvers
struct MinimalProblem <: CTSolvers.Optimization.AbstractOptimizationProblem end
struct MinimalModeler <: CTSolvers.Modelers.AbstractNLPModeler end
nothing # hide
```

The generic stub in `Modelers/contract.jl` throws `NotImplemented` as soon as `build_model`
is called with a `(problem, modeler)` pair for which no concrete method exists:

```@repl optprob
CTSolvers.Optimization.build_model(MinimalProblem(), nothing, MinimalModeler())
```

**Fix**: Implement `build_model` and `build_solution` in the package providing the
problem, dispatching on the concrete `(problem, modeler)` pair (see
[Implementing an Optimization Problem](@ref)).

### Where it's thrown

| Method | Context |
|--------|---------|
| `CTBase.Strategies.id(::Type{T})` | Strategy type missing `id` |
| `CTBase.Strategies.metadata(::Type{T})` | Strategy type missing `metadata` |
| `CTBase.Strategies.options(strategy)` | Strategy instance has no `options` field and no custom getter |
| `Optimization.build_model(prob, init, modeler)` | No concrete method for this `(problem, modeler)` pair |
| `Optimization.build_solution(built, stats, modeler)` | No concrete method for this `(built, modeler)` pair |

## IncorrectArgument — Invalid Arguments

Thrown for invalid values, types, or routing errors. This is the most common exception in CTSolvers.

### Type mismatch in extraction

When `extract_option` receives a value of the wrong type:

```@repl errors
def = CTBase.Options.OptionDefinition(
    name = :max_iter, type = Integer, default = 100,
    description = "Maximum iterations",
)
CTBase.Options.extract_option((max_iter = "hello",), def)
```

**Fix**: Provide a value of the correct type.

### Validator failure

When a value doesn't satisfy the validator constraint:

```@example errors
bad_def = CTBase.Options.OptionDefinition(
    name = :tol, type = Real, default = 1e-8,
    description = "Tolerance",
    validator = x -> x > 0 || throw(Exceptions.IncorrectArgument(
        "Invalid tolerance value",
        got = "tol=$x",
        expected = "positive real number (> 0)",
        suggestion = "Provide a positive tolerance value (e.g., 1e-6, 1e-8)",
        context = "tol validation",
    )),
)
nothing # hide
```

```@repl errors
CTBase.Options.extract_option((tol = -1.0,), bad_def)
```

**Fix**: Provide a value that satisfies the validator constraint.

### Type mismatch in OptionDefinition constructor

When the default value doesn't match the declared type:

```@repl errors
CTBase.Options.OptionDefinition(
    name = :count, type = Integer, default = "hello",
    description = "A count",
)
```

**Fix**: Ensure the default value matches the declared type.

### Invalid OptionValue source

```@repl errors
CTBase.Options.OptionValue(42, :invalid_source)
```

**Fix**: Use `:default`, `:user`, or `:computed`.

### Invalid output grid in `regrid`

[`Integrators.regrid`](@ref) checks that the new grid has at least two times, is strictly
monotone in the integration direction and lies in the integration span:

```@example regrid
using CTSolvers: Integrators
using OrdinaryDiffEqTsit5
using SciMLBase: ODEProblem
using CommonSolve: CommonSolve
r = CommonSolve.solve(ODEProblem((u, p, t) -> -u, 1.0, (0.0, 1.0)), Integrators.SciML())
nothing # hide
```

```@repl regrid
Integrators.regrid(r, [0.0, 2.0])
```

**Fix**: Use a grid inside `(t0, tf)`, e.g. `Integrators.regrid(r, 0:0.25:1)`.

## ExtensionError — Extension Not Loaded

Thrown when a solver requires a package extension that hasn't been loaded.

```@repl errors
CTSolvers.Solvers.MadNLP()
```

**Fix**: Load the required package before using the solver:

```julia
using MadNLP  # loads the CTSolversMadNLP extension
solver = Solvers.MadNLP(max_iter = 1000)
```

### Where it's thrown

| Strategy | Required packages |
|----------|-------------------|
| `Solvers.Ipopt` | `NLPModelsIpopt` |
| `Solvers.MadNLP` | `MadNLP` |
| `Solvers.MadNCL` | `MadNCL`, `MadNLP` |
| `Solvers.Knitro` | `NLPModelsKnitro` |
| `Solvers.Uno` | `UnoSolver` |
| `Solvers.MadNLP{GPU}`, `Solvers.MadNCL{GPU}` | `MadNLPGPU`, `CUDA`, `CUDSS` (in addition) |
| `Modelers.ADNLP` | `ADNLPModels` |
| `Modelers.Exa` | `ExaModels` (and `CUDA` for `Modelers.Exa{GPU}`) |
| `Integrators.SciML` | `OrdinaryDiffEqTsit5`, `OrdinaryDiffEq`, or `DifferentialEquations` |

Some ADNLP backends also need their AD package (`Enzyme`, `Zygote`).

## PreconditionError — Missing Precondition

Thrown when `Integrators.SciML` is built with the SciML extension active (`SciMLBase` and
`DiffEqBase` loaded) but no algorithm is available: no explicit `alg` and
`OrdinaryDiffEqTsit5` not loaded to provide the default `Tsit5()`.

```julia
julia> using OrdinaryDiffEqVerner   # loads SciMLBase/DiffEqBase, but not Tsit5

julia> CTSolvers.Integrators.SciML()
PreconditionError
│  No ODE algorithm specified and OrdinaryDiffEqTsit5 is not loaded
│  Reason   alg is missing
│  Context  SciML integrator construction
│  Hint     Load OrdinaryDiffEqTsit5: using OrdinaryDiffEqTsit5
│           Or specify an algorithm explicitly, for example:
│             SciML(alg=Vern6())
```

**Fix**: Pass an algorithm explicitly, `Integrators.SciML(alg = Vern6())`, or load
`OrdinaryDiffEqTsit5`.

## SolverFailure — Backend Failure

Thrown by `CommonSolve.solve(prob, ::Integrators.SciML)` when the ODE solver returns an
unsuccessful retcode, e.g. a solution that blows up in finite time:

```julia
julia> prob = ODEProblem((u, p, t) -> u^2, 1.0, (0.0, 2.0));

julia> CommonSolve.solve(prob, Integrators.SciML())
SolverFailure
│  ODE integration failed
│  Retcode  Unstable
│  Context  SciML solve
│  Hint     Try tightening tolerances (reltol, abstol) or changing the solver algorithm.
```

**Fix**: Check the model, tighten the tolerances or change the algorithm. To inspect the
partial result instead, pass `unsafe = true`: no exception is thrown and
`Integrators.successful(r)` is `false`, `Integrators.status(r)` is `:Unstable`.

## Best Practices for Error Messages

When implementing new validators or error paths, follow the CTSolvers convention:

```julia
throw(Exceptions.IncorrectArgument(
    "Short, clear description of the problem",
    got        = "what the user actually provided",
    expected   = "what was expected instead",
    suggestion = "actionable fix the user can apply",
    context    = "ModuleName.function_name - specific validation step",
))
```

- **`got`**: Show the actual value, including its type if relevant
- **`expected`**: Be specific about valid values or ranges
- **`suggestion`**: Provide a concrete example the user can copy
- **`context`**: Include the module and function name for traceability
