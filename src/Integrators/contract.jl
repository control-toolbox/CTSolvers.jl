# Integrator contract
#
# Canonical contract for integrator strategies: the mid-level
# `CommonSolve.solve(prob, integ)` method dispatched on `AbstractIntegrator`, and the
# `merge` of integration results for multi-phase trajectories. Both are `NotImplemented`
# stubs; the typed methods (on the external ODE-problem / result format) live in each
# backend extension (e.g. `CTSolversSciMLIntegrator`). Also defines `__unsafe`, the default
# retcode-checking behavior shared by the contract stub and the backend solve.

"""
$(TYPEDSIGNATURES)

Internal helper defining the default retcode-checking behavior. Returns `false`, meaning
ODE solver retcodes are checked and failures throw exceptions unless explicitly bypassed.
"""
__unsafe()::Bool = false

"""
$(TYPEDSIGNATURES)

Mid-level solve: integrate an ODE problem directly with an integrator strategy.

# Contract
Concrete integrators implement this method, typically in a backend extension,
dispatching on both the problem type and the integrator type, e.g.
`CommonSolve.solve(prob::SciMLBase.AbstractODEProblem, integ::SciML; options, unsafe)`
in the `CTSolversSciMLIntegrator` extension. This generic stub throws `NotImplemented`.
`SciMLBase` is a weak dep — the typed method lives in the integrator extension.

# Arguments
- `prob`: The ODE problem to integrate (type depends on backend; the time span is embedded).
- `integ::AbstractIntegrator`: Integrator strategy to use.
- `options`: Resolved solver options.
- `unsafe::Bool`: If `true`, bypass retcode checking (default: `false`).

# Returns
- An [`CTSolvers.Integrators.AbstractIntegrationResult`](@ref).

# Throws
- [`CTBase.Exceptions.NotImplemented`](@extref): until a backend extension provides the
  typed method.

See also: [`CTSolvers.Integrators.AbstractIntegrator`](@ref).
"""
function CommonSolve.solve(prob, integ::AbstractIntegrator; kwargs...)
    return throw(
        Exceptions.NotImplemented(
            "Solve not implemented for this integrator";
            required_method="CommonSolve.solve(prob, integ::$(typeof(integ)); options, unsafe)",
            suggestion="Load OrdinaryDiffEqTsit5, OrdinaryDiffEq, or DifferentialEquations to activate the CTSolversSciMLIntegrator extension.",
            context="Integrators.solve - required method implementation",
        ),
    )
end

"""
$(TYPEDSIGNATURES)

Merge a sequence of integration results into a single result.

This is used for concatenating multi-phase trajectories. Concrete integrator types
implement this method for their specific result types, typically in a backend extension.

# Arguments
- `segments::AbstractVector{T}`: Sequence of integration results to merge, where
  `T <: AbstractIntegrationResult`.

# Returns
- A single [`CTSolvers.Integrators.AbstractIntegrationResult`](@ref) representing the merged trajectory.

# Throws
- [`CTBase.Exceptions.NotImplemented`](@extref): until a backend extension provides the
  typed method.

See also: [`CTSolvers.Integrators.AbstractIntegrator`](@ref), [`CTSolvers.Integrators.AbstractIntegrationResult`](@ref).
"""
function merge(segments::AbstractVector{T}) where {T<:AbstractIntegrationResult}
    return throw(
        Exceptions.NotImplemented(
            "merge not implemented for this integration result";
            required_method="merge(segments::Vector{<:$(T)})",
            suggestion="Implement merge(segments::Vector{<:YourIntegrationResult}) returning a merged result.",
            context="AbstractIntegrationResult - merge implementation for multi-phase trajectories",
        ),
    )
end
