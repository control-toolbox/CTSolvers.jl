"""
    CTSolversSciMLIntegrator

Package extension providing the SciML integration backend for CTSolvers.
Activated automatically when `DiffEqBase` and `SciMLBase` are loaded together with `CTSolvers`.

This extension provides:
- `real_norm` overload for grid invariance (array case)
- `Strategies.metadata` for `Integrators.SciML` options
- `_build_sciml_integrator` — constructs a `SciML` integrator with pre-computed option caches
- `SciMLIntegrationResult` — wraps `SciMLBase.AbstractODESolution`
- `CommonSolve.solve(prob::AbstractODEProblem, integ::SciML)` — integrates and returns a result
- `status`/`successful` — termination status derived from the ODE solution's `retcode`
- `merge` — concatenates a sequence of integration results (multi-phase), aggregating `retcode`

The domain glue that turns a control system/config into an `ODEProblem` (`build_problem`,
`build_options`) is intentionally **not** part of CTSolvers; it lives in the consuming package
(e.g. CTFlows).
"""
module CTSolversSciMLIntegrator

using DocStringExtensions: TYPEDEF, TYPEDSIGNATURES
using CommonSolve: CommonSolve
using CTBase: Exceptions
using CTBase: Strategies
using CTBase: Core

using CTSolvers: Integrators
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
or dual numbers. Uses [`CTSolvers.Integrators.deepvalue`](@extref) to extract primal parts
and `DiffEqBase.ODE_DEFAULT_NORM` to compute the norm.

See also: [`CTSolvers.Integrators.deepvalue`](@extref), [`CTSolvers.Integrators.real_norm`](@extref).
"""
function Integrators.real_norm(u::AbstractArray, t)
    return DiffEqBase.ODE_DEFAULT_NORM(Integrators.deepvalue.(u), t)
end

# =============================================================================
# Strategies.metadata — option definitions for SciML
# =============================================================================

"""
$(TYPEDSIGNATURES)

Return metadata defining `Integrators.SciML{P}` options and their specifications.

The `internalnorm` option defaults to `real_norm`, which extracts the primal (Float64)
part of ForwardDiff dual numbers to ensure grid invariance (IND) when ForwardDiff is loaded.

The metadata is specialized on the execution device `P` (`Strategies.CPU`/`Strategies.GPU`);
the option set is currently identical for both — `P` marks the seam where GPU-specific
defaults/validators land as they are discovered. The bare `metadata(SciML)` (core) delegates
here through `SciML{Strategies.CPU}`.
"""
function _sciml_alg_option(default)
    return Strategies.OptionDefinition(;
        name=:alg,
        type=Union{Missing, SciMLBase.AbstractDEAlgorithm},
        default=default,
        description="ODE algorithm (e.g. Tsit5(), Vern6()).",
        aliases=(:algorithm, :solver),
    )
end

function Strategies.metadata(
    ::Type{Integrators.SciML{P}}
) where {P<:Union{Strategies.CPU,Strategies.GPU}}
    return Strategies.StrategyMetadata(
        _sciml_alg_option(Integrators.__default_sciml_algorithm(Integrators.Tsit5Tag)),
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
# _build_sciml_integrator — actual implementation
# =============================================================================

"""
$(TYPEDSIGNATURES)

Tuple of option keys that support automatic resolution based on the integration kind.

These options use the `:auto` sentinel value in their metadata and are resolved during
integrator construction into two cached dictionaries:
- `options_point`: `:auto` → `false` (only the final state is needed); `saveat` is dropped
- `options_trajectory`: `:auto` → `true` (full trajectory storage needed), except
  `save_everystep`, which resolves to `false` when `saveat` is given (the output grid is
  then the `saveat` grid only — see `CommonSolve.solve`)

Users can override automatic resolution by providing explicit `true`/`false` values
when constructing the integrator.

See also: [`CTSolvers.Integrators._build_sciml_integrator`](@extref).
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
- `::Type{P}`: The execution device parameter (`Strategies.CPU`/`Strategies.GPU`); threaded
  into the built `SciML{P}`.
- `mode::Symbol`: Validation mode for strategy options (`:strict` or `:permissive`).
- `kwargs...`: User-provided option values. Explicit `true`/`false` override `:auto` resolution.

# Returns
- [`CTSolvers.Integrators.SciML`](@extref): integrator with cached `options_point`/`options_trajectory`.

# Throws
- `CTBase.Exceptions.PreconditionError`: If no algorithm is available (e.g. `OrdinaryDiffEqTsit5`
  not loaded and no explicit `alg`).

