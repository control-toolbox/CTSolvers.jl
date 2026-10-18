# Integration Results

```@meta
CurrentModule = CTSolvers
```

`CommonSolve.solve(prob, integrator)` integrates an ODE problem and returns an
[`Integrators.AbstractIntegrationResult`](@ref). This page describes how to read it and
how the saving options shape it. CTFlows builds on this layer; its documentation covers
flows, multi-phase trajectories and control laws at a higher level.

```@example res
using CTSolvers: Integrators
using OrdinaryDiffEqTsit5
using SciMLBase: ODEProblem
using CommonSolve: solve

prob = ODEProblem((u, p, t) -> -u, [1.0], (0.0, 1.0))   # u(t) = exp(-t)
integ = Integrators.SciML()
r = solve(prob, integ)
nothing # hide
```

## Reading a result

| Accessor | Returns |
| :--------- | :-------- |
| [`Integrators.final_state`](@ref)`(r)` | State at the final time |
| [`Integrators.times`](@ref)`(r)` | Output time grid |
| [`Integrators.evaluate_at`](@ref)`(r, t)` | State at any time `t` of the span |
| [`Integrators.is_dense`](@ref)`(r)` | Whether `evaluate_at` reads a dense interpolant |
| [`Integrators.status`](@ref)`(r)` | Termination status, as a `Symbol` |
| [`Integrators.successful`](@ref)`(r)` | Whether the integration succeeded |

```@repl res
Integrators.final_state(r)
Integrators.evaluate_at(r, 0.5)
Integrators.is_dense(r), Integrators.status(r), Integrators.successful(r)
```

`status` and `successful` are the same functions as `CTModels.Solutions.status` and
`CTModels.Solutions.successful`.

## Point vs trajectory integration

The integrator caches two option sets, built once at construction:

- [`Integrators.options_trajectory`](@ref) — the default of `solve`: dense output and
  every step saved, for a full trajectory.
- [`Integrators.options_point`](@ref) — only the final state is needed: no dense output,
  no intermediate saving, no `saveat`. Much cheaper in memory.

```@example res
rp = solve(prob, integ; options = Integrators.options_point(integ))
Integrators.times(rp)
```

These options default to `:auto` and are resolved this way unless you set them explicitly
(`dense`, `save_everystep`, `save_start`).

## `saveat` is an output grid

With `saveat`, the result's time grid is the requested grid, while the solution stays
dense: `evaluate_at` is accurate everywhere, not only at the saved times. The problem is
integrated with the same steps (and cost) as SciML's native `saveat`, and returns the same
values on the grid.

```@example res
integ_grid = Integrators.SciML(saveat = 0.0:0.25:1.0)
rg = solve(prob, integ_grid)
Integrators.times(rg)
```

```@repl res
Integrators.is_dense(rg)
Integrators.evaluate_at(rg, 0.1) ≈ [exp(-0.1)]
```

The solver steps are added to the grid only with an explicit `save_everystep = true`.
With `dense = false`, SciML's native saving is used and `is_dense(r)` is `false`.

## Changing the grid afterwards

[`Integrators.regrid`](@ref) returns a copy of a result on another output grid, read from
the interpolant without integrating again:

```@repl res
Integrators.times(Integrators.regrid(r, range(0, 1; length = 5)))
```

The grid must contain at least two times, be strictly monotone in the integration
direction, and lie in the integration span; otherwise `regrid` throws `IncorrectArgument`.

## Multi-phase results

[`Integrators.merge`](@ref) combines the consecutive results of a multi-phase integration
into a [`Integrators.PiecewiseIntegrationResult`](@ref). Each phase keeps its own
interpolant, so a dense multi-phase trajectory is as accurate as a single-phase one.

Below, the state jumps by `+1` at `t = 1`:

```@example res
decay(u, p, t) = -u
r1 = solve(ODEProblem(decay, [1.0], (0.0, 1.0)), integ)
u1 = Integrators.final_state(r1) .+ 1    # the jump
r2 = solve(ODEProblem(decay, u1, (1.0, 2.0)), integ)
rm = Integrators.merge([r1, r2])
nothing # hide
```

```@repl res
Integrators.evaluate_at(rm, 1.0)           # end of the first phase
Integrators.evaluate_at(rm, 1.0 + 1e-12)   # second phase, after the jump
```

The merged trajectory is **left-continuous** at a switching time: at `t = 1.0` it returns
the end of the first phase (before the jump), and any later time belongs to the second.
[`Integrators.switching_times`](@ref) lists the switching times, and
[`Integrators.right_limit`](@ref) returns the value just after one of them, so both limits
at a jump are available:

```@repl res
Integrators.switching_times(rm)
Integrators.right_limit(rm, 1)             # after the jump at the first switching time
```

The grid `times(rm)` holds each switching time **once**, so it stays strictly monotone.
`successful(rm)` is `true` only if every phase succeeded, and `status(rm)` is the status of
the first failed phase.

## Failures and `unsafe`

By default, an unsuccessful SciML return code throws a `SolverFailure`. Pass
`unsafe = true` to get the result anyway and check it yourself:

```julia
r = solve(prob, integ; unsafe = true)
Integrators.successful(r) ||
    @warn "integration stopped early" Integrators.status(r)
```

See [Error Messages Reference](@ref) for the error itself.
