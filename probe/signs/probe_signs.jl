#!/usr/bin/env julia
# =============================================================================
# Multiplier sign probe for CTSolvers
# =============================================================================
#
# Which sign convention do the NLP solvers follow for the multipliers they return, and does
# it stay the same when the problem is written differently?
#
# The same small NLP, with a known solution and known active constraints, is written in
# 8 ways: {min f, max -f} × {g ≤ 0, -g ≥ 0} × {x₃ ≤ a as a bound, -x₃ ≥ -a as a constraint
# row}. It is solved by each solver, directly and through CTSolvers, on ADNLPModels and
# ExaModels.
#
# For each way of writing it, the expected multipliers are computed for two candidate
# conventions (see `CONVENTIONS`) from the stationarity condition at the known solution.
# Each solver's output is then compared with both, so the probe states which convention a
# solver follows, rather than assuming one.
#
# The report is Markdown, to paste in an issue or a discussion. It is printed and written to
# `probe/signs/report.md` (git-ignored), or to the path given as first argument.
#
# Diagnostic only: nothing asserts, every cell is try/catch'd, the run always succeeds.
#
#     julia --project=probe/signs probe/signs/probe_signs.jl [report.md]
#
# The header activates this folder's environment and `dev`s the checked-out CTSolvers, so
# the probe measures the working-tree source (Manifest not committed).
# =============================================================================

using Pkg: Pkg
Pkg.activate(@__DIR__)
Pkg.develop(; path=joinpath(@__DIR__, "..", ".."))   # the repo root (this CTSolvers)
Pkg.instantiate()

using CTSolvers: Solvers
using CommonSolve: CommonSolve
using ADNLPModels: ADNLPModels
using ExaModels: ExaModels
using NLPModels: NLPModels
using NLPModelsIpopt: NLPModelsIpopt
using MadNLP: MadNLP
using MadNCL: MadNCL
using UnoSolver: UnoSolver
using Dates: Dates
using Printf: @sprintf

# =============================================================================
# The problem
# =============================================================================
#
#   F = f (min) or F = -f (max), with
#     f(x) = (x₁ - 3)² + (x₂ - 1)² - x₃ + x₄ + 2x₅
#   c(x) = x₁ + x₂ - 3 = 0
#   g(x) = x₁² + x₂² - 6 ≤ 0              (active)
#   x₃ ≤ 1   as a bound, or  -x₃ ≥ -1  as a constraint row   (active)
#   x₄ ≥ 0   as a bound                                       (active)
#   x₅ = 1/2 as a fixed variable (lvar = uvar)
#
# Solution: x* = ((3 + √3)/2, (3 - √3)/2, 1, 0, 1/2). The multipliers are unique (the
# active constraint gradients are linearly independent).

const NVAR = 5
f(x) = (x[1] - 3)^2 + (x[2] - 1)^2 - x[3] + x[4] + 2 * x[5]
c(x) = x[1] + x[2] - 3
g(x) = x[1]^2 + x[2]^2 - 6
const XSTAR = [(3 + sqrt(3)) / 2, (3 - sqrt(3)) / 2, 1.0, 0.0, 0.5]
const X0 = [1.0, 1.0, 0.0, 0.5, 0.5]
const TOL = 1e-10          # solver tolerance
const MATCH = 1e-4         # multiplier agreement

"""
One way of writing the problem: `sense` is `:min` or `:max`, `ineq` is `:le` (`g ≤ 0`) or
`:ge` (`-g ≥ 0`), `box` is `:bound` (`x₃ ≤ 1`) or `:row` (`-x₃ ≥ -1`, a row of the
constraints).
"""
struct Case
    sense::Symbol
    ineq::Symbol
    box::Symbol
end

const CASES = [
    Case(sense, ineq, box) for box in (:bound, :row) for sense in (:min, :max) for
    ineq in (:le, :ge)
]

function label(k::Case)
    return string(
        k.sense === :min ? "min f" : "max -f",
        " · ",
        k.ineq === :le ? "g ≤ 0" : "-g ≥ 0",
        " · ",
        k.box === :bound ? "x₃ ≤ a" : "-x₃ ≥ -a",
    )
end

"Multiplier groups present in `k`, in display order."
function groups(k::Case)
    return if k.box === :bound
        [:y_c, :y_g, :z_x3, :z_x4, :z_x5]
    else
        [:y_c, :y_g, :y_x3, :z_x4, :z_x5]
    end
