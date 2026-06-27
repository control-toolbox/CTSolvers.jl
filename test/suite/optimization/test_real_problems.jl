module TestRealProblems

using Test: Test
using NLPModels: NLPModels
using ADNLPModels: ADNLPModels
using ExaModels: ExaModels

include(joinpath(@__DIR__, "..", "..", "problems", "TestProblems.jl"))
import .TestProblems

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

# Import from CTSolvers
import CTSolvers.Optimization
import CTSolvers.Modelers

# ============================================================================
# TEST FUNCTION
# ============================================================================

function test_real_problems()
    Test.@testset "Optimization with Real Problems" verbose = VERBOSE showtiming =
        SHOWTIMING begin

        # ====================================================================
        # TESTS WITH ROSENBROCK PROBLEM
        # ====================================================================

        Test.@testset "Rosenbrock Problem" begin
            ros = TestProblems.Rosenbrock()

            Test.@testset "build_model (ADNLP) with Rosenbrock" begin
                nlp = Optimization.build_model(ros.prob, ros.init, Modelers.ADNLP()).nlp
                Test.@test nlp isa ADNLPModels.ADNLPModel
                Test.@test nlp.meta.x0 == ros.init
                Test.@test nlp.meta.minimize == true

                obj_val = NLPModels.obj(nlp, ros.init)
                Test.@test obj_val ≈ TestProblems.rosenbrock_objective(ros.init)

                cons_val = NLPModels.cons(nlp, ros.init)
                Test.@test cons_val[1] ≈ TestProblems.rosenbrock_constraint(ros.init)
            end

            Test.@testset "build_model (Exa, Float64) with Rosenbrock" begin
                nlp64 = Optimization.build_model(ros.prob, ros.init, Modelers.Exa()).nlp
                Test.@test nlp64 isa ExaModels.ExaModel{Float64}
                Test.@test nlp64.meta.x0 == Float64.(ros.init)
                Test.@test nlp64.meta.minimize == true

                obj_val = NLPModels.obj(nlp64, nlp64.meta.x0)
                Test.@test obj_val ≈ TestProblems.rosenbrock_objective(Float64.(ros.init))

                cons_val = NLPModels.cons(nlp64, nlp64.meta.x0)
                Test.@test cons_val[1] ≈ TestProblems.rosenbrock_constraint(Float64.(ros.init))
            end

            Test.@testset "build_model (Exa, Float32) with Rosenbrock" begin
                nlp32 = Optimization.build_model(
                    ros.prob, ros.init, Modelers.Exa(; base_type=Float32)
                ).nlp
                Test.@test nlp32 isa ExaModels.ExaModel{Float32}
                Test.@test nlp32.meta.x0 == Float32.(ros.init)
                Test.@test eltype(nlp32.meta.x0) == Float32
                Test.@test nlp32.meta.minimize == true

                obj_val = NLPModels.obj(nlp32, nlp32.meta.x0)
                Test.@test obj_val ≈ TestProblems.rosenbrock_objective(Float32.(ros.init))

                cons_val = NLPModels.cons(nlp32, nlp32.meta.x0)
                Test.@test cons_val[1] ≈ TestProblems.rosenbrock_constraint(Float32.(ros.init))
            end
        end

        # ====================================================================
        # INTEGRATION TESTS WITH REAL PROBLEMS
        # ====================================================================

        Test.@testset "Integration with Real Problems" begin
            Test.@testset "Complete workflow - Rosenbrock ADNLP" begin
                ros = TestProblems.Rosenbrock()
                nlp = Optimization.build_model(ros.prob, ros.init, Modelers.ADNLP()).nlp
                Test.@test nlp isa ADNLPModels.ADNLPModel
                Test.@test nlp.meta.nvar == 2
                Test.@test nlp.meta.ncon == 1
                Test.@test nlp.meta.minimize == true

                Test.@test NLPModels.obj(nlp, ros.init) ≈
                    TestProblems.rosenbrock_objective(ros.init)
                Test.@test NLPModels.obj(nlp, ros.sol) ≈
                    TestProblems.rosenbrock_objective(ros.sol)
                Test.@test TestProblems.rosenbrock_objective(ros.sol) <
                    TestProblems.rosenbrock_objective(ros.init)
            end

            Test.@testset "Complete workflow - Rosenbrock Exa" begin
                ros = TestProblems.Rosenbrock()
                nlp = Optimization.build_model(ros.prob, ros.init, Modelers.Exa()).nlp
                Test.@test nlp isa ExaModels.ExaModel{Float64}
                Test.@test nlp.meta.nvar == 2
                Test.@test nlp.meta.ncon == 1
                Test.@test nlp.meta.minimize == true

                Test.@test NLPModels.obj(nlp, Float64.(ros.init)) ≈
                    TestProblems.rosenbrock_objective(ros.init)
                Test.@test NLPModels.obj(nlp, Float64.(ros.sol)) ≈
                    TestProblems.rosenbrock_objective(ros.sol)
            end
        end
    end
end

end # module

test_real_problems() = TestRealProblems.test_real_problems()
