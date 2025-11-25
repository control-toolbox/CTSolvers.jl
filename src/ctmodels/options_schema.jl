# Internal metadata schema for backend and discretizer options.

abstract type AbstractOCPTool end

struct OptionSpec
    type::Any         # Expected Julia type for the option value, or `missing` if unknown.
    description::Any  # Short English description (String) or `missing` if not documented yet.
end

# Default: no metadata for a given tool type.
function _option_specs(::Type{T}) where {T<:AbstractOCPTool}
    return missing
end

# Convenience overload to accept instances as well as types.
_option_specs(x::AbstractOCPTool) = _option_specs(typeof(x))

function _options(tool::AbstractOCPTool)
    throw(
        CTBase.NotImplemented("_options not implemented for $(typeof(tool))"),
    )
end

function _option_sources(tool::AbstractOCPTool)
    throw(
        CTBase.NotImplemented("_option_sources not implemented for $(typeof(tool))"),
    )
end

# Retrieve the list of known option keys for a given tool type.
function options_keys(tool_type::Type{<:AbstractOCPTool})
    specs = _option_specs(tool_type)
    specs === missing && return missing
    return propertynames(specs)
end

options_keys(x::AbstractOCPTool) = options_keys(typeof(x))

function is_an_option_key(key::Symbol, tool_type::Type{<:AbstractOCPTool})
    specs = _option_specs(tool_type)
    specs === missing && return missing
    return key in propertynames(specs)
end

is_an_option_key(key::Symbol, x::AbstractOCPTool) = is_an_option_key(key, typeof(x))

function option_type(key::Symbol, tool_type::Type{<:AbstractOCPTool})
    specs = _option_specs(tool_type)
    specs === missing && return missing
    if !(haskey(specs, key))
        return missing
    end
    spec = getfield(specs, key)::OptionSpec
    return spec.type
end

option_type(key::Symbol, x::AbstractOCPTool) = option_type(key, typeof(x))

function option_description(key::Symbol, tool_type::Type{<:AbstractOCPTool})
    specs = _option_specs(tool_type)
    specs === missing && return missing
    if !(haskey(specs, key))
        return missing
    end
    spec = getfield(specs, key)::OptionSpec
    return spec.description
end

option_description(key::Symbol, x::AbstractOCPTool) = option_description(key, typeof(x))

# Simple Levenshtein distance for suggestion of close option names.
function _string_distance(a::AbstractString, b::AbstractString)
    m = lastindex(a)
    n = lastindex(b)
    # Use 1-based indices over code units for simplicity; option keys are short.
    da = collect(codeunits(a))
    db = collect(codeunits(b))
    # dp[i+1, j+1] = distance between first i chars of a and first j chars of b
    dp = Array{Int}(undef, m + 1, n + 1)
    for i in 0:m
        dp[i + 1, 1] = i
    end
    for j in 0:n
        dp[1, j + 1] = j
    end
    for i in 1:m
        for j in 1:n
            cost = da[i] == db[j] ? 0 : 1
            dp[i + 1, j + 1] = min(
                dp[i, j + 1] + 1,      # deletion
                dp[i + 1, j] + 1,      # insertion
                dp[i, j] + cost,       # substitution
            )
        end
    end
    return dp[m + 1, n + 1]
end

# Suggest up to `max_suggestions` closest option keys for a tool type.
function _suggest_option_keys(key::Symbol, tool_type::Type{<:AbstractOCPTool}; max_suggestions::Int=3)
    specs = _option_specs(tool_type)
    specs === missing && return Symbol[]
    names = collect(propertynames(specs))
    distances = [(_string_distance(String(key), String(n)), n) for n in names]
    sort!(distances; by=first)
    take = min(max_suggestions, length(distances))
    return [distances[i][2] for i in 1:take]
end

_suggest_option_keys(key::Symbol, x::AbstractOCPTool; max_suggestions::Int=3) =
    _suggest_option_keys(key, typeof(x); max_suggestions=max_suggestions)

# Human-readable listing of options and their metadata.
function _show_options(tool_type::Type{<:AbstractOCPTool})
    specs = _option_specs(tool_type)
    if specs === missing
        println("No option metadata available for ", tool_type, ".")
        return
    end
    println("Options for ", tool_type, ":")
    for name in propertynames(specs)
        spec = getfield(specs, name)::OptionSpec
        T = spec.type === missing ? "Any" : string(spec.type)
        desc = spec.description === missing ? "" : " — " * String(spec.description)
        println(" - ", name, " :: ", T, desc)
    end
end

function _show_options(x::AbstractOCPTool)
    return _show_options(typeof(x))
end

# Validate user-supplied keyword options against the metadata of a tool.
# If `strict_keys` is true, unknown keys trigger an error. If false, unknown
# keys are accepted and only known keys are type-checked when a type is
# available in the metadata.
function _validate_option_kwargs(
    user_nt::NamedTuple,
    tool_type::Type{<:AbstractOCPTool};
    strict_keys::Bool=false,
)
    specs = _option_specs(tool_type)
    specs === missing && return nothing

    known_keys = propertynames(specs)

    # Unknown keys
    if strict_keys
        unknown = Symbol[]
        for k in keys(user_nt)
            if !(k in known_keys)
                push!(unknown, k)
            end
        end
        if !isempty(unknown)
            # Only report the first unknown key with suggestions.
            k = first(unknown)
            suggestions = _suggest_option_keys(k, tool_type; max_suggestions=3)
            tool_name = string(nameof(tool_type))
            msg = "Unknown option $(k) for $(tool_name)."
            if !isempty(suggestions)
                msg *= " Did you mean " * join(string.(suggestions), " or ") * "?"
            end
            msg *= " Use CTSolvers._show_options($(tool_name)) to list all available options."
            throw(CTBase.IncorrectArgument(msg))
        end
    end

    # Type checks for known keys where a type is provided.
    for k in keys(user_nt)
        if !(k in known_keys)
            continue
        end
        T = option_type(k, tool_type)
        T === missing && continue
        v = user_nt[k]
        if !(v isa T)
            tool_name = string(nameof(tool_type))
            msg = "Invalid type for option $(k) of $(tool_name). " *
                  "Expected value of type $(T), got value of type $(typeof(v))."
            throw(CTBase.IncorrectArgument(msg))
        end
    end

    return nothing
end

_validate_option_kwargs(user_nt::NamedTuple, x::AbstractOCPTool; strict_keys::Bool=false) =
    _validate_option_kwargs(user_nt, typeof(x); strict_keys=strict_keys)
