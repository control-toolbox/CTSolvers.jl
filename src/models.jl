# ------------------------------------------------------------------------------
# Problem definition
# ------------------------------------------------------------------------------
struct ADNLPModelBuilder{T<:Function}
    build_adnlp_model::T
end
function (prob::ADNLPModelBuilder)(initial_guess; kwargs...)::ADNLPModels.ADNLPModel
    return prob.build_adnlp_model(initial_guess; kwargs...)
end

struct ExaModelBuilder{T<:Function}
    build_exa_model::T
end
function (prob::ExaModelBuilder)(
    ::Type{BaseType}, initial_guess; kwargs...
)::ExaModels.ExaModel where {BaseType<:AbstractFloat}
    return prob.build_exa_model(BaseType, initial_guess; kwargs...)
end

abstract type AbstractCTOptimizationProblem end

function get_build_exa_model(prob::AbstractCTOptimizationProblem)
    return throw(
        CTBase.NotImplemented("get_build_exa_model not implemented for $(typeof(prob))")
    )
end

function get_build_adnlp_model(prob::AbstractCTOptimizationProblem)
    return throw(
        CTBase.NotImplemented("get_build_adnlp_model not implemented for $(typeof(prob))")
    )
end

# ------------------------------------------------------------------------------
# NLP Model builder
# ------------------------------------------------------------------------------
abstract type AbstractNLPModelBackend end

function nlp_model(
    prob::AbstractCTOptimizationProblem, initial_guess, modeler::AbstractNLPModelBackend
)::NLPModels.AbstractNLPModel
    return modeler(prob, initial_guess)
end

# ------------------------------------------------------------------------------
# Model backends
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# ADNLPModels
struct ADNLPModelBackend{EmptyBackends<:Tuple{Vararg{Symbol}},KW} <: AbstractNLPModelBackend
    # attributes
    show_time::Bool
    backend::Symbol
    empty_backends::EmptyBackends
    kwargs::KW

    # constructor
    function ADNLPModelBackend(;
        show_time::Bool=__adnlp_model_show_time(),
        backend::Symbol=__adnlp_model_backend(),
        empty_backends::EmptyBackends=__adnlp_model_empty_backends(),
        kwargs...,
    ) where {EmptyBackends<:Tuple{Vararg{Symbol}}}
        return new{EmptyBackends,typeof(kwargs)}(show_time, backend, empty_backends, kwargs)
    end
end

function (modeler::ADNLPModelBackend)(
    prob::AbstractCTOptimizationProblem, initial_guess
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
    return get_build_adnlp_model(prob)(
        initial_guess; show_time=modeler.show_time, backend_options..., modeler.kwargs...
    )
end

# ------------------------------------------------------------------------------
# ExaModels
struct ExaModelBackend{
    BaseType<:AbstractFloat,BackendType<:Union{Nothing,KernelAbstractions.Backend},KW
} <: AbstractNLPModelBackend
    backend::BackendType
    kwargs::KW
    function ExaModelBackend(;
        base_type::Type{<:AbstractFloat}=__exa_model_base_type(),
        backend::Union{Nothing,KernelAbstractions.Backend}=__exa_model_backend(),
        kwargs...,
    )
        return new{base_type,typeof(backend),typeof(kwargs)}(backend, kwargs)
    end
end

function (modeler::ExaModelBackend{BaseType,BackendType,KW})(
    prob::AbstractCTOptimizationProblem, initial_guess
)::ExaModels.ExaModel{BaseType} where {BaseType,BackendType,KW}
    return get_build_exa_model(prob)(
        BaseType, initial_guess; backend=modeler.backend, modeler.kwargs...
    )
end
