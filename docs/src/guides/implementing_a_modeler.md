# Implementing a Modeler

```@meta
CurrentModule = CTSolvers
```

This guide explains how to implement an optimization modeler in CTSolvers. Modelers are strategies that select and configure the NLP backend (ADNLPModels, ExaModels, …) used to turn an `AbstractOptimizationProblem` into an NLP model. We use **Modelers.ADNLP** and **Modelers.Exa** as reference examples.

!!! tip "Prerequisites"
    Read [Architecture](@ref) first. A modeler is a strategy (see Implementing a Strategy in CTBase.jl documentation): it **carries validated backend options** and acts as a dispatch token — it does not build anything itself.

## The AbstractNLPModeler Contract

A modeler must satisfy **two contracts**:

1. **Strategy contract** — `id`, `metadata`, `options`, `parameter`, `default_parameter` (inherited from `AbstractStrategy`)
2. **Modeler contract** — the generic functions `Optimization.build_model` / `Optimization.build_solution`, dispatched on the `(problem, modeler)` pair

```text
AbstractStrategy
├─ id(::Type)       → Symbol
├─ metadata(::Type) → StrategyMetadata
└─ options(inst)    → StrategyOptions

AbstractNLPModeler <: AbstractStrategy
├─ build_model(prob, x0, modeler)        → BuiltModel  (generic stub in CTSolvers)
├─ build_solution(built, stats, modeler) → Solution    (generic stub in CTSolvers)
├─► Modelers.ADNLP{P<:CPU}
└─► Modelers.Exa{P<:Union{CPU,GPU}}
```

The modeler is **not callable** and does not know how to build an NLP model. The typed
`build_model` / `build_solution` methods are implemented by the **package providing the
problem** (e.g. CTDirect for `DiscretizedModel`), by multiple dispatch on the concrete
`(problem, modeler)` pair. The generic stubs in CTSolvers (`src/Modelers/contract.jl`)
throw `NotImplemented` with guidance when no method exists for a pair.

```@example modeler
using CTSolvers
using CTBase: CTBase
nothing # hide
```

The `id` is available directly, without any extension:

```@example modeler
CTBase.Strategies.id(CTSolvers.Modelers.ADNLP)
```

```@example modeler
CTBase.Strategies.id(CTSolvers.Modelers.Exa)
```

## Step-by-Step Implementation

We walk through the `Modelers.ADNLP` implementation (`src/Modelers/adnlp.jl`) as a reference.

### Step 1 — Define the parameterized struct and its tag

Modelers are **parameterized** by an execution parameter `P <: AbstractStrategyParameter`
(see Strategy Parameters in CTBase.jl documentation). ADNLP only supports CPU:

```julia
struct ADNLPTag <: CTBase.Core.AbstractTag end

struct ADNLP{P<:CPU} <: AbstractNLPModeler
    options::CTBase.Strategies.StrategyOptions
end
```

The tag type is used later to route the constructor to the extension (see Step 4).

### Step 2 — Implement `id`, `description`, and the default parameter

```julia
CTBase.Strategies.id(::Type{<:Modelers.ADNLP}) = :adnlp

CTBase.Strategies.description(::Type{<:Modelers.ADNLP}) =
    "NLP modeler using ADNLPModels with automatic differentiation.\n" *
    "See: https://jso.dev/ADNLPModels.jl"

CTBase.Strategies.default_parameter(::Type{<:Modelers.ADNLP}) = CPU
CTBase.Strategies.parameter(::Type{<:Modelers.ADNLP{P}}) where {P<:CPU} = P
```

`default_parameter` is part of the parameterized-strategy contract: it tells the
unparameterized constructor `Modelers.ADNLP(...)` which parameter to use. `parameter`
declares the parameter type of the strategy.

### Step 3 — Declare `metadata` (stub in `src/`, real in `ext/`)

The metadata defines all configurable options with types, defaults, and validators. Since
the option definitions depend on the backend package, the method in `src/` is a stub that
throws `ExtensionError`; the real implementation lives in `ext/CTSolversADNLPModels.jl`
and requires `ADNLPModels` to be loaded:

```julia
# src/Modelers/adnlp.jl — stub
function CTBase.Strategies.metadata(::Type{<:Modelers.ADNLP{P}}) where {P<:CPU}
    throw(CTBase.Exceptions.ExtensionError(:ADNLPModels; ...))
end

# Fallback for the unparameterized type: delegate to the default parameter
function CTBase.Strategies.metadata(::Type{Modelers.ADNLP})
    return CTBase.Strategies.metadata(
        Modelers.ADNLP{CTBase.Strategies.default_parameter(Modelers.ADNLP)}
    )
end
```

### Step 4 — Constructors via Tag Dispatch

The constructor chain goes from the friendly keyword form down to a builder function
dispatched on the **tag and parameter types** (not instances). The builder is a stub in
`src/` and is overridden by the extension:

