# ------------------------------------------------------------------------------
# Problems definition
struct ADNLPProblem
    build_adnlp_model::Function
end
function (prob::ADNLPProblem)(
    initial_guess::AbstractVector;
    kwargs...
)::ADNLPModels.ADNLPModel
    return prob.build_adnlp_model(initial_guess; kwargs...)
end

struct ExaProblem
    build_exa_model::Function
end
function (prob::ExaProblem)(
    ::Type{BaseType},
    initial_guess;
    kwargs...
)::ExaModels.ExaModel where {BaseType<:AbstractFloat}
    return prob.build_exa_model(BaseType, initial_guess; kwargs...)
end

abstract type AbstractOptimizationProblem end

# ------------------------------------------------------------------------------
# Generic model builders with ADNLPModels and ExaModels backends
abstract type AbstractNLPModelBackend end

# ------------------------------------------------------------------------------
# ADNLPModels
struct ADNLPModelBackend <: AbstractNLPModelBackend
    # attributes
    show_time::Bool
    backend::Symbol
    empty_backends::NamedTuple
    kwargs

    # constructor
    function ADNLPModelBackend(;
        show_time::Bool=false,
        backend::Symbol=:optimized,
        empty_backends::NamedTuple=(
            hprod_backend=ADNLPModels.EmptyADbackend,
            jtprod_backend=ADNLPModels.EmptyADbackend,
            jprod_backend=ADNLPModels.EmptyADbackend,
            ghjvprod_backend=ADNLPModels.EmptyADbackend,
        ),
        kwargs...,
    )
        return new(show_time, backend, empty_backends, kwargs)
    end
end

function build_model(
    prob::AbstractOptimizationProblem,
    initial_guess::AbstractVector,
    modeler::ADNLPModelBackend,
)

    # build the backend options
    backend_options = if modeler.backend==:manual # we define the AD backend manually with sparsity pattern (OCP)
        (
            gradient_backend=ADNLPModels.ReverseDiffADGradient,
            jacobian_backend=ADNLPModels.SparseADJacobian,
            hessian_backend=ADNLPModels.SparseReverseADHessian,
            modeler.empty_backends...
        )
    else
        (backend=modeler.backend, modeler.empty_backends...)
    end

    # build the model
    return prob.build_adnlp_model(initial_guess; 
        show_time=modeler.show_time,
        backend_options...,
        modeler.kwargs...,
    )
end;

# ------------------------------------------------------------------------------
# ExaModels
struct ExaModelBackend{
    BackendType<:Union{Nothing, KernelAbstractions.Backend}
} <: AbstractNLPModelBackend
    base_type::DataType
    backend::BackendType
    kwargs
    function ExaModelBackend(;
        base_type::DataType=Float64,
        backend::Union{Nothing, KernelAbstractions.Backend}=nothing,
        kwargs...,
    )
        return new{typeof(backend)}(base_type, backend, kwargs)
    end
end

function build_model(
    prob::AbstractOptimizationProblem,
    initial_guess,
    modeler::ExaModelBackend,
)
    return prob.build_exa_model(modeler.base_type, initial_guess; 
        backend=modeler.backend,
        modeler.kwargs..., 
    )
end;