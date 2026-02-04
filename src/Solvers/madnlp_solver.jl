"""
    MadNLPSolver

$(TYPEDEF)

Pure-Julia interior point solver with GPU support.

MadNLP is a modern implementation of an interior point method written entirely in Julia,
with support for GPU acceleration and various linear solver backends. It provides excellent
performance for large-scale optimization problems.

# Fields

$(TYPEDFIELDS)

# Solver Options

- `max_iter::Integer`: Maximum number of iterations (default: 3000, must be ≥ 0)
- `tol::Real`: Convergence tolerance (default: 1e-8, must be > 0)
- `print_level::String`: MadNLP log level (default: "MadNLP.INFO")
  - "MadNLP.DEBUG": Detailed debugging output
  - "MadNLP.INFO": Standard informational output
  - "MadNLP.WARN": Warning messages only
  - "MadNLP.ERROR": Error messages only
- `linear_solver::String`: Linear solver backend (default: "MadNLPMumps.MumpsSolver")

# Examples

```julia
# Create solver with default options
solver = MadNLPSolver()

# Create solver with custom options
solver = MadNLPSolver(max_iter=1000, tol=1e-6, print_level="MadNLP.DEBUG")

# Solve an NLP problem
using ADNLPModels
nlp = ADNLPModel(x -> sum(x.^2), zeros(10))
stats = solver(nlp, display=true)
```

# Extension Required

This solver requires the `MadNLP` and `MadNLPMumps` packages:
```julia
using MadNLP, MadNLPMumps
```

# Implementation Notes

- Implements the `AbstractStrategy` contract via `Strategies.id`, `Strategies.metadata`, and `Strategies.options`
- Options are validated at construction time using enriched `Exceptions.IncorrectArgument`
- Callable interface: `(solver::MadNLPSolver)(nlp; display=true)`
- Supports GPU acceleration when appropriate backends are loaded

See also: [`AbstractOptimizationSolver`](@ref), [`IpoptSolver`](@ref), [`MadNCLSolver`](@ref)
"""
struct MadNLPSolver <: AbstractOptimizationSolver
    "Solver configuration options containing validated option values"
    options::Strategies.StrategyOptions
end

# ============================================================================
# AbstractStrategy Contract Implementation
# ============================================================================

"""
    Strategies.id(::Type{<:MadNLPSolver})

Return the unique identifier for MadNLPSolver.
"""
Strategies.id(::Type{<:MadNLPSolver}) = :madnlp

"""
    Strategies.metadata(::Type{<:MadNLPSolver})

Return metadata defining MadNLPSolver options and their specifications.
"""
function Strategies.metadata(::Type{<:MadNLPSolver})
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
                context="MadNLPSolver max_iter validation"
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
                context="MadNLPSolver tol validation"
            ))
        ),
        Strategies.OptionDefinition(;
            name=:print_level,
            type=String,
            default="MadNLP.INFO",
            description="MadNLP output verbosity level",
            validator=x -> x in ["MadNLP.DEBUG", "MadNLP.INFO", "MadNLP.WARN", "MadNLP.ERROR"] || 
                          throw(Exceptions.IncorrectArgument(
                "Invalid print_level value",
                got="print_level='$x'",
                expected="'MadNLP.DEBUG', 'MadNLP.INFO', 'MadNLP.WARN', or 'MadNLP.ERROR'",
                suggestion="Use 'MadNLP.INFO' for standard output or 'MadNLP.DEBUG' for detailed logging",
                context="MadNLPSolver print_level validation"
            ))
        ),
        Strategies.OptionDefinition(;
            name=:linear_solver,
            type=String,
            default="MadNLPMumps.MumpsSolver",
            description="Linear solver type for MadNLP"
        )
    )
end

# ============================================================================
# Constructor
# ============================================================================

"""
    MadNLPSolver(; kwargs...)

Create a MadNLPSolver with specified options.

# Arguments
- `kwargs...`: Solver options (see MadNLPSolver documentation for available options)

# Example
```julia
solver = MadNLPSolver(max_iter=1000, tol=1e-6)
```
"""
function MadNLPSolver(; kwargs...)
    opts = Strategies.build_strategy_options(MadNLPSolver; kwargs...)
    return MadNLPSolver(opts)
end

# ============================================================================
# Callable Interface
# ============================================================================

"""
    (solver::MadNLPSolver)(nlp; display=true)

Solve an NLP problem using MadNLP.

# Arguments
- `nlp::NLPModels.AbstractNLPModel`: The NLP problem to solve
- `display::Bool`: Whether to show solver output (default: true)

# Returns
- `SolverCore.GenericExecutionStats`: Solver execution statistics

# Example
```julia
solver = MadNLPSolver(max_iter=100)
nlp = ADNLPModel(x -> sum(x.^2), zeros(5))
stats = solver(nlp, display=false)
```
"""
function (solver::MadNLPSolver)(
    nlp::NLPModels.AbstractNLPModel;
    display::Bool=true
)::SolverCore.AbstractExecutionStats
    opts = Strategies.options(solver)
    
    # Extract raw options as Dict
    raw_opts = Options.extract_raw_options(opts.options)
    
    # Adjust print_level based on display flag
    if !display
        raw_opts[:print_level] = "MadNLP.ERROR"
    end
    
    # Call backend interface (stub or extension implementation)
    return solve_with_madnlp(nlp; raw_opts...)
end

# ============================================================================
# Extension Stub
# ============================================================================

"""
    solve_with_madnlp(nlp; kwargs...)

Backend interface for MadNLP solver.

This is a stub that throws an ExtensionError if the MadNLP extension
is not loaded. Load the extension with:
```julia
using MadNLP, MadNLPMumps
```

# Arguments
- `nlp::NLPModels.AbstractNLPModel`: The NLP problem to solve
- `kwargs...`: Solver options to pass to MadNLP

# Returns
- `SolverCore.GenericExecutionStats`: Solver execution statistics
"""
function solve_with_madnlp(nlp::NLPModels.AbstractNLPModel; kwargs...)
    throw(Exceptions.ExtensionError(
        [:MadNLP, :MadNLPMumps],
        suggestion="Install and load MadNLP packages: `using Pkg; Pkg.add([\"MadNLP\", \"MadNLPMumps\"]); using MadNLP, MadNLPMumps`",
        context="MadNLPSolver requires the MadNLP and MadNLPMumps extensions to solve NLP problems. MadNLP is a pure-Julia interior point solver with GPU support."
    ))
end
