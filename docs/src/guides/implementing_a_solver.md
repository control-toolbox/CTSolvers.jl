# Implementing a Solver

```@meta
CurrentModule = CTSolvers
```

This guide explains how to implement an optimization solver in CTSolvers. Solvers are strategies that wrap NLP backend libraries (Ipopt, MadNLP, Knitro, etc.) behind a unified interface. We use **Solvers.Ipopt** as the reference example throughout.

!!! tip "Prerequisites"
    Read [Architecture](@ref) first. A solver is a strategy (see Implementing a Strategy in CTBase.jl documentation) with two additional requirements: a **solve contract** and a **Tag Dispatch** extension.

## The AbstractNLPSolver Contract

A solver must satisfy **three contracts**:

1. **Strategy contract** — `id`, `metadata`, `options`, `parameter`, `default_parameter` (inherited from `AbstractStrategy`)
2. **Solve contract** — `CommonSolve.solve(nlp, solver; display) → ExecutionStats`
3. **Tag Dispatch** — separates type definition from backend implementation

Solvers are **parameterized** by an execution parameter `P <: AbstractStrategyParameter`
(see Strategy Parameters in CTBase.jl documentation). `Solvers.Ipopt{P<:CPU}` is CPU-only;
`Solvers.MadNLP` and `Solvers.MadNCL` accept `Union{CPU,GPU}`.

```text
AbstractStrategy
├─ id(::Type)       → Symbol
├─ metadata(::Type) → StrategyMetadata
└─ options(inst)    → StrategyOptions

AbstractNLPSolver <: AbstractStrategy
└─ CommonSolve.solve(nlp, solver; display) → ExecutionStats
   ├─► Solvers.Ipopt{P<:CPU}
   ├─► Solvers.MadNLP{P<:Union{CPU,GPU}}
   ├─► Solvers.MadNCL{P<:Union{CPU,GPU}}
   ├─► Solvers.Knitro
   └─► Solvers.Uno
```

The generic stub throws `NotImplemented` until a backend extension provides the typed method. Without the extension loaded, constructing a solver throws `ExtensionError`.

## Implementing the Solver Type

### Step 1 — Define the Tag

A **tag type** is a lightweight struct used for dispatch. It routes the constructor call to the right extension:

```julia
# In src/Solvers/ipopt.jl
struct IpoptTag <: AbstractTag end
```

### Step 2 — Define the parameterized struct

Like any strategy, the solver has a single `options` field. It is parameterized by its
execution parameter — Ipopt supports CPU only:

```julia
# In module Solvers (src/Solvers/ipopt.jl)
struct Ipopt{P<:CPU} <: AbstractNLPSolver
    options::CTBase.Strategies.StrategyOptions
end
```

### Step 3 — Implement `id` and the default parameter

The `id` is available even without the extension. `default_parameter` tells the
unparameterized constructor which parameter to use, and `parameter` declares the
parameter type of the strategy:

```@example solver
using CTSolvers
using CTBase
CTBase.Strategies.id(CTSolvers.Solvers.Ipopt)
```

```julia
CTBase.Strategies.default_parameter(::Type{<:Solvers.Ipopt}) = CPU
CTBase.Strategies.parameter(::Type{<:Solvers.Ipopt{P}}) where {P<:CPU} = P
```

### Step 4 — Constructors with Tag Dispatch

The unparameterized constructor resolves the default parameter, then delegates to the
parameterized one, which calls a `build_*` function dispatching on the **tag and parameter
types** (passed as types, not instances). The stub in `src/` throws an `ExtensionError`
until the extension is loaded:

```julia
# Unparameterized → resolve the default parameter
function Solvers.Ipopt(; mode::Symbol = :strict, kwargs...)
    P = CTBase.Strategies.default_parameter(Solvers.Ipopt)
    return Solvers.Ipopt{P}(; mode = mode, kwargs...)
end

# Parameterized → tag dispatch, IpoptTag and P passed as TYPES
function Solvers.Ipopt{P}(; mode::Symbol = :strict, kwargs...) where {P<:CPU}
    return build_ipopt_solver(IpoptTag, P; mode = mode, kwargs...)
end

# Stub — real implementation in ext/CTSolversIpopt.jl
function build_ipopt_solver(
    ::Type{<:Core.AbstractTag}, parameter::Type{<:AbstractStrategyParameter}; kwargs...
)
    throw(Exceptions.ExtensionError(
        :NLPModelsIpopt;
        message = "to create Solvers.Ipopt, access options, and solve problems",
        feature = "Solvers.Ipopt functionality",
        context = "Load NLPModelsIpopt extension first: using NLPModelsIpopt",
    ))
end
```

Live demonstration of the `ExtensionError` for all solvers:

```@repl solver
try # hide
CTSolvers.Solvers.MadNLP()
catch e # hide
showerror(IOContext(stdout, :color => false), e) # hide
end # hide
```

