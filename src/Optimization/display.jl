# Display
#
# `Base.show` methods for `BuiltModel`, and the internal helpers shared with `DOCP`:
# a one-line summary hook (`_summary_line`) and a tree printer (`_show_tree`). The output
# never contains type parameters and its length does not depend on the problem size.

"""
$(TYPEDSIGNATURES)

Qualified name of the type `T`, without its type parameters.

# Arguments
- `T::Type`: The type to name.

# Returns
- `String`: `"<parent module>.<type name>"`, e.g. `"CTSolvers.Optimization.NoCache"`.

# Example
```julia-repl
julia> CTSolvers.Optimization._type_name(CTSolvers.Optimization.NoCache)
"CTSolvers.Optimization.NoCache"
```

See also: [`CTSolvers.Optimization._summary_line`](@ref).
"""
_type_name(T::Type) = string(parentmodule(T), ".", nameof(T))

"""
$(TYPEDSIGNATURES)

Print a one-line summary of `x` to `io`, used by the displays of
[`CTSolvers.Optimization.BuiltModel`](@extref) and [`CTSolvers.DOCP.DiscretizedModel`](@extref).

The fallback prints the qualified type name of `x`, without type parameters, so that
an object CTSolvers knows nothing about (a backend cache, an NLP model whose package is
not loaded) never floods the display. Methods for specific types are provided by `DOCP`
(optimal control problem, discretizer, discretized model) and by the `CTSolversNLPModels`
extension (NLP model with its sizes).

# Arguments
- `io::IO`: Output stream.
- `x`: The object to summarise.

# Returns
- `Nothing`: Prints to `io`.

# Example
```julia-repl
julia> CTSolvers.Optimization._summary_line(stdout, CTSolvers.Optimization.NoCache())
CTSolvers.Optimization.NoCache
```

See also: [`CTSolvers.Optimization._type_name`](@ref), [`CTSolvers.Optimization._show_tree`](@ref).
"""
function _summary_line(io::IO, x)
    print(io, _type_name(typeof(x)))
    return nothing
end

"""
$(TYPEDSIGNATURES)

Print `title` followed by one tree line per field, each field summarised by
[`CTSolvers.Optimization._summary_line`](@ref).

Colors follow the active CTBase palette and are emitted only when `io` has `:color`
set. No trailing newline is printed.

# Arguments
- `io::IO`: Output stream.
- `title::AbstractString`: First line of the tree.
- `fields::Tuple{Vararg{Pair{String}}}`: `label => value` pairs, in display order.

# Returns
- `Nothing`: Prints to `io`.

# Example
```julia-repl
julia> CTSolvers.Optimization._show_tree(stdout, "Bundle", ("cache" => CTSolvers.Optimization.NoCache(),))
Bundle
└─ cache: CTSolvers.Optimization.NoCache
```

See also: [`CTSolvers.Optimization._summary_line`](@ref).
"""
function _show_tree(io::IO, title::AbstractString, fields::Tuple{Vararg{Pair{String}}})
    fmt = Core.get_format_codes(io)
    print(io, fmt.name, title, fmt.reset)
    for (i, (label, value)) in enumerate(fields)
        prefix = i == length(fields) ? "└─ " : "├─ "
        print(io, '\n', fmt.muted, prefix, fmt.reset, fmt.name, label, fmt.reset, ": ")
        _summary_line(io, value)
    end
    return nothing
end

"""
$(TYPEDSIGNATURES)

One-line summary of a built model: its compact display.
"""
function _summary_line(io::IO, built::BuiltModel)
    show(io, built)
    return nothing
end

"""
$(TYPEDSIGNATURES)

Compact display of a [`CTSolvers.Optimization.BuiltModel`](@extref): the problem and the NLP
model on one line, without type parameters.

# Arguments
- `io::IO`: Output stream.
- `built::BuiltModel`: The built model to display.

# Returns
- `Nothing`: Prints to `io`.

# Example
```julia-repl
julia> print(built)
BuiltModel(DiscretizedModel(Collocation(grid_size=100, scheme=midpoint, time_grid=nothing)), ADNLPModels.ADNLPModel (nvar=302, ncon=204))
```

See also: [`CTSolvers.Optimization.BuiltModel`](@extref).
"""
function Base.show(io::IO, built::BuiltModel)
    fmt = Core.get_format_codes(io)
    print(io, fmt.name, "BuiltModel", fmt.reset, "(")
    _summary_line(io, built.problem)
    print(io, ", ")
    _summary_line(io, built.nlp)
    print(io, ")")
    return nothing
end

"""
$(TYPEDSIGNATURES)

Display a [`CTSolvers.Optimization.BuiltModel`](@extref) as a tree: the problem, the NLP model
(with its numbers of variables and constraints when `NLPModels` is loaded) and the
build-time cache. The cache is shown by its type name only.

The output does not depend on the size of the problem.

# Arguments
- `io::IO`: Output stream.
- `::MIME"text/plain"`: Plain-text MIME type (REPL display).
- `built::BuiltModel`: The built model to display.

# Returns
- `Nothing`: Prints to `io`.

# Example
```julia-repl
julia> built
BuiltModel
├─ problem: DiscretizedModel(Collocation(grid_size=100, scheme=midpoint, time_grid=nothing))
├─ nlp: ADNLPModels.ADNLPModel (nvar=302, ncon=204)
└─ cache: CTSolvers.Optimization.NoCache
```

See also: [`CTSolvers.Optimization.BuiltModel`](@extref).
"""
function Base.show(io::IO, ::MIME"text/plain", built::BuiltModel)
    return _show_tree(
        io,
        "BuiltModel",
        ("problem" => built.problem, "nlp" => built.nlp, "cache" => built.cache),
    )
end
