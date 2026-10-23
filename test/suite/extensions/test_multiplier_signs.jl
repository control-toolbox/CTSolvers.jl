module TestMultiplierSigns

# Signs of the multipliers on the problem of the sign probe, written in eight ways
# (min f / max -f, g ≤ 0 / -g ≥ 0, x₃ ≤ 1 as a bound / as a row), on ADNLPModels and
# ExaModels. Two layers, and the difference between their failures is the point
# (control-toolbox/CTSolvers.jl#288):
#
#   1. "native": the raw output of each backend (`solve_with_<solver>`) follows the
#      convention that `Solvers.reference_multipliers!` assumes for it. A failure here
#      means that a solver changed its convention upstream: update its method.
#   2. "CTSolvers": `CommonSolve.solve(nlp, solver)` returns the same multipliers for the
#      eight cases, in the convention of CTSolvers. A failure here, with (1) passing, is a
#      bug of the normalisation.
#
# Knitro is not tested (license); its convention is derived from its manual (see
# `Solvers.reference_multipliers!`).

using Test: Test
using CTBase: Strategies
using CTSolvers: CTSolvers
using CTSolvers: Solvers
using CommonSolve: CommonSolve
using NLPModels: NLPModels
using ADNLPModels: ADNLPModels
using ExaModels: ExaModels
using NLPModelsIpopt: NLPModelsIpopt
using MadNLP: MadNLP
using MadNCL: MadNCL
using UnoSolver: UnoSolver

include(joinpath(@__DIR__, "..", "..", "problems", "multiplier_signs.jl"))
using .MultiplierSigns: MultiplierSigns

const CTSolversIpopt = Base.get_extension(CTSolvers, :CTSolversIpopt)
const CTSolversMadNLP = Base.get_extension(CTSolvers, :CTSolversMadNLP)
const CTSolversMadNCL = Base.get_extension(CTSolvers, :CTSolversMadNCL)
const CTSolversUno = Base.get_extension(CTSolvers, :CTSolversUno)

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

const TOL = 1e-10      # solver tolerance
const ATOL = 1e-6      # multiplier agreement

# ============================================================================
# The solvers, with their raw backend call and their native convention
# ============================================================================

"""
A solver of the test: its name and version (shown in the testset names, so a failure
says which version changed), the CTSolvers strategy, the raw backend call, and its
native convention as a map from the reference multipliers.
"""
struct SolverCase
    name::String
    strategy::Solvers.AbstractNLPSolver
    raw::Function
    native::Function
end

# Reference → native. `s = ±1` is the sense; see `Solvers.reference_multipliers!`.
native_as_written(y, zL, zU, s) = (s * y, s * zL, s * zU)               # Ipopt
native_uno(y, zL, zU, s) = (s * y, -s * zL, s * zU)                     # Uno (B)
native_rows_only(y, zL, zU, s) = (s * y, zL, zU)                        # MadNLP, MadNCL

function raw_madncl(nlp)
    solver = MadNCL.NCLSolver(
        nlp;
        ncl_options=MadNCL.NCLOptions{Float64}(; verbose=false),
        print_level=MadNLP.ERROR,
        tol=TOL,
    )
    return MadNCL.solve!(solver)
end

const SOLVERS = [
    SolverCase(
        "Ipopt (NLPModelsIpopt $(pkgversion(NLPModelsIpopt)))",
        Solvers.Ipopt(; print_level=0, tol=TOL),
        nlp -> CTSolversIpopt.solve_with_ipopt(nlp; print_level=0, tol=TOL),
        native_as_written,
    ),
    SolverCase(
        "MadNLP $(pkgversion(MadNLP))",
        Solvers.MadNLP(; tol=TOL),
        nlp -> CTSolversMadNLP.solve_with_madnlp(nlp; print_level=MadNLP.ERROR, tol=TOL),
        native_rows_only,
    ),
    SolverCase(
        "MadNCL $(pkgversion(MadNCL))",
        Solvers.MadNCL(; tol=TOL),
        raw_madncl,
        native_rows_only,
    ),
    SolverCase(
        "Uno (UnoSolver $(pkgversion(UnoSolver)))",
        Solvers.Uno(; primal_tolerance=TOL, dual_tolerance=TOL),
        nlp -> CTSolversUno.solve_with_uno(
            nlp; logger="SILENT", primal_tolerance=TOL, dual_tolerance=TOL
        ),
        native_uno,
    ),
]

# ============================================================================
# Comparison
# ============================================================================

"""
Compare the multipliers of `stats` with `(y, zL, zU)` on the components that the problem
fixes: every row, the bounds of `x₃` and `x₄`, and the net multiplier of the fixed `x₅`,
`zU₅ + σ zL₅` (`σ = -1` when `zL` enters the stationarity with a minus sign, `+1` for
Uno's native output).
"""
function check(stats, (y, zL, zU); σ=-1.0)
    sy = Array(stats.multipliers)
    sL = Array(stats.multipliers_L)
    sU = Array(stats.multipliers_U)
    Test.@test stats.status in (:first_order, :acceptable) ||
        Symbol(stats.status) in (:SOLVE_SUCCEEDED, :SOLVED_TO_ACCEPTABLE_LEVEL)
    Test.@test sy ≈ y atol = ATOL
    Test.@test sL[3:4] ≈ zL[3:4] atol = ATOL
    Test.@test sU[3:4] ≈ zU[3:4] atol = ATOL
    Test.@test sU[5] + σ * sL[5] ≈ zU[5] + σ * zL[5] atol = ATOL
    return nothing
end

function test_multiplier_signs()
    Test.@testset "Multiplier signs" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ====================================================================
        # INTEGRATION TESTS - (1) native convention of each backend
        # ====================================================================

        Test.@testset "native: $(sc.name)" for sc in SOLVERS
            Test.@testset "$mname: $k" for (mname, build) in MultiplierSigns.MODELERS,
                k in MultiplierSigns.CASES

                s = k.sense === :min ? 1.0 : -1.0
                expected = sc.native(MultiplierSigns.reference(k)..., s)
                σ = sc.native === native_uno ? 1.0 : -1.0
                check(sc.raw(build(k)), expected; σ=σ)
            end
        end

        # ====================================================================
        # INTEGRATION TESTS - (2) what CTSolvers returns: the same for every case
        # ====================================================================

        Test.@testset "CTSolvers: $(sc.name)" for sc in SOLVERS
            Test.@testset "$mname: $k" for (mname, build) in MultiplierSigns.MODELERS,
                k in MultiplierSigns.CASES

                stats = CommonSolve.solve(build(k), sc.strategy; display=false)
                check(stats, MultiplierSigns.normalized(k))
            end
        end

        # ====================================================================
        # UNIT TESTS - the reference values of the problem
        # ====================================================================

        Test.@testset "closed form" begin
            yc, yg = MultiplierSigns.row_multipliers()
            Test.@test yc ≈ 0.5359 atol = 1e-4
            Test.@test yg ≈ 0.1547 atol = 1e-4
            # one set of numbers for the eight ways of writing the problem
            ys = [MultiplierSigns.normalized(k)[1][1:2] for k in MultiplierSigns.CASES]
            Test.@test all(y -> y ≈ [yc, yg], ys)
            Test.@test all(
                MultiplierSigns.normalized(k)[1][3] == 1.0 for
                k in MultiplierSigns.CASES if k.x3 === :row
            )
        end
    end
end

end # module TestMultiplierSigns

test_multiplier_signs() = TestMultiplierSigns.test_multiplier_signs()
