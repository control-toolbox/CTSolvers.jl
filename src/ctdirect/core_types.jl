abstract type AbstractIntegratorScheme end
struct Midpoint <: AbstractIntegratorScheme end
struct Trapezoidal <: AbstractIntegratorScheme end
const Trapeze = Trapezoidal

const SchemeSymbol = Dict(
    Midpoint => :midpoint,
    Trapezoidal => :trapeze,
    Trapeze => :trapeze,
)

abstract type AbstractOptimalControlDiscretizer end

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
