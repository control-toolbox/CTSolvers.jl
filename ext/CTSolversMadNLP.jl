"""
CTSolversMadNLP Extension

Extension providing MadNLP solver metadata, constructor, and backend interface.
Implements the complete MadNLPSolver functionality with proper option definitions.
"""
module CTSolversMadNLP

using DocStringExtensions
using CTSolvers
using CTSolvers.Solvers
using CTSolvers.Strategies
using CTSolvers.Options
using CTBase.Exceptions
using MadNLP
using MadNLPMumps
using NLPModels
using SolverCore

# ============================================================================
# Metadata Definition
# ============================================================================

"""
    Strategies.metadata(::Type{<:Solvers.MadNLPSolver})

Return metadata defining MadNLPSolver options and their specifications.
"""
function Strategies.metadata(::Type{<:Solvers.MadNLPSolver})
    return Strategies.StrategyMetadata(
        Strategies.OptionDefinition(;
            name=:max_iter,
            type=Integer,
            default=3000,
            description="Maximum number of interior-point iterations before termination. Set to 0 to evaluate initial point only.",
            aliases=(:maxiter,),
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
            description="Convergence tolerance for optimality conditions. The algorithm terminates when optimality error falls below this threshold.",
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
            type=MadNLP.LogLevels,
            default=MadNLP.INFO,
            description="Logging verbosity level. Valid values: MadNLP.TRACE, DEBUG, INFO (default), NOTICE, WARN, ERROR."
        ),
        Strategies.OptionDefinition(;
            name=:linear_solver,
            type=Type{<:MadNLP.AbstractLinearSolver},
            default=MadNLPMumps.MumpsSolver,
            description="Sparse linear solver for the KKT system. Default is MadNLPMumps.MumpsSolver. Other options include MadNLP.UmfpackSolver, MadNLP.LDLSolver, MadNLP.CHOLMODSolver."
        ),
        # ---- Termination options ----
        Strategies.OptionDefinition(;
            name=:acceptable_tol,
            type=Real,
            default=Options.NotProvided,
            description="Relaxed tolerance for acceptable solution. If optimality error stays below this for 'acceptable_iter' iterations, algorithm terminates with SOLVED_TO_ACCEPTABLE_LEVEL.",
            aliases=(:acc_tol,),
            validator=x -> x > 0 || throw(Exceptions.IncorrectArgument(
                "Invalid acceptable_tol value",
                got="acceptable_tol=$x",
                expected="positive real number (> 0)",
                suggestion="Provide a positive tolerance (typically 1e-6)",
                context="MadNLPSolver acceptable_tol validation"
            ))
        ),
        Strategies.OptionDefinition(;
            name=:acceptable_iter,
            type=Integer,
            default=Options.NotProvided,
            description="Number of consecutive iterations with acceptable (but not optimal) error required before accepting the solution.",
            validator=x -> x >= 1 || throw(Exceptions.IncorrectArgument(
                "Invalid acceptable_iter value",
                got="acceptable_iter=$x",
                expected="positive integer (>= 1)",
                suggestion="Provide a positive integer (typically 15)",
                context="MadNLPSolver acceptable_iter validation"
            ))
        ),
        Strategies.OptionDefinition(;
            name=:max_wall_time,
            type=Real,
            default=Options.NotProvided,
            description="Maximum wall-clock time limit in seconds. Algorithm terminates with MAXIMUM_WALLTIME_EXCEEDED if exceeded.",
            aliases=(:max_time,),
            validator=x -> x > 0 || throw(Exceptions.IncorrectArgument(
                "Invalid max_wall_time value",
                got="max_wall_time=$x",
                expected="positive real number (> 0)",
                suggestion="Provide a positive time limit in seconds",
                context="MadNLPSolver max_wall_time validation"
            ))
        ),
        Strategies.OptionDefinition(;
            name=:diverging_iterates_tol,
            type=Real,
            default=Options.NotProvided,
            description="NLP error threshold above which algorithm is declared diverging. Terminates with DIVERGING_ITERATES status.",
            validator=x -> x > 0 || throw(Exceptions.IncorrectArgument(
                "Invalid diverging_iterates_tol value",
                got="diverging_iterates_tol=$x",
                expected="positive real number (> 0)",
                suggestion="Provide a large positive value (typically 1e20)",
                context="MadNLPSolver diverging_iterates_tol validation"
            ))
        ),
        # ---- NLP Scaling Options ----
        Strategies.OptionDefinition(;
            name=:nlp_scaling,
            type=Bool,
            default=Options.NotProvided,
            description="Whether to scale the NLP problem. If true, MadNLP automatically scales the objective and constraints."
        ),
        Strategies.OptionDefinition(;
            name=:nlp_scaling_max_gradient,
            type=Real,
            default=Options.NotProvided,
            description="Maximum allowed gradient value when scaling the NLP problem. Used to prevent excessive scaling.",
            validator=x -> x > 0 || throw(Exceptions.IncorrectArgument(
                "Invalid nlp_scaling_max_gradient value",
                got="nlp_scaling_max_gradient=$x",
                expected="positive real number (> 0)",
                suggestion="Provide a positive value (typically 100.0)",
                context="MadNLPSolver nlp_scaling_max_gradient validation"
            ))
        ),
        # ---- Structural Options ----
        Strategies.OptionDefinition(;
            name=:jacobian_constant,
            type=Bool,
            default=Options.NotProvided,
            description="Whether the Jacobian of the constraints is constant (i.e., linear constraints). Can improve performance.",
            aliases=(:jacobian_cst,)
        ),
        Strategies.OptionDefinition(;
            name=:hessian_constant,
            type=Bool,
            default=Options.NotProvided,
            description="Whether the Hessian of the Lagrangian is constant (i.e., quadratic objective with linear constraints). Can improve performance.",
            aliases=(:hessian_cst,)
        ),
        # ---- Initialization Options ----
        Strategies.OptionDefinition(;
            name=:bound_push,
            type=Real,
            default=Options.NotProvided,
            description="Amount by which the initial point is pushed inside the bounds to ensure strictly interior starting point.",
            validator=x -> x > 0 || throw(Exceptions.IncorrectArgument(
                "Invalid bound_push value",
                got="bound_push=$x",
                expected="positive real number (> 0)",
                suggestion="Provide a positive value (e.g., 0.01)",
                context="MadNLPSolver bound_push validation"
            ))
        ),
        Strategies.OptionDefinition(;
            name=:bound_fac,
            type=Real,
            default=Options.NotProvided,
            description="Factor to determine how much the initial point is pushed inside the bounds.",
            validator=x -> x > 0 || throw(Exceptions.IncorrectArgument(
                "Invalid bound_fac value",
                got="bound_fac=$x",
                expected="positive real number (> 0)",
                suggestion="Provide a positive value (e.g., 0.01)",
                context="MadNLPSolver bound_fac validation"
            ))
        ),
        Strategies.OptionDefinition(;
            name=:constr_mult_init_max,
            type=Real,
            default=Options.NotProvided,
            description="Maximum allowed value for the initial constraint multipliers.",
            validator=x -> x >= 0 || throw(Exceptions.IncorrectArgument(
                "Invalid constr_mult_init_max value",
                got="constr_mult_init_max=$x",
                expected="non-negative real number (>= 0)",
                suggestion="Provide a non-negative value (e.g., 1000.0)",
                context="MadNLPSolver constr_mult_init_max validation"
            ))
        ),
        Strategies.OptionDefinition(;
            name=:fixed_variable_treatment,
            type=MadNLP.FixedVariableTreatment,
            default=Options.NotProvided,
            description="Method to handle fixed variables. Options are from MadNLP.FixedVariableTreatment enum (e.g., MAKE_PARAMETER, RELAX_BOUNDS)."
        ),
        Strategies.OptionDefinition(;
            name=:equality_treatment,
            type=MadNLP.EqualityTreatment,
            default=Options.NotProvided,
            description="Method to handle equality constraints. Options are from MadNLP.EqualityTreatment enum (e.g., RELAX_BOUNDS)."
        )
    )
