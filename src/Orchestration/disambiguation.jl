# ============================================================================
# Disambiguation helpers for strategy-based option routing
# ============================================================================

# ----------------------------------------------------------------------------
# Strategy ID Extraction
# ----------------------------------------------------------------------------

"""
$(TYPEDSIGNATURES)

Extract strategy IDs from disambiguation syntax.

This function detects whether an option value uses disambiguation syntax to
explicitly route the option to specific strategies. It supports the modern
[`RoutedOption`](@ref) type created by [`route_to`](@ref), as well as legacy
tuple-based syntax for backward compatibility.

# Disambiguation Syntax

**Recommended (RoutedOption)**:
```julia
value = route_to(solver=100)                    # Single strategy
value = route_to(solver=100, modeler=50)        # Multiple strategies
```

**Legacy (tuples, for backward compatibility)**:
```julia
value = (:sparse, :adnlp)                       # Single strategy
value = ((:sparse, :adnlp), (:cpu, :ipopt))     # Multiple strategies
```

# Arguments
- `raw`: The raw option value to analyze
- `method::Tuple{Vararg{Symbol}}`: Complete method tuple containing all
  strategy IDs

# Returns
- `nothing` if no disambiguation syntax detected
- `Vector{Tuple{Any, Symbol}}` of (value, strategy_id) pairs if disambiguated

# Throws

- `Exceptions.IncorrectArgument`: If a strategy ID in the disambiguation syntax
  is not present in the method tuple

# Examples
```julia-repl
julia> # RoutedOption (recommended)
julia> extract_strategy_ids(route_to(solver=100), (:collocation, :adnlp, :ipopt))
[(100, :solver)]

julia> # Multiple strategies
julia> extract_strategy_ids(route_to(solver=100, modeler=50), (:collocation, :adnlp, :ipopt))
[(100, :solver), (50, :modeler)]

julia> # No disambiguation
julia> extract_strategy_ids(:sparse, (:collocation, :adnlp, :ipopt))
nothing
```

See also: [`route_to`](@ref), [`RoutedOption`](@ref), [`route_all_options`](@ref)
"""
function extract_strategy_ids(
    raw,
    method::Tuple{Vararg{Symbol}}
)::Union{Nothing, Vector{Tuple{Any, Symbol}}}
    
    # Modern syntax: RoutedOption (recommended)
    if raw isa Strategies.RoutedOption
        results = Tuple{Any, Symbol}[]
        for (strategy_id, value) in pairs(raw.routes)
            if strategy_id in method
                push!(results, (value, strategy_id))
            else
                throw(Exceptions.IncorrectArgument(
                    "Strategy ID not found in method tuple",
                    got="strategy ID :$strategy_id",
                    expected="one of available strategy IDs: $method",
                    suggestion="Use a valid strategy ID from your method tuple",
                    context="extract_strategy_ids - validating RoutedOption strategy ID"
                ))
            end
        end
        return results
    end
    
    # Legacy syntax: Single strategy tuple (value, :id)
    # Must be a 2-tuple where second element is Symbol and first is NOT a tuple
    # (to distinguish from multi-strategy syntax)
    if raw isa Tuple && length(raw) == 2 && raw[2] isa Symbol && !(raw[1] isa Tuple)
        value, id = raw
        if id in method
            return [(value, id)]
        else
            throw(Exceptions.IncorrectArgument(
                "Strategy ID not found in method tuple",
                got="strategy ID :$id",
                expected="one of available strategy IDs: $method",
                suggestion="Use route_to($id=$value) for clearer syntax",
                context="extract_strategy_ids - validating strategy ID in tuple disambiguation"
            ))
        end
    end
    
    # Legacy syntax: Multiple strategies ((v1, :id1), (v2, :id2), ...)
    if raw isa Tuple && length(raw) > 0
        # First pass: check if ALL elements have the right structure
        # Each element must be a Tuple (not just any value) with exactly 2 elements
        all_valid_structure = true
        for item in raw
            if !(item isa Tuple && length(item) == 2 && item[2] isa Symbol)
                all_valid_structure = false
                break
            end
        end
        
        # If structure is valid, validate IDs and collect results
        if all_valid_structure
            results = Tuple{Any, Symbol}[]
            for item in raw
                value, id = item
                if id in method
                    push!(results, (value, id))
                else
                    throw(Exceptions.IncorrectArgument(
                        "Strategy ID not found in method tuple",
                        got="strategy ID :$id",
                        expected="one of available strategy IDs: $method",
                        suggestion="Use route_to() for clearer syntax",
                        context="extract_strategy_ids - validating multi-strategy tuple disambiguation"
                    ))
                end
            end
            return results
        end
    end
    
    # No disambiguation detected
    return nothing
