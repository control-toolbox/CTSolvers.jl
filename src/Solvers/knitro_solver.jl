# ============================================================================
# Tag Dispatch Infrastructure
# ============================================================================

"""
    KnitroTag <: AbstractTag

Tag type for Knitro-specific implementation dispatch.
"""
struct KnitroTag <: AbstractTag end

# ============================================================================
# Solver Type Definition
# ============================================================================

"""
    KnitroSolver

$(TYPEDEF)

Commercial optimization solver with advanced algorithms.

Knitro is a commercial solver offering state-of-the-art algorithms for
nonlinear optimization, including interior point, active set, and SQP methods.
It provides excellent performance and robustness for large-scale problems.

# Fields

$(TYPEDFIELDS)

# Solver Options

Solver options are defined in the CTSolversKnitro extension.
Load the extension to access option definitions and documentation:
```julia
using NLPModelsKnitro
```

# Examples

```julia
# Load the extension first
using NLPModelsKnitro

# Create solver with default options
solver = KnitroSolver()

# Create solver with custom options
solver = KnitroSolver(maxit=1000, maxtime=3600, ftol=1e-10, outlev=2)

# Solve an NLP problem
using ADNLPModels
nlp = ADNLPModel(x -> sum(x.^2), zeros(10))
stats = solver(nlp, display=true)
```

# Extension Required

This solver requires the `NLPModelsKnitro` package:
```julia
using NLPModelsKnitro
```

**Note:** Knitro is a commercial solver requiring a valid license.

# Implementation Notes

- Implements the `AbstractStrategy` contract via `Strategies.id()`
- Metadata and constructor implementation provided by CTSolversKnitro extension
- Options are validated at construction time using enriched `Exceptions.IncorrectArgument`
- Callable interface: `(solver::KnitroSolver)(nlp; display=true)` provided by extension
- Requires valid Knitro license for operation

See also: [`AbstractOptimizationSolver`](@ref), [`IpoptSolver`](@ref), [`MadNLPSolver`](@ref)
"""
struct KnitroSolver <: AbstractOptimizationSolver
    "Solver configuration options containing validated option values"
    options::Strategies.StrategyOptions
end

# ============================================================================
# AbstractStrategy Contract Implementation
# ============================================================================

"""
    Strategies.id(::Type{<:KnitroSolver})

Return the unique identifier for KnitroSolver.
"""
Strategies.id(::Type{<:KnitroSolver}) = :knitro

# ============================================================================
# Constructor with Tag Dispatch
# ============================================================================

"""
    KnitroSolver(; kwargs...)

Create a KnitroSolver with specified options.

Requires the CTSolversKnitro extension to be loaded.

# Arguments
- `kwargs...`: Solver options (see extension documentation for available options)

# Example
```julia
using NLPModelsKnitro
solver = KnitroSolver(maxit=1000, outlev=2)
```
"""
function KnitroSolver(; kwargs...)
    return build_knitro_solver(KnitroTag(); kwargs...)
end

"""
    build_knitro_solver(::AbstractTag; kwargs...)

Stub function that throws ExtensionError if CTSolversKnitro extension is not loaded.
Real implementation provided by the extension.
"""
function build_knitro_solver(::AbstractTag; kwargs...)
    throw(Exceptions.ExtensionError(
        :NLPModelsKnitro;
        message="to create KnitroSolver, access options, and solve problems",
        feature="KnitroSolver functionality",
        context="Load NLPModelsKnitro extension first: using NLPModelsKnitro"
    ))
end
