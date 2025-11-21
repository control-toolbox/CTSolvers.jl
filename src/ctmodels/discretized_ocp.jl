# ------------------------------------------------------------------------------
# Discretized optimal control problem
# ------------------------------------------------------------------------------
# Helpers
abstract type AbstractOCPSolutionHelper <: AbstractCTSolutionHelper end

struct ADNLPModelOCPSolutionHelper{T<:Function} <: AbstractOCPSolutionHelper
    f::T
end
function (helper::ADNLPModelOCPSolutionHelper)(nlp_solution::SolverCore.AbstractExecutionStats, val::Symbol)
    return helper.f(nlp_solution, val)
end

struct ExaModelOCPSolutionHelper{T<:Function} <: AbstractOCPSolutionHelper
    f::T
end
function (helper::ExaModelOCPSolutionHelper)(nlp_solution::SolverCore.AbstractExecutionStats, val::Symbol)
    return helper.f(nlp_solution, val)
end

# Problem
struct DiscretizedOptimalControlProblem{
    TOC <:CTModels.Model,
    TAB <:ADNLPModelBuilder, 
    TEB <:ExaModelBuilder,
    TAH <:ADNLPModelOCPSolutionHelper,
    TEH <:ExaModelOCPSolutionHelper,
} <: AbstractCTOptimizationProblem
    optimal_control_problem::TOC
    build_adnlp_model::TAB
    build_exa_model::TEB
    adnlp_solution_helper::TAH
    exa_solution_helper::TEH
end

function ocp_model(
    prob::DiscretizedOptimalControlProblem{
        TOC,
        <:ADNLPModelBuilder,
        <:ExaModelBuilder,
        <:ADNLPModelOCPSolutionHelper,
        <:ExaModelOCPSolutionHelper,
    }
)::TOC where {TOC<:CTModels.Model}
    return prob.optimal_control_problem
end

function get_adnlp_model_builder(
    prob::DiscretizedOptimalControlProblem{
        <:CTModels.Model,
        TAB, 
        <:ExaModelBuilder,
        <:ADNLPModelOCPSolutionHelper,
        <:ExaModelOCPSolutionHelper,
    }
)::TAB where {TAB<:ADNLPModelBuilder}
    return prob.build_adnlp_model
end

function get_exa_model_builder(
    prob::DiscretizedOptimalControlProblem{
        <:CTModels.Model,
        <:ADNLPModelBuilder, 
        TEB,
        <:ADNLPModelOCPSolutionHelper,
        <:ExaModelOCPSolutionHelper,
    }
)::TEB where {TEB<:ExaModelBuilder}
    return prob.build_exa_model
end

function get_adnlp_solution_helper(
    prob::DiscretizedOptimalControlProblem{
        <:CTModels.Model,
        <:ADNLPModelBuilder, 
        <:ExaModelBuilder,
        TAH,
        <:ExaModelOCPSolutionHelper,
    }
)::TAH where {TAH<:ADNLPModelOCPSolutionHelper}
    return prob.adnlp_solution_helper
end

function get_exa_solution_helper(
    prob::DiscretizedOptimalControlProblem{
        <:CTModels.Model,
        <:ADNLPModelBuilder, 
        <:ExaModelBuilder,
        <:ADNLPModelOCPSolutionHelper,
        TEH,
    }
)::TEH where {TEH<:ExaModelOCPSolutionHelper}
    return prob.exa_solution_helper
end
