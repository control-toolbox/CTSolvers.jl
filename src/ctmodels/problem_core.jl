# ------------------------------------------------------------------------------
# Problem definition
# ------------------------------------------------------------------------------
# builders of NLP models
abstract type AbstractCTModelBuilder end

struct ADNLPModelBuilder{T<:Function} <: AbstractCTModelBuilder
    f::T
end
function (builder::ADNLPModelBuilder)(initial_guess; kwargs...)::ADNLPModels.ADNLPModel
    return builder.f(initial_guess; kwargs...)
end

struct ExaModelBuilder{T<:Function} <: AbstractCTModelBuilder
    f::T
end
function (builder::ExaModelBuilder)(
    ::Type{BaseType}, initial_guess; kwargs...
)::ExaModels.ExaModel where {BaseType<:AbstractFloat}
    return builder.f(BaseType, initial_guess; kwargs...)
end

# helpers to build solutions
abstract type AbstractCTSolutionHelper end

# problem
abstract type AbstractCTOptimizationProblem end

function get_exa_model_builder(prob::AbstractCTOptimizationProblem)
    throw(
        CTBase.NotImplemented("get_exa_model_builder not implemented for $(typeof(prob))")
    )
end

function get_adnlp_model_builder(prob::AbstractCTOptimizationProblem)
    throw(
        CTBase.NotImplemented("get_adnlp_model_builder not implemented for $(typeof(prob))")
    )
end

function get_adnlp_solution_helper(prob::AbstractCTOptimizationProblem)
    throw(
        CTBase.NotImplemented("get_adnlp_solution_helper not implemented for $(typeof(prob))")
    )
end

function get_exa_solution_helper(prob::AbstractCTOptimizationProblem)
    throw(
        CTBase.NotImplemented("get_exa_solution_helper not implemented for $(typeof(prob))")
    )
end
