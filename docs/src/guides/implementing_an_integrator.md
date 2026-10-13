# Implementing an Integrator

```@meta
CurrentModule = CTSolvers
```

This guide explains how to implement an ODE integrator in CTSolvers. Integrators are strategies that wrap ODE backend libraries (the SciML stack) behind a unified `CommonSolve.solve(prob, integrator)` interface. We use **Integrators.SciML** as the reference example throughout. The structure mirrors [Implementing a Solver](@ref) one-to-one — an integrator is a second instance of the very same *strategy + core/extension split* idiom, applied to ODE solving instead of NLP solving.

!!! tip "Prerequisites"
    Read [Architecture](@ref) first. An integrator is a strategy (see Implementing a Strategy in CTBase.jl documentation) with two additional requirements: a **`CommonSolve.solve` method** and a **Tag Dispatch** extension.

## The AbstractIntegrator Contract

An integrator must satisfy **three contracts**:

- **Strategy contract** — `id`, `metadata`, `options`, `parameter`, `default_parameter` (inherited from `AbstractStrategy`)
- **Solve contract** — `CommonSolve.solve(prob, integrator; options, unsafe) → AbstractIntegrationResult`
- **Tag Dispatch** — separates type definition from backend implementation

```text
AbstractStrategy
├─ id(::Type)       → Symbol
├─ metadata(::Type) → StrategyMetadata
└─ options(inst)    → StrategyOptions

AbstractIntegrator <: AbstractStrategy
└─ solve(prob, integ; options, unsafe) → AbstractIntegrationResult
   └─► AbstractSciMLIntegrator
           └─► Integrators.SciML{P<:Union{CPU,GPU}}
```

Like solvers, integrators are **parameterized** by an execution parameter
`P <: CTBase.Strategies.AbstractStrategyParameter`: `Integrators.SciML{CPU}` (the default)
integrates host arrays, `Integrators.SciML{GPU}` device arrays such as `CuArray`.

Unlike the NLP solver, there is **no callable** — the solve contract is expressed directly as
`CommonSolve.solve` methods, problem-first, exactly like the mid-level `solve(nlp, solver)` of
the NLP side. The generic stub throws `NotImplemented` with guidance.

```@example integrator
using CTSolvers
using CTBase: CTBase
nothing # hide
```

Without the extension loaded, constructing an integrator throws `ExtensionError`. Loading `OrdinaryDiffEqTsit5` activates the extension (it pulls in `SciMLBase` and `DiffEqBase`) and provides `Tsit5()` as the default algorithm:

```@example integrator
using OrdinaryDiffEqTsit5
CTSolvers.Integrators.SciML()
```

To use a different algorithm, load the corresponding backend package and pass it via `alg`.
An explicit `alg` also works without `OrdinaryDiffEqTsit5`; with neither, construction raises
a `PreconditionError` (see [Error Messages Reference](@ref)):

```@example integrator
using OrdinaryDiffEqVerner
CTSolvers.Integrators.SciML(; alg = Vern6())
```

## The Integration Result

An integrator does not return a raw ODE solution; it returns a subtype of
[`Integrators.AbstractIntegrationResult`](@ref) that exposes semantic accessors,
decoupling consumers from the backend solution type:

- `final_state(r)` — the final state vector
- `times(r)` — the vector of time points
- `evaluate_at(r, t)` — the continuous solution at time `t`
- `is_dense(r)` — whether `evaluate_at` reads a dense interpolant (defaults to `false`)
- `status(r)` — the termination status, as a `Symbol`
- `successful(r)` — whether the integration succeeded
- `regrid(r, grid)` — a copy of `r` whose output grid `times` is `grid`, read from the
  interpolant without re-integrating

For multi-phase trajectories, `merge(segments)` combines a sequence of results; the SciML
backend returns a `PiecewiseIntegrationResult`, which keeps each segment (and its
interpolant), is left-continuous at the switching times, and aggregates
`status`/`successful` so a merged result stays truthful even if one segment was solved
with `unsafe = true`.

With `saveat`, the SciML backend treats the requested times as an **output grid**: when
dense output is wanted it integrates without `saveat`, keeps the interpolant, and
returns the grid from `times(r)` — same times, values and integration cost as SciML's
native saving, with `evaluate_at` accurate everywhere.

See [Integration Results](@ref) for these semantics from the user's side.

## Implementing the Integrator Type

### Step 1 — Define the Tag

A **tag type** is a lightweight struct used for dispatch. It routes the constructor call to the right extension:

```julia
# In src/Integrators/sciml.jl
struct SciMLTag <: Core.AbstractTag end
```

### Step 2 — Define the struct

The integrator is parameterized by its execution parameter `P` and stores the validated
`options` plus two pre-computed option dictionaries — one for *point* (final-state)
integration and one for *trajectory* integration:

