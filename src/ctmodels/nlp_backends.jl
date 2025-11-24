# ------------------------------------------------------------------------------
# Model backends
# ------------------------------------------------------------------------------
abstract type AbstractOptimizationModeler end

# ------------------------------------------------------------------------------
# ADNLPModels
# ------------------------------------------------------------------------------
struct ADNLPModeler{T<:Tuple} <: AbstractOptimizationModeler
    options::T
end

function (modeler::ADNLPModeler)(
    prob::AbstractOptimizationProblem, 
    initial_guess,
)::ADNLPModels.ADNLPModel
    # build the model
    builder = get_adnlp_model_builder(prob)
    return builder(initial_guess; modeler.options...)
end

function (modeler::ADNLPModeler)(
    prob::AbstractOptimizationProblem, 
    nlp_solution::SolverCore.AbstractExecutionStats
)
    builder = get_adnlp_solution_builder(prob)
    return builder(nlp_solution)
end

# ------------------------------------------------------------------------------
# ExaModels
# ------------------------------------------------------------------------------
struct ExaModeler{BaseType<:AbstractFloat,T<:Tuple} <: AbstractOptimizationModeler
    options::T
end

ExaModeler{BaseType}(options::T) where {BaseType<:AbstractFloat,T<:Tuple} =
    ExaModeler{BaseType,T}(options)

function (modeler::ExaModeler{BaseType,T})(
    prob::AbstractOptimizationProblem, 
    initial_guess,
)::ExaModels.ExaModel{BaseType} where {BaseType<:AbstractFloat,T<:Tuple}
    builder = get_exa_model_builder(prob)
    return builder(BaseType, initial_guess; modeler.options...)
end

function (modeler::ExaModeler)(
    prob::AbstractOptimizationProblem, 
    nlp_solution::SolverCore.AbstractExecutionStats,
)
    builder = get_exa_solution_builder(prob)
    return builder(nlp_solution)
end
