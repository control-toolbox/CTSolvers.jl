"""
    CTSolversSciMLIntegrator

Package extension providing the SciML integration backend for CTSolvers.
Activated automatically when `DiffEqBase` and `SciMLBase` are loaded together with `CTSolvers`.

This extension provides:
- `real_norm` overload for grid invariance (array case)
- `Strategies.metadata` for `Integrators.SciML` options
- `build_sciml_integrator` — constructs a `SciML` integrator with pre-computed option caches
- `SciMLIntegrationResult` — wraps `SciMLBase.AbstractODESolution`
- `CommonSolve.solve(prob::AbstractODEProblem, integ::SciML)` — integrates and returns a result
- `status`/`successful` — termination status derived from the ODE solution's `retcode`
- `merge` — concatenates a sequence of integration results (multi-phase), aggregating `retcode`

The domain glue that turns a control system/config into an `ODEProblem` (`build_problem`,
`build_options`) is intentionally **not** part of CTSolvers; it lives in the consuming package
(e.g. CTFlows).
"""
module CTSolversSciMLIntegrator

import DocStringExtensions: TYPEDEF, TYPEDSIGNATURES
using CommonSolve: CommonSolve
import CTBase.Exceptions
import CTBase.Strategies
import CTBase.Core

using CTSolvers.Integrators: Integrators
using DiffEqBase: DiffEqBase
using SciMLBase: SciMLBase

# =============================================================================
# real_norm overload (array case) — grid invariance (IND)
# =============================================================================

"""
$(TYPEDSIGNATURES)

Compute the internal norm for adaptive step-size control using only the primal
parts of dual numbers.

Ensures grid invariance (IND) when integrating ODEs with ForwardDiff dual numbers:
the adaptive time grid chosen by the solver is identical whether integrating with real
or dual numbers. Uses [`CTSolvers.Integrators.deepvalue`](@ref) to extract primal parts
and `DiffEqBase.ODE_DEFAULT_NORM` to compute the norm.

See also: [`CTSolvers.Integrators.deepvalue`](@ref), [`CTSolvers.Integrators.real_norm`](@ref).
"""
function Integrators.real_norm(u::AbstractArray, t)
    return DiffEqBase.ODE_DEFAULT_NORM(Integrators.deepvalue.(u), t)
end

# =============================================================================
# Strategies.metadata — option definitions for SciML
# =============================================================================