```julia
struct SciML{
    P<:Union{CPU,GPU},
    O<:StrategyOptions,
    OP<:Dict{Symbol,Any},
    OT<:Dict{Symbol,Any},
} <: AbstractSciMLIntegrator
    options::O
    options_point::OP
    options_trajectory::OT
end
```

The two dictionaries are exposed through the [`options_point`](@ref) / [`options_trajectory`](@ref)
accessors. Consumers (e.g. CTFlows) decide which one to pass to `solve` based on what they need;
CTSolvers does not own that decision.

### Step 3 — Implement `id` and the parameter contract

The `id` is available even without the extension:

```@example integrator
CTBase.Strategies.id(CTSolvers.Integrators.SciML)
```

```julia
CTBase.Strategies.default_parameter(::Type{<:SciML}) = CPU
CTBase.Strategies.parameter(::Type{<:SciML{P}}) where {P<:Union{CPU,GPU}} = P
```

### Step 4 — Constructors with Tag Dispatch

The constructor chain is the same as for solvers: the unparameterized constructor resolves
the default parameter, and the parameterized one calls a `build_*` function dispatching on
the **tag and parameter types**. The stub in `src/` throws an `ExtensionError` if the
extension is not loaded:

```julia
function SciML(; mode::Symbol = :strict, kwargs...)
    P = CTBase.Strategies.default_parameter(SciML)
    return SciML{P}(; mode = mode, kwargs...)
end

function SciML{P}(; mode::Symbol = :strict, kwargs...) where {P<:AbstractStrategyParameter}
    return _build_sciml_integrator(SciMLTag, P; mode = mode, kwargs...)
end

# Stub — real implementation in ext/CTSolversSciMLIntegrator.jl
function _build_sciml_integrator(
    ::Type{<:Core.AbstractTag}, ::Type{<:AbstractStrategyParameter}; kwargs...
)
    throw(Exceptions.ExtensionError(
        :OrdinaryDiffEqTsit5;
        message = "to construct a SciML integrator",
        feature = "ODE integration via SciML",
        context = "Load OrdinaryDiffEqTsit5, OrdinaryDiffEq, or DifferentialEquations ...",
    ))
end
```

!!! note "Why Tag Dispatch?"
    The `metadata` (option definitions) and the `CommonSolve.solve` method (backend call) both live in the extension. The tag type lets the constructor in `src/` dispatch to the extension without a direct dependency on the backend package. `SciMLBase` is a **weak** dependency, pulled in transitively by whichever backend extension is loaded.

## The Tag Dispatch Pattern

```text
src/Integrators/sciml.jl                    ext/CTSolversSciMLIntegrator.jl
────────────────────────────────────────    ──────────────────────────────────────────
SciML{P} <: AbstractSciMLIntegrator         metadata(::Type{SciML{P}})
SciMLTag <: Core.AbstractTag                  → StrategyMetadata(option defs...)

SciML(; kwargs...) → SciML{CPU}(; kwargs...) _build_sciml_integrator(::Type{SciMLTag}, P; …)
  → _build_sciml_integrator(SciMLTag, P; …)    → SciML{P}(opts, options_point, options_traj)

_build_sciml_integrator(::AbstractTag, P)   solve(prob::AbstractODEProblem, ::SciML)
  → ExtensionError(:OrdinaryDiffEqTsit5)      → SciMLIntegrationResult

solve(prob, ::AbstractIntegrator)           SciMLIntegrationResult (with accessors,
  → NotImplemented                            merge, regrid)
```

The split is:

| Location | Contains |
|----------|----------|
| `src/Integrators/sciml.jl` | Struct, `id`/`description`/parameter contract, tags, constructor chain, `metadata`/`build` stubs, option accessors |
| `src/Integrators/integration_result.jl` | `AbstractIntegrationResult` and its accessor stubs |
| `src/Integrators/piecewise_result.jl` | `PiecewiseIntegrationResult` (backend-agnostic multi-phase result) |
| `src/Integrators/contract.jl` | Generic `solve`, `merge` and `regrid` stubs, `__unsafe` default |
| `ext/CTSolversSciMLIntegrator.jl` | `metadata`, `_build_sciml_integrator`, `SciMLIntegrationResult`, the typed `solve`, `merge`, `regrid` |

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
function CTBase.Strategies.metadata(
    ::Type{Integrators.SciML{P}}
) where {P<:Union{CTBase.Strategies.CPU,CTBase.Strategies.GPU}}
    return CTBase.Strategies.StrategyMetadata(
        CTBase.Strategies.OptionDefinition(;
            name = :alg,
            type = Union{Missing,SciMLBase.AbstractDEAlgorithm},
            default = Integrators.__default_sciml_algorithm(Integrators.Tsit5Tag),  # missing without Tsit5
            description = "ODE algorithm (e.g. Tsit5(), Vern6()).",
            aliases = (:algorithm, :solver),
        ),
        # ... reltol, abstol, dense, save_everystep, internalnorm, etc.
    )
