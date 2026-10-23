# Multiplier Convention

```@meta
CurrentModule = CTSolvers
```

`CommonSolve.solve(nlp, solver)` returns the multipliers of the NLP in the statistics:
`multipliers` (one per constraint row `lcon ≤ c(x) ≤ ucon`), `multipliers_L` and
`multipliers_U` (one per variable, for the bounds `lvar ≤ x ≤ uvar`). The NLP solvers do
not agree on their signs. CTSolvers brings them to **one convention**, the same for every
solver, so that the duals of an optimal control problem do not depend on the solver, nor
on the way the problem is written.

The convention is discussed in
[OptimalControl.jl#1014](https://github.com/control-toolbox/OptimalControl.jl/discussions/1014)
and implemented in
[CTSolvers.jl#288](https://github.com/control-toolbox/CTSolvers.jl/issues/288).

## The convention

A multiplier belongs to a **constraint** and to a **problem**, not to the way they are
written.

1. **`min f` and `max -f` are the same problem**: they have the same multipliers. A
   maximisation `max F` is treated as the minimisation `min -F`.
2. **Inequalities have nonnegative multipliers.** The bound multipliers `zL` and `zU` are
   nonnegative, and so is the multiplier of a constraint row with a **single** finite bound:
   `g(x) ≤ 0` and `-g(x) ≥ 0` are the same constraint, with the same multiplier.
3. **An equality keeps its sign**, the one of the stationarity below: `c(x) = 0` and
   `-c(x) = 0` have opposite multipliers, as they must, since an equality has no preferred
   side.

For the equivalent minimisation of `F_min` (`F_min = F` for `min F`, `-F` for `max F`):

```math
\nabla F_{\min}(x) + J(x)^\top y - z_L + z_U = 0, \qquad z_L, z_U \ge 0,
```

where `y = μU − μL` on a row, with `μL, μU ≥ 0` the multipliers of its lower and upper
side. In the statistics returned by CTSolvers:

| Row or bound | Returned multiplier |
| :--- | :--- |
| `c(x) ≤ u` (only an upper bound) | `μU ≥ 0` |
| `c(x) ≥ l` (only a lower bound) | `μL ≥ 0` |
| `c(x) = b` (equality) | `y`, signed |
| `l ≤ c(x) ≤ u` (two finite bounds) | `y = μU − μL`: `≥ 0` when the upper side is active, `≤ 0` when the lower side is |
| `x ≥ lvar`, `x ≤ uvar` | `zL ≥ 0`, `zU ≥ 0` |

!!! note "Two-sided rows"
    For a row with two finite bounds, the signed value `y = μU − μL` is kept: at most one
    side is active, and its sign tells which. Splitting it into a pair `(μL, μU)` would need
    another field in the statistics.

## Example: eight ways of writing the same problem

The problem of the sign probe (`probe/signs/` in the repository): an equality, an
inequality, an upper bound written as a bound or as a row, an active lower bound, and a
fixed variable. Its solution and multipliers are known in closed form.

```@example mult
using CTSolvers: Solvers
using CommonSolve: solve
using ADNLPModels: ADNLPModel
using NLPModelsIpopt, MadNLP, UnoSolver

f(x) = (x[1] - 3)^2 + (x[2] - 1)^2 - x[3] + x[4] + 2x[5]
c(x) = x[1] + x[2] - 3            # = 0
g(x) = x[1]^2 + x[2]^2 - 6        # ≤ 0, active at the solution

function nlp(; sense, ineq)
    sg = ineq === :le ? 1.0 : -1.0                  # g ≤ 0, or -g ≥ 0
    lg, ug = ineq === :le ? (-Inf, 0.0) : (0.0, Inf)
    return ADNLPModel(
        sense === :min ? f : x -> -f(x),
        [1.0, 1.0, 0.0, 0.5, 0.5],
        [0.0, 0.0, -5.0, 0.0, 0.5], [Inf, Inf, 1.0, 5.0, 0.5],   # x₃ ≤ 1, x₄ ≥ 0, x₅ = 1/2
        x -> [c(x), sg * g(x)], [0.0, lg], [0.0, ug];
        minimize=(sense === :min),
    )
end

solvers = [
    Solvers.Ipopt(; print_level=0, tol=1e-10),
    Solvers.MadNLP(; tol=1e-10),
    Solvers.Uno(; primal_tolerance=1e-10, dual_tolerance=1e-10),
]
rows = []
for solver in solvers, sense in (:min, :max), ineq in (:le, :ge)
    s = solve(nlp(; sense, ineq), solver; display=false)
    push!(rows, (
        solver=nameof(typeof(solver)), sense, ineq,
        y=round.(s.multipliers; digits=4),
        zU3=round(s.multipliers_U[3]; digits=4),
        zL4=round(s.multipliers_L[4]; digits=4),
    ))
end
rows
```

Every line gives the same numbers: `y = (0.5359, 0.1547)` for the equality and the
inequality, `zU = 1` on `x₃`, `zL = 1` on `x₄`.

## What each solver returns natively

CTSolvers applies [`Solvers.normalize_multipliers!`](@ref) at the end of each `solve`. It
calls [`Solvers.reference_multipliers!`](@ref), one method per solver, then makes the
multiplier of every one-sided lower row nonnegative. The native conventions, measured by
the tests of CTSolvers on every way of writing the problem above (NLPModelsIpopt 0.11,
MadNLP 0.10, MadNCL 0.2, UnoSolver 0.3):

| Solver | Stationarity (`min`) | `max F` | Change applied |
| :--- | :--- | :--- | :--- |
| Ipopt | `∇F + Jᵀy − zL + zU = 0` | multipliers of `F` as written: all change sign | negate everything for `max` |
| Uno | `∇F + Jᵀy + zL + zU = 0` (`zL ≤ 0`) | as written: all change sign | negate `zL`; negate everything for `max` |
| MadNLP, MadNCL | `∇F + Jᵀy − zL + zU = 0` | rows as written, bounds of the minimisation | negate `y` for `max` |
| Knitro | `∇F + Jᵀλᶜ + λᵇ = 0`, `F` as written | as written | swap `zL` and `zU` for `min`; negate `y` for `max` |

!!! warning "Knitro is not tested"
    Knitro needs a license, so its convention is derived, not measured: from its manual
    (stationarity with the objective as written, `λ ≥ 0` on an active upper side, `λ ≤ 0` on
    an active lower side) and from NLPModelsKnitro, which maps the bound multiplier
    `λᵇ = zU − zL` as `zL = max(λᵇ, 0)`, `zU = −min(λᵇ, 0)` (its own test `test_maximize`
    checks `zU = 1` for `max x` with `x ≤ 1` active). Please report a mismatch.

The tests pin these native conventions separately from the normalised output: if a solver
changes its convention upstream, the test of its native convention fails and names the
solver and its version; if only the normalised output is wrong, the bug is in CTSolvers.

The raw multipliers of a backend are still available from the functions the extensions
call (`solve_with_ipopt`, `solve_with_madnlp`, …), which do not normalise.

## Downstream

- **Optimal control (CTDirect)**: the duals of the discretised problem are built from these
  multipliers, so `dual(sol, ocp, :label)` has the same sign for `min` and `max`, and a path
  constraint with a single bound has a nonnegative dual.
- **Indirect methods (CTFlows)**: `Flow(ocp, law; constraint=:label, multiplier=μ)` returns
  the same duals, built from `μ` (see the CTFlows documentation, *Constraint duals of a
  flow*).
