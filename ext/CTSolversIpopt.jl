"""
CTSolversIpopt Extension

Extension providing Ipopt solver metadata, constructor, and backend interface.
Implements the complete IpoptSolver functionality with proper option definitions.
"""
module CTSolversIpopt

using CTSolvers
using CTSolvers.Solvers
using CTSolvers.Strategies
using CTSolvers.Options
using CTBase.Exceptions
using NLPModelsIpopt
using NLPModels
using SolverCore

# ============================================================================
# Metadata Definition
# ============================================================================

"""
    Strategies.metadata(::Type{<:Solvers.IpoptSolver})

Return metadata defining IpoptSolver options and their specifications.
"""
function Strategies.metadata(::Type{<:Solvers.IpoptSolver})
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
            name=:timing_statistics,
            type=String,
            default="no",
            description="Indicates whether to measure time spent in components of Ipopt and NLP evaluation. The overall algorithm time is unaffected by this option.",
            validator=x -> x in ["yes", "no"] || throw(Exceptions.IncorrectArgument(
                "Invalid timing_statistics value",
                got="timing_statistics='$x'",
                expected="'yes' or 'no'",
                suggestion="Use 'yes' to enable component timing or 'no' to disable",
                context="IpoptSolver timing_statistics validation"
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
# Constructor Implementation
# ============================================================================

"""
    Solvers.build_ipopt_solver(::Solvers.IpoptTag; kwargs...)

Build an IpoptSolver with validated options.
"""
function Solvers.build_ipopt_solver(::Solvers.IpoptTag; kwargs...)
    opts = Strategies.build_strategy_options(Solvers.IpoptSolver; kwargs...)
    return Solvers.IpoptSolver(opts)
end

# ============================================================================
# Callable Interface with Display Handling
# ============================================================================

"""
    (solver::Solvers.IpoptSolver)(nlp; display=true)

Solve an NLP problem using Ipopt.

# Arguments
- `nlp::NLPModels.AbstractNLPModel`: The NLP problem to solve
- `display::Bool`: Whether to show solver output (default: true)

# Returns
- `SolverCore.GenericExecutionStats`: Solver execution statistics
"""
function (solver::Solvers.IpoptSolver)(
    nlp::NLPModels.AbstractNLPModel;
    display::Bool=true
)::SolverCore.GenericExecutionStats
    options = Strategies.options_dict(solver)
    options[:print_level] = display ? options[:print_level] : 0
    return solve_with_ipopt(nlp; options...)
end

# ============================================================================
# Backend Solver Interface
# ============================================================================

"""
    solve_with_ipopt(nlp; kwargs...)

Backend interface for Ipopt solver.

Calls NLPModelsIpopt to solve the NLP problem.
"""
function solve_with_ipopt(
    nlp::NLPModels.AbstractNLPModel;
    kwargs...
)::SolverCore.GenericExecutionStats
    solver = NLPModelsIpopt.IpoptSolver(nlp)
    return NLPModelsIpopt.solve!(solver, nlp; kwargs...)
end

end
