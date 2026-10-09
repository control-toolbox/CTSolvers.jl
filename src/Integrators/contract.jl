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
- An [`CTSolvers.Integrators.AbstractIntegrationResult`](@extref).

# Throws
- [`CTBase.Exceptions.NotImplemented`](@extref): until a backend extension provides the
  typed method.

See also: [`CTSolvers.Integrators.AbstractIntegrator`](@extref).
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
- A single [`CTSolvers.Integrators.AbstractIntegrationResult`](@extref) representing the merged trajectory.

# Throws
- [`CTBase.Exceptions.NotImplemented`](@extref): until a backend extension provides the
  typed method.

See also: [`CTSolvers.Integrators.AbstractIntegrator`](@extref), [`CTSolvers.Integrators.AbstractIntegrationResult`](@extref).
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

"""
$(TYPEDSIGNATURES)

Return a copy of the integration result whose output time grid
([`CTSolvers.Integrators.times`](@extref)) is `grid`. The integration is not redone: the
values on the new grid are read with [`CTSolvers.Integrators.evaluate_at`](@extref) (dense
interpolant when [`CTSolvers.Integrators.is_dense`](@extref)). The original result is left
unchanged.

`grid` must hold at least two times, be strictly monotone in the integration direction and
lie in the integration span. Concrete result types implement this method, typically in a
backend extension.

# Throws
- [`CTBase.Exceptions.IncorrectArgument`](@extref): If `grid` is invalid (in the concrete
  methods).
- [`CTBase.Exceptions.NotImplemented`](@extref): For a result type without a `regrid` method.

See also: [`CTSolvers.Integrators.times`](@extref), [`CTSolvers.Integrators.PiecewiseIntegrationResult`](@extref).
"""
function regrid(r::AbstractIntegrationResult, grid::AbstractVector{<:Real})
    return throw(
        Exceptions.NotImplemented(
            "regrid not implemented for this integration result";
            required_method="regrid(r::$(typeof(r)), grid::AbstractVector{<:Real})",
            suggestion="Implement regrid(r, grid) returning a result whose times are grid.",
            context="AbstractIntegrationResult - regrid implementation",
        ),
    )
end

"""
$(TYPEDSIGNATURES)

Check that `grid` is a valid output grid for the integration span `(t0, tf)`: at least two
times, strictly monotone in the integration direction, inside the span. Returns `nothing`.

# Throws
- [`CTBase.Exceptions.IncorrectArgument`](@extref): If any condition fails.
"""
function _check_grid(grid::AbstractVector{<:Real}, (t0, tf)::Tuple{Real,Real})
    _grid_error(msg, expected) = throw(
        Exceptions.IncorrectArgument(
            msg; got="$(grid)", expected=expected, context="Integrators.regrid"
        ),
    )
    length(grid) >= 2 ||
        _grid_error("An output grid needs at least two times", "≥ 2 times")
    forward = tf >= t0
    monotone = forward ? all(>(0), diff(grid)) : all(<(0), diff(grid))
    monotone || _grid_error(
        "The output grid must be strictly monotone in the integration direction",
        forward ? "strictly increasing times" : "strictly decreasing times",
    )
    lo, hi = minmax(t0, tf)
    all(t -> lo <= t <= hi, grid) ||
        _grid_error("The output grid must lie in the integration span", "times in [$lo, $hi]")
    return nothing
end

"""
$(TYPEDSIGNATURES)

Return the integration span `(t0, tf)` of a result. Defaults to the first and last times of
its grid; result types that know their span (e.g. from the integrated problem) override it.
"""
_tspan(r::AbstractIntegrationResult) = (first(times(r)), last(times(r)))
