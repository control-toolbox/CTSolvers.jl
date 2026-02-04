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

- `max_iter::Integer`: Maximum number of iterations (default: 3000, must be ≥ 0)
- `tol::Real`: Convergence tolerance (default: 1e-8, must be > 0)
- `print_level::Integer`: Output verbosity level (default: 5, range: 0-12)
  - 0: No output
  - 5: Standard output
  - 12: Maximum verbosity
- `mu_strategy::String`: Barrier parameter update strategy (default: "adaptive")
  - "adaptive": Automatically adjusts barrier parameter
  - "monotone": Monotonically decreases barrier parameter
- `linear_solver::String`: Linear solver used for step computations (default: "mumps")
  - "ma27": Harwell routine MA27
  - "ma57": Harwell routine MA57 (robust performance)
  - "ma77": Harwell routine HSL_MA77
  - "ma86": Harwell routine HSL_MA86
  - "ma97": Harwell routine HSL_MA97
  - "pardiso": Pardiso package from pardiso-project.org
  - "pardisomkl": Pardiso package from Intel MKL
  - "spral": Spral package
  - "wsmp": Wsmp package
  - "mumps": Mumps package (general purpose)
- `sb::String`: Suppress Ipopt banner (default: "yes", options: "yes"/"no")

# Examples

```julia
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

- Implements the `AbstractStrategy` contract via `Strategies.id`, `Strategies.metadata`, and `Strategies.options`
- Options are validated at construction time using enriched `Exceptions.IncorrectArgument`
- Callable interface: `(solver::IpoptSolver)(nlp; display=true)`

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

"""
    Strategies.metadata(::Type{<:IpoptSolver})

Return metadata defining IpoptSolver options and their specifications.
"""
function Strategies.metadata(::Type{<:IpoptSolver})
    return Strategies.StrategyMetadata(
        Strategies.OptionDefinition(;
            name=:max_iter,
            type=Integer,
            default=1000,
            description="Maximum number of iterations",
            aliases=(:maxiter, ),
            validator=x -> x >= 0 || throw(Exceptions.IncorrectArgument(
                "Invalid max_iter value",
                got="max_iter=$x",
                expected="non-negative integer (>= 0)",
                suggestion="Provide a non-negative value for maximum iterations",
                context="IpoptSolver max_iter validation"
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
                context="IpoptSolver tol validation"
            ))
        ),
        Strategies.OptionDefinition(;
            name=:print_level,
            type=Integer,
            default=5,
            description="Ipopt output verbosity (0-12)",
            validator=x -> (0 <= x <= 12) || throw(Exceptions.IncorrectArgument(
                "Invalid print_level value",
                got="print_level=$x",
                expected="integer between 0 and 12",
                suggestion="Use 0 for no output, 5 for standard output, or 12 for maximum verbosity",
                context="IpoptSolver print_level validation"
            ))
        ),
        Strategies.OptionDefinition(;
            name=:mu_strategy,
            type=String,
            default="adaptive",
            description="Barrier parameter update strategy",
            validator=x -> x in ["monotone", "adaptive"] || throw(Exceptions.IncorrectArgument(
                "Invalid mu_strategy value",
                got="mu_strategy='$x'",
                expected="'monotone' or 'adaptive'",
                suggestion="Use 'adaptive' for most problems or 'monotone' for specific cases",
                context="IpoptSolver mu_strategy validation"
            ))
        ),
        Strategies.OptionDefinition(;
            name=:linear_solver,
            type=String,
            default="mumps",
            description="Linear solver used for step computations. Determines which linear algebra package is to be used for the solution of the augmented linear system (for obtaining the search directions).",
            validator=x -> x in ["ma27", "ma57", "ma77", "ma86", "ma97", "pardiso", "pardisomkl", "spral", "wsmp", "mumps"] || throw(Exceptions.IncorrectArgument(
                "Invalid linear_solver value",
                got="linear_solver='$x'",
                expected="one of: ma27, ma57, ma77, ma86, ma97, pardiso, pardisomkl, spral, wsmp, mumps",
                suggestion="Use 'mumps' for general purpose, 'ma57' for robust performance, or 'pardiso' for Intel MKL",
                context="IpoptSolver linear_solver validation"
            ))
        ),
        Strategies.OptionDefinition(;
            name=:sb,
            type=String,
            default="yes",
            description="Suppress Ipopt banner (yes/no)",
            validator=x -> x in ["yes", "no"] || throw(Exceptions.IncorrectArgument(
                "Invalid sb (suppress banner) value",
                got="sb='$x'",
                expected="'yes' or 'no'",
                suggestion="Use 'yes' to suppress Ipopt banner or 'no' to show it",
                context="IpoptSolver sb validation"
            ))
        )
    )
end

# ============================================================================
# Constructor
# ============================================================================

"""
    IpoptSolver(; kwargs...)

Create an IpoptSolver with specified options.

# Arguments
- `kwargs...`: Solver options (see IpoptSolver documentation for available options)

# Example
```julia
solver = IpoptSolver(max_iter=1000, tol=1e-6)
```
"""
function IpoptSolver(; kwargs...)
    opts = Strategies.build_strategy_options(IpoptSolver; kwargs...)
    return IpoptSolver(opts)
end

# ============================================================================
# Callable Interface
# ============================================================================

"""
    (solver::IpoptSolver)(nlp; display=true)

Solve an NLP problem using Ipopt.

# Arguments
- `nlp::NLPModels.AbstractNLPModel`: The NLP problem to solve
- `display::Bool`: Whether to show solver output (default: true)

# Returns
- `SolverCore.GenericExecutionStats`: Solver execution statistics

# Example
```julia
solver = IpoptSolver(max_iter=100)
nlp = ADNLPModel(x -> sum(x.^2), zeros(5))
stats = solver(nlp, display=false)
```
"""
function (solver::IpoptSolver)(
    nlp::NLPModels.AbstractNLPModel;
    display::Bool=true
)::SolverCore.AbstractExecutionStats
    opts = Strategies.options(solver)
    
    # Extract raw options as Dict
    raw_opts = Options.extract_raw_options(opts.options)
    
    # Adjust print_level based on display flag
    raw_opts[:print_level] = display ? raw_opts[:print_level] : 0
    
    # Call backend interface (stub or extension implementation)
    return solve_with_ipopt(nlp; raw_opts...)
end

# ============================================================================
# Extension Stub
# ============================================================================

"""
    solve_with_ipopt(nlp; kwargs...)

Backend interface for Ipopt solver.

This is a stub that throws an ExtensionError if the NLPModelsIpopt extension
is not loaded. Load the extension with:
```julia
using NLPModelsIpopt
```

# Arguments
- `nlp::NLPModels.AbstractNLPModel`: The NLP problem to solve
- `kwargs...`: Solver options to pass to Ipopt

# Returns
- `SolverCore.GenericExecutionStats`: Solver execution statistics
"""
function solve_with_ipopt(nlp::NLPModels.AbstractNLPModel; kwargs...)
    throw(Exceptions.ExtensionError(
        :NLPModelsIpopt,
        suggestion="Install and load NLPModelsIpopt: `using Pkg; Pkg.add(\"NLPModelsIpopt\"); using NLPModelsIpopt`",
        context="IpoptSolver requires the NLPModelsIpopt extension to solve NLP problems. The extension provides the interface to the Ipopt optimization library."
    ))
end
