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
    # the same with multipliers=:native: the raw multipliers of the backend
    "CTSolvers.Ipopt (native)" =>
        nlp -> CommonSolve.solve(
            nlp,
            Solvers.Ipopt(; print_level=0, tol=TOL, multipliers=:native);
            display=false,
        ),
    "CTSolvers.MadNLP (native)" =>
        nlp -> CommonSolve.solve(
            nlp, Solvers.MadNLP(; tol=TOL, multipliers=:native); display=false
        ),
    "CTSolvers.Uno (native)" =>
        nlp -> CommonSolve.solve(
            nlp,
            Solvers.Uno(;
                primal_tolerance=TOL, dual_tolerance=TOL, multipliers=:native
            );
            display=false,
        ),
]

# =============================================================================
# Conventions, expected multipliers, and what a solver returned
# =============================================================================
#
# A convention is the choice of three things, not only of the signs in one equation:
#
#   1. the stationarity of the Lagrangian at the solution, for the objective F AS WRITTEN IN
#      THE MODEL (for `max -f` it is `F = -f`, not `f`):
#
#          ∇F + Jᵀy + sL·zL + sU·zU = 0,
#
#      where `y` gathers the multipliers of the rows `lcon ≤ c(x) ≤ ucon` (the equality, the
#      inequality, and the bound written as a row): one signed value per row, `y = μU - μL`
#      with `μL, μU ≥ 0` the multipliers of the lower and upper side of the row, at most one
#      of them nonzero, so `Jᵀy = Jᵀ(μU - μL)` and an equality has one signed `y`. `J` is the
#      Jacobian of the rows. `zL`, `zU` are the same for the bounds of the variables, kept in
#      two vectors (`multipliers_L`, `multipliers_U`) by the NLPModels interface;
#   2. the dual feasibility, i.e. the sign of the multipliers for a minimisation: `μL`, `μU`,
#      and the part of `zL`, `zU` that enters with a minus sign, are nonnegative;
#   3. the rule for a maximisation. A solver maximises F by minimising -F, so it can report
#      either the multipliers of F as written (`:written`: they all change sign with the
#      sense, and dual feasibility flips), or those of the equivalent minimisation min(-F)
#      (`:min_equivalent`: they do not change sign, and dual feasibility is the one of a
#      minimisation). For a minimisation the two rules coincide.

"""
A convention: the signs `sL` and `sU` of `zL` and `zU` in the stationarity (`stationarity` is
its name), and the `rule` for a maximisation, `:written` or `:min_equivalent`. The dual
feasibility is implied by the stationarity signs: a multiplier enters the stationarity with
the sign that makes it nonnegative for a minimisation.
"""
struct Convention
    stationarity::Symbol
    sL::Int
    sU::Int
    rule::Symbol
    text::String
end

const STATIONARITIES = [
    (:A, -1, +1, "∇F + Jᵀy − zL + zU = 0, with μL, μU, zL, zU ≥ 0 for a minimisation"),
    (
        :B,
        +1,
        +1,
        "∇F + Jᵀy + zL + zU = 0, with μL, μU, zU ≥ 0 and zL ≤ 0 for a minimisation",
    ),
]

const CONVENTIONS = [
    Convention(name, sL, sU, rule, text) for (name, sL, sU, text) in STATIONARITIES for
    rule in (:written, :min_equivalent)
]

"Name of `conv` as it applies to `k`: the rule only matters for a maximisation."
function shortname(conv::Convention, k::Case)
    k.sense === :min && return string(conv.stationarity)
    return string(
        conv.stationarity, ", ", conv.rule === :written ? "as written" : "min-equiv."
    )
end

"Long name of `conv`."
function longname(conv::Convention)
    return string(
        conv.stationarity, ", ", conv.rule === :written ? "as written" : "min-equiv."
    )
end

