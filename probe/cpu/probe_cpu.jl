#!/usr/bin/env julia
# =============================================================================
# CPU capability probe for CTSolvers
# =============================================================================
#
# Measures, against the CURRENT working-tree CTSolvers, which strategy combinations
# actually work on CPU — the ground truth for the documentation's capability claims
# (docs/src/using/strategies.md, docs/src/using/gpu.md, solver docstrings).
#
#   A. NLP: modeler × solver. The same small NLP (known solution) is built with each
#      modeler's own options — as CTDirect does — and solved with each solver.
#   B. Parameters: every strategy × {CPU, GPU}, constructed without a device.
#   C. Integrators: SciML × state type × point/trajectory options.
#
# Diagnostic only: nothing asserts, every cell is try/catch'd, the run always succeeds.
#
#     julia --project=probe/cpu probe/cpu/probe_cpu.jl
#
# The header activates this folder's environment and `dev`s the checked-out CTSolvers,
# so the probe measures the working-tree source (Manifest not committed).
# =============================================================================

using Pkg
Pkg.activate(@__DIR__)
Pkg.develop(; path=joinpath(@__DIR__, "..", ".."))   # the repo root (this CTSolvers)
Pkg.instantiate()

include(joinpath(@__DIR__, "..", "common.jl"))

using CTSolvers: CTSolvers, Modelers, Solvers, Integrators
using CTBase: CTBase
using CommonSolve: solve
using ADNLPModels: ADNLPModels
using ExaModels: ExaModels
using NLPModelsIpopt: NLPModelsIpopt
using MadNLP: MadNLP
using MadNCL: MadNCL
using NLPModelsKnitro: NLPModelsKnitro
using UnoSolver: UnoSolver
using OrdinaryDiffEqTsit5: OrdinaryDiffEqTsit5
using SciMLBase: SciMLBase

const CPU = CTBase.Strategies.CPU
const GPU = CTBase.Strategies.GPU

println("CTSolvers CPU capability probe — Julia ", VERSION)

# =============================================================================
# A. NLP: modeler × solver
# =============================================================================
#
#   min (x₁ - 1)² + (x₂ - 2)²   s.t.   0 ≤ x₁ + x₂ ≤ 1     ⇒   x* = (0, 1), f* = 2

const F_STAR = 2.0

function build_nlp(modeler::Modelers.ADNLP)
    return ADNLPModels.ADNLPModel(
        x -> (x[1] - 1)^2 + (x[2] - 2)^2,
        [1.0, 1.0],
        x -> [x[1] + x[2]],
        [0.0],
        [1.0];
        backend=modeler[:backend],
    )
end

function build_nlp(modeler::Modelers.Exa)
    T = modeler[:base_type]
    c = ExaModels.ExaCore(T; backend=modeler[:backend])
    c, x = ExaModels.add_var(c, 2; start=one(T))
    c, _ = ExaModels.add_obj(c, (x[i] - i)^2 for i in 1:2)
    c, _ = ExaModels.add_con(c, x[1] + x[2] for _ in 1:1; lcon=zero(T), ucon=one(T))
    return ExaModels.ExaModel(c)
end

const MODELERS = [
    "ADNLP" => () -> Modelers.ADNLP(),
    "Exa{CPU}" => () -> Modelers.Exa(),
    "Exa{CPU} Float32" => () -> Modelers.Exa(; base_type=Float32),
]

# Each factory takes the model's float type: in Float32 the default tolerances (≈1e-8)
# are out of reach, so a tolerance of 1e-5 is passed — a failure is then a real
# incompatibility, not a mistuned solver.
_tol(T) = T == Float32 ? 1e-5 : 1e-8

const SOLVERS = [
    "Ipopt" => T -> Solvers.Ipopt(; print_level=0, tol=_tol(T)),
    "MadNLP" => T -> Solvers.MadNLP(; print_level=MadNLP.ERROR, tol=_tol(T)),
    "MadNCL" => T -> Solvers.MadNCL(; print_level=MadNLP.ERROR, tol=_tol(T)),
    "Knitro" => T -> Solvers.Knitro(; outlev=0, opttol_abs=_tol(T), feastol_abs=_tol(T)),
    "Uno" => T -> Solvers.Uno(; primal_tolerance=_tol(T), dual_tolerance=_tol(T)),
]