```julia
# Unparameterized constructor → resolve the default parameter
function Modelers.ADNLP(; mode::Symbol=:strict, kwargs...)
    P = CTBase.Strategies.default_parameter(Modelers.ADNLP)
    return Modelers.ADNLP{P}(; mode=mode, kwargs...)
end

# Parameterized constructor → tag dispatch, tag and parameter passed as TYPES
function Modelers.ADNLP{P}(; mode::Symbol=:strict, kwargs...) where {P<:CPU}
    return build_adnlp_modeler(ADNLPTag, P; mode=mode, kwargs...)
end

# Stub — throws until ADNLPModels is loaded; the extension provides the
# typed method build_adnlp_modeler(::Type{ADNLPTag}, ::Type{<:CPU}; ...)
function build_adnlp_modeler(
    ::Type{<:CTBase.Core.AbstractTag}, parameter::Type{<:AbstractStrategyParameter};
    kwargs...,
)
    throw(CTBase.Exceptions.ExtensionError(:ADNLPModels; ...))
end
```

Without the extension, constructing the modeler therefore raises `ExtensionError`:

```@repl modeler
try # hide
CTSolvers.Modelers.ADNLP()
catch e # hide
showerror(IOContext(stdout, :color => false), e) # hide
end # hide
```

With `using ADNLPModels`, the extension's `build_adnlp_modeler` validates the options
against the metadata and returns the configured instance:

```julia
# requires: using ADNLPModels
modeler = CTSolvers.Modelers.ADNLP(backend = :optimized)
CTBase.Strategies.options(modeler)
# → StrategyOptions with backend = :optimized (and all defaults, with provenance)
```

And that is all: the modeler is complete. It carries options — nothing else.

## The build_model / build_solution Contract

Model building is **not** the modeler's job. The `Optimization` module owns two generic
functions whose `NotImplemented` stubs — the modeler contract — live in
`src/Modelers/contract.jl`, typed on `AbstractNLPModeler`:

```julia
function Optimization.build_model(
    prob::Optimization.AbstractOptimizationProblem, initial_guess, modeler::AbstractNLPModeler
)
    throw(Exceptions.NotImplemented(
        "Model building not implemented";
        suggestion="Implement build_model for this (problem, modeler) pair in the package providing the problem",
        ...
    ))
end
```

The **package providing the problem** implements the typed methods by multiple dispatch
on the concrete `(problem, modeler)` pair. For example, CTDirect implements the pair
`(DiscretizedModel{<:Any,<:Collocation}, Modelers.ADNLP)` (simplified from
`CTDirect/src/collocation.jl`):

```julia
# In CTDirect — the problem package builds the NLP, using the modeler's options
function CTSolvers.build_model(
    dm::CTSolvers.DiscretizedModel{<:Any,<:Collocation},
    initial_guess::CTModels.AbstractInitialGuess,
    modeler::CTSolvers.Modelers.ADNLP,
)
    docp = dm.cache.docp

    # the modeler contributes its validated options
    options = CTBase.Strategies.options_dict(modeler)
    backend = pop!(options, :backend)

    # ... build objective, constraints, initial guess from docp ...
    nlp = ADNLPModels.ADNLPModel!(f, x0, ...; backend, options...)

    # bundle problem + NLP + build-time cache (ADNLP needs none)
    return CTSolvers.BuiltModel(dm, nlp, CTSolvers.NoCache())
end

function CTSolvers.build_solution(
    built::CTSolvers.BuiltModel{<:CTSolvers.DiscretizedModel{<:Any,<:Collocation}},
    nlp_solution::SolverCore.AbstractExecutionStats,
    ::CTSolvers.Modelers.ADNLP,
)
    docp = built.problem.cache.docp
    # ... build the OCP solution from the NLP solver output ...
end
```

`build_model` returns an [`CTSolvers.Optimization.BuiltModel`](@ref) — an immutable
bundle `(problem, nlp, cache)` — and `build_solution` dispatches on that bundle. See
[Implementing an Optimization Problem](@ref) for the problem-side view of this contract.

## Modelers.Exa: A Second Example

`Modelers.Exa` follows exactly the same pattern, with two differences.

**GPU support.** Exa accepts both execution parameters:

```julia
struct Exa{P<:Union{CPU,GPU}} <: AbstractNLPModeler
    options::CTBase.Strategies.StrategyOptions
end

CTBase.Strategies.id(::Type{<:Modelers.Exa}) = :exa
CTBase.Strategies.default_parameter(::Type{<:Modelers.Exa}) = CPU
CTBase.Strategies.parameter(::Type{<:Modelers.Exa{P}}) where {P<:Union{CPU,GPU}} = P

function Modelers.Exa{P}(; mode::Symbol=:strict, kwargs...) where {P<:AbstractStrategyParameter}
    return build_exa_modeler(ExaTag, P; mode=mode, kwargs...)
end
```

`Modelers.Exa{GPU}()` selects GPU-specific option defaults through the parameterized
`metadata(Modelers.Exa{GPU})` (requires the CUDA-related extensions).

