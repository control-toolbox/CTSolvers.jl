# ------------------------------------------------------------------------------
# NLP Model and Solution builders
# ------------------------------------------------------------------------------
function build_model(
    prob::AbstractCTOptimizationProblem, initial_guess, modeler::AbstractNLPModelBackend
)::NLPModels.AbstractNLPModel
    return modeler(prob, initial_guess)
end

function nlp_model(
    prob::AbstractCTOptimizationProblem, initial_guess, modeler::AbstractNLPModelBackend
)::NLPModels.AbstractNLPModel
    return build_model(prob, initial_guess, modeler)
end

function build_solution(
    prob::AbstractCTOptimizationProblem, nlp_solution::SolverCore.AbstractExecutionStats, modeler::AbstractNLPModelBackend
)
    return modeler(prob, nlp_solution)
end

function ocp_solution(
    docp::DiscretizedOptimalControlProblem, nlp_solution::SolverCore.AbstractExecutionStats, modeler::AbstractNLPModelBackend
)::CTModels.AbstractSolution
    return build_solution(docp, nlp_solution, modeler)
end

function build_solution(::SolverCore.AbstractExecutionStats, helper::AbstractCTSolutionHelper)
    throw(
        CTBase.NotImplemented("build_solution not implemented for $(typeof(helper))")
    )
end