end
```

The option set is currently identical for `CPU` and `GPU`; the parameter is the seam where
device-specific defaults land. The core keeps a fallback `metadata(::Type{SciML})` that
delegates to `SciML{CPU}`.

**2. Constructor** — builds validated options, checks that an algorithm is available, and
resolves the `:auto` sentinel into the cached point/trajectory dictionaries:

```julia
function Integrators._build_sciml_integrator(
    ::Type{Integrators.SciMLTag}, ::Type{P}; mode = :strict, kwargs...
) where {P<:CTBase.Strategies.AbstractStrategyParameter}
    opts = CTBase.Strategies.build_strategy_options(Integrators.SciML{P}; mode = mode, kwargs...)
    raw  = CTBase.Strategies.options_dict(opts)
    raw[:alg] === missing && throw(_missing_sciml_algorithm_error())  # PreconditionError

    # point integration: only the final state is needed — :auto → false, no saveat
    options_point = copy(raw)
    for key in (:dense, :save_everystep, :save_start)
        get(options_point, key, :auto) === :auto && (options_point[key] = false)
    end
    delete!(options_point, :saveat)

    # trajectory integration: :auto → true, except save_everystep when saveat is given
    options_trajectory = copy(raw)
    has_saveat = _requested_saveat(options_trajectory) !== nothing
    for key in (:dense, :save_everystep, :save_start)
        get(options_trajectory, key, :auto) === :auto || continue
        options_trajectory[key] = !(key === :save_everystep && has_saveat)
    end

    return Integrators.SciML{P,typeof(opts),typeof(options_point),typeof(options_trajectory)}(
        opts, options_point, options_trajectory,
    )
end
```

**3. Solve** — integrates the (external) `ODEProblem` and wraps the solution:

```julia
function CommonSolve.solve(prob::SciMLBase.AbstractODEProblem, integ::Integrators.SciML;
                           options = Integrators.options_trajectory(integ),
                           unsafe = Integrators.__unsafe())
    saveat = _requested_saveat(options, prob)
    if saveat === nothing                       # plain integration
        ode_sol = SciMLBase.solve(prob; options...)
        _check_retcode(ode_sol, unsafe)          # SolverFailure unless unsafe
        return SciMLIntegrationResult(ode_sol)
    end
    # with dense output, saveat is an output grid only: integrate dense without it,
    # keep the interpolant, and return the saveat grid as the result's time grid
    # (with dense = false, SciML's native saveat is used instead)
    ...
    return SciMLIntegrationResult(ode_sol, grid)
end
```

!!! info "Grid invariance (IND)"
    The `internalnorm` option defaults to [`Integrators.real_norm`](@ref), which strips the primal part of ForwardDiff dual numbers so the adaptive time grid is identical with real or dual numbers. The dual overloads live in `CTSolversForwardDiff`; the array overload lives in `CTSolversSciMLIntegrator`.

## CommonSolve Integration

```julia
using CTSolvers
using OrdinaryDiffEqTsit5     # activates CTSolversSciMLIntegrator + default Tsit5
using SciMLBase: ODEProblem
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

- Define `MyTag <: Core.AbstractTag`
- Define `MyIntegrator{P<:CPU} <: AbstractIntegrator` with an `options::StrategyOptions` field (widen the bound to `Union{CPU,GPU}` for device-capable backends)
- Implement `CTBase.Strategies.id(::Type{<:MyIntegrator}) = :my_integrator`, `default_parameter` and `parameter`
- Write the constructor chain: `MyIntegrator(; ...)` → `MyIntegrator{P}(; ...)` → `build_my_integrator(MyTag, P; mode, kwargs...)`
- Write stub: `build_my_integrator(::Type{<:Core.AbstractTag}, ::Type{<:AbstractStrategyParameter}; kwargs...) = throw(ExtensionError(...))`

### In `ext/CTSolversMyBackend.jl`

- Implement `CTBase.Strategies.metadata(::Type{MyIntegrator{P}}) where {P<:CPU}` with all option definitions
- Implement `Integrators.build_my_integrator(::Type{MyTag}, P; kwargs...)` — real constructor
- Implement `CommonSolve.solve(prob::ExternalProblem, integ::MyIntegrator; options, unsafe)` returning an `AbstractIntegrationResult`, plus its `final_state`/`times`/`evaluate_at`/`is_dense`/`status`/`successful` (and `merge`, `regrid`)

### In `Project.toml`

- Add `MyBackend` to `[weakdeps]` and `CTSolversMyBackend = "MyBackend"` to `[extensions]`

### Tests

- **Contract test**: `id`, `metadata` (extension loaded), and `options`
- **Solve test**: `solve(prob, integ)` returns an `AbstractIntegrationResult` with correct `final_state`/`times`/`evaluate_at`/`status`/`successful`
- **Extension error test**: without `using MyBackend`, `MyIntegrator()` throws `ExtensionError`, and the generic `solve`/`merge`/`regrid` stubs throw `NotImplemented`
