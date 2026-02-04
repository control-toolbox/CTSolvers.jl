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

## Termination Options

- `tol::Real`: Desired convergence tolerance (relative) (default: 1e-8, must be > 0)
  - Determines when the algorithm terminates successfully based on NLP error
- `max_iter::Integer`: Maximum number of iterations (default: 3000, must be ≥ 0)
  - Algorithm terminates if this number of iterations is exceeded
- `max_wall_time::Real`: Maximum walltime clock seconds (default: 1e20, must be > 0)
  - Limit on walltime that Ipopt can use to solve one problem
- `max_cpu_time::Real`: Maximum CPU seconds (default: 1e20, must be > 0)
  - Limit on CPU time that Ipopt can use to solve one problem
- `dual_inf_tol::Real`: Threshold for dual infeasibility (default: 1.0, must be > 0)
  - Absolute tolerance on dual infeasibility for successful termination
- `constr_viol_tol::Real`: Threshold for constraint violation (default: 1e-4, must be > 0)
  - Absolute tolerance on constraint and variable bound violation

## Algorithm Options

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

## Output Options

- `print_level::Integer`: Output verbosity level (default: 5, range: 0-12)
  - 0: No output
  - 5: Standard output
  - 12: Maximum verbosity
- `print_timing_statistics::String`: Switch to print timing statistics (default: "no")
  - "yes": Print time spent for selected tasks (implies timing_statistics=yes)
  - "no": Disable timing statistics
- `print_frequency_iter::Integer`: Iteration frequency for summary output (default: 1, must be ≥ 1)
  - Controls how often the summarizing iteration output line is printed
  - Output printed every N iterations if time condition is also met
- `print_frequency_time::Real`: Time frequency for summary output (default: 0.0, must be ≥ 0)
  - Minimum seconds between summary outputs
  - Used together with print_frequency_iter for output control
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
        # ====================================================================
        # TERMINATION OPTIONS
        # ====================================================================
        
        Strategies.OptionDefinition(;
            name=:tol,
            type=Real,
            default=1e-8,
            description="Desired convergence tolerance (relative). Determines the convergence tolerance for the algorithm. The algorithm terminates successfully, if the (scaled) NLP error becomes smaller than this value, and if the (absolute) criteria according to dual_inf_tol, constr_viol_tol, and compl_inf_tol are met.",
            validator=x -> x > 0 || throw(Exceptions.IncorrectArgument(
                "Invalid tolerance value",
                got="tol=$x",
                expected="positive real number (> 0)",
                suggestion="Provide a positive tolerance value (e.g., 1e-6, 1e-8)",
                context="IpoptSolver tol validation"
            ))
        ),
        
        Strategies.OptionDefinition(;
            name=:max_iter,
            type=Integer,
            default=3000,
            description="Maximum number of iterations. The algorithm terminates with a message if the number of iterations exceeded this number.",
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
            name=:max_wall_time,
            type=Real,
            default=1e20,
            description="Maximum number of walltime clock seconds. A limit on walltime clock seconds that Ipopt can use to solve one problem.",
            validator=x -> x > 0 || throw(Exceptions.IncorrectArgument(
                "Invalid max_wall_time value",
                got="max_wall_time=$x",
                expected="positive real number (> 0)",
                suggestion="Provide a positive time limit in seconds (e.g., 3600 for 1 hour)",
                context="IpoptSolver max_wall_time validation"
            ))
        ),
        
        Strategies.OptionDefinition(;
            name=:max_cpu_time,
            type=Real,
            default=1e20,
            description="Maximum number of CPU seconds. A limit on CPU seconds that Ipopt can use to solve one problem.",
            validator=x -> x > 0 || throw(Exceptions.IncorrectArgument(
                "Invalid max_cpu_time value",
                got="max_cpu_time=$x",
                expected="positive real number (> 0)",
                suggestion="Provide a positive CPU time limit in seconds",
                context="IpoptSolver max_cpu_time validation"
            ))
        ),
        
        Strategies.OptionDefinition(;
            name=:dual_inf_tol,
            type=Real,
            default=1.0,
            description="Desired threshold for the dual infeasibility. Absolute tolerance on the dual infeasibility. Successful termination requires that the max-norm of the (unscaled) dual infeasibility is less than this threshold.",
            validator=x -> x > 0 || throw(Exceptions.IncorrectArgument(
                "Invalid dual_inf_tol value",
                got="dual_inf_tol=$x",
                expected="positive real number (> 0)",
                suggestion="Use 1.0 for standard tolerance or smaller for stricter convergence",
                context="IpoptSolver dual_inf_tol validation"
            ))
        ),
        
        Strategies.OptionDefinition(;
            name=:constr_viol_tol,
            type=Real,
            default=1e-4,
            description="Desired threshold for the constraint and variable bound violation. Absolute tolerance on the constraint and variable bound violation.",
            validator=x -> x > 0 || throw(Exceptions.IncorrectArgument(
                "Invalid constr_viol_tol value",
                got="constr_viol_tol=$x",
                expected="positive real number (> 0)",
                suggestion="Use 1e-4 for standard tolerance or smaller for stricter feasibility",
                context="IpoptSolver constr_viol_tol validation"
            ))
        ),
        
        # ====================================================================
        # ALGORITHM OPTIONS
        # ====================================================================
        
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
        
        # ====================================================================
        # OUTPUT OPTIONS
        # ====================================================================
        
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
            name=:print_timing_statistics,
            type=String,
            default="no",
            description="Switch to print timing statistics. If selected, the program will print the time spent for selected tasks. This implies timing_statistics=yes.",
            validator=x -> x in ["yes", "no"] || throw(Exceptions.IncorrectArgument(
                "Invalid print_timing_statistics value",
                got="print_timing_statistics='$x'",
                expected="'yes' or 'no'",
                suggestion="Use 'yes' to enable timing statistics or 'no' to disable",
                context="IpoptSolver print_timing_statistics validation"
            ))
        ),
        
        Strategies.OptionDefinition(;
            name=:print_frequency_iter,
            type=Integer,
            default=1,
            description="Determines at which iteration frequency the summarizing iteration output line should be printed. Summarizing iteration output is printed every print_frequency_iter iterations, if at least print_frequency_time seconds have passed since last output.",
            validator=x -> x >= 1 || throw(Exceptions.IncorrectArgument(
                "Invalid print_frequency_iter value",
                got="print_frequency_iter=$x",
                expected="integer >= 1",
                suggestion="Use 1 for every iteration, or larger values for less frequent output",
                context="IpoptSolver print_frequency_iter validation"
            ))
        ),
        
        Strategies.OptionDefinition(;
            name=:print_frequency_time,
            type=Real,
            default=0.0,
            description="Determines at which time frequency the summarizing iteration output line should be printed. Summarizing iteration output is printed if at least print_frequency_time seconds have passed since last output and the iteration number is a multiple of print_frequency_iter.",
            validator=x -> x >= 0 || throw(Exceptions.IncorrectArgument(
                "Invalid print_frequency_time value",
                got="print_frequency_time=$x",
                expected="real number >= 0",
                suggestion="Use 0 for no time-based filtering, or positive value for time-based output control",
                context="IpoptSolver print_frequency_time validation"
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
