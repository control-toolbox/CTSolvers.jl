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
- `Exceptions.IncorrectArgument`: If the strategy ID is not found in the registry for the given family

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
- `Exceptions.IncorrectArgument`: If no ID or multiple IDs are found for the family

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
    found::Union{Nothing, Symbol} = nothing
    n_hits::Int = 0

    for s in method
        if s in allowed
            n_hits += 1
            if found === nothing
                found = s
            end
        end
    end

    if n_hits == 1
        return (found::Symbol)
    elseif n_hits == 0
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
            got="family $family appears $n_hits times in method $method",
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
    param = extract_global_parameter_from_method(method, registry)
    available_params = _available_parameters_for_strategy_id(s_id, family, registry)
    strategy_type = if isempty(available_params)
        type_from_id(s_id, family, registry)
    else
        type_from_id(s_id, family, registry; parameter=param)
    end
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
    available_params = _available_parameters_for_strategy_id(s_id, family, registry)
    if isempty(available_params)
        return build_strategy(s_id, family, registry; mode=mode, kwargs...)
    end
    param = extract_global_parameter_from_method(method, registry)
    return build_strategy(s_id, param, family, registry; mode=mode, kwargs...)
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
ERROR: Missing or unsupported parameter in method
```

# Notes
- This function is based on the registry - no hardcoded parameter IDs
- Returns `nothing` only when the selected strategy is not parameterized
- For parameterized strategies, the method tuple must contain a supported parameter ID (no implicit defaults)
- Parameter IDs must be globally unique from strategy IDs
"""
function extract_parameter_from_method(
    method::Tuple{Vararg{Symbol}},
    registry::StrategyRegistry
)
    return extract_global_parameter_from_method(method, registry)
end

function _parameter_id_map(registry::StrategyRegistry)
    pairs = Pair{Symbol, Type{<:AbstractStrategyParameter}}[
        id(CPU) => CPU,
        id(GPU) => GPU,
    ]
    for strategies in values(registry.families)
        for T in strategies
            P = get_parameter_type(T)
            if P !== nothing
                push!(pairs, id(P) => (P::Type{<:AbstractStrategyParameter}))
            end
        end
    end
    return Dict(pairs)
end

function _strategy_id_set(registry::StrategyRegistry)
    ids = Set{Symbol}()
    for strategies in values(registry.families)
        for T in strategies
            push!(ids, id(T))
        end
    end
    return ids
end

function _available_parameters_for_strategy_id(
    strategy_id::Symbol,
    family::Type{<:AbstractStrategy},
    registry::StrategyRegistry
)
    params = Type{<:AbstractStrategyParameter}[]
    for T in registry.families[family]
        if id(T) === strategy_id
            P = get_parameter_type(T)
            if P !== nothing
                push!(params, P::Type{<:AbstractStrategyParameter})
            end
        end
    end
    return params
end

function extract_global_parameter_from_method(
    method::Tuple{Vararg{Symbol}},
    registry::StrategyRegistry
)
    param_map = _parameter_id_map(registry)
    param_tokens = Symbol[s for s in method if haskey(param_map, s)]
    if length(param_tokens) > 1
        throw(Exceptions.IncorrectArgument(
            "Multiple parameters found in method",
            got="method $method",
            expected="at most one global parameter token",
            suggestion="Remove extra parameter tokens; keep a single one like :cpu or :gpu",
            context="extract_global_parameter_from_method - validating unique global parameter"
        ))
    end
    param = isempty(param_tokens) ? nothing : param_map[param_tokens[1]]

    strategy_ids = _strategy_id_set(registry)
    selected_strategy_ids = Symbol[s for s in method if s in strategy_ids]

    any_parameterized = false
    for (family, _) in registry.families
        for s_id in selected_strategy_ids
            available = _available_parameters_for_strategy_id(s_id, family, registry)
            if !isempty(available)
                any_parameterized = true
                if param === nothing
                    throw(Exceptions.IncorrectArgument(
                        "Missing parameter in method",
                        got="method $method",
                        expected="a global parameter token for parameterized strategies",
                        suggestion="Add :cpu or :gpu to your method tuple",
                        context="extract_global_parameter_from_method - parameter required"
                    ))
                end
                if !(param in available)
                    available_ids = Tuple(id(p) for p in available)
                    throw(Exceptions.IncorrectArgument(
                        "Unsupported parameter in method",
                        got="strategy :$s_id with parameter $(id(param)) in method $method",
                        expected="strategy :$s_id with one of: $available_ids",
                        suggestion="Use one of: $available_ids",
                        context="extract_global_parameter_from_method - validating parameter support"
                    ))
                end
            end
        end
    end

    if param !== nothing && !any_parameterized
        throw(Exceptions.IncorrectArgument(
            "Useless parameter in method",
            got="method $method with parameter $(id(param))",
            expected="parameter token to be accepted by at least one selected strategy",
            suggestion="Remove the parameter token or select a strategy that accepts it",
            context="extract_global_parameter_from_method - unused parameter"
        ))
    end

    return param
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
