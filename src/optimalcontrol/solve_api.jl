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
    ocp::AbstractOptimalControlProblem;
    initial_guess,
    discretizer::AbstractOptimalControlDiscretizer,
    modeler::AbstractOptimizationModeler,
    solver::AbstractOptimizationSolver,
    display::Bool=__display(),
)::AbstractOptimalControlSolution
    return CommonSolve.solve(ocp, initial_guess, discretizer, modeler, solver; display=display)
end