function nlp_cell(make_modeler, make_solver)
    cell = probe_cell() do
        nlp = build_nlp(make_modeler())
        T = eltype(nlp.meta.x0)
        stats = solve(nlp, make_solver(T); display=false)
        obj, iter, _, _, status, ok = Solvers.extract_solver_infos(stats)
        ok || return Cell(:warn, "not successful: status $status after $iter iterations")
        return check_close(obj, F_STAR; rtol=T == Float32 ? 1e-3 : 1e-6)
    end
    # KN_new fails with -520 when no Knitro license is found on the machine
    occursin("KN_new: -520", cell.note) &&
        return Cell(:fail, "no Knitro license (KN_new: -520)")
    return cell
end

let rows = first.(MODELERS), cols = first.(SOLVERS), cells = Dict()
    for (m, mk) in MODELERS, (s, sk) in SOLVERS
        cells[(m, s)] = nlp_cell(mk, sk)
    end
    print_matrix("A. NLP on CPU — modeler (rows) × solver (columns)", rows, cols, cells)
end

# =============================================================================
# B. Execution parameters: strategy × {CPU, GPU}, no device needed
# =============================================================================
#
# CPU-only strategies bound their parameter by `CPU` (expected: TypeError for GPU).
# GPU-capable ones need GPU packages that this CPU probe does not load (expected:
# ExtensionError naming them).

const STRATEGIES = [
    "Solvers.Ipopt" => Solvers.Ipopt,
    "Solvers.MadNLP" => Solvers.MadNLP,
    "Solvers.MadNCL" => Solvers.MadNCL,
    "Solvers.Knitro" => Solvers.Knitro,
    "Solvers.Uno" => Solvers.Uno,
    "Modelers.ADNLP" => Modelers.ADNLP,
    "Modelers.Exa" => Modelers.Exa,
    "Integrators.SciML" => Integrators.SciML,
]

let rows = first.(STRATEGIES), cols = ["CPU", "GPU"], cells = Dict()
    for (name, S) in STRATEGIES, (pname, P) in ("CPU" => CPU, "GPU" => GPU)
        cells[(name, pname)] = probe_cell() do
            s = S{P}()
            CTBase.Strategies.parameter(typeof(s)) === P ||
                return Cell(:warn, "parameter is $(CTBase.Strategies.parameter(typeof(s)))")
            return Cell(:ok, "")
        end
    end
    print_matrix(
        "B. Construction with an explicit parameter (no GPU package loaded)",
        rows,
        cols,
        cells,
    )
end

# =============================================================================
# C. Integrators: state type × options (CPU)
# =============================================================================
#
#   u' = -u on (0, 1)   ⇒   u(1) = u0 · e⁻¹,  u(0.5) = u0 · e^-0.5

const E1 = exp(-1.0)

const STATES = [
    "scalar Float64" => (1.0, false),
    "Vector{Float64}" => ([1.0, 2.0], false),
    "Vector{Float64} in-place" => ([1.0, 2.0], true),
    "Vector{Float32}" => (Float32[1, 2], false),
    "Matrix{Float64}" => ([1.0 2.0; 3.0 4.0], false),
]

function ode_problem(u0, inplace)
    tspan = (zero(eltype(u0)), one(eltype(u0)))
    inplace && return SciMLBase.ODEProblem((du, u, p, t) -> (du .= .-u), u0, tspan)
    return SciMLBase.ODEProblem((u, p, t) -> -u, u0, tspan)
end

function integration_cell(u0, inplace, which)
    return probe_cell() do
        integ = Integrators.SciML()
        options = if which == "point"
            Integrators.options_point(integ)
        else
            Integrators.options_trajectory(integ)
        end
        r = solve(ode_problem(u0, inplace), integ; options=options)
        xf = Integrators.final_state(r)
        typeof(xf) == typeof(u0) || return Cell(:warn, "final state is $(typeof(xf))")
        err = maximum(abs.(xf .- u0 .* E1))
        tol = eltype(u0) == Float32 ? 1e-5 : 1e-7
        err < tol || return Cell(:warn, @sprintf("final-state error %.2e", err))
        which == "trajectory" || return Cell(:ok, "")
        Integrators.is_dense(r) || return Cell(:warn, "trajectory result not dense")
        err_mid = maximum(abs.(Integrators.evaluate_at(r, 0.5) .- u0 .* exp(-0.5)))
        err_mid < tol ||
            return Cell(:warn, @sprintf("evaluate_at(0.5) error %.2e", err_mid))
        return Cell(:ok, "")
    end
end

let rows = first.(STATES), cols = ["point", "trajectory"], cells = Dict()
    for (name, (u0, inplace)) in STATES, which in cols
        cells[(name, which)] = integration_cell(u0, inplace, which)
    end
    print_matrix(
        "C. Integrators.SciML (Tsit5) on CPU — state type × options", rows, cols, cells
    )
end

println("\nDone.")
