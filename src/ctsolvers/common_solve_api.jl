# ------------------------------------------------------------------------------
# Generic solver method
# ------------------------------------------------------------------------------
abstract type AbstractOptimizationSolver end

function CommonSolve.solve(
    problem::AbstractOptimizationProblem,
    initial_guess,
    modeler::AbstractOptimizationModeler,
    solver::AbstractOptimizationSolver;
    display::Bool,
)
    nlp = build_model(problem, initial_guess, modeler)
    nlp_solution = CommonSolve.solve(nlp, solver; display=display)
    solution = build_solution(problem, nlp_solution, modeler)
    return solution
end

function CommonSolve.solve(
    nlp::NLPModels.AbstractNLPModel,
    solver::AbstractOptimizationSolver;
    display::Bool,
)::SolverCore.AbstractExecutionStats
    return solver(nlp; display=display)
end

# to let freedom to the user
function CommonSolve.solve(
    nlp,
    solver::AbstractOptimizationSolver;
    display::Bool,
)
    return solver(nlp; display=display)
end