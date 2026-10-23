module TestMultiplierConvention

using Test: Test
using CTBase: Exceptions
using CTBase: Strategies
using CTSolvers: Solvers

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

# ============================================================================
# Fakes (top-level, TST3)
# ============================================================================

"Statistics with the three multiplier fields only."
struct FakeStats
    multipliers::Vector{Float64}
    multipliers_L::Vector{Float64}
    multipliers_U::Vector{Float64}
end

"A solver with no multiplier convention."
struct FakeSolver <: Solvers.AbstractNLPSolver
    options::Strategies.StrategyOptions
end

opts() = Strategies.StrategyOptions()

# ============================================================================
# One scenario, written in each native convention
# ============================================================================
#
# Rows: 1 equality, 2 upper side only, 3 lower side only (active), 4 two-sided with the
# lower side active. Reference stationarity (equivalent minimisation):
# ∇F_min + Jᵀy − zL + zU = 0, zL, zU ≥ 0, y = μU − μL.

const LCON = [0.0, -Inf, 0.0, -1.0]
const UCON = [0.0, 0.0, Inf, 1.0]
const Y_REF = [0.5, 0.2, -0.3, -0.4]
const ZL_REF = [1.0, 0.0]
const ZU_REF = [0.0, 2.0]

# After normalisation: the one-sided lower row 3 becomes μL = 0.3; the others are kept.
const Y_EXPECTED = [0.5, 0.2, 0.3, -0.4]

"""
The multipliers `(y, zL, zU)` that `solver` returns for the scenario, from its native
convention as stated in the docstring of `Solvers.reference_multipliers!`.
"""
function native(::Solvers.Ipopt, minimize::Bool)
    s = minimize ? 1.0 : -1.0                      # F as written: all flip
    return s * Y_REF, s * ZL_REF, s * ZU_REF
end
function native(::Solvers.Uno, minimize::Bool)
    s = minimize ? 1.0 : -1.0                      # B: zL enters with +
    return s * Y_REF, -s * ZL_REF, s * ZU_REF
end
function native(::Union{Solvers.MadNLP,Solvers.MadNCL}, minimize::Bool)
    s = minimize ? 1.0 : -1.0                      # rows flip, bounds do not
    return s * Y_REF, copy(ZL_REF), copy(ZU_REF)
end
function native(::Solvers.Knitro, minimize::Bool)
    # λᵇ = zU − zL (F as written); NLPModelsKnitro: zL = max(λᵇ, 0), zU = -min(λᵇ, 0).
    s = minimize ? 1.0 : -1.0
    λb = s * (ZU_REF - ZL_REF)
    return s * Y_REF, max.(λb, 0), -min.(λb, 0)
end

const SOLVERS = [
    "Ipopt" => Solvers.Ipopt{Strategies.CPU}(opts()),
    "Uno" => Solvers.Uno{Strategies.CPU}(opts()),
    "MadNLP" => Solvers.MadNLP{Strategies.CPU}(opts()),
    "MadNCL" => Solvers.MadNCL{Strategies.CPU}(opts()),
    "Knitro" => Solvers.Knitro{Strategies.CPU}(opts()),
]

function test_multiplier_convention()
    Test.@testset "Multiplier convention" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ====================================================================
        # UNIT TESTS - native convention → reference, per solver
        # ====================================================================

        Test.@testset "reference_multipliers! ($name, $(minimize ? :min : :max))" for (
                name, solver
            ) in SOLVERS,
            minimize in (true, false)

            y, zL, zU = native(solver, minimize)
            Test.@test Solvers.reference_multipliers!(solver, y, zL, zU, minimize) ===
                nothing
            Test.@test y ≈ Y_REF
            Test.@test zL ≈ ZL_REF
            Test.@test zU ≈ ZU_REF
        end

        # ====================================================================
        # UNIT TESTS - one-sided rows
        # ====================================================================

        Test.@testset "_one_sided_rows!" begin
            y = copy(Y_REF)
            Test.@test Solvers._one_sided_rows!(y, LCON, UCON) === y
            Test.@test y == Y_EXPECTED
            # no rows
            e = Float64[]
            Test.@test Solvers._one_sided_rows!(e, Float64[], Float64[]) == Float64[]
            # a free row (no finite bound) is left unchanged
            y = [0.7]
            Solvers._one_sided_rows!(y, [-Inf], [Inf])
            Test.@test y == [0.7]
            # element type of y is kept
            y = Float32[-1.0, 1.0]
            Solvers._one_sided_rows!(y, [0.0, -Inf], [Inf, 0.0])
            Test.@test y == Float32[1.0, 1.0]
            Test.@test eltype(y) == Float32
        end

        # ====================================================================
        # INTEGRATION TESTS - every solver, both senses, give the same numbers
        # ====================================================================

        Test.@testset "normalize_multipliers! ($name, $(minimize ? :min : :max))" for (
                name, solver
            ) in SOLVERS,
            minimize in (true, false)

            stats = FakeStats(native(solver, minimize)...)
            out = Solvers.normalize_multipliers!(stats, solver, LCON, UCON, minimize)
            Test.@test out === stats
            Test.@test stats.multipliers ≈ Y_EXPECTED
            Test.@test stats.multipliers_L ≈ ZL_REF
            Test.@test stats.multipliers_U ≈ ZU_REF
        end

        Test.@testset "normalize_multipliers! without bounds" begin
            stats = FakeStats([0.1, -0.2], Float64[], Float64[])
            Solvers.normalize_multipliers!(
                stats, Solvers.Uno{Strategies.CPU}(opts()), [0.0, 0.0], [Inf, Inf], false
            )
            Test.@test stats.multipliers ≈ [0.1, -0.2]   # max flips, then one-sided flips
            Test.@test isempty(stats.multipliers_L)
            Test.@test isempty(stats.multipliers_U)
        end

        # ====================================================================
        # ERROR TESTS - a solver with no convention
        # ====================================================================

        Test.@testset "NotImplemented stub" begin
            stats = FakeStats([1.0], Float64[], Float64[])
            Test.@test_throws Exceptions.NotImplemented Solvers.normalize_multipliers!(
                stats, FakeSolver(opts()), [0.0], [Inf], true
            )
        end

        # ====================================================================
        # CONTRACT TESTS - exports
        # ====================================================================

        Test.@testset "Exports" begin
            Test.@test :normalize_multipliers! in names(Solvers)
            Test.@test :reference_multipliers! in names(Solvers)
        end
    end
end

end # module TestMultiplierConvention

test_multiplier_convention() = TestMultiplierConvention.test_multiplier_convention()
