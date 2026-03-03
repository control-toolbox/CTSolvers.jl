# ============================================================================
# Strategy Builders and Construction Utilities
# ============================================================================

"""
$(TYPEDSIGNATURES)

Build a strategy instance from its ID and options.

This function creates a concrete strategy instance by:
1. Looking up the strategy type from its ID in the registry
2. Constructing the instance with the provided options

# Arguments
- `id::Symbol`: Strategy identifier (e.g., `:adnlp`, `:ipopt`)
- `family::Type{<:AbstractStrategy}`: Abstract family type to search within
- `registry::StrategyRegistry`: Registry containing strategy mappings
- `mode::Symbol=:strict`: Validation mode (`:strict` or `:permissive`)
- `kwargs...`: Options to pass to the strategy constructor

# Returns
- Concrete strategy instance of the appropriate type

# Throws
- `KeyError`: If the ID is not found in the registry for the given family

# Example
```julia-repl
julia> registry = create_registry(
           AbstractNLPModeler => (Modelers.ADNLP, Modelers.Exa)
       )

julia> modeler = build_strategy(:adnlp, AbstractNLPModeler, registry; backend=:sparse)
Modelers.ADNLP(options=StrategyOptions{...})

julia> modeler = build_strategy(:adnlp, AbstractNLPModeler, registry; 
           backend=:sparse, mode=:permissive)
Modelers.ADNLP(options=StrategyOptions{...})
```

See also: [`type_from_id`](@ref), [`build_strategy_from_method`](@ref)
"""
function build_strategy(
    id::Symbol,
    family::Type{<:AbstractStrategy},
    registry::StrategyRegistry;
    mode::Symbol = :strict,
    kwargs...
)
    T = type_from_id(id, family, registry)
    return T(; mode=mode, kwargs...)
end

"""
$(TYPEDSIGNATURES)

Extract the strategy ID for a specific family from a method tuple.

A method tuple contains multiple strategy IDs (e.g., `(:collocation, :adnlp, :ipopt)`).
This function identifies which ID corresponds to the requested family.

# Arguments
- `method::Tuple{Vararg{Symbol}}`: Tuple of strategy IDs
- `family::Type{<:AbstractStrategy}`: Abstract family type to search for
- `registry::StrategyRegistry`: Registry containing strategy mappings

# Returns
- `Symbol`: The ID corresponding to the requested family

# Throws
- `ErrorException`: If no ID or multiple IDs are found for the family

# Example
```julia-repl
julia> method = (:collocation, :adnlp, :ipopt)

julia> extract_id_from_method(method, AbstractNLPModeler, registry)
:adnlp

julia> extract_id_from_method(method, AbstractNLPSolver, registry)
:ipopt
```

See also: [`strategy_ids`](@ref), [`build_strategy_from_method`](@ref)
"""
function extract_id_from_method(
    method::Tuple{Vararg{Symbol}},
    family::Type{<:AbstractStrategy},
    registry::StrategyRegistry
)
    allowed = strategy_ids(family, registry)
    hits = Symbol[]
    
    for s in method
        if s in allowed
            push!(hits, s)
        end
    end
    
    if length(hits) == 1
        return hits[1]
    elseif isempty(hits)
        throw(Exceptions.IncorrectArgument(
            "No strategy ID found for family in method",
            got="family $family in method $method",
            expected="family ID present in method tuple",
            suggestion="Add the family ID to your method tuple, e.g., (:$family, ...)",
            context="extract_id_from_method - validating method tuple contains family"
        ))
    else
        throw(Exceptions.IncorrectArgument(
            "Multiple strategy IDs found for family in method",
            got="family $family appears $length(hits) times in method $method",
            expected="exactly one ID per family in method tuple",
            suggestion="Remove duplicate family IDs from method tuple, keep only one",
            context="extract_id_from_method - validating unique family IDs"
        ))
    end
end