!!! note "Why Tag Dispatch?"
    The `metadata` (option definitions) and the solve method (backend call) both live in the extension. The tag type allows the constructor in `src/` to dispatch to the extension without a direct dependency on the backend package.

## The Tag Dispatch Pattern

**`src/Solvers/ipopt.jl`** — type definition and stubs, always loaded with CTSolvers:

```julia
struct IpoptTag <: Core.AbstractTag end

struct Ipopt{P<:CPU} <: AbstractNLPSolver
    options::CTBase.Strategies.StrategyOptions
end

CTBase.Strategies.id(::Type{<:Solvers.Ipopt}) = :ipopt
CTBase.Strategies.default_parameter(::Type{<:Solvers.Ipopt}) = CPU
CTBase.Strategies.parameter(::Type{<:Solvers.Ipopt{P}}) where {P<:CPU} = P

# Constructors — resolve the parameter, then dispatch via tag (types, not instances)
Solvers.Ipopt(; mode = :strict, kwargs...) =
    Solvers.Ipopt{CTBase.Strategies.default_parameter(Solvers.Ipopt)}(; mode, kwargs...)

Solvers.Ipopt{P}(; mode = :strict, kwargs...) where {P<:CPU} =
    build_ipopt_solver(IpoptTag, P; mode, kwargs...)

# Stub — throws until NLPModelsIpopt is loaded
build_ipopt_solver(::Type{<:Core.AbstractTag}, ::Type{<:AbstractStrategyParameter}; kwargs...) =
    throw(Exceptions.ExtensionError(:NLPModelsIpopt))
```

**`ext/CTSolversIpopt.jl`** — real implementations, loaded only with `using NLPModelsIpopt`:

```julia
# Option definitions (parameterized on P)
CTBase.Strategies.metadata(::Type{Solvers.Ipopt{P}}) where {P<:CPU} = StrategyMetadata(...)

# Real constructor — validates options for the parameterized type and builds the struct
build_ipopt_solver(::Type{Solvers.IpoptTag}, parameter::Type{<:AbstractStrategyParameter}; mode, kwargs...) =
    Solvers.Ipopt{parameter}(CTBase.Strategies.build_strategy_options(Solvers.Ipopt{parameter}; mode, kwargs...))

# Solve method — dispatches on NLP type and solver type
CommonSolve.solve(nlp::NLPModels.AbstractNLPModel, solver::Solvers.Ipopt; display = true) =
    solve_with_ipopt(nlp; options_dict(solver)...)
```

This keeps CTSolvers lightweight — `NLPModelsIpopt` is only loaded when the user does `using NLPModelsIpopt`.

### Parameterization `{P}`

The execution parameter `P` flows through the whole chain — constructor, `build_*`, and
`metadata` — so a single implementation covers every supported backend. A GPU-capable
solver simply widens the bound and provides GPU-specific defaults through the
parameterized metadata:

```julia
struct MadNLP{P<:Union{CPU,GPU}} <: AbstractNLPSolver
    options::CTBase.Strategies.StrategyOptions
end

# GPU-specific option defaults selected by the parameter
CTBase.Strategies.metadata(::Type{Solvers.MadNLP{GPU}}) = StrategyMetadata(...)  # CUDA defaults

Solvers.MadNLP{GPU}(max_iter = 1000)   # requires the CUDA-related extensions
```

See the Strategy Parameters guide in CTBase.jl documentation for the full parameter contract.

## Creating the Extension

### File structure

```text
ext/
└── CTSolversIpopt.jl    # Single-file extension module
```

### Project.toml declaration

```toml
[weakdeps]
NLPModelsIpopt = "f4238b75-b362-5c4c-b852-0801c9a21d71"

[extensions]
CTSolversIpopt = "NLPModelsIpopt"
```

### Extension implementation

The extension module provides three things:

**1. Metadata** — option definitions with types, defaults, validators (parameterized on `P`):

```julia
module CTSolversIpopt

using CTSolvers, CTSolvers.Solvers, CTBase.Strategies, CTBase.Options
using CTBase.Exceptions
using NLPModelsIpopt, NLPModels, SolverCore

function CTBase.Strategies.metadata(::Type{Solvers.Ipopt{P}}) where {P<:CPU}
    return CTBase.Strategies.StrategyMetadata(
        CTBase.Options.OptionDefinition(
            name = :tol,
            type = Real,
            default = 1e-8,
            description = "Desired convergence tolerance (relative)",
            validator = x -> x > 0 || throw(Exceptions.IncorrectArgument(...)),
        ),
        CTBase.Options.OptionDefinition(
            name = :max_iter,
            type = Integer,
            default = 1000,
            description = "Maximum number of iterations",
            aliases = (:maxiter,),
            validator = x -> x >= 0 || throw(Exceptions.IncorrectArgument(...)),
        ),
        # ... more options (print_level, linear_solver, mu_strategy, etc.)
    )
end
```

