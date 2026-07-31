# Performance & Type Stability

```@meta
CurrentModule = CTSolvers
```

This guide explains **how CTSolvers keeps its runtime-critical code fast**, and how
a contributor can check that a change has not introduced a regression.

The whole approach rests on one distinction.

## The one principle: hot path vs. setup path

CTSolvers code falls into two categories:

- **Hot path** — code called *repeatedly* while reading back an integration
  result: evaluating a [`Integrators.SciML`](@ref) trajectory at many time
  points ([`Integrators.evaluate_at`](@ref)), reading the cached option
  dictionaries ([`Integrators.options_point`](@ref) /
  [`Integrators.options_trajectory`](@ref)), and reading the other result
  accessors ([`Integrators.final_state`](@ref), [`Integrators.times`](@ref),
  [`Integrators.status`](@ref), [`Integrators.successful`](@ref)). This code
  **must be type-stable and allocation-clean** — a defect here multiplies over
  thousands of calls.
- **Setup path** — code called *once per problem*, before/around a solve:
  strategy construction (`Solvers.Ipopt()`, `Integrators.SciML(...)`),
  `Strategies.options`/`Options.extract_raw_options`,
  `route_to`/`Strategies.RoutedOption`, `Optimization.build_model` /
  `build_solution`, `DOCP.DiscretizedModel` construction, and the
  `Modelers.nlp_model`/`ocp_solution` convenience wrappers. Runtime dispatch
  here is **acceptable and by design** — CTSolvers' strategy registry is
  deliberately built for runtime extensibility, and the cost is paid once, not
  per iteration.

The rule of thumb for contributors: **keep the hot path inferable; do not
worry about a few dispatches in one-time construction/routing code.**

## The toolbox

| Tool | What it does | When to reach for it |
| --- | --- | --- |
| `@code_warntype f(args...)` | Colored dump of inferred types for one call; red marks instability. | First local look at a single function in the REPL. |
| `Cthulhu.@descend f(args...)` | Interactive, navigable version of the above; descend into callees. | Finding *where* deep in a call chain an instability originates. |
| `JET.@report_opt f(args...)` | Reports runtime-dispatch / optimization failures for one concrete call. | The at-a-glance stability check used on this page. |
| `JET.report_package(CTSolvers)` | Whole-package *correctness* scan (undefined names, method errors). | Catching latent bugs; runs automatically in the test suite (see below). |
| `Test.@inferred f(args...)` | Fails unless the call is type-stable. | Locking a fixed hot-path function against future regressions in a test. |
| `BenchmarkTools.@ballocated f(args...)` | Counts allocations for one call, deterministically. | Locking a hot-path call's allocation behavior in a test. |

`JET` and `BenchmarkTools` are dev/test/docs dependencies only — neither is a
runtime dependency of CTSolvers.

## Checking the hot path at a glance

[`JET.@report_opt`](https://aviatesk.github.io/JET.jl/stable/optanalysis/) inspects
a concrete call and prints `No errors detected` when the call is free of
runtime dispatch. The block below runs **live at documentation build time**, so
if a change ever destabilises this hot-path entry point, this page's build
surfaces it.

```@example perf
using CTSolvers: Integrators
using OrdinaryDiffEqTsit5: Tsit5
using SciMLBase: ODEProblem
using CommonSolve: CommonSolve
using JET

integ = Integrators.SciML(alg=Tsit5())
prob = ODEProblem((u, p, t) -> -u, [1.0], (0.0, 1.0))
r = CommonSolve.solve(prob, integ)
nothing # hide
```

**Evaluating an integration result at a time point** (called at many points
when reading back a trajectory):

```@example perf
JET.@report_opt Integrators.evaluate_at(r, 0.5)
```

**Reading the cached point/trajectory option dictionaries:**

```@example perf
JET.@report_opt Integrators.options_point(integ)
```

Both report `No errors detected`: the repeated-call path is stable.

## What is enforced automatically

The whole-package correctness scan runs as part of the test suite, so a
correctness-level regression fails CI:

```julia
# test/suite/meta/test_jet.jl
JET.test_package(CTSolvers; target_modules=(CTSolvers,))
```

To run the same scan interactively on a fresh checkout:

```julia
using CTSolvers, JET
JET.report_package(CTSolvers; target_modules=(CTSolvers,))
```

Note that `report_package`/`test_package` are **correctness** analyses
(undefined bindings, method errors), not type-stability ones — for stability,
use `@report_opt` on a concrete call as shown above, or the `Test.@inferred`
guards in `test/suite/integrators/test_integrator_type_stability.jl`.

Allocation behavior on the same hot-path calls is locked in as a deterministic
regression guard in `test/suite/meta/test_performance.jl`:

```julia
# Zero-overhead wrapper: evaluate_at costs exactly what the raw ODE solution call does
Test.@test (BenchmarkTools.@ballocated Integrators.evaluate_at($r, $t)) ==
    (BenchmarkTools.@ballocated $(r.ode_sol)($t))

# Zero-allocation reads
Test.@test (BenchmarkTools.@ballocated Integrators.options_point($integ)) == 0
```

## Known, acceptable dynamism

Running `@report_opt` on setup-path entry points does report runtime dispatch.
This is expected and does not indicate a regression:

- **Strategy / options construction and routing**
  (`Strategies.build_strategy_options`, `Options.extract_raw_options`,
  `route_to`/`Strategies.RoutedOption`) uses `Vector`/`Dict`/`NamedTuple`
  storage with abstract element types so that strategies and options can be
  registered and routed at runtime. The dispatch is confined to this setup
  code and is paid once per problem, before any solve.
- **NLP model/solution building** (`Optimization.build_model`,
  `Optimization.build_solution`, `DOCP.DiscretizedModel` construction,
  `Modelers.nlp_model`/`ocp_solution`) dispatches on the concrete
  problem/modeler pair by multiple dispatch, resolved once per solve.

## Investigating a regression

If a hot-path check above starts reporting dispatch, drill in locally:

```julia
using CTSolvers: Integrators
integ = Integrators.SciML(alg=Tsit5())

# 1. Quick look
using InteractiveUtils
@code_warntype Integrators.options_point(integ)

# 2. Navigate the call chain to the root cause
using Cthulhu
@descend Integrators.options_point(integ)
```

Once fixed, lock the result with a stability test so it cannot silently
regress:

```julia
using Test
@inferred Integrators.options_point(integ)
```

## See Also

- [`philosophy/performance.md`](https://github.com/control-toolbox/Handbook/blob/main/philosophy/performance.md)
  in the control-toolbox Handbook: the full hot-path/setup-path workflow this
  page follows.
- [Implementing an Integrator](@ref): where `Integrators.SciML` and the result
  accessors used above come from.
