# Architecture

```@meta
CurrentModule = CTSolvers
```

CTSolvers is the **resolution layer** of the [control-toolbox](https://github.com/control-toolbox) ecosystem. It transforms optimal control problems (defined in [CTModels.jl](https://github.com/control-toolbox/CTModels.jl)) into NLP models, solves them, and converts the results back into optimal control solutions.

This page provides the complete architectural overview. Read it before diving into any specific guide.

## Module Overview

CTSolvers relies on **CTBase** for its generic infrastructure and adds CTSolvers-specific modules:

### Generic infrastructure (provided by CTBase)

| Module | Responsibility |
|--------|---------------|
| `CTBase.Options` | Configuration primitives: `OptionDefinition`, `OptionValue`, extraction, validation |
| `CTBase.Strategies` | Strategy contract (`AbstractStrategy`), registry, metadata, options building |
| `CTBase.Orchestration` | Multi-strategy option routing and disambiguation |

### CTSolvers-specific modules, loaded in dependency order

| # | Module | Responsibility |
|---|--------|---------------|
| 1 | `Optimization` | Abstract optimization types (`AbstractOptimizationProblem`), builders, `build_model`/`build_solution` |
| 2 | `Modelers` | NLP model backends: `Modelers.ADNLP`, `Modelers.Exa` |
| 3 | `DOCP` | `DiscretizedModel` — bridges CTModels and CTSolvers |
| 4 | `Solvers` | Solver integration: `Solvers.Ipopt`, `Solvers.MadNLP`, `Solvers.MadNCL`, `Solvers.Knitro`, CommonSolve API |
| 5 | `Integrators` | ODE integration: `Integrators.SciML` — wraps the SciML stack |

All access is **qualified** — neither CTBase nor CTSolvers export symbols at the top level:

```julia
using CTSolvers
using CTBase

# Correct: qualified access
CTBase.Strategies.id(CTSolvers.Solvers.Ipopt)
CTBase.Options.OptionDefinition(name=:x, type=Int, default=1, description="...")

# Wrong: not exported
id(MyStrategy)  # ERROR: UndefVarError
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
│       ├─ (modeler)(prob, x0)    → NLP model
│       ├─ (modeler)(prob, stats) → Solution
│       ├─► Modelers.ADNLP
│       └─► Modelers.Exa
│
├─► AbstractNLPSolver
│       ├─ (solver)(nlp; display) → ExecutionStats
│       ├─► Solvers.Ipopt
│       ├─► Solvers.MadNLP
│       ├─► Solvers.MadNCL
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

### Optimization / Builder Branch

The optimization module defines the **problem–builder** pattern: problems provide builders, modelers use them.

```text
AbstractOptimizationProblem
├─ get_adnlp_model_builder(prob)     → AbstractModelBuilder
├─ get_exa_model_builder(prob)       → AbstractModelBuilder
├─ get_adnlp_solution_builder(prob)  → AbstractSolutionBuilder
├─ get_exa_solution_builder(prob)    → AbstractSolutionBuilder
└─► DiscretizedModel  (concrete implementation, in DOCP)

AbstractBuilder
├─► AbstractModelBuilder
│       ├─ (builder)(x0; kwargs...) → NLP
│       ├─► ADNLPModelBuilder
│       └─► ExaModelBuilder
└─► AbstractSolutionBuilder
        └─► AbstractOCPSolutionBuilder
                ├─► ADNLPSolutionBuilder
                └─► ExaSolutionBuilder
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
 ▼  solve(docp, x0, modeler, solver)
CommonSolve.solve
 │
 ├─► build_model(docp, x0, modeler)
 │       │
 │       ├─► get_adnlp_model_builder(docp)  →  ADNLPModelBuilder
 │       └─► builder(x0; options...)        →  ADNLPModel (NLP)
 │
 ├─► solve(nlp, solver)
 │       │
 │       └─► solver(nlp; display)           →  ExecutionStats
 │
 └─► build_solution(docp, stats, modeler)
         │
         ├─► get_adnlp_solution_builder(docp)  →  ADNLPSolutionBuilder
         └─► builder(stats)                    →  OCP Solution
```

The three levels of `CommonSolve.solve`:

| Level | Signature | Purpose |
|-------|-----------|---------|
| **High** | `solve(problem, x0, modeler, solver)` | Full pipeline: build NLP → solve → build solution |
| **Mid** | `solve(nlp, solver)` | Solve an NLP model directly |
| **Low** | `solve(any, solver)` | Flexible dispatch for custom types |

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

metadata(Solvers.MadNLP, CPU)  →  CPU defaults  →  MadNLP(CPU; max_iter=1000)
metadata(Solvers.MadNLP, GPU)  →  GPU defaults  →  MadNLP(GPU; max_iter=1000)
```

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
from backend implementations (in `ext/`):

```text
src/Solvers/ipopt.jl                    ext/CTSolversIpopt.jl
─────────────────────                   ─────────────────────
Solvers.Ipopt <: AbstractNLPSolver      metadata(::Type{<:Solvers.Ipopt})
IpoptTag      <: AbstractTag              → StrategyMetadata(option defs...)
                                        build_ipopt_solver(::IpoptTag; kwargs...)
Solvers.Ipopt(; kwargs...)                → Solvers.Ipopt(validated_opts)
  → build_ipopt_solver(IpoptTag(); …)   (solver::Solvers.Ipopt)(nlp; display)
                                          → ipopt(nlp; opts...)
build_ipopt_solver(::AbstractTag; …)
  → ExtensionError(:NLPModelsIpopt)
```

- **`src/Solvers/`**: defines the solver type, its id, and a constructor that dispatches on a tag.
- **`ext/CTSolversXxx/`**: implements metadata, the real constructor, and the callable.
  Loaded only when the backend package is available.
- This keeps CTSolvers lightweight — backend dependencies are optional weak deps.

### Qualified Access

CTSolvers does **not** export symbols at the top level. All access goes through qualified module paths:

```julia
CTBase.Strategies.id(CTSolvers.Solvers.Ipopt)
CTBase.Options.OptionDefinition(...)
CTSolvers.Optimization.build_model(problem, x0, modeler)
```

This ensures namespace clarity, avoids conflicts with other packages, and makes dependencies explicit.

## Conventions

### Naming

- **Types**: `PascalCase` — `StrategyOptions`, `ADNLPModelBuilder`
- **Modules**: `PascalCase` — `Options`, `Strategies`, `Orchestration`
- **Functions**: `snake_case` — `build_strategy_options`, `option_value`
- **Strategy IDs**: `snake_case` symbols — `:collocation`, `:adnlp`, `:ipopt`
- **Private defaults**: `__name()` pattern — `__grid_size()`, `__scheme()`

### Constructor Pattern

Every strategy constructor follows the same pattern:

```julia
function MyStrategy(; mode::Symbol = :strict, kwargs...)
    opts = CTBase.Strategies.build_strategy_options(MyStrategy; mode = mode, kwargs...)
    return MyStrategy(opts)
end
```

- `mode = :strict` (default): rejects unknown options with Levenshtein suggestions.
- `mode = :permissive`: accepts unknown options with a warning.

### OptionDefinition Pattern

Options are declared via `OptionDefinition` in the `metadata` method:

```julia
CTBase.Strategies.metadata(::Type{<:MyStrategy}) = CTBase.Strategies.StrategyMetadata(
    CTBase.Options.OptionDefinition(
        name = :max_iter,
        type = Int,
        default = 1000,
        description = "Maximum number of iterations",
    ),
    CTBase.Options.OptionDefinition(
        name = :tol,
        type = Float64,
        default = 1e-8,
        description = "Convergence tolerance",
        aliases = [:tolerance],
    ),
)
```

Each definition specifies: `name`, `type`, `default`, `description`, and optionally `aliases` and `validator`.
