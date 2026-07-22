# Implementing an Integrator

```@meta
CurrentModule = CTSolvers
```

This guide explains how to implement an ODE integrator in CTSolvers. Integrators are strategies that wrap ODE backend libraries (the SciML stack) behind a unified `CommonSolve.solve(prob, integrator)` interface. We use **Integrators.SciML** as the reference example throughout. The structure mirrors [Implementing a Solver](@ref) one-to-one — an integrator is a second instance of the very same *strategy + core/extension split* idiom, applied to ODE solving instead of NLP solving.

!!! tip "Prerequisites"
    Read [Architecture](@ref) first. An integrator is a strategy (see Implementing a Strategy in CTBase.jl documentation) with two additional requirements: a **`CommonSolve.solve` method** and a **Tag Dispatch** extension.

## The AbstractIntegrator Contract

An integrator must satisfy **three contracts**:

1. **Strategy contract** — `id`, `metadata`, `options` (inherited from `AbstractStrategy`)
2. **Solve contract** — `CommonSolve.solve(prob, integrator; options, unsafe) → AbstractIntegrationResult`
3. **Tag Dispatch** — separates type definition from backend implementation

```text
AbstractStrategy
├─ id(::Type)       → Symbol
├─ metadata(::Type) → StrategyMetadata
└─ options(inst)    → StrategyOptions

AbstractIntegrator <: AbstractStrategy
└─ solve(prob, integ; options, unsafe) → AbstractIntegrationResult
   └─► AbstractSciMLIntegrator
           └─► Integrators.SciML
```

Unlike the NLP solver, there is **no callable** — the solve contract is expressed directly as
`CommonSolve.solve` methods, problem-first, exactly like the mid-level `solve(nlp, solver)` of
the NLP side. The generic stub throws `NotImplemented` with guidance.

```@example integrator
using CTSolvers
using CTBase: CTBase
nothing # hide
```

Without the extension loaded, constructing an integrator throws `ExtensionError`:

```@repl integrator
try # hide
CTSolvers.Integrators.SciML()
catch e # hide
showerror(IOContext(stdout, :color => false), e) # hide
end # hide
```

## The Integration Result

An integrator does not return a raw ODE solution; it returns a subtype of
[`Integrators.AbstractIntegrationResult`](@ref) that exposes semantic accessors,
decoupling consumers from the backend solution type:

- `final_state(r)` — the final state vector
- `times(r)` — the vector of time points
- `evaluate_at(r, t)` — the continuous solution at time `t`
- `status(r)` — the termination status, as a `Symbol`
- `successful(r)` — whether the integration succeeded

For multi-phase trajectories, `merge(segments)` concatenates a sequence of results,
aggregating `status`/`successful` so a merged result stays truthful even if one segment
was solved with `unsafe = true`.

## Implementing the Integrator Type

### Step 1 — Define the Tag

A **tag type** is a lightweight struct used for dispatch. It routes the constructor call to the right extension:

```julia
# In src/Integrators/sciml.jl
struct SciMLTag <: Core.AbstractTag end
```

### Step 2 — Define the struct

The integrator stores the validated `options` plus two pre-computed option dictionaries —
one for *point* (final-state) integration and one for *trajectory* integration:

```julia
struct SciML{O,OP,OT} <: AbstractSciMLIntegrator
    options::O               # StrategyOptions
    options_point::OP        # Dict{Symbol,Any}
    options_trajectory::OT   # Dict{Symbol,Any}
end
```

The two dictionaries are exposed through the [`options_point`](@ref) / [`options_trajectory`](@ref)
accessors. Consumers (e.g. CTFlows) decide which one to pass to `solve` based on what they need;
CTSolvers does not own that decision.

### Step 3 — Implement `id`

The `id` is available even without the extension:

```@example integrator
CTBase.Strategies.id(CTSolvers.Integrators.SciML)
```

### Step 4 — Constructor with Tag Dispatch

The constructor delegates to a `build_*` function that dispatches on the tag. The stub in `src/` throws an `ExtensionError` if the extension is not loaded:

