# ============================================================================
# Describe - Registry-aware introspection
# ============================================================================

"""
$(TYPEDSIGNATURES)

Display comprehensive information about a strategy using its ID and registry.

This function provides registry-aware introspection that shows:
- Strategy ID and family membership
- Available parameters (CPU, GPU, etc.)
- Default parameter (if applicable)
- Options grouped by source (common vs computed)
- Parameter-specific computed option values

# Arguments
- `strategy_id::Symbol`: The strategy identifier (e.g., `:adnlp`, `:exa`, `:ipopt`)
- `registry::StrategyRegistry`: The registry containing strategy definitions

# Example
```julia-repl
julia> using CTSolvers.Strategies

julia> registry = create_registry(
           AbstractNLPModeler => (
               (ADNLP, [CPU]),
               (Exa, [CPU, GPU])
           )
       )

julia> describe(:exa, registry)
Exa (strategy)
├─ id: :exa
├─ family: AbstractNLPModeler
├─ default parameter: CPU
├─ parameters: CPU, GPU
│
├─ common options (1 option):
│  └─ base_type::DataType (default: Float64)
│     description: Base floating-point type used by ExaModels
│
├─ computed options for CPU:
│  └─ backend::Union{Nothing, ...} (default: nothing [computed])
│     description: Execution backend for ExaModels
│
└─ computed options for GPU:
   └─ backend::Union{Nothing, ...} (default: CUDABackend [computed])
      description: Execution backend for ExaModels
```

# Throws
- `Exceptions.IncorrectArgument`: If the strategy ID is not found in the registry

See also: `describe(::Type{<:AbstractStrategy})`, `StrategyRegistry`, `create_registry`
"""
function describe(id_symbol::Symbol, registry::StrategyRegistry)
    describe(stdout, id_symbol, registry)
end

function describe(io::IO, id_symbol::Symbol, registry::StrategyRegistry)
    # Disambiguation: check if it's a parameter ID first, then strategy ID
    if haskey(registry.parameters, id_symbol)
        # It's a parameter ID
        param_type = registry.parameters[id_symbol]
        _describe_parameter_registry(io, id_symbol, param_type, registry)
    else
        # Try as strategy ID
        _describe_strategy_registry(io, id_symbol, registry)
    end
end

"""
Describe a strategy using registry (internal implementation).
"""
function _describe_strategy_registry(
    io::IO, strategy_id::Symbol, registry::StrategyRegistry
)
    fmt = get_format_codes(io)

    # 1. Find family and strategy types from registry
    family, strategy_types = _find_strategy_in_registry(strategy_id, registry)

    # 2. Get base type name (use first match, extract UnionAll name)
    base_type = first(strategy_types)
    type_name = _strategy_type_name(base_type)

    # 3. Get available parameters
    params = [get_parameter_type(T) for T in strategy_types]
    params = filter(!isnothing, params)
    unique!(params)  # Remove duplicates

    # 4. Get default parameter (if parameterized)
    default_param = if !isempty(params)
        try
            # Try to get the UnionAll wrapper type
            wrapper_type = if base_type isa UnionAll
                base_type
            elseif base_type isa DataType && base_type.name.wrapper isa UnionAll
                base_type.name.wrapper
            else
                base_type
            end
            _default_parameter(wrapper_type)
        catch
            nothing
        end
    else
        nothing
    end

    # 5. Header with hierarchy
    println(io, fmt.name, type_name, fmt.reset, " (strategy)")
    println(
        io, "├─ ", fmt.label, "id: ", fmt.reset, fmt.keyword, ":", strategy_id, fmt.reset
    )

    # Build hierarchy chain for the base type
    hierarchy_chain = _supertype_chain(base_type, AbstractStrategy)
    hierarchy_str = join(
        [fmt.type * string(nameof(t)) * fmt.reset for t in hierarchy_chain], " → "
    )
    println(io, "├─ ", fmt.label, "hierarchy: ", fmt.reset, hierarchy_str)

    println(
        io, "├─ ", fmt.label, "family: ", fmt.reset, fmt.type, nameof(family), fmt.reset
    )

    if !isempty(params)
        if default_param !== nothing
            println(
                io,
                "├─ ",
                fmt.label,
                "default parameter: ",
                fmt.reset,
                fmt.type,
                nameof(default_param),
                fmt.reset,
            )
        end
        param_names = join([fmt.type * string(nameof(P)) * fmt.reset for P in params], ", ")
        println(io, "├─ ", fmt.label, "parameters: ", fmt.reset, param_names)
        println(io, "│")  # vertical separator
    else
        println(io, "│")  # vertical separator for consistency
    end

    # 6. Retrieve and display metadata
    _describe_metadata(io, fmt, strategy_types, params, registry)