See also: [`CTSolvers.Integrators.SciML`](@extref).
"""
function _missing_sciml_algorithm_error()
    return Exceptions.PreconditionError(
        "No ODE algorithm specified and OrdinaryDiffEqTsit5 is not loaded";
        reason="alg is missing",
        suggestion="Load OrdinaryDiffEqTsit5: using OrdinaryDiffEqTsit5\n" *
                   "Or specify an algorithm explicitly, for example:\n" *
                   "  SciML(alg=Vern6())\n" *
                   "  Flow(ocp, law; alg=Vern6())\n" *
                   "Note: when specifying an algorithm, also load its package " *
                   "(e.g., using OrdinaryDiffEqVerner for Vern6)",
        context="SciML integrator construction",
    )
end

function Integrators._build_sciml_integrator(
    ::Type{Integrators.SciMLTag}, ::Type{P}; mode::Symbol=:strict, kwargs...
) where {P<:Strategies.AbstractStrategyParameter}
    opts = Strategies.build_strategy_options(Integrators.SciML{P}; mode=mode, kwargs...)
    raw = Strategies.options_dict(opts)

    # Check if algorithm is missing and raise PreconditionError
    alg_val = raw[:alg]
    if alg_val === missing
        throw(_missing_sciml_algorithm_error())
    end

    # Pre-compute options for point integration: only the final state is needed, so the
    # output grid `saveat` is irrelevant and dropped.
    options_point = copy(raw)
    for key in _AUTO_OPTION_KEYS
        get(options_point, key, :auto) === :auto && (options_point[key] = false)
    end
    delete!(options_point, :saveat)

    # Pre-compute options for trajectory integration. With `saveat`, an automatic
    # `save_everystep` resolves to `false`: the returned grid is the `saveat` grid only (the
    # dense interpolant is kept anyway, see `CommonSolve.solve`).
    options_trajectory = copy(raw)
    has_saveat = _requested_saveat(options_trajectory) !== nothing
    for key in _AUTO_OPTION_KEYS
        get(options_trajectory, key, :auto) === :auto || continue
        options_trajectory[key] = !(key === :save_everystep && has_saveat)
    end

    return Integrators.SciML{
        P,typeof(opts),typeof(options_point),typeof(options_trajectory)
    }(
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
- `grid::G`: The output time grid requested through `saveat` when the solution was kept
  dense (see `CommonSolve.solve`), or `nothing` when the grid is the solution's own
  `ode_sol.t`.
"""
struct SciMLIntegrationResult{
    S<:SciMLBase.AbstractODESolution,G<:Union{Nothing,AbstractVector}
} <: Integrators.AbstractIntegrationResult
    ode_sol::S
    grid::G
end

"""
$(TYPEDSIGNATURES)

Wrap a SciML ODE solution whose own time points are the output grid.
"""
SciMLIntegrationResult(ode_sol::SciMLBase.AbstractODESolution) =
    SciMLIntegrationResult(ode_sol, nothing)

"""
$(TYPEDSIGNATURES)

Return the final state vector from the SciML ODE solution.
"""
Integrators.final_state(r::SciMLIntegrationResult) = last(r.ode_sol.u)

"""
$(TYPEDSIGNATURES)

Return the vector of time points from the SciML ODE solution.
"""
Integrators.times(r::SciMLIntegrationResult{<:Any,Nothing}) = r.ode_sol.t

"""
$(TYPEDSIGNATURES)

Return the output grid requested through `saveat` (the solution itself is kept dense).
"""
Integrators.times(r::SciMLIntegrationResult{<:Any,<:AbstractVector}) = r.grid

"""
$(TYPEDSIGNATURES)

Return whether the SciML ODE solution carries a dense interpolant.
"""
Integrators.is_dense(r::SciMLIntegrationResult) = r.ode_sol.dense

"""
$(TYPEDSIGNATURES)

Return the integration span of the underlying ODE problem.
"""
Integrators._tspan(r::SciMLIntegrationResult) = r.ode_sol.prob.tspan

"""
$(TYPEDSIGNATURES)

Return a copy of the result whose output grid is `grid`; the ODE solution (and its
interpolant) is shared, values on the grid are read with `evaluate_at`.

# Throws
- `CTBase.Exceptions.IncorrectArgument`: If `grid` is not a valid output grid for the
  integration span.
"""
function Integrators.regrid(r::SciMLIntegrationResult, grid::AbstractVector{<:Real})
    Integrators._check_grid(grid, Integrators._tspan(r))
    return SciMLIntegrationResult(r.ode_sol, collect(eltype(r.ode_sol.t), grid))
end

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
# merge — piecewise SciML integration results (multi-phase trajectories)
# =============================================================================

"""
$(TYPEDSIGNATURES)

Merge a sequence of SciML integration results into a
[`CTSolvers.Integrators.PiecewiseIntegrationResult`](@extref). Each phase keeps its own
solution and interpolant, so a dense multi-phase trajectory is as accurate as a single-phase
one. A single segment is returned unchanged.

# Throws
- `CTBase.Exceptions.IncorrectArgument`: If `segments` is empty.
"""
function Integrators.merge(segments::AbstractVector{<:SciMLIntegrationResult})
    if isempty(segments)
        throw(
            Exceptions.IncorrectArgument(
                "Cannot merge empty sequence of segments";
                got="0 segments",
                expected="at least 1 segment",
                context="SciML merge",
            ),
        )
    end
    length(segments) == 1 && return segments[1]
    return Integrators.PiecewiseIntegrationResult(segments)
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
Returns a [`CTSolversSciMLIntegrator.SciMLIntegrationResult`](@extref) wrapping the raw `ODESolution`.