**2. Constructor** — builds validated options for the parameterized type and returns the solver:

```julia
function Solvers.build_ipopt_solver(
    ::Type{Solvers.IpoptTag},
    parameter::Type{<:AbstractStrategyParameter};
    mode::Symbol = :strict,
    kwargs...,
)
    opts = CTBase.Strategies.build_strategy_options(Solvers.Ipopt{parameter}; mode = mode, kwargs...)
    return Solvers.Ipopt{parameter}(opts)
end
```

**3. Solve method** — implements `CommonSolve.solve` dispatching on the NLP type and solver type:

```julia
function CommonSolve.solve(
    nlp::NLPModels.AbstractNLPModel,
    solver::Solvers.Ipopt;
    display::Bool = true,
)::SolverCore.GenericExecutionStats
    options = CTBase.Strategies.options_dict(solver)
    options[:print_level] = display ? options[:print_level] : 0
    return solve_with_ipopt(nlp; options...)
end

function solve_with_ipopt(nlp::NLPModels.AbstractNLPModel; kwargs...)
    ipopt_solver = NLPModelsIpopt.IpoptSolver(nlp)
    return NLPModelsIpopt.solve!(ipopt_solver, nlp; kwargs...)
end

end # module CTSolversIpopt
```

!!! info "Display handling"
    The `display` parameter controls solver output. When `display = false`, the solver sets `print_level = 0` to suppress all output. This is a convention shared by all CTSolvers solvers.

## CommonSolve Integration

CTSolvers provides a unified `CommonSolve.solve` interface at two levels:

```text
High-level:  solve(problem, x0, modeler, solver)          ← orchestration.jl
                │
                ├─► build_model(problem, x0, modeler)     → BuiltModel
                │
                ├─► CommonSolve.solve(built.nlp, solver)  → ExecutionStats
                │
                └─► build_solution(built, stats, modeler) → OCP Solution

Mid-level:   CommonSolve.solve(nlp, solver; display)      ← backend extension
                → ExecutionStats
```

### High-level: full pipeline

```julia
using CommonSolve

solution = solve(problem, x0, modeler, solver)
# Internally:
#   1. built = build_model(problem, x0, modeler)
#   2. stats = CommonSolve.solve(built.nlp, solver)
#   3. solution = build_solution(built, stats, modeler)
```

### Mid-level: NLP → Stats

```julia
using ADNLPModels, NLPModelsIpopt

nlp = ADNLPModel(x -> sum(x.^2), zeros(10))
solver = CTSolvers.Solvers.Ipopt(max_iter = 1000)
stats = CommonSolve.solve(nlp, solver; display = false)
```

## Summary: Adding a New Solver

To add a new solver (e.g., `MySolver` backed by `MyBackend`):

### In `src/Solvers/`

1. Define `MyTag <: Core.AbstractTag`
2. Define the parameterized struct `MySolver{P<:CPU} <: AbstractNLPSolver` with `options::CTBase.Strategies.StrategyOptions` (widen the bound to `Union{CPU,GPU}` for GPU-capable backends)
3. Implement `CTBase.Strategies.id(::Type{<:MySolver}) = :my_solver`, `CTBase.Strategies.default_parameter(::Type{<:MySolver}) = CPU`, and `CTBase.Strategies.parameter(::Type{<:MySolver{P}}) where {P<:CPU} = P`
4. Write the constructor chain: `MySolver(; ...)` → `MySolver{P}(; ...)` → `build_my_solver(MyTag, P; mode, kwargs...)`
5. Write stub: `build_my_solver(::Type{<:Core.AbstractTag}, ::Type{<:AbstractStrategyParameter}; kwargs...) = throw(ExtensionError(...))`

### In `ext/CTSolversMyBackend.jl`

6. Implement `CTBase.Strategies.metadata(::Type{MySolver{P}}) where {P<:CPU}` with all option definitions
7. Implement `Solvers.build_my_solver(::Type{Solvers.MyTag}, parameter::Type{<:AbstractStrategyParameter}; kwargs...)` — real constructor
8. Implement `CommonSolve.solve(nlp, solver::MySolver; display)` — solve method invoking the backend

### In `Project.toml`

9. Add `MyBackend` to `[weakdeps]` and `CTSolversMyBackend = "MyBackend"` to `[extensions]`

### Tests

10. **Contract test**: `CTBase.Strategies.id(MySolver)`, `CTBase.Strategies.metadata(MySolver)`, and `CTBase.Strategies.options(MySolver())` (requires extension loaded)
11. **Solve test**: `CommonSolve.solve(nlp, solver; display = false)` returns `AbstractExecutionStats`
12. **Extension error test**: without `using MyBackend`, `MySolver()` throws `ExtensionError`
