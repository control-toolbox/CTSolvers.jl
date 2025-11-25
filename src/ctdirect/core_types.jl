abstract type AbstractIntegratorScheme end
struct Midpoint <: AbstractIntegratorScheme end
struct Trapezoidal <: AbstractIntegratorScheme end
const Trapeze = Trapezoidal

const SchemeSymbol = Dict(
    Midpoint => :midpoint,
    Trapezoidal => :trapeze,
    Trapeze => :trapeze,
)

abstract type AbstractOptimalControlDiscretizer <: AbstractOCPTool end

function _option_specs(::Type{Collocation})
    return (
        grid_size = OptionSpec(
            Int,
            "Number of time steps used in the collocation grid.",
        ),
        scheme = OptionSpec(
            AbstractIntegratorScheme,
            "Time integration scheme used by the collocation discretizer.",
        ),
    )
end

struct Collocation{T<:AbstractIntegratorScheme} <: AbstractOptimalControlDiscretizer
    grid_size::Int
    scheme::T
    function Collocation(;
        grid_size::Int=__grid_size(),
        scheme::AbstractIntegratorScheme=__scheme(),
    )
        return new{typeof(scheme)}(grid_size, scheme)
    end
end

function _options(discretizer::Collocation)
    return (
        grid_size=grid_size(discretizer),
        scheme=scheme_symbol(discretizer),
    )
end

function _option_sources(discretizer::Collocation)
    # Determine provenance of discretizer options by comparing against the
    # global defaults used in the Collocation constructor.
    default_grid_size = __grid_size()
    default_scheme    = __scheme()

    current_grid_size = grid_size(discretizer)
    current_scheme    = scheme(discretizer)

    src_grid = current_grid_size == default_grid_size ? :ct_default : :user
    src_scheme = current_scheme == default_scheme ? :ct_default : :user

    return (
        grid_size=src_grid,
        scheme=src_scheme,
    )
end

function grid_size(discretizer::AbstractOptimalControlDiscretizer)
    throw(
        CTBase.NotImplemented("grid_size not implemented for $(typeof(discretizer))")
    )
end

function grid_size(discretizer::Collocation)
    return discretizer.grid_size
end

function scheme(discretizer::AbstractOptimalControlDiscretizer)
    throw(
        CTBase.NotImplemented("scheme not implemented for $(typeof(discretizer))")
    )
end

function scheme(discretizer::Collocation)
    return discretizer.scheme
end

function scheme_symbol(discretizer::AbstractOptimalControlDiscretizer)
    throw(
        CTBase.NotImplemented("scheme_symbol not implemented for $(typeof(discretizer))")
    )
end

function scheme_symbol(::Collocation{T}) where {T<:AbstractIntegratorScheme}
    return SchemeSymbol[T]
end

function discretizer_options(name::Symbol)
    if name === :collocation
        return (:grid_size, :scheme)
    else
        msg = "Unknown discretizer symbol $(name). Supported symbols: :collocation."
        throw(CTBase.IncorrectArgument(msg))
    end
end