"""
$(TYPEDSIGNATURES)

Get option names for a strategy family from a method tuple.

This is a convenience function that combines ID extraction with option introspection.

# Arguments
- `method::Tuple{Vararg{Symbol}}`: Tuple of strategy IDs
- `family::Type{<:AbstractStrategy}`: Abstract family type to search for
- `registry::StrategyRegistry`: Registry containing strategy mappings

# Returns
- `Tuple{Vararg{Symbol}}`: Tuple of option names for the identified strategy

# Example
```julia-repl
julia> method = (:collocation, :adnlp, :ipopt)

julia> option_names_from_method(method, AbstractNLPModeler, registry)
(:backend, :show_time)
```

See also: [`extract_id_from_method`](@ref), [`option_names`](@ref)
"""
function option_names_from_method(
    method::Tuple{Vararg{Symbol}},
    family::Type{<:AbstractStrategy},
    registry::StrategyRegistry
)
    s_id = extract_id_from_method(method, family, registry)
    param = extract_parameter_from_method(method, registry)
    strategy_type = type_from_id(s_id, family, registry; parameter=param)
    return option_names(strategy_type)
end

"""
$(TYPEDSIGNATURES)

Build a strategy from a method tuple and options.

This is a high-level convenience function that:
1. Extracts the appropriate ID from the method tuple
2. Builds the strategy with the provided options

# Arguments
- `method::Tuple{Vararg{Symbol}}`: Tuple of strategy IDs
- `family::Type{<:AbstractStrategy}`: Abstract family type to search for
- `registry::StrategyRegistry`: Registry containing strategy mappings
- `mode::Symbol=:strict`: Validation mode (`:strict` or `:permissive`)
- `kwargs...`: Options to pass to the strategy constructor

# Returns
- Concrete strategy instance of the appropriate type

# Example
```julia-repl
julia> method = (:collocation, :adnlp, :ipopt)

julia> modeler = build_strategy_from_method(
           method, 
           AbstractNLPModeler, 
           registry; 
           backend=:sparse
       )
Modelers.ADNLP(options=StrategyOptions{...})

julia> modeler = build_strategy_from_method(
           method, 
           AbstractNLPModeler, 
           registry; 
           backend=:sparse,
           mode=:permissive
       )
Modelers.ADNLP(options=StrategyOptions{...})
```

See also: [`extract_id_from_method`](@ref), [`build_strategy`](@ref)
"""
function build_strategy_from_method(
    method::Tuple{Vararg{Symbol}},
    family::Type{<:AbstractStrategy},
    registry::StrategyRegistry;
    mode::Symbol = :strict,
    kwargs...
)
    s_id = extract_id_from_method(method, family, registry)
    param = extract_parameter_from_method(method, registry)
    
    if param === nothing
        # Non-parameterized strategy
        return build_strategy(s_id, family, registry; mode=mode, kwargs...)
    else
        # Parameterized strategy
        return build_strategy(s_id, param, family, registry; mode=mode, kwargs...)
    end
end

"""
$(TYPEDSIGNATURES)

Extract the parameter type from a method tuple.

Searches the method tuple for parameter IDs (like `:cpu`, `:gpu`) and returns
the corresponding parameter type if found. This enables routing of parameterized
strategies from symbolic method descriptions.

# Arguments
- `method::Tuple{Vararg{Symbol}}`: Tuple of strategy and parameter symbols
- `registry::StrategyRegistry`: Registry containing strategy-parameter mappings

# Returns
- `Union{Type{<:AbstractStrategyParameter}, Nothing}`: Parameter type or `nothing` if no parameter found

# Example
```julia-repl
julia> method = (:collocation, :exa, :madnlp, :gpu)
julia> extract_parameter_from_method(method, registry)
GPU

julia> method = (:collocation, :exa, :madnlp)  # No parameter
julia> extract_parameter_from_method(method, registry)
nothing
```

# Notes
- This function is based on the registry - no hardcoded parameter IDs
- Returns `nothing` if no parameter is found (constructors handle defaults)
- Parameter IDs must be globally unique from strategy IDs
"""
function extract_parameter_from_method(
    method::Tuple{Vararg{Symbol}},
    registry::StrategyRegistry
)
    return _extract_parameter_from_method_union(method, registry)
