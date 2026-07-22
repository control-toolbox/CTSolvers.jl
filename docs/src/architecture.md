# Architecture

```@meta
CurrentModule = CTSolvers
```

CTSolvers provides the **resolution infrastructure** of the [control-toolbox](https://github.com/control-toolbox) ecosystem — solvers, modelers, integrators, and abstract problem types — consumed by [CTDirect.jl](https://github.com/control-toolbox/CTDirect.jl) (direct methods) and [CTFlows.jl](https://github.com/control-toolbox/CTFlows.jl) (flows for indirect methods).

This page provides the complete architectural overview. Read it before diving into any specific guide.

## Module Overview

CTSolvers modules, loaded in dependency order:

| # | Module | Responsibility |
|---|--------|---------------|
| 1 | `Optimization` | Abstract problem types (`AbstractOptimizationProblem`), `BuiltModel`/`NoCache`, `build_model`/`build_solution` |
| 2 | `Modelers` | NLP backend adapters: `Modelers.ADNLP`, `Modelers.Exa` |
| 3 | `DOCP` | `DiscretizedModel` — pairs an OCP with its discretizer (provided by CTDirect) |
| 4 | `Solvers` | NLP solver wrappers: `Solvers.Ipopt`, `Solvers.MadNLP`, `Solvers.MadNCL`, `Solvers.Knitro`, `Solvers.Uno` |
| 5 | `Integrators` | ODE integrator wrapper: `Integrators.SciML` |

CTSolvers relies on **CTBase** for its generic infrastructure (`CTBase.Options`, `CTBase.Strategies`, `CTBase.Orchestration`). See the [CTBase documentation](https://control-toolbox.org/CTBase.jl/dev/) for details on the strategy contract, option system, and orchestration.

All access is **qualified** — CTSolvers does not export symbols at the top level:

```julia
using CTSolvers

CTSolvers.Solvers.Ipopt(max_iter = 1000)           # ✓ qualified
CTBase.Strategies.id(CTSolvers.Solvers.Ipopt)      # ✓ qualified
CTSolvers.Optimization.build_model(docp, x0, m)    # ✓ qualified

id(CTSolvers.Solvers.Ipopt)   # ERROR: UndefVarError — not exported
```

## Type Hierarchies

### Strategy Branch

All configurable components (modelers, solvers, integrators) in CTSolvers are **strategies**.
They share a common contract defined by `AbstractStrategy`:

```text
AbstractStrategy
├─ id(::Type)       → Symbol
├─ metadata(::Type) → StrategyMetadata
├─ options(inst)    → StrategyOptions
│
├─► AbstractNLPModeler
│       ├─ build_model(prob, x0, modeler)           → BuiltModel
│       ├─ build_solution(built, stats, modeler)    → OCP Solution
│       ├─► Modelers.ADNLP{P<:CPU}
│       └─► Modelers.Exa{P<:Union{CPU,GPU}}
│
├─► AbstractNLPSolver
│       ├─ solve(nlp, solver; display) → ExecutionStats
│       ├─► Solvers.Ipopt{P<:CPU}
│       ├─► Solvers.MadNLP{P<:Union{CPU,GPU}}
│       ├─► Solvers.MadNCL{P<:Union{CPU,GPU}}
│       ├─► Solvers.Knitro
│       └─► Solvers.Uno
│
└─► AbstractIntegrator
        ├─ solve(prob, integ) → AbstractIntegrationResult
        └─► AbstractSciMLIntegrator
                └─► Integrators.SciML
```

!!! note "External Strategy Families"
    Other packages in the control-toolbox ecosystem define additional strategy families:
    **`AbstractDiscretizer`** (in [CTDirect.jl](https://github.com/control-toolbox/CTDirect.jl))
    discretizes continuous-time OCP into finite-dimensional problems (e.g., `Collocation`, `DirectShooting`).
    These external strategies follow the same `AbstractStrategy` contract.
    See the Implementing a Strategy guide in CTBase.jl documentation for a complete tutorial.

### Optimization Branch

`AbstractOptimizationProblem` is a **marker type** with no required methods. The
`build_model` / `build_solution` contract is satisfied by multiple dispatch: external
packages (e.g. CTDirect) implement the typed methods for their own problem types.

```text
AbstractOptimizationProblem                 (marker — no interface methods)
└─► DiscretizedModel  (in DOCP module, concrete implementation from CTDirect)

build_model(prob, x0, modeler)    → BuiltModel   (generic stub; CTDirect provides typed methods)
build_solution(built, stats, modeler) → Solution  (generic stub; CTDirect provides typed methods)

BuiltModel{TP, TN, TC}                      (problem + NLP + cache, immutable)
├─ .problem  → TP <: AbstractOptimizationProblem
├─ .nlp      → TN  (backend NLP model, e.g. ADNLPModel)
└─ .cache    → TC <: AbstractCache
       └─► NoCache  (for backends needing no auxiliary storage)
```

## Module Dependencies

The loading order is strict and acyclic:

```text
CTBase: Options → Strategies → Orchestration
                                    │
                         ┌──────────┴──────────┐
                         ▼                     ▼
                    Optimization           Integrators
                         │
               ┌─────────┼─────────┐
               ▼         ▼         ▼
           Modelers     DOCP     Solvers
```

Each module only depends on modules loaded before it. This strict ordering ensures
no circular dependencies and makes extensions straightforward to reason about.

## Data Flow

The complete resolution pipeline, from user call to optimal control solution:

```text
User
 │
 ▼  solve(docp, x0, modeler, solver)          ← orchestration.jl
CommonSolve.solve
 │
 ├─► build_model(docp, x0, modeler)           →  BuiltModel
 │       (CTDirect provides typed method for DiscretizedModel + modeler pair)
 │
 ├─► CommonSolve.solve(built.nlp, solver)     →  ExecutionStats
 │       (backend extension provides typed method, e.g. CTSolversIpopt)
 │
 └─► build_solution(built, stats, modeler)    →  OCP Solution
         (CTDirect provides typed method for DiscretizedModel + modeler pair)
```

The three levels of `CommonSolve.solve`:

| Level | Signature | Purpose |
|-------|-----------|---------|
| **High** | `solve(problem, x0, modeler, solver)` | Full pipeline: build NLP → solve → build solution |
| **Mid** | `CommonSolve.solve(nlp, solver; display)` | Solve an NLP directly; implemented by each backend extension |

## Architectural Patterns

### Two-Level Contract

Every strategy implements a **two-level contract** separating static metadata from dynamic configuration:

```text
Type-Level (static, called on the type itself)
├─ id(::Type{MyStrategy})       → :my_strategy  (unique symbol identifier)
└─ metadata(::Type{MyStrategy}) → StrategyMetadata (option definitions, defaults)
        │
        ▼  used for: introspection, routing, validation before construction
Constructor
        │
        ▼
Instance-Level (dynamic, called on a constructed instance)
└─ options(strategy)            → StrategyOptions (actual values with provenance)
        │
        ▼  used for: backend call, options_dict extraction
Execution
```

- **Type-level methods** (`id`, `metadata`) are called on the **type** — they enable
  introspection, routing, and validation without creating objects.
- **Instance-level methods** (`options`) are called on **instances** — they provide
  the actual configuration with provenance tracking.

See the Implementing a Strategy guide in CTBase.jl documentation for a step-by-step tutorial.

### Strategy Parameters (Overview)

Strategies can be **parameterized** to specialize behavior based on execution context
(e.g., CPU vs GPU). Parameters are singleton types enabling compile-time dispatch:

```text
AbstractStrategyParameter
├─► CPU  (singleton type)
└─► GPU  (singleton type)

metadata(Solvers.MadNLP{CPU})  →  CPU defaults  →  Solvers.MadNLP{CPU}(max_iter=1000)
metadata(Solvers.MadNLP{GPU})  →  GPU defaults  →  Solvers.MadNLP{GPU}(max_iter=1000)
```

The parameter is a **type parameter** of the strategy (`Solvers.MadNLP{P}`), not a separate
argument. `Solvers.MadNLP(...)` resolves `P` from `default_parameter` (here `CPU`).

See the Strategy Parameters guide in CTBase.jl documentation for a complete guide.

### NotImplemented Pattern

All contract methods have default implementations that throw `NotImplemented` with helpful error messages:

```julia
# If you forget to implement `id` for your strategy:
julia> CTBase.Strategies.id(IncompleteStrategy)
# ERROR: NotImplemented
#   Strategy ID method not implemented
#   Required method: id(::Type{<:IncompleteStrategy})
#   Suggestion: Implement id(::Type{<:IncompleteStrategy}) to return a unique Symbol identifier
```

This pattern ensures that missing implementations are detected immediately with clear guidance —
no silent failures or incorrect defaults.

### Tag Dispatch

Solvers (and integrators) use **Tag Dispatch** to separate type definitions (in `src/Solvers/`)
from backend implementations (in `ext/`).

**`src/Solvers/ipopt.jl`** — type definition and stubs (always loaded):

```julia
struct Ipopt{P<:CPU} <: AbstractNLPSolver
    options::StrategyOptions
end
struct IpoptTag <: Core.AbstractTag end

CTBase.Strategies.id(::Type{<:Solvers.Ipopt}) = :ipopt
CTBase.Strategies.default_parameter(::Type{<:Solvers.Ipopt}) = CPU
CTBase.Strategies.parameter(::Type{<:Solvers.Ipopt{P}}) where {P<:CPU} = P

# Constructor chain: resolve P, then dispatch on the tag and parameter TYPES
Solvers.Ipopt(; kwargs...) =
    Solvers.Ipopt{CTBase.Strategies.default_parameter(Solvers.Ipopt)}(; kwargs...)
Solvers.Ipopt{P}(; kwargs...) where {P<:CPU} = _build_ipopt_solver(IpoptTag, P; kwargs...)
_build_ipopt_solver(::Type{<:Core.AbstractTag}, ::Type{<:AbstractStrategyParameter}; kwargs...) =
    throw(ExtensionError(:NLPModelsIpopt))
```

**`ext/CTSolversIpopt.jl`** — real implementations (loaded only with `using NLPModelsIpopt`):

```julia
metadata(::Type{Solvers.Ipopt{P}}) where {P<:CPU} = StrategyMetadata(...)
_build_ipopt_solver(::Type{Solvers.IpoptTag}, P::Type{<:AbstractStrategyParameter}; kwargs...) =
    Solvers.Ipopt{P}(validated_opts)
CommonSolve.solve(nlp, solver::Solvers.Ipopt; display) = ipopt(nlp; options_dict(solver)...)
```

This keeps CTSolvers lightweight — backend dependencies are optional weak deps loaded on demand.

### Qualified Access

CTSolvers does **not** export symbols at the top level. All access goes through qualified module paths:

```julia
CTBase.Strategies.id(CTSolvers.Solvers.Ipopt)
CTSolvers.Optimization.build_model(problem, x0, modeler)
```

This ensures namespace clarity, avoids conflicts with other packages, and makes dependencies explicit.