"""
Whether the expected multipliers `t` of `k` satisfy the dual feasibility of `conv`: for a
minimisation, the multiplier of an active upper side is `≥ 0`, that of an active lower side
`≤ 0` (`y = μU - μL`), and `zU`, and `-sL·zL`, are `≥ 0`. For a maximisation with the
`:written` rule every sign flips.
"""
function dual_feasible(conv::Convention, t, k::Case)
    m = conv.rule === :written && k.sense === :max ? -1 : 1
    ok = m * t[:y_g] * (k.ineq === :le ? 1 : -1) ≥ -MATCH
    ok &= m * conv.sL * t[:z_x4] ≤ MATCH
    ok &= k.box === :bound ? m * t[:z_x3] ≥ -MATCH : m * t[:y_x3] ≤ MATCH
    return ok
end

"""
Expected multipliers of `nlp` at `XSTAR` under `conv`, as a `Dict(group => value)`. The
active set is the one of the problem (see the header), so they come from one square linear
system. A fixed variable has a single net multiplier, `sL·zL + sU·zU`. With the
`:min_equivalent` rule, a maximisation is solved as the minimisation of `-F`.
"""
function expected(conv::Convention, nlp, k::Case)
    G = NLPModels.grad(nlp, XSTAR)
    J = NLPModels.jac(nlp, XSTAR)
    e(i) = (v = zeros(NVAR); v[i] = 1.0; v)
    cols = Matrix{Float64}[Matrix(J')]   # y, one per row
    k.box === :bound && push!(cols, reshape(conv.sU * e(3), :, 1))      # zU on x₃
    push!(cols, reshape(conv.sL * e(4), :, 1))                          # zL on x₄
    push!(cols, reshape(e(5), :, 1))                                    # net on x₅
    m = conv.rule === :min_equivalent && k.sense === :max ? -1.0 : 1.0
    w = hcat(cols...) \ (-m * G)
    out = Dict{Symbol,Float64}(:y_c => w[1], :y_g => w[2])
    if k.box === :bound
        out[:z_x3], out[:z_x4], out[:z_x5] = w[3], w[4], w[5]
    else
        out[:y_x3], out[:z_x4], out[:z_x5] = w[3], w[4], w[5]
    end
    return out
end

"""
Expected multipliers of `nlp` in the convention of CTSolvers (ct-conventions `SGN1`–`SGN3`):
the multipliers of the equivalent minimisation with the stationarity A, and the multiplier
of a row with a single finite **lower** bound made nonnegative (`μL = −y`). Here those rows
are `-g ≥ 0` and `-x₃ ≥ -1`. The eight cases then give the same numbers.
"""
function expected_ctsolvers(nlp, k::Case)
    t = expected(CONVENTIONS[conv_index(:A, :min_equivalent)], nlp, k)
    k.ineq === :ge && (t[:y_g] = -t[:y_g])
    k.box === :row && (t[:y_x3] = -t[:y_x3])
    return t
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
What one solver returned for one case: for each entry of `CONVENTIONS`, the groups where its
multipliers differ from the expected ones (`bads`) and the multipliers as read under that
convention (`obs`); the raw multipliers, to compare solvers with each other; the solver
status; and an error message if the run failed (`err`).
"""
struct Outcome
    bads::Vector{Vector{Symbol}}
    obs::Vector{Dict{Symbol,Float64}}
    raw::Vector{Float64}
    status::String
    err::String
    ctsolvers::Bool   # matches the convention of CTSolvers (see `expected_ctsolvers`)
end

Outcome(err::AbstractString) = Outcome([], [], Float64[], "", String(err), false)

function measure(stats, nlp, k::Case)
    observed(CONVENTIONS[1], stats, k) === nothing && return Outcome("n/a")
    obs = [observed(conv, stats, k) for conv in CONVENTIONS]
    bads = [
        mismatches(obs[j], expected(conv, nlp, k), k) for
        (j, conv) in enumerate(CONVENTIONS)
    ]
    raw = vcat(
        field(stats, :multipliers),
        field(stats, :multipliers_L),
        field(stats, :multipliers_U),
    )
    ct = isempty(mismatches(obs[1], expected_ctsolvers(nlp, k), k))
    return Outcome(bads, obs, raw, string(getproperty(stats, :status)), "", ct)
end

function conv_index(name::Symbol, rule::Symbol)
    return findfirst(c -> c.stationarity == name && c.rule === rule, CONVENTIONS)
end

"""
Stationarity convention (`:A` or `:B`) followed by a solver on every minimisation case, or
`nothing`. For a minimisation the two rules coincide, so this is the part of the convention
that is read without ambiguity.
"""
function stationarity_of(mname, sname)
    mins = [i for (i, k) in enumerate(CASES) if k.sense === :min]
    for (name, _, _, _) in STATIONARITIES
        j = conv_index(name, :written)
        all(
            !isempty(results[(mname, sname, i)].bads) &&
                isempty(results[(mname, sname, i)].bads[j]) for i in mins
        ) && return name
    end
    return nothing
end

"The multipliers are checked in two classes: the rows `y`, and everything on the variables."
const ROW_GROUPS = [:y_c, :y_g, :y_x3]
const VAR_GROUPS = [:z_x3, :z_x4, :z_x5]

"""
For a maximisation, how a solver that follows stationarity `S` treats a class of
multipliers: `"as written"`, `"min-equiv."`, or `"neither"`.
"""
function class_rule(bw, be, class)
    any(g -> g in bw, class) || return "as written"
    any(g -> g in be, class) || return "min-equiv."
    return "neither"
end

"""
Rules of a solver on case `i`, as `(rows, variables)`, or `nothing` when it follows no
stationarity convention on the minimisations.
"""
function rules(mname, sname, i)
    o = results[(mname, sname, i)]
    S = stationarity_of(mname, sname)
    (S === nothing || isempty(o.bads)) && return nothing
    bw, be = o.bads[conv_index(S, :written)], o.bads[conv_index(S, :min_equivalent)]
    return (class_rule(bw, be, ROW_GROUPS), class_rule(bw, be, VAR_GROUPS))
end

"""
Cell of the verdict tables: the convention a solver follows on a case when all its
multipliers match it, `none` otherwise.
"""
function cell(mname, sname, i)
    o = results[(mname, sname, i)]
    isempty(o.bads) && return o.err
    k = CASES[i]
    S = stationarity_of(mname, sname)
    # CTSolvers coincides with A on some cases: claim it only for a solver that follows it
    # in every case
    ct_row = all(results[(mname, sname, j)].ctsolvers for j in eachindex(CASES))
    text = if ct_row
        "**CTSolvers**"
    elseif S === nothing
        "**none**"
    elseif k.sense === :min
        isempty(o.bads[conv_index(S, :written)]) ? "**$S**" : "**none**"
    elseif isempty(o.bads[conv_index(S, :written)])
        "**$S, as written**"
    elseif isempty(o.bads[conv_index(S, :min_equivalent)])
        "**$S, min-equiv.**"
    else
        "**none**"
    end
    ok = o.status in
    ("first_order", "SOLVE_SUCCEEDED", "acceptable", "SOLVED_TO_ACCEPTABLE_LEVEL")
    return ok ? text : text * " ⚠ " * o.status
end

# =============================================================================
# Run
# =============================================================================

println("CTSolvers multiplier sign probe — Julia ", VERSION)

# results[(modeler, solver, case index)] = Outcome
results = Dict{Tuple{String,String,Int},Outcome}()
for (mname, build) in MODELERS, (sname, run) in SOLVERS, (i, k) in enumerate(CASES)
    results[(mname, sname, i)] = try
        nlp = build(k)
        measure(run(nlp), nlp, k)
    catch e
        Outcome("ERR " * first(sprint(showerror, e), 40))
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
    return println(io)
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
        omin, omax = results[(mname, sname, imin)], results[(mname, sname, imax)]
        (isempty(omin.obs) || isempty(omax.obs)) && continue
        omin, omax = omin.obs[1], omax.obs[1]
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
        "`F` is the objective **as written in the model** (`F = -f` for `max -f`), and the solvers maximise it by minimising `-F`. `y` gathers the multipliers of the rows `lcon ≤ c(x) ≤ ucon`, i.e. of the equality `c`, of the inequality `g` and, in the row form, of `-x₃ ≥ -a`: one signed value per row, `y = μU − μL`, where `μL, μU` are the multipliers of the lower and upper side of the row, at most one being nonzero. So `Jᵀy = Jᵀ(μU − μL)`, `J` being the Jacobian of the rows, and an equality has a single signed `y`. `zL` and `zU` are the same thing for the bounds of the variables `lvar ≤ x ≤ uvar`, stored in two vectors; `x₅`, fixed, has a single net multiplier.\n",
    )
    println(io, "A **convention** is the choice of three things:\n")
    println(
        io,
        "1. the stationarity of the Lagrangian at the solution, for `F` as written, i.e. the signs of the multipliers in `∇F + Jᵀy ± zL + zU = 0`;",
    )
    println(
        io,
        "2. the dual feasibility, i.e. which multipliers are nonnegative for a minimisation (`μL`, `μU`, `zU`, and `zL` or `-zL` according to its sign in the stationarity);",
    )
    println(
        io,
        "3. the rule for a **maximisation**: the solver reports either the multipliers of `F` as written (**as written**: every multiplier changes sign with the sense, and so does dual feasibility), or those of the equivalent minimisation `min(-F)` (**min-equiv.**: nothing changes sign). For a minimisation the two rules coincide.\n",
    )
    println(io, "That gives four conventions:\n")
    table(
        io,
        ["Convention", "Stationarity and dual feasibility (minimisation)", "Maximisation"],
        [
            [
                "**" *
                string(conv.stationarity) *
                ", " *
                (conv.rule === :written ? "as written" : "min-equiv.") *
                "**",
                "`" * conv.text * "`",
                if conv.rule === :written
                    "multipliers of `F` as written: all flip"
                else
                    "multipliers of `min(-F)`: none flips"
                end,
            ] for conv in CONVENTIONS
        ],
    )
    println(
        io,
        "A fifth convention, **CTSolvers**, is the one `CommonSolve.solve(nlp, solver)` returns (ct-conventions `SGN1`–`SGN3`): stationarity A for the equivalent minimisation (`max -f` has the multipliers of `min f`), and a nonnegative multiplier for a row with a single finite bound (`-g ≥ 0` has the multiplier of `g ≤ 0`, the row `-x₃ ≥ -a` that of the bound `x₃ ≤ a`). All eight cases give the same numbers. The raw multipliers of the backend are returned with `multipliers=:native` (the rows `CTSolvers.* (native)`).\n",
    )
    println(
        io,
        "With the active set above the multipliers are unique, so each convention gives one expected value per multiplier, computed from the gradient and Jacobian of the model at `x*`. A solver follows a convention if **all** its multipliers match.\n",
    )

    println(io, "### Expected values\n")
    model_for_truth = build_adnlp
    all_feasible = true
    for conv in CONVENTIONS
        println(io, "<details><summary>Convention <b>", longname(conv), "</b></summary>\n")
        rows = Vector{Vector{String}}()
        for (i, k) in enumerate(CASES)
            t = expected(conv, model_for_truth(k), k)
            all_feasible &= dual_feasible(conv, t, k)
            bx = k.box === :bound ? "zU(x₃) = " * num(t[:z_x3]) : "y₃ = " * num(t[:y_x3])
            push!(
                rows,
                [string(i), num(t[:y_c]), num(t[:y_g]), bx, num(t[:z_x4]), num(t[:z_x5])],
            )
        end
        table(
            io, ["#", "y_c (equality)", "y_g (inequality)", "x₃", "zL(x₄)", "net(x₅)"], rows
        )
        println(io, "</details>\n")
    end
    println(io, "<details><summary>Convention <b>CTSolvers</b></summary>\n")
    rows = Vector{Vector{String}}()
    for (i, k) in enumerate(CASES)
        t = expected_ctsolvers(model_for_truth(k), k)
        bx = k.box === :bound ? "zU(x₃) = " * num(t[:z_x3]) : "y₃ = " * num(t[:y_x3])
        push!(
            rows, [string(i), num(t[:y_c]), num(t[:y_g]), bx, num(t[:z_x4]), num(t[:z_x5])]
        )
    end
    table(io, ["#", "y_c (equality)", "y_g (inequality)", "x₃", "zL(x₄)", "net(x₅)"], rows)
    println(io, "</details>\n")
    println(
        io,
        "The expected values satisfy the dual feasibility of their convention in every case: **",
        all_feasible,
        "**.\n",
    )

    println(io, "### What each solver returns\n")
    println(
        io,
        "A cell is the convention the solver follows when **all** its multipliers match it: **A** or **B** for a minimisation (the two rules for a maximisation coincide there), and **A, as written** / **A, min-equiv.** (or B) for a maximisation. If they match none of the considered conventions, the cell is **none**, and the multipliers that disagree are listed below. `⚠ status` marks a solve that did not converge.\n",
    )
    for (mname, _) in MODELERS
        println(io, "#### ", mname, "\n")
        rows = [
            [sname; [cell(mname, sname, i) for i in eachindex(CASES)]] for
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
    ct_all = all(
        results[(m, s, i)].ctsolvers for (m, _) in MODELERS,
        s in ("CTSolvers.Ipopt", "CTSolvers.MadNLP", "CTSolvers.MadNCL", "CTSolvers.Uno"),
        i in eachindex(CASES)
    )
    println(
        io,
        "- `CTSolvers.*` (normalised) follow the **CTSolvers** convention in every case, on both modelers: **",
        ct_all,
        "**.",
    )
    same_models = all(
        cell("ADNLPModels", s, i) == cell("ExaModels", s, i) for (s, _) in SOLVERS,
        i in eachindex(CASES)
    )
    println(
        io, "- ADNLPModels and ExaModels give the same verdicts: **", same_models, "**."
    )
    for name in ("Ipopt", "MadNLP", "Uno")
        same = all(
            isempty(results[(m, name, i)].bads) || (
                cell(m, name, i) == cell(m, "CTSolvers." * name * " (native)", i) &&
                isapprox(
                    results[(m, name, i)].raw,
                    results[(m, "CTSolvers." * name * " (native)", i)].raw;
                    atol=1e-6,
                )
            ) for (m, _) in MODELERS, i in eachindex(CASES)
        )
        println(
            io,
            "- `CTSolvers.",
            name,
            " (native)` (`multipliers=:native`) returns the same multipliers as the raw `",
            name,
            "`: **",
            same,
            "**.",
        )
    end
    println(io)

    # ---- multipliers that disagree with the conventions -------------------------------------
    disagree = [
        (sname, i) for (sname, _) in SOLVERS for
        i in eachindex(CASES) if occursin("none", cell("ADNLPModels", sname, i)) &&
        !startswith(sname, "CTSolvers.") ||
        (sname == "CTSolvers.MadNCL" && occursin("none", cell("ADNLPModels", sname, i)))
    ]
    if !isempty(disagree)
        println(io, "#### Multipliers that disagree with the conventions\n")
        println(
            io,
            "For the cases where a solver follows none of the conventions (ADNLPModels; ExaModels is identical), its multipliers next to the expected ones for its own stationarity convention (the one it follows on every minimisation), under both rules for a maximisation. The solver's value is in **bold** when it matches neither rule.\n",
        )
        for sname in unique(first.(disagree))
            S = stationarity_of("ADNLPModels", sname)
            println(
                io,
                "<details><summary><b>",
                sname,
                "</b> (stationarity ",
                S,
                ")</summary>\n",
            )
            rows = Vector{Vector{String}}()
            for (sn, i) in disagree
                sn == sname || continue
                k = CASES[i]
                o = results[("ADNLPModels", sname, i)]
                jw, je = conv_index(S, :written), conv_index(S, :min_equivalent)
                tw = expected(CONVENTIONS[jw], build_adnlp(k), k)
                te = expected(CONVENTIONS[je], build_adnlp(k), k)
                for gr in groups(k)
                    v = o.obs[jw][gr]
                    miss = !(abs(v - tw[gr]) < MATCH) && !(abs(v - te[gr]) < MATCH)
                    push!(
                        rows,
                        [
                            string(i),
                            string(gr),
                            miss ? "**" * num(v) * "**" : num(v),
                            num(tw[gr]),
                            num(te[gr]),
                        ],
                    )
                end
            end
            table(
                io, ["#", "multiplier", "solver", "$S, as written", "$S, min-equiv."], rows
            )
            println(io, "</details>\n")
        end
    end

    # ---- conclusion --------------------------------------------------------------------------
    println(io, "### Conclusion\n")
    rows = Vector{Vector{String}}()
    for (sname, _) in SOLVERS
        if all(results[(m, sname, i)].ctsolvers for (m, _) in MODELERS, i in eachindex(CASES))
            push!(
                rows,
                [
                    sname,
                    "CTSolvers",
                    "**CTSolvers** — the same multipliers for the eight cases",
                ],
            )
            continue
        end
        S = stationarity_of("ADNLPModels", sname)
        S2 = stationarity_of("ExaModels", sname)
        sty = S === nothing ? "none" : (S == S2 ? string(S) : "differs between modelers")
        mx = unique(
            filter(
                !isnothing,
                [
                    rules(m, sname, i) for (m, _) in MODELERS for
                    (i, k) in enumerate(CASES) if k.sense === :max
                ],
            ),
        )
        behaviour = if S === nothing
            "n/a"
        elseif length(mx) == 1 && mx[1][1] == mx[1][2] == "as written"
            "**" * string(S) * ", as written** — every multiplier changes sign"
        elseif length(mx) == 1 && mx[1][1] == mx[1][2] == "min-equiv."
            "**" * string(S) * ", min-equiv.** — no multiplier changes sign"
        elseif length(mx) == 1
            "**none**, inconsistent: the rows follow *" *
            mx[1][1] *
            "*, the bounds and fixed variable *" *
            mx[1][2] *
            "*"
        else
            "**none**, varies with the case"
        end
        push!(rows, [sname, sty, behaviour])
    end
    table(io, ["Solver", "Stationarity (read on `min f`)", "Maximisation (`max -f`)"], rows)
    fam = Dict{String,Vector{String}}()
    for (sname, _) in SOLVERS
        S = if all(
            results[(m, sname, i)].ctsolvers for (m, _) in MODELERS, i in eachindex(CASES)
        )
            "CTSolvers"
        else
            stationarity_of("ADNLPModels", sname)
        end
        S === nothing || push!(get!(fam, string(S), String[]), sname)
    end
    for S in sort(collect(keys(fam)))
        label_S = S == "CTSolvers" ? "Convention **CTSolvers**" : "Stationarity **" * S * "**"
        println(io, "- ", label_S, ": ", join("`" .* fam[S] .* "`", ", "), ".")
    end
    println(io)
    if any(r -> occursin("inconsistent", r[3]), rows)
        println(
            io,
            "A solver marked **none** has the stationarity of its family on `min f`, but on `max -f` it mixes the two rules: some multipliers change sign between `min f` and `max -f` (those of the rows), others do not (those of the bounds and of fixed variables). No single convention, as defined above, describes its output.\n",
        )
    end
    return String(take!(io))
end

md = report()
println()
println(md)
out = isempty(ARGS) ? joinpath(@__DIR__, "report.md") : ARGS[1]
write(out, md)
println("Report written to ", out)
