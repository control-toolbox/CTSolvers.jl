# Implementing an Optimization Problem

```@meta
CurrentModule = CTSolvers
```

This guide explains how to implement an optimization problem in CTSolvers. An optimization problem is a concrete subtype of `AbstractOptimizationProblem` that pairs problem data with a discretizer and a backend-opaque cache. We use **DiscretizedModel** (DOCP) as the reference implementation.

!!! tip "Prerequisites"
    Read [Architecture](@ref) and [Implementing a Modeler](@ref) first. The optimization problem is the data holder; the modeler and the package providing the problem (e.g. CTDirect) implement the NLP building logic.

## The AbstractOptimizationProblem Contract

`AbstractOptimizationProblem` is a marker abstract type with **no required methods of its own**. The contract is expressed through two generic functions that must be implemented by **multiple dispatch** in the package providing the concrete problem:

| Method | Signature | Returns | Implemented in |
|--------|-----------|---------|----------------|
| `build_model` | `(prob::MyProblem, init, modeler::ADNLP)` | `BuiltModel` | package providing `MyProblem` |
| `build_solution` | `(built::BuiltModel{<:MyProblem}, stats, modeler::ADNLP)` | domain solution | package providing `MyProblem` |

The generic stubs in CTSolvers throw `NotImplemented` with guidance. Defining a subtype without these methods is valid — the error only fires when the pipeline is actually invoked:

```@example optprob
using CTSolvers
struct EmptyProblem <: CTSolvers.Optimization.AbstractOptimizationProblem end
nothing # hide
```

## BuiltModel and NoCache

`build_model` does not return a raw NLP model. It returns a [`CTSolvers.Optimization.BuiltModel`](@ref) — an immutable bundle that carries everything `build_solution` needs:

```text
BuiltModel{TP <: AbstractOptimizationProblem, TN, TC <: AbstractCache}
├─ problem::TP   — the original problem (gives access to ocp, discretizer, cache)
├─ nlp::TN       — the backend NLP model (ADNLPModel, ExaModel, …)
└─ cache::TC     — immutable build-time auxiliary
```

[`CTSolvers.Optimization.NoCache`](@ref) is the default `cache` for backends that produce no auxiliary data:

```@example optprob
CTSolvers.Optimization.NoCache()
```

## Implementing DiscretizedModel

`DiscretizedModel` is the canonical `AbstractOptimizationProblem` implementation in CTSolvers.
It pairs an OCP with the discretizer that produced it and a backend-opaque cache:

### Step 1 — Define the struct

```julia
struct DiscretizedModel{
    TO <: CTModels.AbstractModel,
    TD <: AbstractDiscretizer,
    TC <: CTBase.Core.AbstractCache,
} <: AbstractOptimizationProblem
    ocp::TO          # original OCP
    discretizer::TD  # e.g. Collocation
    cache::TC        # opaque to CTSolvers; populated by the discretizing package
end
```

The accessor `ocp_model(docp)` returns the original OCP.

### Step 2 — Construct via `discretize` (in CTDirect)

`DiscretizedModel` is not constructed by calling the struct directly. CTSolvers owns a
generic `CTSolvers.discretize` stub (`src/DOCP/contract.jl`) that throws `NotImplemented`;
the package providing the discretizer implements the typed method. In CTDirect
(`src/collocation.jl`) it preprocesses the OCP into a `DOCP` and wraps it in a cache:

```julia
# In CTDirect — typed method for the Collocation discretizer
function CTSolvers.discretize(ocp::AbstractModel, discretizer::Collocation)
    docp = get_docp(discretizer, ocp)                        # problem-specific preprocessing
    return CTSolvers.DiscretizedModel(ocp, discretizer, DOCPCache(docp))
end
```

`DOCPCache` is a `CTBase.Core.AbstractCache` subtype defined in CTDirect — CTSolvers only
requires the `cache` field to be `<: CTBase.Core.AbstractCache`.

### Step 3 — Implement build_model / build_solution (in CTDirect)

CTSolvers owns the generic stubs; CTDirect owns the concrete methods via multiple dispatch:

```julia
# In CTDirect — concrete methods for (DiscretizedModel + Collocation, ADNLP)
function CTSolvers.build_model(
    dm::CTSolvers.DiscretizedModel{<:Any,<:Collocation},
    initial_guess::CTModels.AbstractInitialGuess,
    modeler::CTSolvers.Modelers.ADNLP,
)
    docp = dm.cache.docp
    options = Strategies.options_dict(modeler)         # the modeler's validated options
    nlp = build_adnlp_model(docp, initial_guess; options...)  # ADNLPModel
    return CTSolvers.BuiltModel(dm, nlp, CTSolvers.NoCache())  # ADNLP needs no aux cache
end

function CTSolvers.build_solution(
    built::CTSolvers.BuiltModel{<:CTSolvers.DiscretizedModel{<:Any,<:Collocation}},
    nlp_solution::SolverCore.AbstractExecutionStats,
    ::CTSolvers.Modelers.ADNLP,
)
    docp = built.problem.cache.docp
    return build_OCP_solution(docp, nlp_solution)      # OCP solution
end
```

## Integration with the Pipeline

The complete data flow from user call to solution:

```text
User
 │
 ▼  solve(docp, x0, modeler, solver)
CommonSolve.solve
 │
 ├─► build_model(docp, x0, modeler)
 │       │
 │       ├─► (CTDirect) build_adnlp_model(docp, x0)  →  ADNLPModel
 │       └─► BuiltModel(docp, nlp, NoCache())
 │
 ├─► solve(nlp, solver) → ExecutionStats
 │
 └─► build_solution(built, stats, modeler)
         └─► (CTDirect) extract_ocp_solution(docp, stats)  →  OCPSolution
```

Separation of responsibilities:

- **CTSolvers** declares `build_model`/`build_solution` and owns the `NotImplemented` stubs
- **CTDirect** provides the concrete methods dispatched on `(DiscretizedModel, ADNLP/Exa)`
- **CTSolvers** orchestrates the pipeline in `CommonSolve.solve` without knowing NLP internals

## Summary: Adding a New Optimization Problem

To add a new optimization problem type that plugs into the CTSolvers pipeline:

1. Define `MyProblem <: AbstractOptimizationProblem` with your data fields
2. Implement `CTSolvers.Optimization.build_model(prob::MyProblem, init, modeler::ADNLP)` returning a `BuiltModel`
3. Implement `CTSolvers.Optimization.build_solution(built::BuiltModel{<:MyProblem}, stats, modeler::ADNLP)` returning your domain solution
4. Optionally add methods for other modelers (`Exa`, future backends) following the same dispatch pattern
5. If `build_model` produces auxiliary data needed by `build_solution`, store it in a custom `<: CTBase.Core.AbstractCache` subtype rather than `NoCache`
