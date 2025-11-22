# ------------------------------------------------------------------------------
# Model backends
# ------------------------------------------------------------------------------
abstract type AbstractOptimizationModeler end

# ------------------------------------------------------------------------------
# ADNLPModels
# ------------------------------------------------------------------------------
struct ADNLPModeler{EmptyBackends<:Tuple{Vararg{Symbol}},KW} <: AbstractOptimizationModeler
    # attributes
    show_time::Bool
    backend::Symbol
    empty_backends::EmptyBackends
    kwargs::KW

    # constructor
    function ADNLPModeler(;
        show_time::Bool=__adnlp_model_show_time(),
        backend::Symbol=__adnlp_model_backend(),
        empty_backends::EmptyBackends=__adnlp_model_empty_backends(),
        kwargs...,
    ) where {EmptyBackends<:Tuple{Vararg{Symbol}}}
        return new{EmptyBackends,typeof(kwargs)}(show_time, backend, empty_backends, kwargs)
    end
end

function (modeler::ADNLPModeler)(
    prob::AbstractOptimizationProblem, 
    initial_guess,
)::ADNLPModels.ADNLPModel

    # build the empty backends
    empty_backends = Dict{Symbol,Type{ADNLPModels.EmptyADbackend}}()
    for backend in modeler.empty_backends
        empty_backends[backend] = ADNLPModels.EmptyADbackend
    end

    # build the backend options
    backend_options = if modeler.backend==:manual # we define the AD backend manually with sparsity pattern (OCP)
        (
            gradient_backend=ADNLPModels.ReverseDiffADGradient,
            jacobian_backend=ADNLPModels.SparseADJacobian,
            hessian_backend=ADNLPModels.SparseReverseADHessian,
            empty_backends...,
        )
    else
        (backend=modeler.backend, empty_backends...)
    end

    # build the model
    builder = get_adnlp_model_builder(prob)
    return builder(
        initial_guess; show_time=modeler.show_time, backend_options..., modeler.kwargs...
    )
end

function (modeler::ADNLPModeler)(
    prob::AbstractOptimizationProblem, 
    nlp_solution::SolverCore.AbstractExecutionStats
)
    helper = get_adnlp_solution_helper(prob)
    return build_solution(nlp_solution, helper)
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
    helper = get_exa_solution_helper(prob)
    return build_solution(nlp_solution, helper)
end
