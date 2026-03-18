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
using NLPModels: NLPModels
using SolverCore: SolverCore
using UnoSolver: UnoSolver

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
            aliases=(:maxiter, :max_iter, :maxit),
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
            aliases=(:max_wall_time, :maxtime, :max_time),
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
                x in
                ["SILENT", "DISCRETE", "WARNING", "INFO", "DEBUG", "DEBUG2", "DEBUG3"] ||
                throw(
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
# Status conversion utilities
# ============================================================================

"""
$(TYPEDSIGNATURES)

Map Uno termination and solution statuses to SolverCore status symbols.

Converts the combination of Uno's optimization status and solution status into
a single SolverCore-compatible status symbol. This mapping follows Uno's MOI
conventions and ensures compatibility with the CTSolvers pipeline.

# Arguments
- `optimization_status::Cint`: Uno optimization termination status (e.g., `UNO_SUCCESS`, `UNO_ITERATION_LIMIT`)
- `solution_status::Cint`: Uno solution quality status (e.g., `UNO_FEASIBLE_KKT_POINT`, `UNO_UNBOUNDED`)

# Returns
- `Symbol`: SolverCore-compatible status symbol

# Status Mapping

## Termination-based statuses
- `UNO_ITERATION_LIMIT` → `:max_iter`
- `UNO_TIME_LIMIT` → `:max_time`
- `UNO_EVALUATION_ERROR` → `:exception`
- `UNO_ALGORITHMIC_ERROR` → `:exception`
- `UNO_USER_TERMINATION` → `:user`

## Success-based statuses (when `optimization_status == UNO_SUCCESS`)
- `UNO_FEASIBLE_KKT_POINT` → `:first_order`
- `UNO_FEASIBLE_FJ_POINT` → `:first_order`
- `UNO_INFEASIBLE_STATIONARY_POINT` → `:infeasible`
- `UNO_FEASIBLE_SMALL_STEP` → `:small_step`
- `UNO_INFEASIBLE_SMALL_STEP` → `:small_step`
- `UNO_UNBOUNDED` → `:unbounded`
- `UNO_NOT_OPTIMAL` → `:unknown`

# Notes
- The function prioritizes termination status over solution status
- When optimization succeeds, the solution status determines the final status
- This mapping ensures Ipopt-compatible status reporting

See also: [`_uno_to_generic_stats`](@ref)
"""
function _uno_status_to_solvercore(optimization_status::Cint, solution_status::Cint)::Symbol
    if optimization_status == UnoSolver.UNO_ITERATION_LIMIT
        return :max_iter
    elseif optimization_status == UnoSolver.UNO_TIME_LIMIT
        return :max_time
    elseif optimization_status == UnoSolver.UNO_EVALUATION_ERROR
        return :exception
    elseif optimization_status == UnoSolver.UNO_ALGORITHMIC_ERROR
        return :exception
    elseif optimization_status == UnoSolver.UNO_USER_TERMINATION
        return :user
    else # UNO_SUCCESS
        if solution_status == UnoSolver.UNO_FEASIBLE_KKT_POINT
            return :first_order
        elseif solution_status == UnoSolver.UNO_FEASIBLE_FJ_POINT
            return :first_order
        elseif solution_status == UnoSolver.UNO_INFEASIBLE_STATIONARY_POINT
            return :infeasible
        elseif solution_status == UnoSolver.UNO_FEASIBLE_SMALL_STEP
            return :small_step
        elseif solution_status == UnoSolver.UNO_INFEASIBLE_SMALL_STEP
            return :small_step
        elseif solution_status == UnoSolver.UNO_UNBOUNDED
            return :unbounded
        else # UNO_NOT_OPTIMAL
            return :unknown
        end
    end
end

"""
$(TYPEDSIGNATURES)

Convert Uno solver statistics to SolverCore generic execution statistics.

Transforms UnoSolver.Statistics into SolverCore.GenericExecutionStats to enable
seamless integration with the CTSolvers pipeline. All fields are marked as reliable
since Uno provides complete statistics.

# Arguments
- `nlp::NLPModels.AbstractNLPModel`: The NLP model that was solved (required for GenericExecutionStats constructor)
- `uno_stats::UnoSolver.Statistics`: Uno solver execution statistics containing solution and performance data

# Returns
- `SolverCore.GenericExecutionStats`: Converted statistics with all fields marked as reliable

# Field Mapping

The following fields are mapped from Uno statistics to GenericExecutionStats:

- `status` ← converted from `optimization_status` and `solution_status` via `_uno_status_to_solvercore`
- `solution` ← `primal_solution`
- `objective` ← `solution_objective`
- `dual_feas` ← `solution_stationarity` (dual feasibility/stationarity residual)
- `primal_feas` ← `solution_primal_feasibility` (constraint violation)
- `multipliers` ← `constraint_dual_solution` (Lagrange multipliers for constraints)
- `multipliers_L` ← `lower_bound_dual_solution` (multipliers for lower bounds)
- `multipliers_U` ← `upper_bound_dual_solution` (multipliers for upper bounds)
- `iter` ← `number_iterations` (converted to Int)
- `elapsed_time` ← `cpu_time`

# Notes
- All fields in the returned GenericExecutionStats are marked as reliable
- Uno-specific information (complementarity, evaluation counts, model, solver) is not preserved
- For full Uno statistics preservation, consider using a specialized UnoExecutionStats type

See also: [`_uno_status_to_solvercore`](@ref), [`solve_with_uno`](@ref)
"""
function _uno_to_generic_stats(
    nlp::NLPModels.AbstractNLPModel, uno_stats::UnoSolver.Statistics
)::SolverCore.GenericExecutionStats
    # Map Uno status to SolverCore status
    status = _uno_status_to_solvercore(
        uno_stats.optimization_status, uno_stats.solution_status
    )

    # Create GenericExecutionStats with all fields marked as reliable
    stats = SolverCore.GenericExecutionStats(
        nlp;
        status=status,
        solution=uno_stats.primal_solution,
        objective=uno_stats.solution_objective,
        dual_feas=uno_stats.solution_stationarity,
        primal_feas=uno_stats.solution_primal_feasibility,
        multipliers=uno_stats.constraint_dual_solution,
        multipliers_L=uno_stats.lower_bound_dual_solution,
        multipliers_U=uno_stats.upper_bound_dual_solution,
        iter=Int(uno_stats.number_iterations),
        elapsed_time=uno_stats.cpu_time,
    )

    return stats
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
- `SolverCore.GenericExecutionStats`: Solver execution statistics
"""
function (solver::Solvers.Uno)(
    nlp::NLPModels.AbstractNLPModel; display::Bool=true
)::SolverCore.GenericExecutionStats
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
- `SolverCore.GenericExecutionStats`: Solver execution statistics

See also: `Solvers.Uno`, `UnoSolver.solve`
"""
function solve_with_uno(
    nlp::NLPModels.AbstractNLPModel; kwargs...
)::SolverCore.GenericExecutionStats
    uno_stats = UnoSolver.uno(nlp; kwargs...)
    return _uno_to_generic_stats(nlp, uno_stats)
end

end
