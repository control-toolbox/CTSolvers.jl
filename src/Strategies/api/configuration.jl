# ============================================================================
# Strategy configuration and setup
# ============================================================================

using DocStringExtensions

"""
$(TYPEDSIGNATURES)

Build StrategyOptions from user kwargs and strategy metadata.

This function creates a StrategyOptions instance by:
1. Validating the mode parameter (`:strict` or `:permissive`)
2. Extracting known options from kwargs using the Options API
3. Handling unknown options based on the mode
4. Converting the extracted Dict to NamedTuple
5. Wrapping in StrategyOptions

The Options.extract_options function handles:
- Alias resolution to primary names
- Type validation
- Custom validators
- Default values
- Provenance tracking (:user, :default)

# Arguments
- `strategy_type::Type{<:AbstractStrategy}`: The strategy type to build options for
- `mode::Symbol = :strict`: Validation mode (`:strict` or `:permissive`)
  - `:strict` (default): Rejects unknown options with detailed error message
  - `:permissive`: Accepts unknown options with warning, stores with `:user` source (unvalidated)
- `kwargs...`: User-provided option values

# Returns
- `StrategyOptions`: Validated options with provenance tracking

# Throws
- `Exceptions.IncorrectArgument`: If mode is not `:strict` or `:permissive`
- `Exceptions.IncorrectArgument`: If an unknown option is provided in strict mode
- `Exceptions.IncorrectArgument`: If type validation fails (both modes)
- `Exceptions.IncorrectArgument`: If custom validation fails (both modes)

# Example
```julia-repl
# Define a minimal strategy for demonstration
julia> struct MyStrategy <: AbstractStrategy end
julia> Strategies.metadata(::Type{MyStrategy}) = StrategyMetadata(
           OptionDefinition(name=:max_iter, type=Int, default=100)
       )

# Strict mode (default) - rejects unknown options
julia> opts = build_strategy_options(MyStrategy; max_iter=200)
StrategyOptions with 1 option:
  max_iter = 200  [user]

# Permissive mode - accepts unknown options with warning
julia> opts = build_strategy_options(MyStrategy; max_iter=200, custom_opt=123, mode=:permissive)
┌ Warning: Unrecognized options passed to MyStrategy
│   Unvalidated options: [:custom_opt]
└ ...
StrategyOptions with 2 options:
  max_iter = 200  [user]
  custom_opt = 123  [user]
```

# Notes
- Known options are always validated (type, custom validators) regardless of mode
- Unknown options in permissive mode are stored with source `:user` but bypass validation
- Use permissive mode only when you need to pass backend-specific options not defined in CTSolvers metadata

See also: [`StrategyOptions`](@ref), [`metadata`](@ref), [`Options.extract_options`](@ref)
"""
function build_strategy_options(
    strategy_type::Type{<:AbstractStrategy};
    mode::Symbol = :strict,
    kwargs...
)
    # Validate mode parameter
    if mode ∉ (:strict, :permissive)
        throw(Exceptions.IncorrectArgument(
            "Invalid validation mode",
            got="mode=$mode",
            expected=":strict or :permissive",
            suggestion="Use mode=:strict for strict validation (default) or mode=:permissive to accept unknown options with warnings",
            context="build_strategy_options - validating mode parameter"
        ))
    end
    
    meta = metadata(strategy_type)
    defs = collect(values(meta))
    
    # Use Options.extract_options for validation and extraction
    # This validates known options (type, custom validators, etc.)
    extracted, remaining = Options.extract_options((; kwargs...), defs)
    
    # Handle unknown options based on mode
    if !isempty(remaining)
        if mode == :strict
            _error_unknown_options_strict(remaining, strategy_type, meta)
        else  # mode == :permissive
            _warn_unknown_options_permissive(remaining, strategy_type)
            # Store unvalidated options with :user source
            # Note: These options bypass validation but are still user-provided
            for (key, value) in pairs(remaining)
                extracted[key] = Options.OptionValue(value, :user)
            end
        end
    end
    
    # Convert Dict to NamedTuple
    nt = (; (k => v for (k, v) in extracted)...)
    
    return StrategyOptions(nt)
end

"""
$(TYPEDSIGNATURES)

Resolve an alias to its primary key name.

Searches through strategy metadata to find if a given key is either:
1. A primary option name
2. An alias for a primary option name

# Arguments
- `meta::StrategyMetadata`: Strategy metadata to search in
- `key::Symbol`: Key to resolve (can be primary name or alias)

# Returns
- `Union{Symbol, Nothing}`: Primary key if found, `nothing` otherwise

# Example
```julia-repl
julia> meta = metadata(MyStrategy)
julia> resolve_alias(meta, :max_iter)  # Primary name
:max_iter

julia> resolve_alias(meta, :max)  # Alias
:max_iter

julia> resolve_alias(meta, :unknown)  # Not found
nothing
```

See also: [`StrategyMetadata`](@ref), [`OptionDefinition`](@ref)
"""
function resolve_alias(meta::StrategyMetadata, key::Symbol)
    # Check if key is a primary name
    if haskey(meta, key)
        return key
    end
    
    # Check if key is an alias
    for (primary_key, spec) in pairs(meta)
        if key in spec.aliases
            return primary_key
        end
    end
    
    return nothing
end