"""
$(TYPEDSIGNATURES)

Return metadata defining `Integrators.SciML` options and their specifications.

The `internalnorm` option defaults to `real_norm`, which extracts the primal (Float64)
part of ForwardDiff dual numbers to ensure grid invariance (IND) when ForwardDiff is loaded.
"""
function Strategies.metadata(::Type{Integrators.SciML})
    return Strategies.StrategyMetadata(
        Strategies.OptionDefinition(;
            name=:alg,
            type=SciMLBase.AbstractDEAlgorithm,
            default=Integrators.__default_sciml_algorithm(Integrators.Tsit5Tag),
            description="ODE algorithm (e.g. Tsit5(), Vern6()).",
            aliases=(:algorithm, :solver),
        ),
        Strategies.OptionDefinition(;
            name=:reltol,
            type=Real,
            default=1e-8,
            description="Relative tolerance for the ODE solver.",
            aliases=(:rtol, :rel_tol),
            validator=x ->
                x > 0 || throw(
                    Exceptions.IncorrectArgument(
                        "Invalid reltol value";
                        got="reltol=$x",
                        expected="positive real number (> 0)",
                        suggestion="Provide a positive tolerance (e.g., 1e-8, 1e-10).",
                        context="SciML reltol validation",
                    ),
                ),
        ),
        Strategies.OptionDefinition(;
            name=:abstol,
            type=Real,
            default=1e-8,
            description="Absolute tolerance for the ODE solver.",
            aliases=(:atol, :abs_tol),
            validator=x ->
                x > 0 || throw(
                    Exceptions.IncorrectArgument(
                        "Invalid abstol value";
                        got="abstol=$x",
                        expected="positive real number (> 0)",
                        suggestion="Provide a positive tolerance (e.g., 1e-8, 1e-10).",
                        context="SciML abstol validation",
                    ),
                ),
        ),
        Strategies.OptionDefinition(;
            name=:maxiters,
            type=Integer,
            default=Core.NotProvided,
            description="Maximum number of solver iterations.",
            aliases=(:max_iters, :max_iter, :maxiter, :max_iterations, :maxit),
            validator=x ->
                x > 0 || throw(
                    Exceptions.IncorrectArgument(
                        "Invalid maxiters value";
                        got="maxiters=$x",
                        expected="positive integer (> 0)",
                        suggestion="Provide a positive iteration count (e.g., 10^5).",
                        context="SciML maxiters validation",
                    ),
                ),
        ),
        Strategies.OptionDefinition(;
            name=:dt,
            type=Real,
            default=Core.NotProvided,
            description="Fixed step size (used when adaptive=false).",
            aliases=(:dt0, :timestep),
            validator=x ->
                x > 0 || throw(
                    Exceptions.IncorrectArgument(
                        "Invalid dt value";
                        got="dt=$x",
                        expected="positive real number (> 0)",
                        suggestion="Provide a positive step size (e.g., 0.01).",
                        context="SciML dt validation",
                    ),
                ),
        ),
        Strategies.OptionDefinition(;
            name=:adaptive,
            type=Bool,
            default=Core.NotProvided,
            description="Whether to use adaptive step-size control.",
            aliases=(:adaptive_step, :adaptive_stepping),
        ),
        Strategies.OptionDefinition(;
            name=:save_everystep,
            type=Union{Bool,Symbol},
            default=:auto,
            description="Save the solution at every solver step. Set `true`/`false` to force, or `:auto` to resolve to `false` for point integration and `true` for trajectory integration.",
        ),
        Strategies.OptionDefinition(;
            name=:saveat,
            type=Union{Real,AbstractVector},
            default=Core.NotProvided,
            description="Times at which to save the solution (Vector or range).",
            aliases=(:save_at, :save_times),
        ),
        Strategies.OptionDefinition(;
            name=:dense,
            type=Union{Bool,Symbol},
            default=:auto,
            description="Dense output. Set `true`/`false` to force, or `:auto` to resolve to `false` for point integration and `true` for trajectory integration.",
        ),
        Strategies.OptionDefinition(;
            name=:save_idxs,
            type=AbstractVector{<:Integer},
            default=Core.NotProvided,
            description="Indices of components to save (Vector of integers).",
            aliases=(:saveindices, :save_indices),
        ),
        Strategies.OptionDefinition(;
            name=:tstops,
            type=AbstractVector{<:Real},
            default=Core.NotProvided,
            description="Extra times the solver must step to (for discontinuities).",
            aliases=(:t_stops, :stop_times),
        ),
        Strategies.OptionDefinition(;
            name=:d_discontinuities,
            type=AbstractVector{<:Real},
            default=Core.NotProvided,
            description="Locations of discontinuities in low-order derivatives.",
        ),
        Strategies.OptionDefinition(;
            name=:dtmax,
            type=Real,
            default=Core.NotProvided,
            description="Maximum step size for adaptive timestepping.",
            aliases=(:max_dt, :dt_max),
            validator=x ->
                x > 0 || throw(
                    Exceptions.IncorrectArgument(
                        "Invalid dtmax value";
                        got="dtmax=$x",
                        expected="positive real number (> 0)",
                        suggestion="Provide a positive maximum step size (e.g., 0.1).",
                        context="SciML dtmax validation",
                    ),
                ),
        ),
        Strategies.OptionDefinition(;
            name=:dtmin,
            type=Real,
            default=Core.NotProvided,
            description="Minimum step size for adaptive timestepping.",
            aliases=(:min_dt, :dt_min),
            validator=x ->
                x > 0 || throw(
                    Exceptions.IncorrectArgument(
                        "Invalid dtmin value";
                        got="dtmin=$x",
                        expected="positive real number (> 0)",
                        suggestion="Provide a positive minimum step size (e.g., 1e-6).",
                        context="SciML dtmin validation",
                    ),
                ),
        ),
        Strategies.OptionDefinition(;
            name=:force_dtmin,
            type=Bool,
            default=Core.NotProvided,
            description="Whether to continue forcing minimum dt usage.",
        ),
        Strategies.OptionDefinition(;
            name=:callback,
            type=Any,
            default=Core.NotProvided,
            description="Callback function for event handling.",
            aliases=(:callbacks, :cb),
        ),
        Strategies.OptionDefinition(;
            name=:progress,
            type=Bool,
            default=Core.NotProvided,
            description="Whether to show progress bar.",
            aliases=(:verbose,),
        ),
        Strategies.OptionDefinition(;
            name=:save_start,
            type=Union{Bool,Symbol},
            default=:auto,
            description="Save initial condition in solution. Set `true`/`false` to force, or `:auto` to resolve to `false` for point integration and `true` for trajectory integration.",
        ),
        Strategies.OptionDefinition(;
            name=:save_end,
            type=Bool,
            default=Core.NotProvided,
            description="Whether to force saving the final timepoint.",
        ),
        Strategies.OptionDefinition(;
            name=:internalnorm,
            type=Function,
            default=Integrators.real_norm,
            description="Internal norm for adaptive step-size control. " *
                        "Defaults to `real_norm`, which extracts the primal (Float64) " *
                        "part of ForwardDiff dual numbers to ensure grid invariance (IND) " *
                        "when ForwardDiff is loaded. Set to `DiffEqBase.ODE_DEFAULT_NORM` to use the SciML default.",
            aliases=(:internal_norm, :norm),
        ),
    )
