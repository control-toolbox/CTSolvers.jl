"""
CTSolversUno Extension

Extension providing Uno solver metadata, constructor, and backend interface.
Implements the complete Solvers.Uno functionality with proper option definitions.
"""
module CTSolversUno

import DocStringExtensions: TYPEDSIGNATURES
import CTSolvers.Optimization
import CTSolvers.Solvers
import CTSolvers.Strategies
import CTSolvers.Options
import CTBase.Exceptions
import UnoSolver

# Import parameter types
using CTSolvers.Strategies: CPU, GPU, AbstractStrategyParameter

# ============================================================================
# Metadata definition
# ============================================================================

"""
$(TYPEDSIGNATURES)

Return metadata defining Uno options and their specifications.
"""
function Strategies.metadata(::Type{Solvers.Uno{P}}) where {P<:CPU}
    return Strategies.StrategyMetadata(
        # ====================================================================
        # Presets
        # ====================================================================
        Strategies.OptionDefinition(;
            name=:preset,
            type=String,
            default="ipopt",
            description="Uno implements presets, that is combinations of ingredients that correspond to existing solvers. At the moment, the available presets are filtersqp (after the trust-region restoration filter SQP solver filterSQP) and ipopt (after the line-search filter restoration infeasible interior-point solver IPOPT).",
            validator=x ->
                x in ["filtersqp", "ipopt"] || throw(
                    Exceptions.IncorrectArgument(
                        "Invalid preset value";
                        got="preset=$x",
                        expected="filtersqp or ipopt",
                        suggestion="Provide a valid preset value (e.g., filtersqp, ipopt)",
                        context="Uno preset validation",
                    ),
                ),
        ),

        # ====================================================================
        # Termination options
        # ====================================================================
        Strategies.OptionDefinition(;
            name=:primal_tolerance,
            type=Real,
            default=1e-8,
            description="Tolerance on constraint violation. Determines the convergence tolerance for primal feasibility.",
            validator=x ->
                x > 0 || throw(
                    Exceptions.IncorrectArgument(
                        "Invalid primal_tolerance value";
                        got="primal_tolerance=$x",
                        expected="positive real number (> 0)",
                        suggestion="Provide a positive tolerance value (e.g., 1e-6, 1e-8)",
                        context="Uno primal_tolerance validation",
                    ),
                ),
        ),
        Strategies.OptionDefinition(;
            name=:dual_tolerance,
            type=Real,
            default=1e-8,
            description="Tolerance on stationarity and complementarity. Determines the convergence tolerance for dual feasibility.",
            validator=x ->
                x > 0 || throw(
                    Exceptions.IncorrectArgument(
                        "Invalid dual_tolerance value";
                        got="dual_tolerance=$x",
                        expected="positive real number (> 0)",
                        suggestion="Provide a positive tolerance value (e.g., 1e-6, 1e-8)",
                        context="Uno dual_tolerance validation",
                    ),
                ),
        ),
        Strategies.OptionDefinition(;
            name=:loose_primal_tolerance,
            type=Real,
            default=Options.NotProvided,
            description="Loose tolerance on constraint violation. Used for acceptable termination criteria.",
            validator=x ->
                x > 0 || throw(
                    Exceptions.IncorrectArgument(
                        "Invalid loose_primal_tolerance value";
                        got="loose_primal_tolerance=$x",
                        expected="positive real number (> 0)",
                        suggestion="Use roughly 100 times larger than primal_tolerance",
                        context="Uno loose_primal_tolerance validation",
                    ),
                ),
        ),
        Strategies.OptionDefinition(;
            name=:loose_dual_tolerance,
            type=Real,
            default=Options.NotProvided,
            description="Loose tolerance on stationarity and complementarity. Used for acceptable termination criteria.",
            validator=x ->
                x > 0 || throw(
                    Exceptions.IncorrectArgument(
                        "Invalid loose_dual_tolerance value";
                        got="loose_dual_tolerance=$x",
                        expected="positive real number (> 0)",
                        suggestion="Use roughly 100 times larger than dual_tolerance",
                        context="Uno loose_dual_tolerance validation",
                    ),
                ),
        ),
        Strategies.OptionDefinition(;
            name=:loose_tolerance_iteration_threshold,
            type=Integer,
            default=Options.NotProvided,
            description="Number of iterations for the loose tolerance to apply. If the algorithm encounters this many consecutive iterations that satisfy loose tolerances, it terminates.",
            validator=x ->
                x >= 0 || throw(
                    Exceptions.IncorrectArgument(
                        "Invalid loose_tolerance_iteration_threshold value";
                        got="loose_tolerance_iteration_threshold=$x",
                        expected="non-negative integer (>= 0)",
                        suggestion="Use 15 (default) or 0 to disable loose tolerance termination",
                        context="Uno loose_tolerance_iteration_threshold validation",
                    ),
                ),
        ),
        Strategies.OptionDefinition(;
            name=:max_iterations,
            type=Integer,
            default=1000,
            description="Maximum number of outer iterations. The algorithm terminates with a message if the number of iterations exceeded this number.",
            aliases=(:maxiter, :max_iter),
            validator=x ->
                x >= 0 || throw(
                    Exceptions.IncorrectArgument(
                        "Invalid max_iterations value";
                        got="max_iterations=$x",
                        expected="non-negative integer (>= 0)",
                        suggestion="Provide a non-negative value for maximum iterations",
                        context="Uno max_iterations validation",
                    ),
                ),
        ),
        Strategies.OptionDefinition(;
            name=:time_limit,
            type=Real,
            default=Options.NotProvided,
            description="Time limit in seconds. A limit on walltime clock seconds that Uno can use to solve one problem.",
            validator=x ->
                x > 0 || throw(
                    Exceptions.IncorrectArgument(
                        "Invalid time_limit value";
                        got="time_limit=$x",
                        expected="positive real number (> 0)",
                        suggestion="Provide a positive time limit in seconds (e.g., 3600 for 1 hour)",
                        context="Uno time_limit validation",
                    ),
                ),
        ),
        Strategies.OptionDefinition(;
            name=:print_solution,
            type=Bool,
            default=false,
            description="Whether the primal-dual solution is printed at termination.",
        ),
        Strategies.OptionDefinition(;
            name=:unbounded_objective_threshold,
            type=Real,
            default=Options.NotProvided,
            description="Objective threshold under which the problem is declared unbounded. If the objective value falls below this threshold, the solver terminates with unbounded status.",
        ),

        # ====================================================================
        # Main options - String options
        # ====================================================================
        Strategies.OptionDefinition(;
            name=:logger,
            type=String,
            default="INFO",
            description="Verbosity level of the logger. Controls the amount of output during the solve.",
            validator=x ->
                x in ["SILENT", "DISCRETE", "WARNING", "INFO", "DEBUG", "DEBUG2", "DEBUG3"] || throw(
                    Exceptions.IncorrectArgument(
                        "Invalid logger value";
                        got="logger=$x",
                        expected="SILENT, DISCRETE, WARNING, INFO, DEBUG, DEBUG2, or DEBUG3",
                        suggestion="Use INFO for standard output, SILENT for no output, or DEBUG for detailed diagnostics",
                        context="Uno logger validation",
                    ),
                ),
        ),
        Strategies.OptionDefinition(;
            name=:progress_norm,
            type=String,
            default=Options.NotProvided,
            description="Norm used for the progress measures. Determines how progress is measured during the solve.",
            validator=x ->
                x in ["L1", "L2", "INF"] || throw(
                    Exceptions.IncorrectArgument(
                        "Invalid progress_norm value";
                        got="progress_norm=$x",
                        expected="L1, L2, or INF",
                        suggestion="Use L1 for sum of absolute values, L2 for Euclidean norm, or INF for maximum absolute value",
                        context="Uno progress_norm validation",
                    ),
                ),
        ),
        Strategies.OptionDefinition(;
            name=:residual_norm,
            type=String,
            default=Options.NotProvided,
            description="Norm used for the residuals. Determines how residuals are measured for convergence.",
            validator=x ->
                x in ["L1", "L2", "INF"] || throw(
                    Exceptions.IncorrectArgument(
                        "Invalid residual_norm value";
                        got="residual_norm=$x",
                        expected="L1, L2, or INF",
                        suggestion="Use INF (default) for maximum norm, L1 for sum, or L2 for Euclidean",
                        context="Uno residual_norm validation",
                    ),
                ),
        ),

        # ====================================================================
        # Main options - Numerical options
        # ====================================================================
        Strategies.OptionDefinition(;
            name=:residual_scaling_threshold,
            type=Real,
            default=Options.NotProvided,
            description="Scaling factor in stationarity and complementarity residuals. Controls how residuals are scaled for convergence checks.",
            validator=x ->
                x > 0 || throw(
                    Exceptions.IncorrectArgument(
                        "Invalid residual_scaling_threshold value";
                        got="residual_scaling_threshold=$x",
                        expected="positive real number (> 0)",
                        suggestion="Use 100.0 (default) or adjust based on problem scaling",
                        context="Uno residual_scaling_threshold validation",
                    ),
                ),
        ),
        Strategies.OptionDefinition(;
            name=:protect_actual_reduction_against_roundoff,
            type=Bool,
            default=Options.NotProvided,
            description="Whether the actual reduction is slightly modified to account for roundoff errors. Can improve numerical stability.",
        ),
        Strategies.OptionDefinition(;
            name=:protected_actual_reduction_macheps_coefficient,
            type=Real,
            default=Options.NotProvided,
            description="Coefficient of the machine epsilon in the protected actual reduction. Only used if protect_actual_reduction_against_roundoff is true.",
            validator=x ->
                x > 0 || throw(
                    Exceptions.IncorrectArgument(
                        "Invalid protected_actual_reduction_macheps_coefficient value";
                        got="protected_actual_reduction_macheps_coefficient=$x",
                        expected="positive real number (> 0)",
                        suggestion="Use 10.0 (default) or adjust for numerical stability",
                        context="Uno protected_actual_reduction_macheps_coefficient validation",
                    ),
                ),
        ),
        Strategies.OptionDefinition(;
            name=:print_subproblem,
            type=Bool,
            default=false,
            description="Whether the subproblem is printed in DEBUG mode. Useful for debugging subproblem formulations.",
        ),

    )