end

"""
Describe a parameter using registry (internal implementation).
"""
function _describe_parameter_registry(
    io::IO,
    param_id::Symbol,
    param_type::Type{<:AbstractStrategyParameter},
    registry::StrategyRegistry,
)
    fmt = get_format_codes(io)
    type_name = nameof(param_type)
    param_desc = description(param_type)

    # Build hierarchy chain
    hierarchy_chain = [param_type, AbstractStrategyParameter]
    hierarchy_str = join(
        [fmt.type * string(nameof(T)) * fmt.reset for T in hierarchy_chain], " → "
    )

    println(io, fmt.name, type_name, fmt.reset, " (parameter)")
    println(io, "├─ ", fmt.label, "id: ", fmt.reset, fmt.keyword, ":", param_id, fmt.reset)
    println(io, "├─ ", fmt.label, "hierarchy: ", fmt.reset, hierarchy_str)
    println(io, "├─ ", fmt.label, "description: ", fmt.reset, param_desc)

    # Find strategies using this parameter
    strategies_using = _find_strategies_using_parameter(param_type, registry)

    if !isempty(strategies_using)
        println(io, "│")
        n_strategies = length(strategies_using)
        println(
            io,
            "└─ ",
            fmt.label,
            "used by strategies (",
            fmt.reset,
            fmt.count,
            n_strategies,
            fmt.reset,
            "):",
        )

        for (i, (strat_id, family, strat_type)) in enumerate(strategies_using)
            is_last = i == length(strategies_using)
            prefix = is_last ? "   └─ " : "   ├─ "
            println(
                io,
                prefix,
                fmt.keyword,
                ":",
                strat_id,
                fmt.reset,
                " (",
                fmt.type,
                nameof(family),
                fmt.reset,
                ") → ",
                fmt.type,
                strat_type,
                fmt.reset,
            )
        end
    else
        println(io, "│")
        println(
            io,
            "└─ ",
            fmt.label,
            "used by strategies: ",
            fmt.reset,
            fmt.keyword,
            "none",
            fmt.reset,
        )
    end
end

# ============================================================================
# Private helpers for registry-aware describe
# ============================================================================

"""
Build a supertype chain from a type up to (and including) a stop type.

Returns a vector of types representing the inheritance chain.

# Arguments
- `T::Type`: Starting type
- `stop_at::Type`: Type to stop at (inclusive)

# Returns
- `Vector{Type}`: Chain of types from T to stop_at

# Example
```julia
chain = _supertype_chain(ADNLP{CPU}, AbstractStrategy)
# Returns: [ADNLP{CPU}, AbstractNLPModeler, AbstractStrategy]
```
"""
function _supertype_chain(T::Type, stop_at::Type)
    chain = Type[T]
    current = T

    while current !== stop_at && current !== Any
        current = supertype(current)
        push!(chain, current)
        if current === stop_at
            break
        end
    end

    return chain
end

"""
Find all strategies in the registry that use a specific parameter type.

Returns a vector of tuples: (strategy_id, family_type, strategy_type)

# Arguments
- `param_type::Type{<:AbstractStrategyParameter}`: The parameter type to search for
- `registry::StrategyRegistry`: The registry to search in

# Returns
- `Vector{Tuple{Symbol, Type, Type}}`: List of (strategy_id, family, strategy_type) tuples
"""
function _find_strategies_using_parameter(
    param_type::Type{<:AbstractStrategyParameter}, registry::StrategyRegistry
)
    results = Tuple{Symbol,Type,Type}[]

    for (family, types) in registry.families
        for T in types
            # Check if this strategy type uses the parameter
            strat_param = get_parameter_type(T)
            if strat_param === param_type
                strat_id = id(T)
                push!(results, (strat_id, family, T))
            end
        end
    end

    # Sort by strategy ID for consistent display
    sort!(results; by=x -> x[1])

    return results
end