end

# ----------------------------------------------------------------------------
# Strategy-to-Family Mapping
# ----------------------------------------------------------------------------

"""
$(TYPEDSIGNATURES)

Build a mapping from strategy IDs to family names.

This helper function creates a reverse lookup dictionary that maps each
strategy ID in the method to its corresponding family name. This is used
by the routing system to determine which family owns each strategy.

# Arguments
- `method::Tuple{Vararg{Symbol}}`: Complete method tuple (e.g.,
  `(:collocation, :adnlp, :ipopt)`)
- `families::NamedTuple`: NamedTuple mapping family names to abstract types
- `registry::Strategies.StrategyRegistry`: Strategy registry

# Returns
- `Dict{Symbol, Symbol}`: Dictionary mapping strategy ID => family name

# Example
```julia-repl
julia> method = (:collocation, :adnlp, :ipopt)

julia> families = (
           discretizer = AbstractOptimalControlDiscretizer,
           modeler = AbstractOptimizationModeler,
           solver = AbstractOptimizationSolver
       )

julia> map = build_strategy_to_family_map(method, families, registry)
Dict{Symbol, Symbol} with 3 entries:
  :collocation => :discretizer
  :adnlp       => :modeler
  :ipopt       => :solver
```

See also: [`build_option_ownership_map`](@ref), [`extract_strategy_ids`](@ref)
"""
function build_strategy_to_family_map(
    method::Tuple{Vararg{Symbol}},
    families::NamedTuple,
    registry::Strategies.StrategyRegistry
)::Dict{Symbol, Symbol}
    
    strategy_to_family = Dict{Symbol, Symbol}()
    
    for (family_name, family_type) in pairs(families)
        id = Strategies.extract_id_from_method(method, family_type, registry)
        strategy_to_family[id] = family_name
    end
    
    return strategy_to_family
end

# ----------------------------------------------------------------------------
# Option Ownership Map
# ----------------------------------------------------------------------------

"""
$(TYPEDSIGNATURES)

Build a mapping from option names to the families that own them.

This function analyzes the metadata of all strategies in the method to
determine which family (or families) define each option. Options that
appear in multiple families are considered ambiguous and require
disambiguation.

# Arguments
- `method::Tuple{Vararg{Symbol}}`: Complete method tuple
- `families::NamedTuple`: NamedTuple mapping family names to abstract types
- `registry::Strategies.StrategyRegistry`: Strategy registry

# Returns
- `Dict{Symbol, Set{Symbol}}`: Dictionary mapping option_name =>
  Set{family_name}

# Example
```julia-repl
julia> map = build_option_ownership_map(method, families, registry)
Dict{Symbol, Set{Symbol}} with 3 entries:
  :grid_size => Set([:discretizer])
  :backend   => Set([:modeler, :solver])  # Ambiguous!
  :max_iter  => Set([:solver])
```

# Notes
- Options appearing in only one family can be auto-routed
- Options appearing in multiple families require disambiguation syntax
- Options not appearing in any family will trigger an error during routing

See also: [`build_strategy_to_family_map`](@ref), [`route_all_options`](@ref)
"""
function build_option_ownership_map(
    method::Tuple{Vararg{Symbol}},
    families::NamedTuple,
    registry::Strategies.StrategyRegistry
)::Dict{Symbol, Set{Symbol}}
    
    option_owners = Dict{Symbol, Set{Symbol}}()
    
    for (family_name, family_type) in pairs(families)
        option_names = Strategies.option_names_from_method(
            method, family_type, registry
        )
        
        for option_name in option_names
            if !haskey(option_owners, option_name)
                option_owners[option_name] = Set{Symbol}()
            end
            push!(option_owners[option_name], family_name)
        end
    end
    
    return option_owners
end