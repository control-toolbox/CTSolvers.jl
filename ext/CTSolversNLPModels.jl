"""
    CTSolversNLPModels

Package extension giving the size of an NLP model in the display of a
[`CTSolvers.Optimization.BuiltModel`](@extref). Activated automatically when `NLPModels`
is loaded together with `CTSolvers`, which is the case whenever an NLP backend
(`ADNLPModels`, `ExaModels`) is loaded.

This extension adds:
- `_summary_line(io, nlp::NLPModels.AbstractNLPModel)` — the NLP type name with its
  numbers of variables and constraints.
"""
module CTSolversNLPModels

using DocStringExtensions: TYPEDSIGNATURES
using NLPModels: NLPModels

using CTSolvers: Optimization

"""
$(TYPEDSIGNATURES)

One-line summary of an NLP model: its qualified type name, without type parameters,
followed by its numbers of variables and constraints.

Extends the fallback `CTSolvers.Optimization._summary_line`, which prints the
type name only.

# Arguments
- `io::IO`: Output stream.
- `nlp::NLPModels.AbstractNLPModel`: The NLP model.

# Returns
- `Nothing`: Prints to `io`.

# Example
```julia-repl
julia> CTSolvers.Optimization._summary_line(stdout, nlp)
ADNLPModels.ADNLPModel (nvar=302, ncon=204)
```

See also: [`CTSolvers.Optimization.BuiltModel`](@extref).
"""
function Optimization._summary_line(io::IO, nlp::NLPModels.AbstractNLPModel)
    print(
        io,
        Optimization._type_name(typeof(nlp)),
        " (nvar=",
        NLPModels.get_nvar(nlp),
        ", ncon=",
        NLPModels.get_ncon(nlp),
        ")",
    )
    return nothing
end

end # module CTSolversNLPModels
