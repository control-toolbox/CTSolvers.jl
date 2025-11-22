# ------------------------------------------------------------------------------
# Discretized optimal control problem
# ------------------------------------------------------------------------------
# Helpers
abstract type AbstractOCPHelper <: AbstractCTHelper end

struct ADNLPModelerOCPHelper{T<:Function} <: AbstractOCPHelper
    f::T
end
function (helper::ADNLPModelerOCPHelper)(
    nlp_solution::SolverCore.AbstractExecutionStats, 
    val::Symbol,
)
    return helper.f(nlp_solution, val)
end

struct ExaModelerOCPHelper{T<:Function} <: AbstractOCPHelper
    f::T
end
function (helper::ExaModelerOCPHelper)(
    nlp_solution::SolverCore.AbstractExecutionStats, 
    val::Symbol,
)
    return helper.f(nlp_solution, val)
end

# Problem
struct DiscretizedOptimalControlProblem{
    TO <:AbstractOptimalControlProblem,
    TB <:Tuple{Vararg{Pair{Symbol,<:AbstractModelBuilder}}},
    TH <:Tuple{Vararg{Pair{Symbol,<:AbstractOCPHelper}}},
} <: AbstractOptimizationProblem
    optimal_control_problem::TO
    model_builders::TB
    solution_helpers::TH
    function DiscretizedOptimalControlProblem(
        optimal_control_problem::TO,
        model_builders::TB,
        solution_helpers::TH,
    ) where {
        TO <:AbstractOptimalControlProblem,
        TB <:Tuple{Vararg{Pair{Symbol,<:AbstractModelBuilder}}},
        TH <:Tuple{Vararg{Pair{Symbol,<:AbstractOCPHelper}}},
    }
        return new{TO, TB, TH}(optimal_control_problem, model_builders, solution_helpers)
    end
    function DiscretizedOptimalControlProblem(
        optimal_control_problem::AbstractOptimalControlProblem,
        adnlpmodel_builder::ADNLPModelBuilder,
        examodel_builder::ExaModelBuilder,
        adnlpmodel_helper::ADNLPModelerOCPHelper,
        examodel_helper::ExaModelerOCPHelper,
    )
        return DiscretizedOptimalControlProblem(
            optimal_control_problem,
            (:adnlpmodel => adnlpmodel_builder, :examodel => examodel_builder),
            (:adnlpmodel => adnlpmodel_helper, :examodel => examodel_helper),
        )
    end
end

function ocp_model(prob::DiscretizedOptimalControlProblem)
    return prob.optimal_control_problem
end

function get_adnlp_model_builder(prob::DiscretizedOptimalControlProblem)
    if !hasfield(typeof(prob), :adnlpmodel)
        throw(ArgumentError("adnlpmodel is not a field of $(typeof(prob))"))
    end
    return getfield(prob.model_builders, :adnlpmodel)
end

function get_exa_model_builder(prob::DiscretizedOptimalControlProblem)
    if !hasfield(typeof(prob), :examodel)
        throw(ArgumentError("examodel is not a field of $(typeof(prob))"))
    end
    return getfield(prob.model_builders, :examodel)
end

function get_adnlp_solution_helper(prob::DiscretizedOptimalControlProblem)
    if !hasfield(typeof(prob), :adnlpmodel)
        throw(ArgumentError("adnlpmodel is not a field of $(typeof(prob))"))
    end
    return getfield(prob.solution_helpers, :adnlpmodel)
end

function get_exa_solution_helper(prob::DiscretizedOptimalControlProblem)
    if !hasfield(typeof(prob), :examodel)
        throw(ArgumentError("examodel is not a field of $(typeof(prob))"))
    end
    return getfield(prob.solution_helpers, :examodel)
end
