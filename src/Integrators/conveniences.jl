"""
$(TYPEDSIGNATURES)

Build a `SciML` integrator with the given options.

# Arguments
- `kwargs...`: Options forwarded to the `SciML` constructor.

# Returns
- [`CTSolvers.Integrators.SciML`](@ref): The configured integrator.

See also: [`CTSolvers.Integrators.SciML`](@ref), [`CTSolvers.Integrators.build_sciml_integrator`](@ref).
"""
function build_integrator(; kwargs...)
    return SciML(; kwargs...)
end
