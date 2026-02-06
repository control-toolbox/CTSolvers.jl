"""
$(TYPEDEF)

Abstract base type for all strategies in the CTSolvers ecosystem.

Every concrete strategy must implement a **two-level contract** separating static type metadata from dynamic instance configuration.

## Contract Overview

### Type-Level Contract (Static Metadata)

Methods defined on the **type** that describe what the strategy can do:

- `id(::Type{<:MyStrategy})::Symbol` - Unique identifier for routing and introspection
- `metadata(::Type{<:MyStrategy})::StrategyMetadata` - Option specifications and validation rules

**Why type-level?** These methods enable:
- **Introspection without instantiation** - Query capabilities without creating objects
- **Routing and dispatch** - Select strategies by symbol for automated construction
- **Validation before construction** - Verify compatibility before resource allocation

### Instance-Level Contract (Configured State)

Methods defined on **instances** that provide the actual configuration:

- `options(strategy::MyStrategy)::StrategyOptions` - Current option values with provenance tracking

**Why instance-level?** These methods enable:
- **Multiple configurations** - Different instances with different settings
- **Provenance tracking** - Know which options came from user vs defaults
- **Encapsulation** - Configuration state belongs to the executing object

## Implementation Requirements

Every concrete strategy must provide:

1. **Type definition** with an `options::StrategyOptions` field (recommended)
2. **Type-level methods** for `id` and `metadata`
3. **Constructor** accepting keyword arguments (uses `build_strategy_options`)
4. **Instance-level access** to configured options

## Validation Modes

The strategy system supports two validation modes for option handling:

- **Strict Mode (default)**: Rejects unknown options with detailed error messages
  - Provides early error detection and safety
  - Suggests corrections for typos using Levenshtein distance
  - Ideal for development and production environments

- **Permissive Mode**: Accepts unknown options with warnings
  - Allows backend-specific options without breaking changes
  - Maintains validation for known options (types, custom validators)
  - Ideal for advanced users and experimental features

The validation mode is controlled by the `mode` parameter in constructors:

```julia-repl
# Strict mode (default) - rejects unknown options
julia> MyStrategy(unknown_option=123)  # ERROR

# Permissive mode - accepts unknown options with warning
julia> MyStrategy(unknown_option=123; mode=:permissive)  # WARNING but works
```

## API Methods

The Strategies module provides these methods for working with strategies:

- `id(strategy_type)` - Get the unique identifier
- `metadata(strategy_type)` - Get option specifications  
- `options(strategy)` - Get current configuration
- `build_strategy_options(Type; mode=:strict, kwargs...)` - Validate and merge options

# Example

```julia-repl
# Define strategy type
julia> struct MyStrategy <: AbstractStrategy
           options::StrategyOptions
       end

# Implement type-level contract
julia> id(::Type{<:MyStrategy}) = :mystrategy
julia> metadata(::Type{<:MyStrategy}) = StrategyMetadata(
           OptionDefinition(name=:max_iter, type=Int, default=100, description="Max iterations")
       )

# Implement constructor (required)
julia> function MyStrategy(; mode::Symbol=:strict, kwargs...)
           options = build_strategy_options(MyStrategy; mode=mode, kwargs...)
           return MyStrategy(options)
       end

# Use the strategy
julia> strategy = MyStrategy(max_iter=200)  # Instance with custom config (strict mode)
julia> id(typeof(strategy))                 # => :mystrategy (type-level)
julia> options(strategy)                    # => StrategyOptions (instance-level)

# Use with permissive mode for unknown options
julia> strategy = MyStrategy(max_iter=200, custom_option=123; mode=:permissive)
```

# Notes

- **Type-level methods** are called on the type: `id(MyStrategy)`
- **Instance-level methods** are called on instances: `options(strategy)`
- **Constructor pattern** is required for registry-based construction
- **Strategy families** can be created with intermediate abstract types

# References

See the [Strategies module documentation](@ref) for complete API reference and examples.
"""
abstract type AbstractStrategy end

