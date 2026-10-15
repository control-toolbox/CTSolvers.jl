#!/usr/bin/env julia
# =============================================================================
# GPU capability probe for CTSolvers (NVIDIA/CUDA)
# =============================================================================
#
# Measures, against the CURRENT working-tree CTSolvers, which strategy combinations
# actually work on a CUDA device — the ground truth for docs/src/using/gpu.md.
#
#   A. Defaults selected by the GPU parameter (backend, linear solver).
#   B. NLP on the device: modeler × solver, including mismatched combinations.
#   C. Integrators.SciML with device states (CuArray): state × point/trajectory options.
#
# Diagnostic only: nothing asserts, every cell is try/catch'd, the run always succeeds.
# Without a functional device, every device cell reports the error it really raises.
#
#     julia --project=probe/gpu probe/gpu/probe_gpu.jl
# =============================================================================

using Pkg
Pkg.activate(@__DIR__)
Pkg.develop(; path=joinpath(@__DIR__, "..", ".."))   # the repo root (this CTSolvers)
Pkg.instantiate()

include(joinpath(@__DIR__, "..", "common.jl"))

using CTSolvers: CTSolvers, Modelers, Solvers, Integrators
using CTBase: CTBase
using CommonSolve: solve
using CUDA: CUDA
using CUDSS: CUDSS
using ExaModels: ExaModels
using MadNLP: MadNLP
using MadNLPGPU: MadNLPGPU
using MadNCL: MadNCL
using NLPModelsIpopt: NLPModelsIpopt
using UnoSolver: UnoSolver
using OrdinaryDiffEqTsit5: OrdinaryDiffEqTsit5
using SciMLBase: SciMLBase

const CPU = CTBase.Strategies.CPU
const GPU = CTBase.Strategies.GPU

println("CTSolvers GPU capability probe — Julia ", VERSION)
println("CUDA.functional() = ", CUDA.functional())
CUDA.functional() && println("device: ", CUDA.name(CUDA.device()))

# =============================================================================
# A. Defaults selected by the GPU parameter
# =============================================================================

let rows = ["Modelers.Exa{GPU}", "Solvers.MadNLP{GPU}", "Solvers.MadNCL{GPU}"],
    cols = ["default"],
    cells = Dict()

    cells[("Modelers.Exa{GPU}", "default")] = probe_cell() do
        b = Modelers.Exa{GPU}()[:backend]
        b isa CUDA.CUDABackend ? Cell(:ok, "backend = $b") : Cell(:warn, "backend = $b")
    end
    for (name, S) in ("Solvers.MadNLP{GPU}" => Solvers.MadNLP, "Solvers.MadNCL{GPU}" => Solvers.MadNCL)
        cells[(name, "default")] = probe_cell() do
            ls = S{GPU}()[:linear_solver]
            ls === MadNLPGPU.CUDSSSolver ? Cell(:ok, "linear_solver = $ls") :
            Cell(:warn, "linear_solver = $ls")
        end
    end
    print_matrix("A. Defaults selected by the GPU parameter", rows, cols, cells)
end

# =============================================================================
# B. NLP on the device: modeler × solver
# =============================================================================
#
# The model of docs/src/using/gpu.md:
#   min Σᵢ (xᵢ - i/N)²   s.t.   |x_{i+1} - xᵢ| ≤ 5e-4
# Its optimum is computed once on CPU (Exa{CPU} + MadNLP) as the reference.

const N = 1000

function quadratic_model(modeler::Modelers.Exa)
    T = modeler[:base_type]
    c = ExaModels.ExaCore(T; backend=modeler[:backend])
    c, x = ExaModels.add_var(c, N; start=T(0.5))
    c, _ = ExaModels.add_obj(c, (x[i] - i / T(N))^2 for i in 1:N)  # i is symbolic
    c, _ = ExaModels.add_con(
        c, x[i + 1] - x[i] for i in 1:(N - 1); lcon=T(-5e-4), ucon=T(5e-4)
    )
    return ExaModels.ExaModel(c)
end

const REFERENCE = let
    stats = solve(
        quadratic_model(Modelers.Exa()), Solvers.MadNLP(; print_level=MadNLP.ERROR);
        display=false,
    )
    Float64(Solvers.extract_solver_infos(stats)[1])
