# display for solve routine
__display() = true

# discretizer
__grid_size()::Int = 250
__scheme()::AbstractIntegratorScheme = Midpoint()
function CTSolvers.Collocation(;
    grid_size::Int=__grid_size(),
    scheme::AbstractIntegratorScheme=__scheme(),
)
    return Collocation(grid_size, scheme)
end
__discretizer()::AbstractOptimalControlDiscretizer = Collocation()

# ADNLPModels defaults and wrapper constructor
__adnlp_model_show_time() = false
__adnlp_model_backend() = :optimized

function CTSolvers.ADNLPModeler(;
    show_time::Bool=__adnlp_model_show_time(),
    backend::Symbol=__adnlp_model_backend(),
    kwargs...,
)
    options = (
        :show_time => show_time,
        :backend => backend,
        kwargs...,
    )
    return CTSolvers.ADNLPModeler{typeof(options)}(options)
end

# ExaModels defaults and wrapper constructor
__exa_model_base_type() = Float64
__exa_model_backend() = nothing

function CTSolvers.ExaModeler(;
    base_type::Type{<:AbstractFloat}=__exa_model_base_type(),
    backend::Union{Nothing,KernelAbstractions.Backend}=__exa_model_backend(),
    kwargs...,
)
    options = (
        :backend => backend,
        kwargs...,
    )
    return CTSolvers.ExaModeler{base_type, typeof(options)}(options)
end
