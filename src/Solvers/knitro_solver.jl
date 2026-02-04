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

## Termination Options

- `maxit::Integer`: Maximum number of iterations (default: 1000, must be ≥ 0)
  - Algorithm terminates if this number of iterations is exceeded
  - Aliases: max_iter, maxiter
- `maxtime::Real`: Maximum allowable real time in seconds (default: 1e8, must be > 0)
  - Real time limit for optimization process
- `maxfevals::Integer`: Maximum function evaluations (default: -1, must be ≥ -1)
  - -1: Unlimited evaluations
  - Positive integer: Evaluation limit
- `feastol_abs::Real`: Absolute feasibility tolerance (default: 1e-8, must be > 0)
  - Absolute tolerance on constraint violation for successful termination
- `opttol_abs::Real`: Absolute optimality tolerance (default: 1e-8, must be > 0)
  - Absolute tolerance on KKT optimality conditions for successful termination
- `ftol::Real`: Relative change tolerance for objective function (default: 1e-12, must be > 0)
  - Terminates if relative change in objective is less than this tolerance
- `xtol::Real`: Relative change tolerance for solution point (default: 1e-12, must be > 0)
  - Terminates if relative change in solution estimate is less than this tolerance

## Algorithm Options

- `soltype::Integer`: Solution type returned (default: 0, must be 0 or 1)
  - 0: Return final solution converged to
  - 1: Return best feasible solution encountered during optimization

## Output Options

- `outlev::Integer`: Controls the level of output produced by Knitro (default: 2, must be ≥ 0)
  - 0: No output (all printing suppressed)
  - 1: Summary information only
  - 2: Basic information every 10 iterations
  - 3: Basic information at each iteration (standard)
  - 4: Basic information and function count at each iteration
  - 5: All above plus solution vector values
  - 6: All above plus constraint values and Lagrange multipliers
  - Alias: print_level

# Examples

```julia
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
        # ====================================================================
        # TERMINATION OPTIONS
        # ====================================================================
        
        Strategies.OptionDefinition(;
            name=:maxit,
            type=Integer,
            default=1000,
            description="Maximum number of iterations before termination",
            aliases=(:max_iter, :maxiter),
            validator=x -> x >= 0 || throw(Exceptions.IncorrectArgument(
                "Invalid maxit value",
                got="maxit=$x",
                expected="non-negative integer (>= 0)",
                suggestion="Provide a non-negative value for maximum iterations",
                context="KnitroSolver maxit validation"
            ))
        ),
        
        Strategies.OptionDefinition(;
            name=:maxtime,
            type=Real,
            default=1e8,
            description="Maximum allowable real time in seconds before termination",
            validator=x -> x > 0 || throw(Exceptions.IncorrectArgument(
                "Invalid maxtime value",
                got="maxtime=$x",
                expected="positive real number (> 0)",
                suggestion="Provide a positive time limit in seconds (e.g., 3600 for 1 hour)",
                context="KnitroSolver maxtime validation"
            ))
        ),
        
        Strategies.OptionDefinition(;
            name=:maxfevals,
            type=Integer,
            default=-1,
            description="Maximum number of function evaluations before termination (-1 for unlimited)",
            validator=x -> x >= -1 || throw(Exceptions.IncorrectArgument(
                "Invalid maxfevals value",
                got="maxfevals=$x",
                expected="integer >= -1 (-1 for unlimited)",
                suggestion="Use -1 for unlimited or positive integer for limit",
                context="KnitroSolver maxfevals validation"
            ))
        ),
        
        Strategies.OptionDefinition(;
            name=:feastol_abs,
            type=Real,
            default=1e-8,
            description="Absolute feasibility tolerance for successful termination",
            validator=x -> x > 0 || throw(Exceptions.IncorrectArgument(
                "Invalid feastol_abs value",
                got="feastol_abs=$x",
                expected="positive real number (> 0)",
                suggestion="Use 1e-8 for standard tolerance or smaller for stricter feasibility",
                context="KnitroSolver feastol_abs validation"
            ))
        ),
        
        Strategies.OptionDefinition(;
            name=:opttol_abs,
            type=Real,
            default=1e-8,
            description="Absolute optimality tolerance for KKT error",
            validator=x -> x > 0 || throw(Exceptions.IncorrectArgument(
                "Invalid opttol_abs value",
                got="opttol_abs=$x",
                expected="positive real number (> 0)",
                suggestion="Use 1e-8 for standard tolerance or smaller for stricter optimality",
                context="KnitroSolver opttol_abs validation"
            ))
        ),
        
        Strategies.OptionDefinition(;
            name=:ftol,
            type=Real,
            default=1e-12,
            description="Relative change tolerance for objective function",
            validator=x -> x > 0 || throw(Exceptions.IncorrectArgument(
                "Invalid ftol value",
                got="ftol=$x",
                expected="positive real number (> 0)",
                suggestion="Use 1e-12 for standard tolerance or smaller for stricter convergence",
                context="KnitroSolver ftol validation"
            ))
        ),
        
        Strategies.OptionDefinition(;
            name=:xtol,
            type=Real,
            default=1e-12,
            description="Relative change tolerance for solution point estimate",
            validator=x -> x > 0 || throw(Exceptions.IncorrectArgument(
                "Invalid xtol value",
                got="xtol=$x",
                expected="positive real number (> 0)",
                suggestion="Use 1e-12 for standard tolerance or smaller for stricter convergence",
                context="KnitroSolver xtol validation"
            ))
        ),
        
        # ====================================================================
        # ALGORITHM OPTIONS
        # ====================================================================
        
        Strategies.OptionDefinition(;
            name=:soltype,
            type=Integer,
            default=0,
            description="Solution type returned by Knitro (0=final, 1=bestfeas)",
            validator=x -> x in [0, 1] || throw(Exceptions.IncorrectArgument(
                "Invalid soltype value",
                got="soltype=$x",
                expected="0 (final) or 1 (bestfeas)",
                suggestion="Use 0 for final solution or 1 for best feasible encountered",
                context="KnitroSolver soltype validation"
            ))
        ),
        
        # ====================================================================
        # OUTPUT OPTIONS
        # ====================================================================
        
        Strategies.OptionDefinition(;
            name=:outlev,
            type=Integer,
            default=2,
            description="Controls the level of output produced by Knitro",
            aliases=(:print_level, ),
            validator=x -> (0 <= x <= 6) || throw(Exceptions.IncorrectArgument(
                "Invalid outlev value",
                got="outlev=$x",
                expected="integer between 0 and 6",
                suggestion="Use 0 for no output, 2 for every 10 iterations, 3 for each iteration, or higher for more details",
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