"""
$(TYPEDSIGNATURES)

Return the unique identifier for this strategy type.

# Arguments
- `strategy_type::Type{<:AbstractStrategy}`: The strategy type

# Returns
- `Symbol`: Unique identifier for the strategy

# Example
```julia-repl
# For a concrete strategy type MyStrategy:
julia> id(MyStrategy)
:mystrategy
```
"""
function id end

"""
$(TYPEDSIGNATURES)

Return the current options of a strategy as a StrategyOptions.

# Arguments
- `strategy::AbstractStrategy`: The strategy instance

# Returns
- `StrategyOptions`: Current option values with provenance tracking

# Example
```julia-repl
# For a concrete strategy instance:
julia> strategy = MyStrategy(backend=:sparse)
julia> opts = options(strategy)
julia> opts
StrategyOptions with values=(backend=:sparse), sources=(backend=:user)
```
"""
function options end

"""
$(TYPEDSIGNATURES)

Return metadata about a strategy type.

# Arguments
- `strategy_type::Type{<:AbstractStrategy}`: The strategy type

# Returns
- `StrategyMetadata`: Option specifications and validation rules

# Example
```julia-repl
# For a concrete strategy type MyStrategy:
julia> meta = metadata(MyStrategy)
julia> meta
StrategyMetadata with option definitions for max_iter, etc.
```
"""
function metadata end

# ============================================================================
# Default implementations that error if not overridden
# ============================================================================

# These default implementations enforce the contract by throwing helpful error
# messages when concrete strategies don't implement required methods.

"""
Default implementation for `id(::Type{T})` that throws `NotImplemented`.

This ensures that any concrete strategy type must explicitly implement
the `id` method to provide its unique identifier.

# Throws

- `Exceptions.NotImplemented`: When the concrete type doesn't override this method
"""
function id(::Type{T}) where {T<:AbstractStrategy}
    throw(Exceptions.NotImplemented(
        "Strategy ID method not implemented",
        required_method="id(::Type{<:$T})",
        suggestion="Implement id(::Type{<:$T}) to return a unique Symbol identifier",
        context="AbstractStrategy.id - required method implementation"
    ))
end

"""
Default implementation for `metadata(::Type{T})` that throws `NotImplemented`.

This ensures that any concrete strategy type must explicitly implement
the `metadata` method to provide its option specifications.

The error message reminds developers to return a `StrategyMetadata` wrapping
a `Dict` of `OptionDefinition` objects.

# Throws

- `Exceptions.NotImplemented`: When the concrete type doesn't override this method
"""
function metadata(::Type{T}) where {T<:AbstractStrategy}
    throw(Exceptions.NotImplemented(
        "Strategy metadata method not implemented",
        required_method="metadata(::Type{<:$T})",
        suggestion="Implement metadata(::Type{<:$T}) to return StrategyMetadata with OptionDefinitions",
        context="AbstractStrategy.metadata - required method implementation"
    ))
end

"""
Default implementation for `options(strategy::T)` with flexible field access.

This implementation supports two common patterns for strategy types:

1. **Field-based (recommended)**: Strategy has an `options::StrategyOptions` field
2. **Custom getter**: Strategy implements its own `options()` method

If the strategy type has an `options` field, this implementation returns it.
Otherwise, it throws a `NotImplemented` error to indicate that the concrete
type must implement its own getter.

# Arguments
- `strategy::T`: The strategy instance

# Returns
- `StrategyOptions`: The configured options for the strategy

# Throws

- `Exceptions.NotImplemented`: When the strategy has no `options` field and doesn't
  implement a custom `options()` method
"""
function options(strategy::T) where {T<:AbstractStrategy}
    if hasfield(T, :options)
        # Recommended pattern: direct field access for performance
        return getfield(strategy, :options)
    else
        # Fallback: require custom implementation for complex internal structures
        throw(Exceptions.NotImplemented(
            "Strategy options method not implemented",
            required_method="options(strategy::$T)",
            suggestion="Add options::StrategyOptions field to strategy type or implement custom options() method",
            context="AbstractStrategy.options - required method implementation"
        ))
    end
end