end

# ============================================================================
# Constructor implementation
# ============================================================================

"""
$(TYPEDSIGNATURES)

Build a Uno solver with validated options.

# Arguments
- `mode::Symbol=:strict`: Validation mode (`:strict` or `:permissive`)
  - `:strict` (default): Rejects unknown options with detailed error message
  - `:permissive`: Accepts unknown options with warning, stores with `:user` source
- `kwargs...`: Options to pass to the Uno constructor

# Example

```julia
# Conceptual usage
solver = build_uno_solver(UnoTag; max_iterations=1000)
solver_permissive = build_uno_solver(UnoTag; max_iterations=1000, custom_option=123; mode=:permissive)
```

See also: `Solvers.Uno`, `Strategies.build_strategy_options`
"""
function Solvers.build_uno_solver(
    ::Type{Solvers.UnoTag},
    parameter::Type{<:AbstractStrategyParameter};
    mode::Symbol=:strict,
    kwargs...,
)
    opts = Strategies.build_strategy_options(Solvers.Uno{parameter}; mode=mode, kwargs...)
    return Solvers.Uno{parameter}(opts)
end

# ============================================================================
# Callable interface with display handling
# ============================================================================

"""
$(TYPEDSIGNATURES)

Solve an NLP problem using Uno.

# Arguments
- `nlp::NLPModels.AbstractNLPModel`: The NLP problem to solve
- `display::Bool`: Whether to show solver output (default: true)

# Returns
- `UnoSolver.Statistics`: Solver execution statistics
"""
function (solver::Solvers.Uno)(
    nlp::NLPModels.AbstractNLPModel; display::Bool=true
)::UnoSolver.Statistics
    options = Strategies.options_dict(solver)
    options[:logger] = display ? options[:logger] : "SILENT"
    return solve_with_uno(nlp; options...)