end

# =============================================================================
# build_sciml_integrator — actual implementation
# =============================================================================

"""
$(TYPEDSIGNATURES)

Tuple of option keys that support automatic resolution based on the integration kind.

These options use the `:auto` sentinel value in their metadata and are resolved during
integrator construction into two cached dictionaries:
- `options_point`: `:auto` → `false` (only the final state is needed)
- `options_trajectory`: `:auto` → `true` (full trajectory storage needed)

Users can override automatic resolution by providing explicit `true`/`false` values
when constructing the integrator.

See also: [`CTSolvers.Integrators.build_sciml_integrator`](@ref).
"""
const _AUTO_OPTION_KEYS = (:dense, :save_everystep, :save_start)

"""
$(TYPEDSIGNATURES)

Build a `SciML` integrator with validated options and pre-computed point/trajectory option
dictionaries.

Options in `_AUTO_OPTION_KEYS` support the `:auto` sentinel value, resolved here into the two
cached dictionaries `options_point` (`:auto` → `false`) and `options_trajectory`
(`:auto` → `true`).

# Arguments
- `::Type{Integrators.SciMLTag}`: The SciML integrator tag type.
- `mode::Symbol`: Validation mode for strategy options (`:strict` or `:permissive`).
- `kwargs...`: User-provided option values. Explicit `true`/`false` override `:auto` resolution.

# Returns
- [`CTSolvers.Integrators.SciML`](@ref): integrator with cached `options_point`/`options_trajectory`.

# Throws
- `CTBase.Exceptions.PreconditionError`: If no algorithm is available (e.g. `OrdinaryDiffEqTsit5`
  not loaded and no explicit `alg`).

See also: [`CTSolvers.Integrators.SciML`](@ref).
"""
function Integrators.build_sciml_integrator(
    ::Type{Integrators.SciMLTag}; mode::Symbol=:strict, kwargs...
)
    opts = Strategies.build_strategy_options(Integrators.SciML; mode=mode, kwargs...)
    raw = Strategies.options_dict(opts)

    # Check if algorithm is missing and raise PreconditionError
    alg_val = raw[:alg]
    if alg_val === missing
        throw(
            Exceptions.PreconditionError(
                "No ODE algorithm specified and OrdinaryDiffEqTsit5 is not loaded";
                reason="alg is missing",
                suggestion="Load OrdinaryDiffEqTsit5: using OrdinaryDiffEqTsit5\n" *
                           "Or specify an algorithm explicitly: SciML(alg=Vern6())\n" *
                           "Note: when specifying an algorithm, also load its package (e.g., using OrdinaryDiffEqVerner for Vern6)",
                context="SciML integrator construction",
            ),
        )
    end

    # Pre-compute options for point integration
    options_point = copy(raw)
    for key in _AUTO_OPTION_KEYS
        get(options_point, key, :auto) === :auto && (options_point[key] = false)
    end

    # Pre-compute options for trajectory integration
    options_trajectory = copy(raw)
    for key in _AUTO_OPTION_KEYS
        get(options_trajectory, key, :auto) === :auto && (options_trajectory[key] = true)
    end

    return Integrators.SciML{typeof(opts),typeof(options_point),typeof(options_trajectory)}(
        opts, options_point, options_trajectory
    )
end

# =============================================================================
# SciMLIntegrationResult — wraps a SciMLBase.AbstractODESolution
# =============================================================================

"""
$(TYPEDEF)

Integration result from a SciML solver.

Wraps a `SciMLBase.AbstractODESolution` and implements the `AbstractIntegrationResult`
interface.

# Fields
- `ode_sol::S`: The raw SciML ODE solution.
"""
struct SciMLIntegrationResult{S<:SciMLBase.AbstractODESolution} <:
       Integrators.AbstractIntegrationResult
    ode_sol::S
end

"""
$(TYPEDSIGNATURES)

Return the final state vector from the SciML ODE solution.
"""
Integrators.final_state(r::SciMLIntegrationResult) = last(r.ode_sol.u)

"""
$(TYPEDSIGNATURES)

Return the vector of time points from the SciML ODE solution.
"""
Integrators.times(r::SciMLIntegrationResult) = r.ode_sol.t

