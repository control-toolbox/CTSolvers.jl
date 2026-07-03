"""
    CTSolversForwardDiff

Package extension providing ForwardDiff-specific implementations for grid invariance (IND).
Activated automatically when `ForwardDiff` is loaded together with `CTSolvers`.

This extension adds:
- `deepvalue(x::ForwardDiff.Dual)` — recursive extraction of primal values from nested duals
- `real_norm(u::ForwardDiff.Dual, t)` — internal norm for scalar dual numbers

These functions extend the fallback implementations in `CTSolvers.Integrators` to support
ForwardDiff dual numbers.
"""
module CTSolversForwardDiff

import DocStringExtensions: TYPEDSIGNATURES
using ForwardDiff: ForwardDiff

using CTSolvers.Integrators: Integrators

"""
$(TYPEDSIGNATURES)

Recursively extract the primal (real) value from a ForwardDiff dual number.

Handles nested dual numbers for higher-order differentiation. Extends the fallback
[`CTSolvers.Integrators.deepvalue`](@ref) to support ForwardDiff.

See also: [`CTSolvers.Integrators.deepvalue`](@ref), [`CTSolvers.Integrators.real_norm`](@ref).
"""
Integrators.deepvalue(x::ForwardDiff.Dual) = Integrators.deepvalue(ForwardDiff.value(x))

"""
$(TYPEDSIGNATURES)

Compute the internal norm for a scalar ForwardDiff dual number using only its primal part.

Extends the fallback [`CTSolvers.Integrators.real_norm`](@ref) to support ForwardDiff dual
numbers, ensuring grid invariance (IND) when integrating ODEs with dual numbers.

See also: [`CTSolvers.Integrators.real_norm`](@ref), [`CTSolvers.Integrators.deepvalue`](@ref).
"""
function Integrators.real_norm(u::ForwardDiff.Dual, t)
    return Integrators.real_norm(Integrators.deepvalue(u), t)
end

end # module CTSolversForwardDiff