end

# ============================================================================
# Constructor Implementation
# ============================================================================

"""
    Solvers.build_madnlp_solver(::Solvers.MadNLPTag; kwargs...)

Build a MadNLPSolver with validated options.
"""
function Solvers.build_madnlp_solver(::Solvers.MadNLPTag; kwargs...)
    opts = Strategies.build_strategy_options(Solvers.MadNLPSolver; kwargs...)
    return Solvers.MadNLPSolver(opts)
end

# ============================================================================
# Callable Interface with Display Handling
# ============================================================================

"""
    (solver::Solvers.MadNLPSolver)(nlp; display=true)

Solve an NLP problem using MadNLP.

# Arguments
- `nlp::NLPModels.AbstractNLPModel`: The NLP problem to solve
- `display::Bool`: Whether to show solver output (default: true)

# Returns
- `MadNLP.MadNLPExecutionStats`: MadNLP execution statistics
"""
function (solver::Solvers.MadNLPSolver)(
    nlp::NLPModels.AbstractNLPModel;
    display::Bool=true
)::MadNLP.MadNLPExecutionStats
    options = Strategies.options_dict(solver)
    options[:print_level] = display ? options[:print_level] : MadNLP.ERROR
    return solve_with_madnlp(nlp; options...)
end

# ============================================================================
# Backend Solver Interface
# ============================================================================

"""
    solve_with_madnlp(nlp; kwargs...)

Backend interface for MadNLP solver.

Calls MadNLP to solve the NLP problem.
"""
function solve_with_madnlp(
    nlp::NLPModels.AbstractNLPModel;
    kwargs...
)::MadNLP.MadNLPExecutionStats
    solver = MadNLP.MadNLPSolver(nlp; kwargs...)
    return MadNLP.solve!(solver)
end

"""
$(TYPEDSIGNATURES)

Extract solver information from MadNLP execution statistics.

This method handles MadNLP-specific behavior:
- Objective sign depends on whether the problem is a minimization or maximization
- Status codes are MadNLP-specific (e.g., `:SOLVE_SUCCEEDED`, `:SOLVED_TO_ACCEPTABLE_LEVEL`)

# Arguments

- `nlp_solution::MadNLP.MadNLPExecutionStats`: MadNLP execution statistics
- `minimize::Bool`: Whether the problem is a minimization problem or not

# Returns

A 6-element tuple `(objective, iterations, constraints_violation, message, status, successful)`:
- `objective::Float64`: The final objective value (sign corrected for minimization)
- `iterations::Int`: Number of iterations performed
- `constraints_violation::Float64`: Maximum constraint violation (primal feasibility)
- `message::String`: Solver identifier string ("MadNLP")
- `status::Symbol`: MadNLP termination status
- `successful::Bool`: Whether the solver converged successfully
"""
function CTSolvers.extract_solver_infos(
    nlp_solution::MadNLP.MadNLPExecutionStats,
    minimize::Bool,
)
    objective = minimize ? nlp_solution.objective : -nlp_solution.objective
    iterations = nlp_solution.iter
    constraints_violation = nlp_solution.primal_feas
    status = Symbol(nlp_solution.status)
    successful = (status == :SOLVE_SUCCEEDED) || (status == :SOLVED_TO_ACCEPTABLE_LEVEL)
    return objective, iterations, constraints_violation, "MadNLP", status, successful
end

end
