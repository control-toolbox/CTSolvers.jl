# ------------------------------------------------------------------------------
# Generic solver method
# ------------------------------------------------------------------------------
abstract type AbstractOptimizationSolver end

function CommonSolve.solve(
    ocp::AbstractOptimalControlProblem,
    initial_guess,
    discretizer::AbstractOptimalControlDiscretizer,
    modeler::AbstractOptimizationModeler,
    solver::AbstractOptimizationSolver;
    display::Bool=__display(),
)::AbstractOptimalControlSolution

    # Validate initial guess against the optimal control problem before discretization.
    # Any inconsistency should trigger a CTBase.IncorrectArgument from the validator.
    normalized_init = build_initial_guess(ocp, initial_guess)
    validate_initial_guess(ocp, normalized_init)

    discrete_problem = discretize(ocp, discretizer)
    return CommonSolve.solve(discrete_problem, normalized_init, modeler, solver; display=display)
end

function CommonSolve.solve(
    problem::AbstractOptimizationProblem,
    initial_guess,
    modeler::AbstractOptimizationModeler,
    solver::AbstractOptimizationSolver;
    display::Bool=__display(),
)
    nlp = build_model(problem, initial_guess, modeler)
    nlp_solution = CommonSolve.solve(nlp, solver; display=display)
    solution = build_solution(problem, nlp_solution, modeler)
    return solution
end

function CommonSolve.solve(
    nlp::NLPModels.AbstractNLPModel,
    solver::AbstractOptimizationSolver;
    display::Bool=__display(),
)::SolverCore.AbstractExecutionStats
    return solver(nlp; display=display)
end

# to let freedom to the user
function CommonSolve.solve(
    nlp,
    solver::AbstractOptimizationSolver;
    display::Bool=__display(),
)
    return solver(nlp; display=display)
end