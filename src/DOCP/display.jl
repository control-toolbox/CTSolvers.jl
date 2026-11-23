# Display
#
# `Base.show` methods for `DiscretizedModel`, and the one-line summaries
# (`Optimization._summary_line`) of an optimal control problem, a discretizer and a
# discretized model. The output never contains type parameters and its length does not
# depend on the grid size.

"""
$(TYPEDSIGNATURES)

Write the space ``\\mathbb{R}^n`` as `"R"` followed by `n` in superscript digits, or `"R"`
alone when `n == 1`.

# Arguments
- `n::Integer`: The dimension.

# Returns
- `String`: e.g. `"R"`, `"R²"`, `"R¹²"`.

# Example
```julia-repl
julia> CTSolvers.DOCP._space(12)
"R¹²"
```
"""
function _space(n::Integer)
    n == 1 && return "R"
    superscripts = ('⁰', '¹', '²', '³', '⁴', '⁵', '⁶', '⁷', '⁸', '⁹')
    return "R" * join(superscripts[d + 1] for d in reverse(digits(n)))
end

"""
$(TYPEDSIGNATURES)

One-line summary of an optimal control problem: the state, control and variable spaces
(a space of dimension zero is omitted) and the time interval, a free time being written
by its name.

# Arguments
- `io::IO`: Output stream.
- `ocp::CTModels.Models.Model`: The optimal control problem.

# Returns
- `Nothing`: Prints to `io`.

# Example
```julia-repl
julia> CTSolvers.Optimization._summary_line(stdout, ocp)
state ∈ R², control ∈ R, times [0, 1]
```
"""
function Optimization._summary_line(io::IO, ocp::CTModels.Models.Model)
    print(io, "state ∈ ", _space(CTModels.Models.state_dimension(ocp)))
    nu = CTModels.Models.control_dimension(ocp)
    nu > 0 && print(io, ", control ∈ ", _space(nu))
    nv = CTModels.Models.variable_dimension(ocp)
    nv > 0 && print(io, ", variable ∈ ", _space(nv))
    t0 = if CTModels.Components.has_fixed_initial_time(ocp)
        CTModels.Components.initial_time(ocp)
    else
        CTModels.Components.initial_time_name(ocp)
    end
    tf = if CTModels.Components.has_fixed_final_time(ocp)
        CTModels.Components.final_time(ocp)
    else
        CTModels.Components.final_time_name(ocp)
    end
    print(io, ", times [", t0, ", ", tf, "]")
    return nothing
end

"""
$(TYPEDSIGNATURES)

One-line summary of a discretizer: its compact strategy display, with its options.
"""
function Optimization._summary_line(io::IO, discretizer::AbstractDiscretizer)
    show(io, discretizer)
    return nothing
end

"""
$(TYPEDSIGNATURES)

One-line summary of a discretized model: its compact display.
"""
function Optimization._summary_line(io::IO, docp::DiscretizedModel)
    show(io, docp)
    return nothing
end

"""
$(TYPEDSIGNATURES)

Compact display of a [`CTSolvers.DOCP.DiscretizedModel`](@extref): the discretizer that
produced it, on one line, without type parameters.

# Arguments
- `io::IO`: Output stream.
- `docp::DiscretizedModel`: The discretized model to display.

# Returns
- `Nothing`: Prints to `io`.

# Example
```julia-repl
julia> print(docp)
DiscretizedModel(Collocation(grid_size=100, scheme=midpoint, time_grid=nothing))
```

See also: [`CTSolvers.DOCP.DiscretizedModel`](@extref).
"""
function Base.show(io::IO, docp::DiscretizedModel)
    fmt = Core.get_format_codes(io)
    print(io, fmt.name, "DiscretizedModel", fmt.reset, "(")
    Optimization._summary_line(io, docp.discretizer)
    print(io, ")")
    return nothing
end

"""
$(TYPEDSIGNATURES)

Display a [`CTSolvers.DOCP.DiscretizedModel`](@extref) as a tree: the optimal control problem
(spaces and time interval), the discretizer with its options, and the backend cache. The
cache is opaque to CTSolvers and is shown by its type name only.

The output does not depend on the grid size.

# Arguments
- `io::IO`: Output stream.
- `::MIME"text/plain"`: Plain-text MIME type (REPL display).
- `docp::DiscretizedModel`: The discretized model to display.

# Returns
- `Nothing`: Prints to `io`.

# Example
```julia-repl
julia> docp
DiscretizedModel
├─ problem: state ∈ R², control ∈ R, times [0, 1]
├─ discretizer: Collocation(grid_size=100, scheme=midpoint, time_grid=nothing)
└─ cache: CTDirect.DOCPCache
```

See also: [`CTSolvers.DOCP.DiscretizedModel`](@extref), [`CTSolvers.DOCP.ocp_model`](@extref).
"""
function Base.show(io::IO, ::MIME"text/plain", docp::DiscretizedModel)
    return Optimization._show_tree(
        io,
        "DiscretizedModel",
        ("problem" => docp.ocp, "discretizer" => docp.discretizer, "cache" => docp.cache),
    )
end
