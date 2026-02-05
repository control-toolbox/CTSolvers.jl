# ============================================================================
# Tag Dispatch Infrastructure
# ============================================================================

"""
    IpoptTag <: AbstractTag

Tag type for Ipopt-specific implementation dispatch.
"""
struct IpoptTag <: AbstractTag end

# ============================================================================
# Solver Type Definition
# ============================================================================

"""
    IpoptSolver

$(TYPEDEF)

Interior point optimization solver using the Ipopt backend.

Ipopt (Interior Point OPTimizer) is an open-source software package for large-scale
nonlinear optimization. It implements a primal-dual interior point method with proven
global convergence properties.

# Fields

$(TYPEDFIELDS)

# Solver Options

Solver options are defined in the CTSolversIpopt extension.
Load the extension to access option definitions and documentation:
```julia
using NLPModelsIpopt
```

# Examples

```julia
# Load the extension first
using NLPModelsIpopt

# Create solver with default options
solver = IpoptSolver()

# Create solver with custom options
solver = IpoptSolver(max_iter=1000, tol=1e-6, print_level=3)

# Solve an NLP problem
using ADNLPModels
nlp = ADNLPModel(x -> sum(x.^2), zeros(10))
stats = solver(nlp, display=true)
```

# Extension Required

This solver requires the `NLPModelsIpopt` package to be loaded:
```julia
using NLPModelsIpopt
```

# Implementation Notes

- Implements the `AbstractStrategy` contract via `Strategies.id()`
- Metadata and constructor implementation provided by CTSolversIpopt extension
- Options are validated at construction time using enriched `Exceptions.IncorrectArgument`
- Callable interface: `(solver::IpoptSolver)(nlp; display=true)` provided by extension

See also: [`AbstractOptimizationSolver`](@ref), [`MadNLPSolver`](@ref), [`KnitroSolver`](@ref)
"""
struct IpoptSolver <: AbstractOptimizationSolver
    "Solver configuration options containing validated option values"
    options::Strategies.StrategyOptions
end

# ============================================================================
# AbstractStrategy Contract Implementation
# ============================================================================

"""
    Strategies.id(::Type{<:IpoptSolver})

Return the unique identifier for IpoptSolver.
"""
Strategies.id(::Type{<:IpoptSolver}) = :ipopt

# ============================================================================
# Constructor with Tag Dispatch
# ============================================================================

"""
    IpoptSolver(; kwargs...)

Create an IpoptSolver with specified options.

Requires the CTSolversIpopt extension to be loaded.

# Arguments
- `kwargs...`: Solver options (see extension documentation for available options)

# Example
```julia
using NLPModelsIpopt
solver = IpoptSolver(max_iter=1000, tol=1e-6)
```
"""
function IpoptSolver(; kwargs...)
    return build_ipopt_solver(IpoptTag(); kwargs...)
end

"""
    build_ipopt_solver(::AbstractTag; kwargs...)

Stub function that throws ExtensionError if CTSolversIpopt extension is not loaded.
Real implementation provided by the extension.
"""
function build_ipopt_solver(::AbstractTag; kwargs...)
    throw(Exceptions.ExtensionError(
        :NLPModelsIpopt;
        message="to create IpoptSolver, access options, and solve problems",
        feature="IpoptSolver functionality",
        context="Load NLPModelsIpopt extension first: using NLPModelsIpopt"
    ))
end