end

function bounds(k::Case)
    lvar = [0.0, 0.0, -5.0, 0.0, 0.5]
    uvar = [Inf, Inf, k.box === :bound ? 1.0 : 5.0, 5.0, 0.5]
    return lvar, uvar
end

function ineq_bounds(k::Case)
    return k.ineq === :le ? (-Inf, 0.0) : (0.0, Inf)
end

# =============================================================================
# The two modelers
# =============================================================================

function build_adnlp(k::Case)
    sg = k.ineq === :le ? 1.0 : -1.0
    F = k.sense === :min ? f : (x -> -f(x))
    rows(x) = k.box === :bound ? [c(x), sg * g(x)] : [c(x), sg * g(x), -x[3]]
    lg, ug = ineq_bounds(k)
    lcon = k.box === :bound ? [0.0, lg] : [0.0, lg, -1.0]
    ucon = k.box === :bound ? [0.0, ug] : [0.0, ug, Inf]
    lvar, uvar = bounds(k)
    return ADNLPModels.ADNLPModel(
        F, X0, lvar, uvar, rows, lcon, ucon; minimize=(k.sense === :min)
    )
end

function build_exa(k::Case)
    sg = k.ineq === :le ? 1.0 : -1.0
    lvar, uvar = bounds(k)
    core = ExaModels.ExaCore(; minimize=(k.sense === :min))
    core, x = ExaModels.add_var(core, NVAR; start=X0, lvar=lvar, uvar=uvar)
    core, _ = ExaModels.add_con(core, c(x) for _ in 1:1; lcon=0.0, ucon=0.0)
    lg, ug = ineq_bounds(k)
    core, _ = ExaModels.add_con(core, sg * g(x) for _ in 1:1; lcon=lg, ucon=ug)
    if k.box === :row
        core, _ = ExaModels.add_con(core, -x[3] for _ in 1:1; lcon=-1.0, ucon=Inf)
    end
    core, _ = ExaModels.add_obj(core, (k.sense === :min ? 1.0 : -1.0) * f(x) for _ in 1:1)
    return ExaModels.ExaModel(core)
end

const MODELERS = ["ADNLPModels" => build_adnlp, "ExaModels" => build_exa]

# =============================================================================
# The solvers: raw, and through CTSolvers
# =============================================================================

const SOLVERS = [
    "Ipopt" => nlp -> NLPModelsIpopt.ipopt(nlp; print_level=0, tol=TOL),
    "MadNLP" =>
        nlp -> MadNLP.solve!(MadNLP.MadNLPSolver(nlp; print_level=MadNLP.ERROR, tol=TOL)),
    "Uno" =>
        nlp ->
            UnoSolver.uno(nlp; logger="SILENT", primal_tolerance=TOL, dual_tolerance=TOL),
    "CTSolvers.Ipopt" =>
        nlp ->
            CommonSolve.solve(nlp, Solvers.Ipopt(; print_level=0, tol=TOL); display=false),
    "CTSolvers.MadNLP" =>
        nlp -> CommonSolve.solve(nlp, Solvers.MadNLP(; tol=TOL); display=false),
    "CTSolvers.MadNCL" =>
        nlp -> CommonSolve.solve(nlp, Solvers.MadNCL(; tol=TOL); display=false),
    "CTSolvers.Uno" =>
        nlp -> CommonSolve.solve(
            nlp, Solvers.Uno(; primal_tolerance=TOL, dual_tolerance=TOL); display=false
        ),
]

# =============================================================================
# Conventions, expected multipliers, and what a solver returned
# =============================================================================
#
# Both conventions write the stationarity of the Lagrangian at the solution for the
# objective F AS WRITTEN IN THE MODEL (so for `max -f` it is `F = -f`, not `f`):
#
#     ∇F + Jᵀy + sL·zL + sU·zU = 0,
#
# where `y` is the multiplier of the rows of the constraint vector (J is their Jacobian),
# and `zL`, `zU` are the multipliers of the lower and upper bounds.

"""
A candidate convention: `sL` and `sU` are the signs of `zL` and `zU` in the stationarity.
"""
struct Convention
    name::Symbol
    sL::Int
    sU::Int
    text::String
end

