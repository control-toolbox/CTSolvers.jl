# Helper types
abstract type AbstractNLPSolutionHelper <: CTSolvers.AbstractCTHelper end
struct ADNLPSolutionHelper <: AbstractNLPSolutionHelper end
struct ExaSolutionHelper <: AbstractNLPSolutionHelper end

#
struct OptimizationProblem <: CTSolvers.AbstractOptimizationProblem
    build_adnlp_model::CTSolvers.ADNLPModelBuilder
    build_exa_model::CTSolvers.ExaModelBuilder
    adnlp_solution_helper::ADNLPSolutionHelper
    exa_solution_helper::ExaSolutionHelper
end

function CTSolvers.get_adnlp_model_builder(prob::OptimizationProblem)
    return prob.build_adnlp_model
end

function CTSolvers.get_exa_model_builder(prob::OptimizationProblem)
    return prob.build_exa_model
end

function CTSolvers.get_adnlp_solution_helper(prob::OptimizationProblem)
    return prob.adnlp_solution_helper
end

function CTSolvers.get_exa_solution_helper(prob::OptimizationProblem)
    return prob.exa_solution_helper
end

function CTSolvers.build_solution(
    nlp_solution::SolverCore.AbstractExecutionStats,
    ::AbstractNLPSolutionHelper
)
    return nlp_solution
end

#
struct DummyProblem <: CTSolvers.AbstractOptimizationProblem end