"""
Find a strategy in the registry by its ID.

Returns `(family_type, [matched_types...])` where matched_types are all
strategy types with the given ID.

Throws `IncorrectArgument` if the ID is not found.
"""
function _find_strategy_in_registry(strategy_id::Symbol, registry::StrategyRegistry)
    for (family, types) in registry.families
        matched = filter(T -> id(T) === strategy_id, types)
        if !isempty(matched)
            return (family, matched)
        end
    end

    # Not found - provide helpful error with available IDs
    all_ids = Symbol[]
    for (family, types) in registry.families
        for T in types
            push!(all_ids, id(T))
        end
    end
    unique!(all_ids)

    # Check if it might be a parameter ID
    if haskey(registry.parameters, strategy_id)
        throw(
            Exceptions.IncorrectArgument(
                "Symbol is a parameter ID, not a strategy ID";
                got=":$strategy_id",
                expected="a strategy ID from: $all_ids",
                suggestion="This is a parameter ID. Use describe(:$strategy_id, registry) to see parameter info.",
                context="describe - disambiguating strategy vs parameter ID",
            ),
        )
    end

    throw(
        Exceptions.IncorrectArgument(
            "ID not found in registry";
            got=":$strategy_id",
            expected="one of available strategy IDs: $all_ids or parameter IDs: $(collect(keys(registry.parameters)))",
            suggestion="Check available IDs or register the missing strategy/parameter",
            context="describe - looking up ID in registry",
        ),
    )
end

"""
Extract a clean type name from a strategy type.

Handles both parameterized types (e.g., `Exa{CPU}` → `Exa`)
and non-parameterized types (e.g., `Collocation` → `Collocation`).
"""
function _strategy_type_name(T::Type)
    if T isa UnionAll
        return string(T.body.name.name)
    elseif T isa DataType
        return string(T.name.name)
    else
        return string(T)
    end
end

"""
Display metadata for strategy types, handling multiple parameters and extensions.

For strategies with multiple parameters, groups options into:
- Common options (default source, same across parameters)
- Computed options (per-parameter, shown separately)
"""
function _describe_metadata(
    io::IO, fmt, strategy_types::Vector, params::Vector, registry::StrategyRegistry
)
    if isempty(params)
        # Non-parameterized strategy - simple case
        _describe_single_metadata(io, fmt, first(strategy_types))
    elseif length(params) == 1
        # Single parameter - simple case
        _describe_single_metadata(io, fmt, first(strategy_types))
    else
        # Multiple parameters - group common vs computed options
        _describe_multi_param_metadata(io, fmt, strategy_types, params)
    end
end

"""
Display metadata for a single strategy type (non-parameterized or single parameter).
"""
function _describe_single_metadata(io::IO, fmt, strategy_type::Type)
    # Try to get metadata, catch ExtensionError
    meta = try
        metadata(strategy_type)
    catch e
        if e isa Exceptions.ExtensionError
            # Extension not loaded - display in red
            ext_names = join(e.weakdeps, ", ")
            println(
                io,
                "└─ ",
                fmt.label,
                "options: ",
                fmt.reset,
                "\033[31m",  # Red color
                "requires extension ",
                ext_names,
                "\033[0m",  # Reset color
            )
            return nothing
        else
            rethrow()
        end
    end

    # Display all options
    n_opts = length(meta)
    println(
        io,
        "└─ ",
        fmt.label,
        "options (",
        fmt.reset,
        fmt.count,
        n_opts,
        fmt.reset,
        " option",
        n_opts == 1 ? "" : "s",
        "):",
    )

    items = collect(pairs(meta))
    for (i, (key, def)) in enumerate(items)
        is_last = i == length(items)
        prefix = is_last ? "   └─ " : "   ├─ "
        cont = is_last ? "      " : "   │  "
        println(io, prefix, def)
        println(io, cont, fmt.label, "description: ", fmt.reset, Options.description(def))
        # Add separator line between options (except after last)
        if !is_last
            println(io, cont)
        end
    end
end

