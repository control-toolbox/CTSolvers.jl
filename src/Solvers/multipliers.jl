# Multiplier convention
#
# The NLP solvers return their multipliers in different conventions: the sign of the
# bound multipliers in the stationarity, and the rule for a maximisation (multipliers of
# the objective as written, or of the equivalent minimisation). `CommonSolve.solve(nlp,
# solver)` brings them to one convention, the same for every solver, before returning
# the statistics. See control-toolbox/CTSolvers.jl#288 and the "Multiplier convention"
# page of the documentation.
#
# The normalisation has two steps:
#
#   1. `reference_multipliers!` (one method per solver): from the native convention of the
#      solver to the reference convention of the stationarity, for the equivalent
#      minimisation:
#
#          ∇F_min + Jᵀy − zL + zU = 0,   zL, zU ≥ 0,   y = μU − μL,   μL, μU ≥ 0,
#
#      with F_min = F for a minimisation and F_min = −F for a maximisation.
#   2. `_one_sided_rows!` (the same for every solver): the multiplier of an inequality row
#      with a single finite bound is the nonnegative multiplier of that side, so a row
#      `lcon ≤ c(x)` with `ucon = Inf` gets `μL = −y`.

"""
$(TYPEDSIGNATURES)

Bring the multipliers `stats.multipliers`, `stats.multipliers_L` and
`stats.multipliers_U` returned by `solver` to the convention of CTSolvers, in place, and
return `stats`.

The convention does not depend on the solver, on the sense of the objective, nor on the
way a constraint is written:

- `max F` is the minimisation of `-F`: `min f` and `max -f` have the **same** multipliers.
- The bound multipliers `multipliers_L` (`zL`) and `multipliers_U` (`zU`) are
  nonnegative, with the stationarity `∇F_min + Jᵀy − zL + zU = 0`.
- The multiplier of an inequality row with a **single** finite bound is **nonnegative**:
  `c(x) ≤ u` and `-c(x) ≥ -u` have the same multiplier.
- An equality row, and an inequality row with two finite bounds, keep the signed value
  `y = μU − μL` of the stationarity above: `y ≥ 0` when the upper side is active,
  `y ≤ 0` when the lower side is.

# Arguments

- `stats`: solver statistics with the fields `multipliers`, `multipliers_L` and
  `multipliers_U` (mutated).
- `solver::AbstractNLPSolver`: the solver that produced `stats`; selects the native
  convention through [`reference_multipliers!`](@ref).
- `lcon::AbstractVector`, `ucon::AbstractVector`: the bounds of the constraint rows of
  the NLP.
- `minimize::Bool`: the sense of the objective of the NLP.

# Returns

- `stats`, with its multipliers in the convention of CTSolvers.

# Notes

Called by `CommonSolve.solve(nlp, solver)` in each backend extension, so the statistics
returned by CTSolvers are already normalised. The raw multipliers of a backend are those
of `solve_with_<solver>` in the extension.

See also: [`reference_multipliers!`](@ref).
"""
function normalize_multipliers!(
    stats, solver::AbstractNLPSolver, lcon::AbstractVector, ucon::AbstractVector,
    minimize::Bool,
)
    y, zL, zU = stats.multipliers, stats.multipliers_L, stats.multipliers_U
    reference_multipliers!(solver, y, zL, zU, minimize)
    _one_sided_rows!(y, lcon, ucon)
    return stats
end