end
println("reference objective (Exa{CPU} + MadNLP{CPU}): ", REFERENCE)

_tol(T) = T == Float32 ? 1e-5 : 1e-8

const MODELERS = [
    "Exa{GPU}" => () -> Modelers.Exa{GPU}(),
    "Exa{GPU} Float32" => () -> Modelers.Exa{GPU}(; base_type=Float32),
]

const SOLVERS = [
    "MadNLP{GPU}" => T -> Solvers.MadNLP{GPU}(; print_level=MadNLP.ERROR, tol=_tol(T)),
    "MadNCL{GPU}" => T -> Solvers.MadNCL{GPU}(; print_level=MadNLP.ERROR, tol=_tol(T)),
    "MadNLP{CPU}" => T -> Solvers.MadNLP(; print_level=MadNLP.ERROR, tol=_tol(T)),
    "Ipopt" => T -> Solvers.Ipopt(; print_level=0, tol=_tol(T)),
    "Uno" => T -> Solvers.Uno(; primal_tolerance=_tol(T), dual_tolerance=_tol(T)),
]

let rows = first.(MODELERS), cols = first.(SOLVERS), cells = Dict()
    for (m, mk) in MODELERS, (s, sk) in SOLVERS
        cells[(m, s)] = probe_cell() do
            nlp = quadratic_model(mk())
            T = eltype(nlp.meta.x0)
            t = @elapsed stats = solve(nlp, sk(T); display=false)
            obj, iter, _, _, status, ok = Solvers.extract_solver_infos(stats)
            ok || return Cell(:warn, "not successful: status $status after $iter iterations")
            check_close(
                Float64(obj), REFERENCE; rtol=T == Float32 ? 1e-3 : 1e-6,
                note=@sprintf("%d iterations, %.2f s (with compilation)", iter, t),
            )
        end
    end
    print_matrix("B. NLP on the device — modeler (rows) × solver (columns)", rows, cols, cells)
end

# =============================================================================
# C. Integrators.SciML with device states
# =============================================================================
#
#   u' = -u on (0, 1)   ⇒   u(1) = u0 · e⁻¹,  u(0.5) = u0 · e^-0.5

const STATES = [
    "CuArray{Float64} in-place" => (Float64[1, 2], true),
    "CuArray{Float64} out-of-place" => (Float64[1, 2], false),
    "CuArray{Float32} in-place" => (Float32[1, 2], true),
]

const INTEGRATORS = ["SciML{GPU}" => GPU, "SciML{CPU}" => CPU]

function device_problem(u0_host, inplace)
    u0 = CUDA.CuArray(u0_host)
    T = eltype(u0_host)
    inplace && return SciMLBase.ODEProblem((du, u, p, t) -> (du .= .-u), u0, (zero(T), one(T)))
    return SciMLBase.ODEProblem((u, p, t) -> .-u, u0, (zero(T), one(T)))
end

let rows = first.(STATES),
    cols = [i * " " * w for (i, _) in INTEGRATORS for w in ("point", "trajectory")],
    cells = Dict()

    for (sname, (u0, inplace)) in STATES, (iname, P) in INTEGRATORS, which in ("point", "trajectory")
        cells[(sname, iname * " " * which)] = probe_cell() do
            integ = Integrators.SciML{P}()
            options = which == "point" ? Integrators.options_point(integ) :
                      Integrators.options_trajectory(integ)
            r = solve(device_problem(u0, inplace), integ; options=options)
            xf = Integrators.final_state(r)
            xf isa CUDA.CuArray || return Cell(:warn, "final state is $(typeof(xf))")
            tol = eltype(u0) == Float32 ? 1e-5 : 1e-7
            err = maximum(abs.(Array(xf) .- u0 .* exp(-1.0)))
            err < tol || return Cell(:warn, @sprintf("final-state error %.2e", err))
            which == "trajectory" || return Cell(:ok, "")
            mid = Integrators.evaluate_at(r, 0.5)
            err_mid = maximum(abs.(Array(mid) .- u0 .* exp(-0.5)))
            err_mid < tol || return Cell(:warn, @sprintf("evaluate_at(0.5) error %.2e", err_mid))
            Cell(:ok, "")
        end
    end
    print_matrix("C. Integrators.SciML with CuArray states — state × integrator/options", rows, cols, cells)
end

println("\nDone.")