`saveat` (in `options`, or stored in the problem) is an **output grid**. When dense output
is wanted (`options[:dense] === true`), the problem is integrated without it — same steps,
same cost — the dense interpolant is kept, and the result's time grid is the one SciML's
native saving would have returned (so `evaluate_at` is solver-accurate everywhere, not
only on the grid). Otherwise SciML's native saving is used. In both cases the solver
steps join the grid only on an explicit `save_everystep=true`.

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
    saveat = _requested_saveat(options, prob)
    if saveat === nothing
        ode_sol = SciMLBase.solve(prob; options...)
        _check_retcode(ode_sol, unsafe)
        return SciMLIntegrationResult(ode_sol)
    end
    # the solver steps join the output grid only on an explicit `save_everystep=true`
    everystep = integ[:save_everystep] === true
    if get(options, :dense, false) !== true
        # dense output not wanted: SciML's native saving at the `saveat` times
        ode_sol = SciMLBase.solve(prob; _native_saveat_options(options, everystep)...)
        _check_retcode(ode_sol, unsafe)
        return SciMLIntegrationResult(ode_sol)
    end
    # `saveat` is an output grid only: integrate dense without it, keep the interpolant
    ode_sol = SciMLBase.solve(prob; _dense_options(options, prob)...)
    _check_retcode(ode_sol, unsafe)
    grid = _output_grid(saveat, ode_sol, prob.tspan, options, everystep)
    return SciMLIntegrationResult(ode_sol, grid)
end

# =============================================================================
# saveat as an output grid
# =============================================================================

"""
$(TYPEDSIGNATURES)

Return the `saveat` requested in `options` (or, failing that, stored in the problem's own
keyword arguments), or `nothing` when none or an empty one is given.
"""
function _requested_saveat(options, prob=nothing)
    saveat = get(options, :saveat, nothing)
    if saveat === nothing && prob !== nothing && hasproperty(prob, :kwargs)
        saveat = get(prob.kwargs, :saveat, nothing)
    end
    saveat === nothing && return nothing
    saveat isa Number && return saveat
    return isempty(saveat) ? nothing : saveat
end

"""
$(TYPEDSIGNATURES)

Return the options of a dense integration over the whole span: `saveat` is overridden by an
empty grid (also shadowing a `saveat` stored in the problem), and every step is saved with
its interpolation data.
"""
function _dense_options(options, prob)
    opts = Dict{Symbol,Any}(pairs(options))
    opts[:saveat] = eltype(prob.tspan)[]
    opts[:dense] = true
    opts[:save_everystep] = true
    opts[:save_start] = true
    opts[:save_end] = true
    return opts
end

"""
$(TYPEDSIGNATURES)

Return the options of SciML's native `saveat` saving: `save_everystep` follows the user's
explicit choice only (an automatic value would add every solver step to the grid).
"""
function _native_saveat_options(options, everystep::Bool)
    get(options, :save_everystep, false) === everystep && return options
    opts = Dict{Symbol,Any}(pairs(options))
    opts[:save_everystep] = everystep
    return opts
end

"""
$(TYPEDSIGNATURES)

Return the `Bool` value of a saving flag in `options`, or `nothing` when it is absent or
still automatic.
"""
function _saving_flag(options, key::Symbol)
    value = get(options, key, nothing)
    return value isa Bool ? value : nothing
end

"""
$(TYPEDSIGNATURES)

Build the output time grid SciML would have returned for `saveat`, so that requesting it on
a dense solution yields the same times as SciML's native saving:

- a scalar `saveat` is a step from `t0` in the integration direction;
- a collection keeps the times strictly after `t0` and up to `tf`, in integration order;
- `t0` (resp. `tf`) is added following `save_start` (resp. `save_end`), with SciML's
  defaults when unset;
- an explicit `save_everystep=true` (`everystep`) adds the solver steps (union, as SciML
  does).
"""
function _output_grid(saveat, ode_sol, tspan, options, everystep::Bool)
    T = eltype(ode_sol.t)
    t0, tf = T(tspan[1]), T(tspan[2])
    tdir = sign(tf - t0)
    after_t0(t) = tdir * t0 < tdir * t ≤ tdir * tf
    grid = T[]
    if saveat isa Number
        Δ = tdir * abs(saveat)
        append!(grid, (t0 + Δ):Δ:tf)
    else
        append!(grid, Iterators.filter(after_t0, saveat))
    end
    everystep && append!(grid, Iterators.filter(after_t0, ode_sol.t))
    sort!(grid; rev=(tdir < 0))
    unique!(grid)
    by_default = everystep || saveat isa Number
    save_start = something(_saving_flag(options, :save_start), by_default || t0 in saveat)
    save_end = something(_saving_flag(options, :save_end), by_default || tf in saveat)
    save_start && pushfirst!(grid, t0)
    if save_end
        (isempty(grid) || last(grid) != tf) && push!(grid, tf)
    else
        filter!(!=(tf), grid)
    end
    return grid
end

end # module CTSolversSciMLIntegrator