end

function _extract_parameter_from_method_union(
    method::Tuple{Vararg{Symbol}},
    registry::StrategyRegistry
)
    # First symbol is the strategy ID
    if length(method) < 1
        return nothing
    end
    
    strategy_id::Symbol = method[1]
    
    # Find the strategy type in the registry
    strategy_type::Union{Type, Nothing} = nothing
    for strategies in values(registry.families)
        for T in strategies
            if id(T) === strategy_id
                strategy_type = T
                break
            end
        end
        if strategy_type !== nothing
            break
        end
    end
    
    # If strategy not found or not parameterized, return nothing
    if strategy_type === nothing || get_parameter_type(strategy_type) === nothing
        return nothing
    end
    
    # Strategy is parameterized. No implicit defaults: a parameter symbol must be present.
    # Search for parameter ID in method (skip first symbol which is strategy ID)
    for i in 2:length(method)
        s::Symbol = method[i]
        # Find a registered strategy variant matching this parameter ID
        for strategies in values(registry.families)
            for T in strategies
                if id(T) === strategy_id
                    param_type::Union{Type{<:AbstractStrategyParameter}, Nothing} = get_parameter_type(T)
                    if param_type !== nothing && id(param_type) === s
                        return param_type::Type{<:AbstractStrategyParameter}
                    end
                end
            end
        end
    end
    
    # No parameter found: this is an error for parameterized strategies
    throw(Exceptions.IncorrectArgument(
        "Missing or unsupported parameter in method",
        got="method $method",
        expected="a supported parameter ID for strategy :$strategy_id (e.g., :cpu, :gpu)",
        suggestion="Add the parameter ID to your method tuple, e.g., (:$strategy_id, :cpu)",
        context="extract_parameter_from_method - parameter required for parameterized strategy"
    ))
end

"""
$(TYPEDSIGNATURES)

Build a parameterized strategy instance from ID, parameter, and options.

This function creates a concrete parameterized strategy instance by:
1. Looking up the parameterized strategy type from its ID and parameter
2. Constructing the instance with the provided options

# Arguments
- `id::Symbol`: Strategy identifier (e.g., `:madnlp`)
- `parameter::Type{<:AbstractStrategyParameter}`: Parameter type (e.g., `GPU`)
- `family::Type{<:AbstractStrategy}`: Abstract family type to search within
- `registry::StrategyRegistry`: Registry containing strategy mappings
- `mode::Symbol=:strict`: Validation mode (`:strict` or `:permissive`)
- `kwargs...`: Options to pass to the strategy constructor

# Returns
- Concrete parameterized strategy instance (e.g., `MadNLP{GPU}`)

# Throws
- `CTBase.Exceptions.IncorrectArgument`: If the strategy-parameter combination is not found

# Example
```julia-repl
julia> registry = create_registry(
           AbstractNLPSolver => ((MadNLP, [CPU, GPU]),)
       )

julia> solver = build_strategy(:madnlp, GPU, AbstractNLPSolver, registry; max_iter=1000)
MadNLP{GPU}(options=StrategyOptions{...})
```

See also: [`build_strategy`](@ref), [`extract_parameter_from_method`](@ref)
"""
function build_strategy(
    id::Symbol,
    parameter::Type{<:AbstractStrategyParameter},
    family::Type{<:AbstractStrategy},
    registry::StrategyRegistry;
    mode::Symbol = :strict,
    kwargs...
)
    T = type_from_id(id, family, registry; parameter=parameter)
    return T(; mode=mode, kwargs...)
end
