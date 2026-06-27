module TestDOCP

using Test: Test
using CTModels: CTModels
using CTSolvers: CTSolvers
import CTSolvers.DOCP
import CTSolvers.Optimization
import CTSolvers.Modelers
import CTBase
using NLPModels: NLPModels
using SolverCore: SolverCore
using ADNLPModels: ADNLPModels
using ExaModels: ExaModels
using CTSolvers.DOCP  # For testing exported symbols

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true
const CurrentModule = TestDOCP

# ============================================================================
# FAKE TYPES FOR TESTING (TOP-LEVEL)
# ============================================================================

"""
Fake OCP for testing DOCP construction.
"""
struct FakeOCP <: CTModels.AbstractModel
    name::String
end

"""
Fake discretizer for testing DiscretizedModel construction and dispatch.
"""
struct FakeDiscretizer <: DOCP.AbstractDiscretizer end

"""
Fake backend cache attached to a DiscretizedModel.
"""
struct FakeCache <: CTBase.Core.AbstractCache end

"""
Mock execution statistics for testing.
"""
mutable struct MockExecutionStats <: SolverCore.AbstractExecutionStats
    objective::Float64
    iter::Int
    primal_feas::Float64
    status::Symbol
end

"""
Fake modeler for testing the build_model / build_solution contract.
"""
struct FakeModelerDOCP <: Modelers.AbstractNLPModeler
    backend::Symbol
end

# Contract implementation by dispatch on (DiscretizedModel{<:FakeDiscretizer}, FakeModelerDOCP)
function Optimization.build_model(
    ::DOCP.DiscretizedModel{<:Any,<:FakeDiscretizer},
    initial_guess,
    modeler::FakeModelerDOCP,
)
    if modeler.backend == :adnlp
        return ADNLPModels.ADNLPModel(z -> sum(z .^ 2), initial_guess)
    else
        n = length(initial_guess)
        m = ExaModels.ExaCore(Float64; concrete=Val(true))
        ExaModels.@add_var(m, x_var, n; start=initial_guess)
        ExaModels.@add_obj(m, sum(x_var[i]^2 for i in 1:n))
        return ExaModels.ExaModel(m)
    end
end

function Optimization.build_solution(
    ::DOCP.DiscretizedModel{<:Any,<:FakeDiscretizer},
    nlp_solution::SolverCore.AbstractExecutionStats,
    ::FakeModelerDOCP,
)
    return (
        objective=nlp_solution.objective,
        iter=nlp_solution.iter,
        status=nlp_solution.status,
        success=(nlp_solution.status == :first_order || nlp_solution.status == :acceptable),
    )
end

# Helper: build a DiscretizedModel around the fake OCP / discretizer / cache.
fake_docp(name::String="test_ocp") =
    DOCP.DiscretizedModel(FakeOCP(name), FakeDiscretizer(), FakeCache())

# ============================================================================
# TEST FUNCTION
# ============================================================================