"""
$(TYPEDSIGNATURES)

Evaluate the SciML ODE solution at a specific time `t` using its interpolation.
"""
Integrators.evaluate_at(r::SciMLIntegrationResult, t::Real) = r.ode_sol(t)

"""
$(TYPEDSIGNATURES)

Return the termination status of the SciML ODE solution, as a `Symbol` derived from its
`retcode` (e.g. `:Success`, `:MaxIters`).
"""
Integrators.status(r::SciMLIntegrationResult) = Symbol(r.ode_sol.retcode)

"""
$(TYPEDSIGNATURES)

Return whether the SciML ODE solution terminated successfully, per
`SciMLBase.successful_retcode`.
"""
function Integrators.successful(r::SciMLIntegrationResult)
    return SciMLBase.successful_retcode(r.ode_sol.retcode)
end

# =============================================================================
# merge — concatenate SciML integration results (multi-phase trajectories)
# =============================================================================

"""
$(TYPEDSIGNATURES)

Return the retcode to report for a merged multi-phase solution: the first non-successful
retcode among `ode_sols`, or `SciMLBase.ReturnCode.Success` if every segment succeeded.

This keeps `Integrators.status`/`Integrators.successful` on a merged result truthful even
when a segment was solved with `unsafe=true` (bypassing the retcode check at `solve` time).
"""
function _merged_retcode(ode_sols)
    for sol in ode_sols
        SciMLBase.successful_retcode(sol.retcode) || return sol.retcode
    end
    return SciMLBase.ReturnCode.Success
end

"""
$(TYPEDSIGNATURES)

Merge a sequence of SciML integration results into a single result by concatenating their
time and state vectors. Used for multi-phase trajectories.
"""
function Integrators.merge(segments::AbstractVector{<:SciMLIntegrationResult})
    ode_sols = [r.ode_sol for r in segments]

    if isempty(ode_sols)
        throw(
            Exceptions.IncorrectArgument(
                "Cannot merge empty sequence of segments";
                got="0 segments",
                expected="at least 1 segment",
                context="SciML merge",
            ),
        )
    end

    if length(ode_sols) == 1
        return segments[1]
    end

    t_merged = copy(ode_sols[1].t)
    u_merged = copy(ode_sols[1].u)

    for i in eachindex(ode_sols)[2:end]
        sol = ode_sols[i]
        append!(t_merged, sol.t)
        append!(u_merged, sol.u)
    end

    sol1 = ode_sols[1]
    merged_sol = DiffEqBase.build_solution(
        sol1.prob,
        sol1.alg,
        t_merged,
        u_merged;
        retcode=_merged_retcode(ode_sols),
        dense=false,
    )

    return SciMLIntegrationResult(merged_sol)
end

# =============================================================================
# CommonSolve.solve — integrate an ODEProblem with a SciML integrator
# =============================================================================

"""
$(TYPEDSIGNATURES)

Check the return code of a SciML ODE solution and throw `SolverFailure` if integration failed.

# Throws
- `CTBase.Exceptions.SolverFailure`: If `!unsafe` and the retcode indicates failure.
"""
function _check_retcode(sol, unsafe)
    if !unsafe && !SciMLBase.successful_retcode(sol.retcode)
        throw(
            Exceptions.SolverFailure(
                "ODE integration failed";
                retcode=string(sol.retcode),
                suggestion="Try tightening tolerances (reltol, abstol) or changing the solver algorithm.",
                context="SciML solve",
            ),
        )
    end
end

"""
$(TYPEDSIGNATURES)

Integrate an `ODEProblem` with a `SciML` integrator and resolved options.
Returns a [`SciMLIntegrationResult`](@ref) wrapping the raw `ODESolution`.

# Arguments
- `prob::SciMLBase.AbstractODEProblem`: The ODE problem to integrate (time span embedded).
- `integ::Integrators.SciML`: The SciML integrator strategy.
- `options`: Resolved solver options (defaults to the integrator's trajectory option dict).
- `unsafe::Bool`: If `true`, bypass retcode checking; if `false`, throw on integration failure.

# Throws
- `CTBase.Exceptions.SolverFailure`: If the ODE solver returns an unsuccessful retcode and `unsafe=false`.
"""
function CommonSolve.solve(
    prob::SciMLBase.AbstractODEProblem,
    integ::Integrators.SciML;
    options=Integrators.options_trajectory(integ),
    unsafe=Integrators.__unsafe(),
)
    ode_sol = SciMLBase.solve(prob; options...)
    _check_retcode(ode_sol, unsafe)
    return SciMLIntegrationResult(ode_sol)
end

end # module CTSolversSciMLIntegrator
