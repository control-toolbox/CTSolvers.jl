# ------------------------------------------------------------------------------
# Generic solver method
# ------------------------------------------------------------------------------
abstract type AbstractNLPSolverBackend end

function CommonSolve.solve(
    prob::AbstractCTOptimizationProblem,
    initial_guess,
    modeler::AbstractNLPModelBackend,
    solver::AbstractNLPSolverBackend;
    display::Bool=__display(),
)::SolverCore.AbstractExecutionStats
    nlp = build_model(prob, initial_guess, modeler)
    nlp_solution = solver(nlp; display=display)
    solution = build_solution(prob, nlp_solution, modeler)
    return solution
end
