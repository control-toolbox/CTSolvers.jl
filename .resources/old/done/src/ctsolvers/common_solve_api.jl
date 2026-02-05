# ------------------------------------------------------------------------------
# Generic solver method
# ------------------------------------------------------------------------------
abstract type AbstractOptimizationSolver <: CTModels.AbstractOCPTool end

__display() = true

function CommonSolve.solve(
    problem::CTModels.AbstractOptimizationProblem,
    initial_guess,
    modeler::CTModels.AbstractOptimizationModeler,
    solver::CTSolvers.AbstractOptimizationSolver;
    display::Bool=__display(),
)
    nlp = CTModels.build_model(problem, initial_guess, modeler)
    nlp_solution = CommonSolve.solve(nlp, solver; display=display)
    solution = CTModels.build_solution(problem, nlp_solution, modeler)
    return solution
end

function CommonSolve.solve(
    nlp::NLPModels.AbstractNLPModel,
    solver::CTSolvers.AbstractOptimizationSolver;
    display::Bool=__display(),
)::SolverCore.AbstractExecutionStats
    return solver(nlp; display=display)
end

# to let freedom to the user
function CommonSolve.solve(
    nlp, solver::CTSolvers.AbstractOptimizationSolver; display::Bool=__display()
)
    return solver(nlp; display=display)
end
