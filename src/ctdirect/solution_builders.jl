function build_solution(
    nlp_solution::SolverCore.AbstractExecutionStats,
    ::AbstractOCPHelper,
) # must return a CTModels.AbstractSolution
    return nlp_solution
end