**Build-time cache.** In CTDirect, building an `ExaModel` also produces a *getter*
needed later to extract the solution. It travels in the `cache` field of the
`BuiltModel` — immutable, no closure, no mutation:

```julia
# In CTDirect
function CTSolvers.build_model(
    dm::CTSolvers.DiscretizedModel{<:Any,<:Collocation},
    initial_guess::CTModels.AbstractInitialGuess,
    modeler::CTSolvers.Modelers.Exa,
)
    # ... build the ExaModel and its getter ...
    nlp, exa_getter = build_exa(; grid_size, backend, scheme, init, base_type)

    # carry the getter in an immutable build-time cache
    return CTSolvers.BuiltModel(dm, nlp, ExaBuildCache(exa_getter))
end

function CTSolvers.build_solution(
    built::CTSolvers.BuiltModel{<:CTSolvers.DiscretizedModel{<:Any,<:Collocation},<:Any,<:ExaBuildCache},
    nlp_solution::SolverCore.AbstractExecutionStats,
    ::CTSolvers.Modelers.Exa,
)
    exa_getter = built.cache.exa_getter   # read back from the bundle
    # ... build the OCP solution using the getter ...
end
```

!!! note "Who owns what"
    `ExaBuildCache` is defined in CTDirect, not CTSolvers — CTSolvers only requires
    `cache <: CTBase.Core.AbstractCache`. Backends that need no auxiliary data use
    [`CTSolvers.Optimization.NoCache`](@ref).

## Integration with the Pipeline

The high-level `CommonSolve.solve` pipeline (`src/Solvers/orchestration.jl`) composes the
two contracts without knowing anything about backends:

```text
User
 │
 ▼  solve(docp, x0, modeler, solver)          ← orchestration.jl
CommonSolve.solve
 │
 ├─► build_model(docp, x0, modeler)           →  BuiltModel
 │       (CTDirect provides the typed method for the (problem, modeler) pair)
 │
 ├─► CommonSolve.solve(built.nlp, solver)     →  ExecutionStats
 │       (backend extension provides the typed method, e.g. CTSolversIpopt)
 │
 └─► build_solution(built, stats, modeler)    →  OCP Solution
         (CTDirect provides the typed method for the (built, modeler) pair)
```

## Validation

Verify the strategy contract explicitly:

```julia
# id and description are always available
CTBase.Strategies.id(CTSolvers.Modelers.ADNLP)    # => :adnlp
CTBase.Strategies.id(CTSolvers.Modelers.Exa)      # => :exa

# metadata and construction require the backend extension
# requires: using ADNLPModels
CTBase.Strategies.metadata(CTSolvers.Modelers.ADNLP) isa CTBase.Strategies.StrategyMetadata  # => true
modeler = CTSolvers.Modelers.ADNLP()
CTBase.Strategies.options(modeler) isa CTBase.Strategies.StrategyOptions  # => true
```

For the modeler contract, test the dispatch with a fake problem (fake types at the
top level of the test module, never inside test functions):

```julia
struct FakeProblem <: CTSolvers.Optimization.AbstractOptimizationProblem end

function CTSolvers.Optimization.build_model(
    prob::FakeProblem, initial_guess, modeler::CTSolvers.Modelers.ADNLP
)
    nlp = build_fake_nlp(initial_guess; CTBase.Strategies.options_dict(modeler)...)
    return CTSolvers.Optimization.BuiltModel(prob, nlp, CTSolvers.Optimization.NoCache())
end

built = CTSolvers.Optimization.build_model(FakeProblem(), x0, modeler)
@test built isa CTSolvers.Optimization.BuiltModel
@test built.cache isa CTSolvers.Optimization.NoCache
```

Without a typed method, the stub fails loudly with `NotImplemented` and names the exact
method to implement.

## Summary: Adding a New Modeler

To add a new modeler (e.g., `MyModeler` for a new NLP backend):

1. Define the tag: `struct MyModelerTag <: CTBase.Core.AbstractTag end`
2. Define the parameterized struct: `MyModeler{P<:CPU} <: AbstractNLPModeler` with `options::CTBase.Strategies.StrategyOptions`
3. Implement `CTBase.Strategies.id(::Type{<:MyModeler}) = :my_backend` and `CTBase.Strategies.description`
4. Implement `CTBase.Strategies.default_parameter(::Type{<:MyModeler}) = CPU` and `CTBase.Strategies.parameter(::Type{<:MyModeler{P}}) where {P<:CPU} = P`
5. Declare the `metadata` stub in `src/` (throws `ExtensionError`); implement the real option definitions in the backend extension
6. Write the constructor chain: `MyModeler(; ...)` → `MyModeler{P}(; ...)` → `build_my_modeler(MyModelerTag, P; ...)`, with the builder stub in `src/` and the real builder in the extension
7. Implement `CTBase.Strategies.options(m::MyModeler) = m.options`
8. **Do not** implement any model building on the modeler — the packages providing problem types opt in by defining `Optimization.build_model(prob, init, ::MyModeler)` and `Optimization.build_solution(built, stats, ::MyModeler)` for their own problems
