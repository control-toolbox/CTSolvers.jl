"""
    CTSolversOrdinaryDiffEqTsit5

Package extension providing the default SciML ODE algorithm (Tsit5) via tag dispatch.
Activated automatically when `OrdinaryDiffEqTsit5` is loaded together with `CTSolvers`.
"""
module CTSolversOrdinaryDiffEqTsit5

import DocStringExtensions: TYPEDSIGNATURES
using CTSolvers.Integrators: Integrators
using OrdinaryDiffEqTsit5: OrdinaryDiffEqTsit5, Tsit5

"""
$(TYPEDSIGNATURES)

Return the default SciML ODE algorithm (Tsit5) for `Tsit5Tag`.

Overrides the stub in `src/Integrators/sciml.jl` that returns `missing`.

See also: [`CTSolvers.Integrators.SciML`](@ref), [`CTSolvers.Integrators.Tsit5Tag`](@ref).
"""
function Integrators.__default_sciml_algorithm(::Type{<:Integrators.Tsit5Tag})
    return Tsit5()
end

end # module CTSolversOrdinaryDiffEqTsit5
