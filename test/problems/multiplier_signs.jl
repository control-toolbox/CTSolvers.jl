# The problem of the multiplier sign probe (probe/signs/probe_signs.jl), with its
# multipliers in closed form, written in the eight ways of the probe.
#
#   F = f (min) or F = -f (max), with
#     f(x) = (x₁ - 3)² + (x₂ - 1)² - x₃ + x₄ + 2x₅
#   c(x) = x₁ + x₂ - 3 = 0
#   g(x) = x₁² + x₂² - 6 ≤ 0                     written g ≤ 0 or -g ≥ 0   (active)
#   x₃ ≤ 1    as a bound, or -x₃ ≥ -1 as a row                              (active)
#   x₄ ≥ 0    as a bound                                                    (active)
#   x₅ = 1/2  a fixed variable (lvar = uvar)
#
# Solution x* = ((3 + √3)/2, (3 - √3)/2, 1, 0, 1/2); the multipliers are unique.
module MultiplierSigns

using ADNLPModels: ADNLPModels
using ExaModels: ExaModels

const NVAR = 5
f(x) = (x[1] - 3)^2 + (x[2] - 1)^2 - x[3] + x[4] + 2 * x[5]
c(x) = x[1] + x[2] - 3
g(x) = x[1]^2 + x[2]^2 - 6
const XSTAR = [(3 + sqrt(3)) / 2, (3 - sqrt(3)) / 2, 1.0, 0.0, 0.5]
const X0 = [1.0, 1.0, 0.0, 0.5, 0.5]

"""
One way of writing the problem: `sense` is `:min` or `:max`, `ineq` is `:le` (`g ≤ 0`) or
`:ge` (`-g ≥ 0`), `x3` is `:bound` (`x₃ ≤ 1`) or `:row` (`-x₃ ≥ -1`).
"""
struct Case
    sense::Symbol
    ineq::Symbol
    x3::Symbol
end

const CASES = [
    Case(sense, ineq, x3) for x3 in (:bound, :row) for sense in (:min, :max) for
    ineq in (:le, :ge)
]

function Base.show(io::IO, k::Case)
    return print(
        io,
        k.sense === :min ? "min f" : "max -f",
        ", ",
        k.ineq === :le ? "g ≤ 0" : "-g ≥ 0",
        ", ",
        k.x3 === :bound ? "x₃ ≤ 1 bound" : "-x₃ ≥ -1 row",
    )
end

function var_bounds(k::Case)
    lvar = [0.0, 0.0, -5.0, 0.0, 0.5]
    uvar = [Inf, Inf, k.x3 === :bound ? 1.0 : 5.0, 5.0, 0.5]
    return lvar, uvar
end

ineq_bounds(k::Case) = k.ineq === :le ? (-Inf, 0.0) : (0.0, Inf)

function adnlp(k::Case)
    sg = k.ineq === :le ? 1.0 : -1.0
    F = k.sense === :min ? f : (x -> -f(x))
    rows(x) = k.x3 === :bound ? [c(x), sg * g(x)] : [c(x), sg * g(x), -x[3]]
    lg, ug = ineq_bounds(k)
    lcon = k.x3 === :bound ? [0.0, lg] : [0.0, lg, -1.0]
    ucon = k.x3 === :bound ? [0.0, ug] : [0.0, ug, Inf]
    lvar, uvar = var_bounds(k)
    return ADNLPModels.ADNLPModel(
        F, X0, lvar, uvar, rows, lcon, ucon; minimize=(k.sense === :min)
    )
end

function exa(k::Case)
    sg = k.ineq === :le ? 1.0 : -1.0
    lvar, uvar = var_bounds(k)
    core = ExaModels.ExaCore(; minimize=(k.sense === :min))
    core, x = ExaModels.add_var(core, NVAR; start=X0, lvar=lvar, uvar=uvar)
    core, _ = ExaModels.add_con(core, c(x) for _ in 1:1; lcon=0.0, ucon=0.0)
    lg, ug = ineq_bounds(k)
    core, _ = ExaModels.add_con(core, sg * g(x) for _ in 1:1; lcon=lg, ucon=ug)
    if k.x3 === :row
        core, _ = ExaModels.add_con(core, -x[3] for _ in 1:1; lcon=-1.0, ucon=Inf)
    end
    core, _ = ExaModels.add_obj(core, (k.sense === :min ? 1.0 : -1.0) * f(x) for _ in 1:1)
    return ExaModels.ExaModel(core)
end

const MODELERS = ["ADNLPModels" => adnlp, "ExaModels" => exa]

"""
Multipliers `(yc, yg)` of `c = 0` and `g ≤ 0` for `min f`, from the stationarity in `x₁`,
`x₂`: `∇f + yc ∇c + yg ∇g = 0`.
"""
function row_multipliers()
    x1, x2 = XSTAR[1], XSTAR[2]
    A = [1.0 2x1; 1.0 2x2]
    b = -[2 * (x1 - 3), 2 * (x2 - 1)]
    yc, yg = A \ b
    return yc, yg
end

"""
Multipliers of `k` in the reference stationarity, for the equivalent minimisation:
`∇f + Jᵀy − zL + zU = 0`, `zL, zU ≥ 0`, `y = μU − μL`, as `(y, zL, zU)`. The fixed `x₅`
carries its net multiplier `zU₅ − zL₅ = −2` as `zL₅ = 2`.
"""
function reference(k::Case)
    yc, yg = row_multipliers()
    y = [yc, k.ineq === :le ? yg : -yg]          # -g ≥ 0 is a lower side: y = -μL
    k.x3 === :row && push!(y, -1.0)              # -x₃ ≥ -1 is a lower side
    zL = [0.0, 0.0, 0.0, 1.0, 2.0]
    zU = [0.0, 0.0, k.x3 === :bound ? 1.0 : 0.0, 0.0, 0.0]
    return y, zL, zU
end

"""
Multipliers of `k` in the convention of CTSolvers: the reference, with the multiplier of
each one-sided inequality row made nonnegative. The same for the eight cases, but for
the length of `y`.
"""
function normalized(k::Case)
    yc, yg = row_multipliers()
    y = k.x3 === :row ? [yc, yg, 1.0] : [yc, yg]
    _, zL, zU = reference(k)
    return y, zL, zU
end

end # module MultiplierSigns
