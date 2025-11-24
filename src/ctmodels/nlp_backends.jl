# ------------------------------------------------------------------------------
# Model backends
# ------------------------------------------------------------------------------
abstract type AbstractOptimizationModeler end

# ------------------------------------------------------------------------------
# ADNLPModels
# ------------------------------------------------------------------------------
struct ADNLPModeler{KW} <: AbstractOptimizationModeler
    # attributes
    show_time::Bool
    backend::Symbol
    kwargs::KW

    # constructor
    function ADNLPModeler(;
        show_time::Bool=__adnlp_model_show_time(),
        backend::Symbol=__adnlp_model_backend(),
        kwargs...,
    )
        return new{typeof(kwargs)}(show_time, backend, kwargs)
    end
end

function (modeler::ADNLPModeler)(
    prob::AbstractOptimizationProblem, 
    initial_guess,
)::ADNLPModels.ADNLPModel
    builder = get_adnlp_model_builder(prob)
    return builder(
        initial_guess; show_time=modeler.show_time, backend=modeler.backend, modeler.kwargs...
    )
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
struct ExaModeler{
    BaseType<:AbstractFloat,BackendType<:Union{Nothing,KernelAbstractions.Backend},KW
} <: AbstractOptimizationModeler
    backend::BackendType
    kwargs::KW
    function ExaModeler(;
        base_type::Type{<:AbstractFloat}=__exa_model_base_type(),
        backend::Union{Nothing,KernelAbstractions.Backend}=__exa_model_backend(),
        kwargs...,
    )
        return new{base_type,typeof(backend),typeof(kwargs)}(backend, kwargs)
    end
end

function (modeler::ExaModeler{BaseType,BackendType,KW})(
    prob::AbstractOptimizationProblem, 
    initial_guess,
)::ExaModels.ExaModel{BaseType} where {BaseType<:AbstractFloat,BackendType<:Union{Nothing,KernelAbstractions.Backend},KW}
    builder = get_exa_model_builder(prob)
    return builder(
        BaseType, initial_guess; backend=modeler.backend, modeler.kwargs...
    )
end

function (modeler::ExaModeler)(
    prob::AbstractOptimizationProblem, 
    nlp_solution::SolverCore.AbstractExecutionStats,
)
    builder = get_exa_solution_builder(prob)
    return builder(nlp_solution)
end