const CONVENTIONS = [
    Convention(:A, -1, +1, "∇F + Jᵀy − zL + zU = 0   (zL ≥ 0, zU ≥ 0 for a minimisation)"),
    Convention(:B, +1, +1, "∇F + Jᵀy + zL + zU = 0   (zL ≤ 0, zU ≥ 0 for a minimisation)"),
]

"""
Expected multipliers of `nlp` at `XSTAR` under `conv`, as a `Dict(group => value)`. The
active set is the one of the problem (see the header), so they come from one square linear
system. A fixed variable has a single net multiplier, `sL·zL + sU·zU`.
"""
function expected(conv::Convention, nlp, k::Case)
    G = NLPModels.grad(nlp, XSTAR)
    J = NLPModels.jac(nlp, XSTAR)
    e(i) = (v = zeros(NVAR); v[i] = 1.0; v)
    cols = Matrix{Float64}[Matrix(J')]   # y, one per row
    k.box === :bound && push!(cols, reshape(conv.sU * e(3), :, 1))      # zU on x₃
    push!(cols, reshape(conv.sL * e(4), :, 1))                          # zL on x₄
    push!(cols, reshape(e(5), :, 1))                                    # net on x₅
    w = hcat(cols...) \ (-G)
    out = Dict{Symbol,Float64}(:y_c => w[1], :y_g => w[2])
    if k.box === :bound
        out[:z_x3], out[:z_x4], out[:z_x5] = w[3], w[4], w[5]
    else
        out[:y_x3], out[:z_x4], out[:z_x5] = w[3], w[4], w[5]
    end
    return out
end

field(s, name) =
    try
        Float64.(collect(getproperty(s, name)))
    catch
        Float64[]
    end

"""
What a solver returned for `k`, as `Dict(group => value)` under `conv` (the net multiplier
of the fixed variable depends on it), or `nothing` if the result has no usable multipliers.
A bound multiplier reported on the wrong side counts as wrong (`NaN` marks it).
"""
function observed(conv::Convention, stats, k::Case)
    y, zL, zU = field(stats, :multipliers),
    field(stats, :multipliers_L),
    field(stats, :multipliers_U)
    ny = k.box === :bound ? 2 : 3
    (length(y) == ny && length(zL) == NVAR && length(zU) == NVAR) || return nothing
    out = Dict{Symbol,Float64}(:y_c => y[1], :y_g => y[2])
    if k.box === :bound
        out[:z_x3] = abs(zL[3]) < MATCH ? zU[3] : NaN
    else
        out[:y_x3] = y[3]
    end
    out[:z_x4] = abs(zU[4]) < MATCH ? zL[4] : NaN
    out[:z_x5] = conv.sL * zL[5] + conv.sU * zU[5]
    return out
end

"Groups where `obs` differs from `exp`, for `k`."
function mismatches(obs, exp, k::Case)
    return [gr for gr in groups(k) if !(abs(obs[gr] - exp[gr]) < MATCH)]
end

"""
Verdict of one solver on one case: the name of the convention it follows, or, if it follows
none, the closest one and the groups that differ. Also returns the raw multipliers, to
compare solvers with each other, and the observations under the first convention, to compare
`min f` with `max -f`.
"""
function verdict(stats, nlp, k::Case)
    obs1 = observed(CONVENTIONS[1], stats, k)
    obs1 === nothing && return ("n/a", Float64[], Dict{Symbol,Float64}())
    best = nothing
    for conv in CONVENTIONS
        bad = mismatches(observed(conv, stats, k), expected(conv, nlp, k), k)
        (best === nothing || length(bad) < length(best.bad)) && (best = (; conv, bad))
    end
    raw = vcat(
        field(stats, :multipliers),
        field(stats, :multipliers_L),
        field(stats, :multipliers_U),
    )
    status = string(getproperty(stats, :status))
    converged = status in
    ("first_order", "SOLVE_SUCCEEDED", "acceptable", "SOLVED_TO_ACCEPTABLE_LEVEL")
    text = if isempty(best.bad)
        "**$(best.conv.name)**"
    else
        "≈$(best.conv.name) ✗ " * join(string.(best.bad), ", ")
    end
    return (converged ? text : text * " ⚠ $status", raw, obs1)
end

# =============================================================================
# Run
# =============================================================================

println("CTSolvers multiplier sign probe — Julia ", VERSION)

# results[(modeler, solver, case index)] = (verdict, raw multipliers, observed multipliers)
results = Dict{Tuple{String,String,Int},Tuple{String,Vector{Float64},Dict{Symbol,Float64}}}()
for (mname, build) in MODELERS, (sname, run) in SOLVERS, (i, k) in enumerate(CASES)
    results[(mname, sname, i)] = try
        nlp = build(k)
        verdict(run(nlp), nlp, k)
    catch e
        ("ERR " * first(sprint(showerror, e), 40), Float64[], Dict{Symbol,Float64}())
    end
end

# =============================================================================
# Markdown report
# =============================================================================

function versions()
    wanted = [
        "CTSolvers",
        "NLPModels",
        "ADNLPModels",
        "ExaModels",
        "NLPModelsIpopt",
        "MadNLP",
        "MadNCL",
        "UnoSolver",
    ]
    deps = Pkg.dependencies()
    byname = Dict(info.name => info for (_, info) in deps)
    jlls = sort([n for n in keys(byname) if occursin(r"^(Ipopt|libuno|Uno)\w*_jll$", n)])
    out = String[]
    for n in vcat(wanted, jlls)
        haskey(byname, n) && push!(out, "| `$n` | $(byname[n].version) |")
    end
    return out
end

function table(io, header, rows)
    println(io, "| ", join(header, " | "), " |")
    println(io, "|", join(fill(" --- ", length(header)), "|"), "|")
    for r in rows
        println(io, "| ", join(r, " | "), " |")
    end
    println(io)
end

num(x) = @sprintf("%+.4f", x)

# `min f` and `max -f` written the same way: cases (1,3), (2,4), (5,7), (6,8).
const PAIRS = [(i, i + 2) for i in (1, 2, 5, 6)]

"Classes of multipliers, with the groups they gather."
const CLASSES = [
    "rows `y`" => [:y_c, :y_g, :y_x3],
    "upper bound `zU(x₃)`" => [:z_x3],
    "lower bound `zL(x₄)`" => [:z_x4],
    "fixed variable, net(x₅)" => [:z_x5],
]

"""
How a multiplier moves from `min f` to `max -f` (same problem, same constraints): `flips`
if it changes sign, `same` if it does not, `?` otherwise.
"""
function relation(a, b)
    (isnan(a) || isnan(b)) && return "?"
    abs(a) < MATCH && abs(b) < MATCH && return "0"
    abs(a + b) < MATCH && return "flips"
    abs(a - b) < MATCH && return "same"
    return "?"
end

"Relations over every pair and modeler, for the groups of one class."
function relations(sname, groups_of_class)
    rels = String[]
    for (mname, _) in MODELERS, (imin, imax) in PAIRS
        omin, omax = results[(mname, sname, imin)][3], results[(mname, sname, imax)][3]
        for gr in groups_of_class
            (haskey(omin, gr) && haskey(omax, gr)) &&
                push!(rels, relation(omin[gr], omax[gr]))
        end
    end
    isempty(rels) && return "n/a"
    u = unique(rels)
    return join(u, " / ")
end

function report()
    io = IOBuffer()
    println(
        io,
        "## Multiplier signs of the NLP solvers: `min f` vs `max -f`, bound vs constraint row\n",
    )
    println(
        io,
        "Generated by `probe/signs/probe_signs.jl` of CTSolvers on ",
        Dates.today(),
        " (Julia ",
        VERSION,
        ").\n",
    )
    table(
        io, ["Package", "Version"], [split(strip(r, ['|', ' ']), " | ") for r in versions()]
    )

    println(io, "### Problem\n")
    println(io, "```text")
    println(
        io,
        "F = f  (min)   or   F = -f  (max),   f(x) = (x₁ - 3)² + (x₂ - 1)² - x₃ + x₄ + 2x₅",
    )
    println(io, "c(x) = x₁ + x₂ - 3 = 0")
    println(
        io, "g(x) = x₁² + x₂² - 6 ≤ 0           written  g ≤ 0   or   -g ≥ 0      (active)"
    )
    println(
        io,
        "x₃ ≤ 1                             written  as a bound, or as the row -x₃ ≥ -1   (active)",
    )
    println(io, "x₄ ≥ 0                             a bound   (active)")
    println(io, "x₅ = 1/2                           a fixed variable (lvar = uvar)")
    println(io, "x* = ((3 + √3)/2, (3 - √3)/2, 1, 0, 1/2)")
    println(io, "```\n")
    println(io, "Eight ways of writing it (`max -f` is the same problem as `min f`):\n")
    table(io, ["#", "Case"], [[string(i), label(k)] for (i, k) in enumerate(CASES)])

    println(io, "### Notation and conventions\n")
    println(
        io,
        "`F` is the objective **as written in the model** (`F = -f` for `max -f`). `y` is the multiplier of the rows of the constraint vector (`J` is their Jacobian), `zL` and `zU` are those of the lower and upper bounds, and `x₅` has a single net multiplier. Two candidate conventions, both for the stationarity at the solution:\n",
    )
    for conv in CONVENTIONS
        println(io, "- **", conv.name, "**: `", conv.text, "`")
    end
    println(
        io,
        "\nThey differ only in the sign of `zL`. With the active set above the multipliers are unique, so each convention gives one expected value per multiplier, computed from the gradient and Jacobian of the model at `x*`.\n",
    )

    println(io, "### Expected values\n")
    model_for_truth = build_adnlp
    for conv in CONVENTIONS
        println(io, "Convention **", conv.name, "**:\n")
        rows = Vector{Vector{String}}()
        for (i, k) in enumerate(CASES)
            t = expected(conv, model_for_truth(k), k)
            bx = k.box === :bound ? "zU(x₃) = " * num(t[:z_x3]) : "y₃ = " * num(t[:y_x3])
            push!(
                rows,
                [string(i), num(t[:y_c]), num(t[:y_g]), bx, num(t[:z_x4]), num(t[:z_x5])],
            )
        end
        table(io, ["#", "y_c", "y_g", "x₃", "zL(x₄)", "net(x₅)"], rows)
    end

    println(io, "### What each solver returns\n")
    println(
        io,
        "A cell is the convention the solver follows (**A** or **B**) when all multipliers match it. Otherwise it is `≈X ✗ groups`: the closest convention and the multipliers that differ (`y_c`, `y_g`, `y_x3` row multipliers; `z_x3`, `z_x4` bound multipliers; `z_x5` net multiplier of the fixed variable). A bound multiplier on the wrong side counts as wrong. `⚠ status` marks a solve that did not converge.\n",
    )
    for (mname, _) in MODELERS
        println(io, "#### ", mname, "\n")
        rows = [
            [sname; [results[(mname, sname, i)][1] for i in eachindex(CASES)]] for
            (sname, _) in SOLVERS
        ]
        table(io, vcat(["Solver"], string.(1:length(CASES))), rows)
    end

    println(io, "#### Does the multiplier change sign from `min f` to `max -f`?\n")
    println(
        io,
        "Independent of any convention: the same problem is written as `min f` and as `max -f` (cases 1/3, 2/4, 5/7, 6/8), and each multiplier of the second is compared with the one of the first. A solver that reports the multipliers of the objective as written should show `flips` everywhere (the objective is `-f`, so every multiplier changes sign). `same` means the multiplier is reported for the equivalent minimisation. Read it together with the verdicts above: a solver whose bound multipliers do not flip can look like the other convention on some cases.\n",
    )
    table(
        io,
        vcat(["Solver"], first.(CLASSES)),
        [[sname; [relations(sname, last(cl)) for cl in CLASSES]] for (sname, _) in SOLVERS],
    )

    println(io, "#### Same on both modelers, and CTSolvers vs the raw solver\n")
    same_models = all(
        results[("ADNLPModels", s, i)][1] == results[("ExaModels", s, i)][1] for
        (s, _) in SOLVERS, i in eachindex(CASES)
    )
    println(
        io, "- ADNLPModels and ExaModels give the same verdicts: **", same_models, "**."
    )
    for name in ("Ipopt", "MadNLP", "Uno")
        same = all(
            m == "n/a" || (
                results[(m, name, i)][1] == results[(m, "CTSolvers." * name, i)][1] &&
                isapprox(
                    results[(m, name, i)][2],
                    results[(m, "CTSolvers." * name, i)][2];
                    atol=1e-6,
                )
            ) for (m, _) in MODELERS, i in eachindex(CASES)
        )
        println(
            io,
            "- `CTSolvers.",
            name,
            "` returns the same multipliers as the raw `",
            name,
            "`: **",
            same,
            "**.",
        )
    end
    println(io)
    return String(take!(io))
end

md = report()
println()
println(md)
out = isempty(ARGS) ? joinpath(@__DIR__, "report.md") : ARGS[1]
write(out, md)
println("Report written to ", out)
