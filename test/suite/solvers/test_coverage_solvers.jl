module TestCoverageSolvers

using Test: Test
import CTBase.Exceptions
import CTSolvers.Solvers
import CTBase.Strategies
import CTBase.Options
using NLPModels: NLPModels
using SolverCore: SolverCore
using ADNLPModels: ADNLPModels
using CommonSolve: CommonSolve

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

# ============================================================================
# Fake types for testing (must be at module top-level)
# ============================================================================

struct CovUnimplementedSolver <: Solvers.AbstractNLPSolver
    options::Strategies.StrategyOptions
end

function test_coverage_solvers()
    Test.@testset "Coverage: Solvers" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ====================================================================
        # UNIT TESTS - AbstractNLPSolver callable (abstract_solver.jl)
        # ====================================================================

        Test.@testset "AbstractNLPSolver solve - NotImplemented" begin
            opts = Strategies.StrategyOptions()
            solver = CovUnimplementedSolver(opts)
            nlp = ADNLPModels.ADNLPModel(x -> sum(x .^ 2), [1.0])

            Test.@test_throws Exceptions.NotImplemented CommonSolve.solve(nlp, solver)
            Test.@test_throws Exceptions.NotImplemented CommonSolve.solve(
                nlp, solver; display=false
            )
        end

        # Note: Knitro tests removed as Knitro is not currently tested

        # ====================================================================
        # UNIT TESTS - __display() helper (common_solve_api.jl)
        # ====================================================================

        Test.@testset "__display() default" begin
            Test.@test Solvers.__display() === true
        end

        # ====================================================================
        # UNIT TESTS - Strategies.id() direct calls for all solvers
        # ====================================================================

        Test.@testset "Strategies.id() direct calls" begin
            Test.@test Strategies.id(Solvers.Ipopt) === :ipopt
            Test.@test Strategies.id(Solvers.MadNLP) === :madnlp
            Test.@test Strategies.id(Solvers.MadNCL) === :madncl
            Test.@test Strategies.id(Solvers.Uno) === :uno
        end
    end
end

end # module

test_coverage_solvers() = TestCoverageSolvers.test_coverage_solvers()
