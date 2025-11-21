abstract type AbstractCTScheme end
struct MidpointScheme <: AbstractCTScheme end
struct TrapezoidalScheme <: AbstractCTScheme end

const SchemeSymbol = Dict(
    MidpointScheme => :midpoint,
    TrapezoidalScheme => :trapeze,
)

abstract type AbstractCTDiscretizationMethod end

struct CollocationMethod{T<:AbstractCTScheme} <: AbstractCTDiscretizationMethod
    grid_size::Int
    scheme::T
    function CollocationMethod(;
        grid_size::Int=__grid_size(),
        scheme::AbstractCTScheme=__scheme(),
    )
        return new{typeof(scheme)}(grid_size, scheme)
    end
end
