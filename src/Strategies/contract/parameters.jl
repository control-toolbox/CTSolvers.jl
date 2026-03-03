# ============================================================================
# Strategy Parameters Contract
# ============================================================================

"""
Abstract base type for strategy parameters.

Strategy parameters allow specialization of strategy behavior and default options.
Every concrete parameter must implement:
- `id(::Type{<:AbstractStrategyParameter})::Symbol` - Unique identifier

# Examples
```julia
struct CPU <: AbstractStrategyParameter end
id(::Type{CPU}) = :cpu

struct GPU <: AbstractStrategyParameter end
id(::Type{GPU}) = :gpu
```

# Notes
- Parameters are singleton types (no fields) - they exist only for type dispatch
- IDs must be globally unique across all strategies and parameters
- Parameters are used to specialize default options in strategy metadata
"""
abstract type AbstractStrategyParameter end

"""
$(TYPEDSIGNATURES)

Get the unique identifier for a parameter type.

Every concrete parameter type must implement this method to provide
a unique symbol identifier used in routing and registry operations.

# Arguments
- `parameter_type::Type{<:AbstractStrategyParameter}`: The parameter type

# Returns
- `Symbol`: Unique identifier for the parameter

# Throws
- `CTBase.Exceptions.NotImplemented`: If the parameter type doesn't implement this method

# Examples
```julia-repl
julia> id(CPU)
:cpu

julia> id(GPU)
:gpu
```
"""
function id(parameter_type::Type{<:AbstractStrategyParameter})
    throw(Exceptions.NotImplemented(
        "id() must be implemented for parameter type",
        required_method="id(::Type{$(parameter_type)})",
        suggestion="Define id(::Type{$(parameter_type)}) = :your_id",
        context="AbstractStrategyParameter contract"
    ))
end

is_parameter_type(::Type{T}) where {T} = T <: AbstractStrategyParameter

parameter_id(parameter_type::Type{<:AbstractStrategyParameter}) = id(parameter_type)

function validate_parameter_type(parameter_type::Type{<:AbstractStrategyParameter})
    if !isconcretetype(parameter_type)
        throw(Exceptions.IncorrectArgument(
            "Invalid parameter type",
            got="parameter_type=$parameter_type",
            expected="a concrete DataType subtype of AbstractStrategyParameter",
            suggestion="Define a concrete struct subtype, e.g. struct MyParam <: AbstractStrategyParameter end",
            context="validate_parameter_type - contract validation"
        ))
    end
    if fieldcount(parameter_type) != 0
        throw(Exceptions.IncorrectArgument(
            "Invalid parameter type",
            got="parameter_type=$parameter_type with $(fieldcount(parameter_type)) fields",
            expected="a singleton parameter type with no fields",
            suggestion="Remove fields from the parameter type; use type dispatch only",
            context="validate_parameter_type - singleton type requirement"
        ))
    end
    _ = id(parameter_type)
    return nothing
end

# ============================================================================

"""
CPU parameter type for CPU-based computation.

This parameter indicates that a strategy should use CPU-based backends
and default options optimized for CPU execution.
"""
struct CPU <: AbstractStrategyParameter end

"""
GPU parameter type for GPU-based computation.

This parameter indicates that a strategy should use GPU-based backends
and default options optimized for GPU execution.

# Notes
- Requires CUDA.jl to be loaded and functional
- Strategies may throw `CTBase.Exceptions.ExtensionError` if CUDA is not available
"""
struct GPU <: AbstractStrategyParameter end

# Implement the contract for built-in parameters
id(::Type{CPU}) = :cpu
id(::Type{GPU}) = :gpu