```julia
function SciML(; mode::Symbol = :strict, kwargs...)
    return _build_sciml_integrator(SciMLTag; mode = mode, kwargs...)
end

# Stub — real implementation in ext/CTSolversSciMLIntegrator.jl
function _build_sciml_integrator(::Type{<:Core.AbstractTag}; kwargs...)
    throw(Exceptions.ExtensionError(
        :OrdinaryDiffEqTsit5;
        message = "to construct a SciML integrator",
        feature = "ODE integration via SciML",
        context = "Load OrdinaryDiffEqTsit5, OrdinaryDiffEq, or DifferentialEquations.",
    ))
end
```

!!! note "Why Tag Dispatch?"
    The `metadata` (option definitions) and the `CommonSolve.solve` method (backend call) both live in the extension. The tag type lets the constructor in `src/` dispatch to the extension without a direct dependency on the backend package. `SciMLBase` is a **weak** dependency, pulled in transitively by whichever backend extension is loaded.

## The Tag Dispatch Pattern

```text
src/Integrators/sciml.jl                ext/CTSolversSciMLIntegrator.jl
────────────────────────────────────    ─────────────────────────────────────────
SciML <: AbstractSciMLIntegrator        metadata(::Type{SciML})
SciMLTag <: Core.AbstractTag              → StrategyMetadata(option defs...)

SciML(; kwargs...)                      _build_sciml_integrator(::Type{SciMLTag}; …)
  → _build_sciml_integrator(SciMLTag; …)   → SciML(opts, options_point, options_traj)

_build_sciml_integrator(::AbstractTag)   solve(prob::AbstractODEProblem, ::SciML)
  → ExtensionError(:OrdinaryDiffEqTsit5)  → SciMLIntegrationResult

solve(prob, ::AbstractIntegrator)       SciMLIntegrationResult (with accessors)
  → NotImplemented
```

The split is:

| Location | Contains |
|----------|----------|
| `src/Integrators/sciml.jl` | Struct, `id`/`description`, tag, constructor stub, `metadata`/`build` stubs, accessors |
| `src/Integrators/contract.jl` | Generic `solve` stub, `merge` stub, `__unsafe` default |
| `ext/CTSolversSciMLIntegrator.jl` | `metadata`, `_build_sciml_integrator`, `SciMLIntegrationResult`, the typed `solve`, `merge` |

This keeps CTSolvers lightweight — `SciMLBase`/`DiffEqBase` are only loaded when the user loads an ODE backend.

## Creating the Extensions

### File structure

```text
ext/
├── CTSolversSciMLIntegrator.jl     # metadata + builder + solve + result + merge
├── CTSolversForwardDiff.jl         # deepvalue / real_norm for ForwardDiff.Dual
└── CTSolversOrdinaryDiffEqTsit5.jl # default algorithm (Tsit5) via tag dispatch
```

### Project.toml declaration

```toml
[weakdeps]
DiffEqBase = "2b5f629d-d688-5b77-993f-72d75c75574e"
ForwardDiff = "f6369f11-7733-5829-9624-2563aa707210"
OrdinaryDiffEqTsit5 = "b1df2697-797e-41e3-8120-5422d3b24e4a"
SciMLBase = "0bca4576-84f4-4d90-8ffe-ffa030f20462"

[extensions]
CTSolversSciMLIntegrator = ["DiffEqBase", "SciMLBase"]
CTSolversForwardDiff = "ForwardDiff"
CTSolversOrdinaryDiffEqTsit5 = "OrdinaryDiffEqTsit5"
```

### Extension implementation

**1. Metadata** — option definitions with types, defaults, validators (`reltol`, `abstol`, `alg`, `dense`, `saveat`, `internalnorm`, …):

```julia
function CTBase.Strategies.metadata(::Type{Integrators.SciML})
    return CTBase.Strategies.StrategyMetadata(
        CTBase.Strategies.OptionDefinition(;
            name = :alg,
            type = SciMLBase.AbstractDEAlgorithm,
            default = Integrators.__default_sciml_algorithm(Integrators.Tsit5Tag),
            description = "ODE algorithm (e.g. Tsit5(), Vern6()).",
        ),
        # ... reltol, abstol, dense, save_everystep, internalnorm, etc.
    )
end
```

**2. Constructor** — builds validated options and resolves the `:auto` sentinel into the cached point/trajectory dictionaries:

```julia
function Integrators._build_sciml_integrator(::Type{Integrators.SciMLTag}; mode = :strict, kwargs...)
    opts = CTBase.Strategies.build_strategy_options(Integrators.SciML; mode = mode, kwargs...)
    raw  = CTBase.Strategies.options_dict(opts)
    options_point = copy(raw); options_trajectory = copy(raw)
    for key in (:dense, :save_everystep, :save_start)
        get(options_point, key, :auto) === :auto && (options_point[key] = false)
        get(options_trajectory, key, :auto) === :auto && (options_trajectory[key] = true)
    end
    return Integrators.SciML{typeof(opts),typeof(options_point),typeof(options_trajectory)}(
        opts, options_point, options_trajectory,
    )
end
```

**3. Solve** — integrates the (external) `ODEProblem` and wraps the solution:

```julia
function CommonSolve.solve(prob::SciMLBase.AbstractODEProblem, integ::Integrators.SciML;
                           options = Integrators.options_trajectory(integ),
                           unsafe = Integrators.__unsafe())
    ode_sol = SciMLBase.solve(prob; options...)
    _check_retcode(ode_sol, unsafe)
    return SciMLIntegrationResult(ode_sol)
end
```

!!! info "Grid invariance (IND)"
    The `internalnorm` option defaults to [`Integrators.real_norm`](@ref), which strips the primal part of ForwardDiff dual numbers so the adaptive time grid is identical with real or dual numbers. The dual overloads live in `CTSolversForwardDiff`; the array overload lives in `CTSolversSciMLIntegrator`.

## CommonSolve Integration

```julia
using CTSolvers
using OrdinaryDiffEqTsit5     # activates CTSolversSciMLIntegrator + default Tsit5
using CommonSolve

integ = CTSolvers.Integrators.SciML(alg = Tsit5())
prob  = ODEProblem((u, p, t) -> -u, [1.0], (0.0, 1.0))

r = solve(prob, integ)                  # → SciMLIntegrationResult
CTSolvers.Integrators.final_state(r)    # ≈ [exp(-1)]
CTSolvers.Integrators.evaluate_at(r, 0.5)  # ≈ [exp(-0.5)]
CTSolvers.Integrators.successful(r)     # true
CTSolvers.Integrators.status(r)         # :Success
```

!!! note "Where the domain glue lives"
    Turning a control system/configuration into an `ODEProblem` (`build_problem`) and choosing
    point vs trajectory options (`build_options`) is **not** part of CTSolvers — it belongs to
    the consuming package (e.g. CTFlows). CTSolvers only integrates a ready-made `ODEProblem`
    and exposes the `options_point`/`options_trajectory` accessors.

## Summary: Adding a New Integrator

To add a new integrator (e.g. `MyIntegrator` backed by `MyBackend`):

### In `src/Integrators/`

1. Define `MyTag <: Core.AbstractTag`
2. Define `MyIntegrator <: AbstractIntegrator` with an `options::StrategyOptions` field
3. Implement `CTBase.Strategies.id(::Type{<:MyIntegrator}) = :my_integrator`
4. Write constructor: `MyIntegrator(; mode, kwargs...) = build_my_integrator(MyTag; mode, kwargs...)`
5. Write stub: `build_my_integrator(::Type{<:Core.AbstractTag}; kwargs...) = throw(ExtensionError(...))`

### In `ext/CTSolversMyBackend.jl`

6. Implement `CTBase.Strategies.metadata(::Type{<:MyIntegrator})` with all option definitions
7. Implement `Integrators.build_my_integrator(::Type{MyTag}; kwargs...)` — real constructor
8. Implement `CommonSolve.solve(prob::ExternalProblem, integ::MyIntegrator; options, unsafe)` returning an `AbstractIntegrationResult`, plus its `final_state`/`times`/`evaluate_at`/`status`/`successful` (and `merge`)

### In `Project.toml`

9. Add `MyBackend` to `[weakdeps]` and `CTSolversMyBackend = "MyBackend"` to `[extensions]`

### Tests

10. **Contract test**: `id`, `metadata` (extension loaded), and `options`
11. **Solve test**: `solve(prob, integ)` returns an `AbstractIntegrationResult` with correct `final_state`/`times`/`evaluate_at`/`status`/`successful`
12. **Extension error test**: without `using MyBackend`, `MyIntegrator()` throws `ExtensionError`, and the generic `solve`/`merge` stubs throw `NotImplemented`
