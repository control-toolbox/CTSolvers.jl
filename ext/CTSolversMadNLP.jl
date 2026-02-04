module CTSolversMadNLP

using DocStringExtensions
using CTSolvers
using MadNLP
using MadNLPMumps
using NLPModels

# # default
# __mad_nlp_max_iter() = 1000
# __mad_nlp_tol() = 1e-8
# __mad_nlp_print_level() = MadNLP.INFO
# __mad_nlp_linear_solver() = MadNLPMumps.MumpsSolver

# function CTSolvers._option_specs(::Type{<:CTSolvers.MadNLPSolver})
#     return (
#         max_iter=CTSolvers.OptionSpec(;
#             type=Integer,
#             default=__mad_nlp_max_iter(),
#             description="Maximum number of iterations.",
#         ),
#         tol=CTSolvers.OptionSpec(;
#             type=Real, default=__mad_nlp_tol(), description="Optimality tolerance."
#         ),
#         print_level=CTSolvers.OptionSpec(;
#             type=MadNLP.LogLevels,
#             default=__mad_nlp_print_level(),
#             description="MadNLP logging level.",
#         ),
#         linear_solver=CTSolvers.OptionSpec(;
#             type=Type{<:MadNLP.AbstractLinearSolver},
#             default=__mad_nlp_linear_solver(),
#             description="Linear solver implementation used by MadNLP.",
#         ),
#     )
# end

# # solver interface
# function CTSolvers.solve_with_madnlp(
#     nlp::NLPModels.AbstractNLPModel; kwargs...
# )::MadNLP.MadNLPExecutionStats
#     solver = MadNLP.MadNLPSolver(nlp; kwargs...)
#     return MadNLP.solve!(solver)
# end

# # backend constructor
# function CTSolvers.MadNLPSolver(; kwargs...)
#     values, sources = CTSolvers._build_ocp_tool_options(
#         CTSolvers.MadNLPSolver; kwargs..., strict_keys=false
#     )
#     return CTSolvers.MadNLPSolver(values, sources)
# end

# function (solver::CTSolvers.MadNLPSolver)(
#     nlp::NLPModels.AbstractNLPModel; display::Bool
# )::MadNLP.MadNLPExecutionStats
#     options = Dict(pairs(CTSolvers._options_values(solver)))
#     options[:print_level] = display ? options[:print_level] : MadNLP.ERROR
#     return CTSolvers.solve_with_madnlp(nlp; options...)
# end

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

# Example

```julia-repl
julia> using CTSolvers, MadNLP

julia> # After solving with MadNLP
julia> obj, iter, viol, msg, stat, success = extract_solver_infos(nlp_solution, minimize)
(1.23, 15, 1.0e-6, "MadNLP", :SOLVE_SUCCEEDED, true)
```
"""
function CTSolvers.extract_solver_infos(
    nlp_solution::MadNLP.MadNLPExecutionStats,
    minimize::Bool, # whether the problem is a minimization problem or not
)
    # Get minimization flag and adjust objective sign accordingly
    objective = minimize ? nlp_solution.objective : -nlp_solution.objective

    # Extract standard fields
    iterations = nlp_solution.iter
    constraints_violation = nlp_solution.primal_feas

    # Convert MadNLP status to Symbol
    status = Symbol(nlp_solution.status)

    # Check if solution is successful based on MadNLP status codes
    successful = (status == :SOLVE_SUCCEEDED) || (status == :SOLVED_TO_ACCEPTABLE_LEVEL)

    return objective, iterations, constraints_violation, "MadNLP", status, successful
end

end
