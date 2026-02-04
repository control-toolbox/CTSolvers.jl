# ============================================================================
# Tag Dispatch Infrastructure
# ============================================================================

"""
    MadNLPTag <: AbstractTag

Tag type for MadNLP-specific implementation dispatch.
"""
struct MadNLPTag <: AbstractTag end

# ============================================================================
# Solver Type Definition
# ============================================================================

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
- `print_level::MadNLP.LogLevels`: MadNLP log level (default: MadNLP.INFO)
  - MadNLP.DEBUG: Detailed debugging output
  - MadNLP.INFO: Standard informational output
  - MadNLP.WARN: Warning messages only
  - MadNLP.ERROR: Error messages only
- `linear_solver::Type{<:MadNLP.AbstractLinearSolver}`: Linear solver backend (default: MadNLPMumps.MumpsSolver)

# Examples

```julia
# Create solver with default options
solver = MadNLPSolver()

# Create solver with custom options
using MadNLP, MadNLPMumps
solver = MadNLPSolver(max_iter=1000, tol=1e-6, print_level=MadNLP.DEBUG)

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

# ============================================================================
# Constructor with Tag Dispatch
# ============================================================================

"""
    MadNLPSolver(; kwargs...)

Create a MadNLPSolver with specified options.

Requires the CTSolversMadNLP extension to be loaded.

# Arguments
- `kwargs...`: Solver options (see extension documentation for available options)

# Example
```julia
using MadNLP, MadNLPMumps
solver = MadNLPSolver(max_iter=1000, tol=1e-6)
```
"""
function MadNLPSolver(; kwargs...)
    return build_madnlp_solver(MadNLPTag(); kwargs...)
end

"""
    build_madnlp_solver(::AbstractTag; kwargs...)

Stub function that throws ExtensionError if CTSolversMadNLP extension is not loaded.
Real implementation provided by the extension.
"""
function build_madnlp_solver(::AbstractTag; kwargs...)
    throw(Exceptions.ExtensionError(
        :MadNLP, :MadNLPMumps;
        message="to create MadNLPSolver",
        feature="solver construction",
        context="MadNLPSolver constructor"
    ))
end

"""
    (solver::MadNLPSolver)(nlp; display=true)

Callable interface stub - implementation provided by CTSolversMadNLP extension.
"""
function (solver::MadNLPSolver) end

"""
    solve_with_madnlp(nlp; kwargs...)

Backend solver interface stub - implementation provided by CTSolversMadNLP extension.
"""
function solve_with_madnlp end

"""
    Strategies.metadata(::Type{<:MadNLPSolver})

Metadata stub - implementation provided by CTSolversMadNLP extension.
"""
function Strategies.metadata(::Type{<:MadNLPSolver})
    throw(Exceptions.ExtensionError(
        :MadNLP, :MadNLPMumps;
        message="to access MadNLPSolver metadata",
        feature="metadata definition",
        context="MadNLPSolver metadata"
    ))
end
