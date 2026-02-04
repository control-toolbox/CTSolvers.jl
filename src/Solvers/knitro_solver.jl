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

- `max_iter::Integer`: Maximum number of iterations (default: 3000, must be ≥ 0)
- `tol::Real`: Convergence tolerance (default: 1e-8, must be > 0)
- `outlev::Integer`: Output verbosity level (default: 3, must be ≥ 0)
  - 0: No output
  - 3: Standard output
  - Higher values: More detailed output

# Examples

```julia
# Create solver with default options
solver = KnitroSolver()

# Create solver with custom options
solver = KnitroSolver(max_iter=1000, tol=1e-6, outlev=2)

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

- Implements the `AbstractStrategy` contract via `Strategies.id`, `Strategies.metadata`, and `Strategies.options`
- Options are validated at construction time using enriched `Exceptions.IncorrectArgument`
- Callable interface: `(solver::KnitroSolver)(nlp; display=true)`
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

"""
    Strategies.metadata(::Type{<:KnitroSolver})

Return metadata defining KnitroSolver options and their specifications.
"""
function Strategies.metadata(::Type{<:KnitroSolver})
    return Strategies.StrategyMetadata(
        Strategies.OptionDefinition(;
            name=:max_iter,
            type=Integer,
            default=3000,
            description="Maximum number of iterations",
            aliases=(:max, :maxiter),
            validator=x -> x >= 0 || throw(Exceptions.IncorrectArgument(
                "Invalid max_iter value",
                got="max_iter=$x",
                expected="non-negative integer (>= 0)",
                suggestion="Provide a non-negative value for maximum iterations",
                context="KnitroSolver max_iter validation"
            ))
        ),
        Strategies.OptionDefinition(;
            name=:tol,
            type=Real,
            default=1e-8,
            description="Convergence tolerance",
            validator=x -> x > 0 || throw(Exceptions.IncorrectArgument(
                "Invalid tolerance value",
                got="tol=$x",
                expected="positive real number (> 0)",
                suggestion="Provide a positive tolerance value (e.g., 1e-6, 1e-8)",
                context="KnitroSolver tol validation"
            ))
        ),
        Strategies.OptionDefinition(;
            name=:outlev,
            type=Integer,
            default=3,
            description="Knitro output verbosity level",
            validator=x -> x >= 0 || throw(Exceptions.IncorrectArgument(
                "Invalid outlev value",
                got="outlev=$x",
                expected="non-negative integer (>= 0)",
                suggestion="Use 0 for no output, 3 for standard output, or higher for more verbosity",
                context="KnitroSolver outlev validation"
            ))
        )
    )
end

# ============================================================================
# Constructor
# ============================================================================

"""
    KnitroSolver(; kwargs...)

Create a KnitroSolver with specified options.

# Arguments
- `kwargs...`: Solver options (see KnitroSolver documentation for available options)

# Example
```julia
solver = KnitroSolver(max_iter=1000, tol=1e-6)
```
"""
function KnitroSolver(; kwargs...)
    opts = Strategies.build_strategy_options(KnitroSolver; kwargs...)
    return KnitroSolver(opts)
end

# ============================================================================
# Callable Interface
# ============================================================================

"""
    (solver::KnitroSolver)(nlp; display=true)

Solve an NLP problem using Knitro.

# Arguments
- `nlp::NLPModels.AbstractNLPModel`: The NLP problem to solve
- `display::Bool`: Whether to show solver output (default: true)

# Returns
- `SolverCore.GenericExecutionStats`: Solver execution statistics

# Example
```julia
solver = KnitroSolver(max_iter=100)
nlp = ADNLPModel(x -> sum(x.^2), zeros(5))
stats = solver(nlp, display=false)
```
"""
function (solver::KnitroSolver)(
    nlp::NLPModels.AbstractNLPModel;
    display::Bool=true
)::SolverCore.AbstractExecutionStats
    opts = Strategies.options(solver)
    
    # Extract raw options as Dict
    raw_opts = Options.extract_raw_options(opts.options)
    
    # Adjust outlev based on display flag
    raw_opts[:outlev] = display ? raw_opts[:outlev] : 0
    
    # Call backend interface (stub or extension implementation)
    return solve_with_knitro(nlp; raw_opts...)
end

# ============================================================================
# Extension Stub
# ============================================================================

"""
    solve_with_knitro(nlp; kwargs...)

Backend interface for Knitro solver.

This is a stub that throws an ExtensionError if the NLPModelsKnitro extension
is not loaded. Load the extension with:
```julia
using NLPModelsKnitro
```

# Arguments
- `nlp::NLPModels.AbstractNLPModel`: The NLP problem to solve
- `kwargs...`: Solver options to pass to Knitro

# Returns
- `SolverCore.GenericExecutionStats`: Solver execution statistics
"""
function solve_with_knitro(nlp::NLPModels.AbstractNLPModel; kwargs...)
    throw(Exceptions.ExtensionError(
        :NLPModelsKnitro,
        suggestion="Install and load NLPModelsKnitro: `using Pkg; Pkg.add(\"NLPModelsKnitro\"); using NLPModelsKnitro`",
        context="KnitroSolver requires the NLPModelsKnitro extension to solve NLP problems. Knitro is a commercial solver with advanced algorithms for nonlinear optimization."
    ))
end