"""
$(TYPEDSIGNATURES)

Change the multipliers `y`, `zL`, `zU` returned by `solver`, in place, from its native
convention to the reference one: the multipliers of the equivalent minimisation, with the
stationarity `∇F_min + Jᵀy − zL + zU = 0` and `zL, zU ≥ 0`.

# Contract

Each concrete solver implements this method; it is called by
[`normalize_multipliers!`](@ref). This generic stub throws `NotImplemented`.

| Solver | Native convention | Change |
| --- | --- | --- |
| `Ipopt` | `∇F + Jᵀy − zL + zU = 0`, `F` as written | negate everything for a maximisation |
| `Uno` | `∇F + Jᵀy + zL + zU = 0`, `F` as written | negate `zL`, then everything for a maximisation |
| `MadNLP`, `MadNCL` | rows as written, bounds of the minimisation | negate `y` for a maximisation |
| `Knitro` | `∇F + Jᵀλᶜ + λᵇ = 0`, `F` as written; NLPModelsKnitro sets `zL = max(λᵇ, 0)`, `zU = -min(λᵇ, 0)` | swap `zL` and `zU` for a minimisation, negate `y` for a maximisation |

# Arguments

- `solver::AbstractNLPSolver`: the solver that produced the multipliers.
- `y::AbstractVector`: the multipliers of the constraint rows (mutated).
- `zL::AbstractVector`, `zU::AbstractVector`: the multipliers of the lower and upper
  bounds of the variables (mutated).
- `minimize::Bool`: the sense of the objective.

# Returns

- `nothing`.

# Throws

- [`CTBase.Exceptions.NotImplemented`](@extref): for a solver with no method.

See also: [`normalize_multipliers!`](@ref).
"""
function reference_multipliers!(
    solver::AbstractNLPSolver, y::AbstractVector, zL::AbstractVector, zU::AbstractVector,
    minimize::Bool,
)
    return throw(
        Exceptions.NotImplemented(
            "Multiplier convention not implemented for this solver";
            required_method="reference_multipliers!(solver::$(typeof(solver)), y, zL, zU, minimize)",
            suggestion="Implement `Solvers.reference_multipliers!` for $(typeof(solver)): see the multiplier convention page of the documentation",
            context="Solvers.normalize_multipliers! - native convention of the solver",
        ),
    )
end

# Ipopt: stationarity of F as written, ∇F + Jᵀy − zL + zU = 0.
function reference_multipliers!(
    ::Ipopt, y::AbstractVector, zL::AbstractVector, zU::AbstractVector, minimize::Bool
)
    minimize || _negate!(y, zL, zU)
    return nothing
end

# Uno: stationarity of F as written, ∇F + Jᵀy + zL + zU = 0 (zL ≤ 0 for a minimisation).
function reference_multipliers!(
    ::Uno, y::AbstractVector, zL::AbstractVector, zU::AbstractVector, minimize::Bool
)
    zL .= .-zL
    minimize || _negate!(y, zL, zU)
    return nothing
end

# MadNLP 0.10: for a maximisation the rows are those of F as written (`unpack_y!` applies
# the sign of the objective) but the bounds are those of the minimisation (`unpack_z!`
# does not).
function reference_multipliers!(
    ::MadNLP, y::AbstractVector, ::AbstractVector, ::AbstractVector, minimize::Bool
)
    minimize || (y .= .-y)
    return nothing
end

# MadNCL 0.2 returns the multipliers of its inner MadNLP solve.
function reference_multipliers!(
    ::MadNCL, y::AbstractVector, ::AbstractVector, ::AbstractVector, minimize::Bool
)
    minimize || (y .= .-y)
    return nothing
end

# Knitro (not tested: needs a license). From its manual, ∇F + Jᵀλᶜ + λᵇ = 0 with F as
# written, λ ≥ 0 on an active upper side and λ ≤ 0 on an active lower side, so λᵇ = zU − zL
# for a minimisation. NLPModelsKnitro 0.10 maps zL = max(λᵇ, 0) and zU = −min(λᵇ, 0): the
# two sides are swapped for a minimisation, and are those of the minimisation for a
# maximisation (its `test_maximize`: `max x`, `x ≤ 1` active, gives `zU = 1`).
function reference_multipliers!(
    ::Knitro, y::AbstractVector, zL::AbstractVector, zU::AbstractVector, minimize::Bool
)
    if minimize
        tmp = copy(zL)
        zL .= zU
        zU .= tmp
    else
        y .= .-y
    end
    return nothing
end

function _negate!(y::AbstractVector, zL::AbstractVector, zU::AbstractVector)
    y .= .-y
    zL .= .-zL
    zU .= .-zU
    return nothing
end

"""
$(TYPEDSIGNATURES)

Make the multiplier of each inequality row with a single finite **lower** bound
nonnegative (`μL = −y`), in place. Rows with a single finite upper bound already have
`μU = y ≥ 0`; equalities and rows with two finite bounds are left unchanged.

The bounds may live on the host while `y` lives on a device: the sign is computed on the
host and copied next to `y`.
"""
function _one_sided_rows!(y::AbstractVector, lcon::AbstractVector, ucon::AbstractVector)
    isempty(y) && return y
    T = eltype(y)
    s = [
        isfinite(l) && !isfinite(u) ? -one(T) : one(T) for
        (l, u) in zip(Array(lcon), Array(ucon))
    ]
    y .*= copyto!(similar(y), s)
    return y
end
