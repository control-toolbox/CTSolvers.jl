#
struct OptimizationProblem <: CTSolvers.AbstractCTOptimizationProblem
    build_adnlp_model::CTSolvers.ADNLPModelBuilder
    build_exa_model::CTSolvers.ExaModelBuilder
end
function CTSolvers.get_build_adnlp_model(prob::OptimizationProblem)
    return prob.build_adnlp_model
end
function CTSolvers.get_build_exa_model(prob::OptimizationProblem)
    return prob.build_exa_model
end

#
struct DummyProblem <: CTSolvers.AbstractCTOptimizationProblem end