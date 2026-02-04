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
            description="Maximum number of iterations",
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
            description="Optimality tolerance",
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
            description="MadNLP logging level"
        ),
        Strategies.OptionDefinition(;
            name=:linear_solver,
            type=Type{<:MadNLP.AbstractLinearSolver},
            default=MadNLPMumps.MumpsSolver,
            description="Linear solver implementation used by MadNLP"
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
    opts = Strategies.options(solver)
    raw_opts = Options.extract_raw_options(opts.options)
    
    # Handle display flag
    if !display
        raw_opts[:print_level] = MadNLP.ERROR
    end
    
    return solve_with_madnlp(nlp; raw_opts...)
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