"""
Display metadata for multi-parameter strategies, grouping common and computed options.
"""
function _describe_multi_param_metadata(io::IO, fmt, strategy_types::Vector, params::Vector)
    # Collect metadata for each parameter
    param_metadata = Dict{Type,Union{StrategyMetadata,Nothing}}()
    param_errors = Dict{Type,Union{Exceptions.ExtensionError,Nothing}}()

    for (T, P) in zip(strategy_types, params)
        meta = try
            metadata(T)
        catch e
            if e isa Exceptions.ExtensionError
                param_errors[P] = e
                nothing  # Extension not loaded for this parameter
            else
                rethrow()
            end
        end
        param_metadata[P] = meta
    end

    # Check if all metadata is missing (all extensions not loaded)
    if all(isnothing, values(param_metadata))
        # All extensions missing - get extension names from first error
        first_error = first(values(param_errors))
        ext_names = join(first_error.weakdeps, ", ")
        println(
            io,
            "└─ ",
            fmt.label,
            "options: ",
            fmt.reset,
            "\033[31m",  # Red color
            "requires extension ",
            ext_names,
            "\033[0m",  # Reset color
        )
        return nothing
    end

    # Collect all option names and definitions across parameters
    all_option_names = Set{Symbol}()
    option_defs = Dict{Symbol,Vector{Tuple{Type,OptionDefinition}}}()

    for (P, meta) in param_metadata
        if meta !== nothing
            for (name, def) in pairs(meta)
                push!(all_option_names, name)
                if !haskey(option_defs, name)
                    option_defs[name] = []
                end
                push!(option_defs[name], (P, def))
            end
        end
    end

    # Separate common (default) and computed options
    common_options = Symbol[]
    computed_options = Symbol[]

    for name in all_option_names
        defs = option_defs[name]
        # Check if this option is computed in any parameter variant
        is_computed = any(Options.is_computed(def) for (P, def) in defs)
        if is_computed
            push!(computed_options, name)
        else
            push!(common_options, name)
        end
    end

    # Display common options
    if !isempty(common_options)
        n_common = length(common_options)
        println(
            io,
            "├─ ",
            fmt.label,
            "common options (",
            fmt.reset,
            fmt.count,
            n_common,
            fmt.reset,
            " option",
            n_common == 1 ? "" : "s",
            "):",
        )

        for (i, name) in enumerate(common_options)
            is_last = i == length(common_options)
            prefix = is_last ? "│  └─ " : "│  ├─ "
            cont = is_last ? "│     " : "│  │  "

            # Use definition from first available parameter
            (P, def) = first(option_defs[name])
            println(io, prefix, def)
            println(
                io, cont, fmt.label, "description: ", fmt.reset, Options.description(def)
            )

            if !is_last
                println(io, cont)
            end
        end
        println(io, "│")
    end

    # Display computed options per parameter
    for (i, P) in enumerate(params)
        is_last_param = i == length(params)
        meta = param_metadata[P]

        if meta === nothing
            # Extension not loaded for this parameter
            prefix = is_last_param ? "└─ " : "├─ "
            # Get extension names from error
            ext_error = get(param_errors, P, nothing)
            ext_names = ext_error !== nothing ? join(ext_error.weakdeps, ", ") : "unknown"
            println(
                io,
                prefix,
                fmt.label,
                "computed options for ",
                fmt.reset,
                fmt.type,
                nameof(P),
                fmt.reset,
                ": ",
                "\033[31m",  # Red color
                "requires extension ",
                ext_names,
                "\033[0m",  # Reset color
            )
            if !is_last_param
                println(io, "│")
            end
            continue
        end

        # Filter computed options for this parameter
        param_computed = filter(name -> name in computed_options, keys(meta))

        if isempty(param_computed)
            # No computed options for this parameter
            prefix = is_last_param ? "└─ " : "├─ "
            println(
                io,
                prefix,
                fmt.label,
                "computed options for ",
                fmt.reset,
                fmt.type,
                nameof(P),
                fmt.reset,
                ": ",
                fmt.keyword,
                "none",
                fmt.reset,
            )
            if !is_last_param
                println(io, "│")
            end
            continue
        end

        # Display computed options for this parameter
        prefix = is_last_param ? "└─ " : "├─ "
        println(
            io,
            prefix,
            fmt.label,
            "computed options for ",
            fmt.reset,
            fmt.type,
            nameof(P),
            fmt.reset,
            ":",
        )

        param_computed_list = collect(param_computed)
        for (j, name) in enumerate(param_computed_list)
            is_last_opt = j == length(param_computed_list)
            opt_prefix = if is_last_param
                is_last_opt ? "   └─ " : "   ├─ "
            else
                is_last_opt ? "│  └─ " : "│  ├─ "
            end
            opt_cont = if is_last_param
                is_last_opt ? "      " : "   │  "
            else
                is_last_opt ? "│     " : "│  │  "
            end

            def = meta[name]
            println(io, opt_prefix, def)
            println(
                io,
                opt_cont,
                fmt.label,
                "description: ",
                fmt.reset,
                Options.description(def),
            )

            if !is_last_opt
                println(io, opt_cont)
            end
        end

        if !is_last_param
            println(io, "│")
        end
    end
end