end

# ============================================================================
# Backend solver interface
# ============================================================================

"""
$(TYPEDSIGNATURES)

Backend interface for Uno solver.

Solves the NLP problem using UnoSolver backend.

# Arguments
- `nlp::NLPModels.AbstractNLPModel`: The NLP problem to solve
- `options...`: Uno options as keyword arguments

# Returns
- `UnoSolver.Statistics`: Solver execution statistics

See also: `Solvers.Uno`, `UnoSolver.solve`
"""
function solve_with_uno(
    nlp::NLPModels.AbstractNLPModel; kwargs...
)::UnoSolver.Statistics
    return UnoSolver.uno(nlp; kwargs...)
end


"""
$(TYPEDSIGNATURES)

Extract solver information from Uno execution statistics.

# Arguments
- `nlp_solution::UnoSolver.Statistics`: Uno execution statistics

# Returns
A 6-element tuple `(objective, iterations, constraints_violation, message, status, successful)`:
- `objective::Float64`: The final objective value
- `iterations::Int`: Number of iterations performed
- `constraints_violation::Float64`: Maximum constraint violation (primal feasibility)
- `message::String`: Solver identifier string ("Uno")
- `status::Symbol`: Termination status from SolverCore
- `successful::Bool`: Whether the solver converged successfully
"""
function Optimization.extract_solver_infos(nlp_solution::UnoSolver.Statistics)
    objective = nlp_solution.solution_objective
    iterations = nlp_solution.number_iterations
    constraints_violation = nlp_solution.solution_primal_feasibility
    status = nlp_solution.solution_status
    successful = (status == UnoSolver.UNO_FEASIBLE_KKT_POINT) || (status == UnoSolver.UNO_FEASIBLE_FJ_POINT)
    return objective, iterations, constraints_violation, "Uno", Symbol(status), successful
end

end