function test_docp()
    Test.@testset "DOCP Module" verbose = VERBOSE showtiming = SHOWTIMING begin

        # ====================================================================
        # META TESTS - Exports / Public API surface
        # ====================================================================

        Test.@testset "Exports verification" begin
            Test.@testset "DOCP Module" begin
                Test.@test isdefined(CTSolvers, :DOCP)
                Test.@test CTSolvers.DOCP isa Module
            end

            Test.@testset "Exported Types" begin
                for T in (DiscretizedModel, AbstractDiscretizer)
                    Test.@testset "$(nameof(T))" begin
                        Test.@test isdefined(DOCP, nameof(T))
                        Test.@test isdefined(CurrentModule, nameof(T))
                        Test.@test T isa DataType || T isa UnionAll
                    end
                end
            end

            Test.@testset "Exported Functions" begin
                for f in (:ocp_model, :nlp_model, :ocp_solution, :discretize)
                    Test.@testset "$f" begin
                        Test.@test isdefined(DOCP, f)
                        Test.@test isdefined(CurrentModule, f)
                        Test.@test getfield(CurrentModule, f) isa Function
                    end
                end
            end
        end

        # ====================================================================
        # UNIT TESTS - DOCP.DiscretizedModel Type
        # ====================================================================

        Test.@testset "DOCP.DiscretizedModel Type" begin
            Test.@testset "Construction" begin
                ocp = FakeOCP("test_ocp")
                disc = FakeDiscretizer()
                cache = FakeCache()
                docp = DOCP.DiscretizedModel(ocp, disc, cache)

                Test.@test docp isa DOCP.DiscretizedModel
                Test.@test docp isa Optimization.AbstractOptimizationProblem
                Test.@test docp.ocp === ocp
                Test.@test docp.discretizer === disc
                Test.@test docp.cache === cache
            end

            Test.@testset "Type parameters" begin
                docp = fake_docp()
                Test.@test typeof(docp.ocp) == FakeOCP
                Test.@test typeof(docp.discretizer) <: DOCP.AbstractDiscretizer
                Test.@test typeof(docp.cache) <: CTBase.Core.AbstractCache
            end
        end

        # ====================================================================
        # UNIT TESTS - Accessors
        # ====================================================================

        Test.@testset "Accessors" begin
            Test.@testset "ocp_model" begin
                ocp = FakeOCP("my_ocp")
                docp = DOCP.DiscretizedModel(ocp, FakeDiscretizer(), FakeCache())

                retrieved_ocp = DOCP.ocp_model(docp)
                Test.@test retrieved_ocp === ocp
                Test.@test retrieved_ocp.name == "my_ocp"
                Test.@test_nowarn Test.@inferred DOCP.ocp_model(docp)
            end
        end

        # ====================================================================
        # UNIT TESTS - Building Functions (build_model / build_solution)
        # ====================================================================

        Test.@testset "Building Functions" begin
            docp = fake_docp()

            Test.@testset "nlp_model with ADNLP backend" begin
                modeler = FakeModelerDOCP(:adnlp)
                x0 = [1.0, 2.0]

                nlp = DOCP.nlp_model(docp, x0, modeler)
                Test.@test nlp isa NLPModels.AbstractNLPModel
                Test.@test nlp isa ADNLPModels.ADNLPModel
                Test.@test NLPModels.obj(nlp, x0) ≈ 5.0

                nlp2 = Optimization.build_model(docp, x0, modeler)
                Test.@test nlp2 isa ADNLPModels.ADNLPModel
                Test.@test NLPModels.obj(nlp2, x0) ≈ 5.0
            end

            Test.@testset "nlp_model with Exa backend" begin
                modeler = FakeModelerDOCP(:exa)
                x0 = [1.0, 2.0]

                nlp = DOCP.nlp_model(docp, x0, modeler)
                Test.@test nlp isa NLPModels.AbstractNLPModel
                Test.@test nlp isa ExaModels.ExaModel{Float64}
                Test.@test NLPModels.obj(nlp, x0) ≈ 5.0

                nlp2 = Optimization.build_model(docp, x0, modeler)
                Test.@test nlp2 isa ExaModels.ExaModel{Float64}
                Test.@test NLPModels.obj(nlp2, x0) ≈ 5.0
            end

            Test.@testset "ocp_solution with ADNLP backend" begin
                modeler = FakeModelerDOCP(:adnlp)
                stats = MockExecutionStats(1.23, 10, 1e-6, :first_order)

                sol = DOCP.ocp_solution(docp, stats, modeler)
                Test.@test sol.objective ≈ 1.23
                Test.@test sol.status == :first_order
                Test.@test sol.success === true

                sol2 = Optimization.build_solution(docp, stats, modeler)
                Test.@test sol2.objective ≈ 1.23
                Test.@test sol2.status == :first_order
            end

            Test.@testset "ocp_solution with Exa backend" begin
                modeler = FakeModelerDOCP(:exa)
                stats = MockExecutionStats(2.34, 15, 1e-5, :acceptable)

                sol = DOCP.ocp_solution(docp, stats, modeler)
                Test.@test sol.objective ≈ 2.34
                Test.@test sol.iter == 15

                sol2 = Optimization.build_solution(docp, stats, modeler)
                Test.@test sol2.objective ≈ 2.34
                Test.@test sol2.iter == 15
            end
        end

        # ====================================================================
        # UNIT TESTS - Contract stubs (NotImplemented)
        # ====================================================================

        Test.@testset "Contract stubs" begin
            docp = fake_docp()

            Test.@testset "build_model NotImplemented for unknown modeler" begin
                # A modeler with no (problem, modeler) method falls back to the
                # generic stub, which throws NotImplemented.
                Test.@test_throws CTBase.Exceptions.NotImplemented Optimization.build_model(
                    docp, [1.0], Modelers.ADNLP()
                )
            end

            Test.@testset "discretize NotImplemented for fake discretizer" begin
                Test.@test_throws CTBase.Exceptions.NotImplemented DOCP.discretize(
                    FakeOCP("x"), FakeDiscretizer()
                )
            end
        end

        # ====================================================================
        # INTEGRATION TESTS
        # ====================================================================

        Test.@testset "Integration Tests" begin
            Test.@testset "Complete DOCP workflow - ADNLP" begin
                docp = fake_docp("integration_test_ocp")
                Test.@test DOCP.ocp_model(docp).name == "integration_test_ocp"

                modeler = FakeModelerDOCP(:adnlp)
                x0 = [1.0, 2.0, 3.0]
                nlp = DOCP.nlp_model(docp, x0, modeler)
                Test.@test nlp isa ADNLPModels.ADNLPModel
                Test.@test NLPModels.obj(nlp, x0) ≈ 14.0

                stats = MockExecutionStats(14.0, 20, 1e-8, :first_order)
                sol = DOCP.ocp_solution(docp, stats, modeler)
                Test.@test sol.objective ≈ 14.0
                Test.@test sol.iter == 20
                Test.@test sol.status == :first_order
                Test.@test sol.success === true
            end

            Test.@testset "Complete DOCP workflow - Exa" begin
                docp = fake_docp("integration_test_exa")
                modeler = FakeModelerDOCP(:exa)
                x0 = [1.0, 2.0, 3.0]
                nlp = DOCP.nlp_model(docp, x0, modeler)
                Test.@test nlp isa ExaModels.ExaModel{Float64}
                Test.@test NLPModels.obj(nlp, x0) ≈ 14.0

                stats = MockExecutionStats(14.0, 25, 1e-7, :acceptable)
                sol = DOCP.ocp_solution(docp, stats, modeler)
                Test.@test sol.objective ≈ 14.0
                Test.@test sol.iter == 25
                Test.@test sol.status == :acceptable
            end
        end
    end
end

end # module

test_docp() = TestDOCP.test_docp()
