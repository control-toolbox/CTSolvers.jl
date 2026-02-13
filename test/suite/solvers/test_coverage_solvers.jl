module TestCoverageSolvers

using Test
using CTBase: CTBase
const Exceptions = CTBase.Exceptions
using CTSolvers
using CTSolvers.Solvers
using CTSolvers.Strategies
using CTSolvers.Options
using NLPModels
using SolverCore
using ADNLPModels
using CommonSolve

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

# ============================================================================
# Fake types for testing (must be at module top-level)
# ============================================================================

struct CovUnimplementedSolver <: Solvers.AbstractOptimizationSolver
    options::Strategies.StrategyOptions
end

struct CovCallableSolver <: Solvers.AbstractOptimizationSolver
    options::Strategies.StrategyOptions
end

# Implement callable for a non-NLPModel argument (covers generic solve overload)
function (s::CovCallableSolver)(nlp; display::Bool=true)
    return (status=:ok, display=display)
end

function test_coverage_solvers()
    Test.@testset "Coverage: Solvers" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ====================================================================
        # UNIT TESTS - AbstractOptimizationSolver callable (abstract_solver.jl)
        # ====================================================================

        Test.@testset "AbstractOptimizationSolver callable - NotImplemented" begin
            opts = Strategies.StrategyOptions()
            solver = CovUnimplementedSolver(opts)
            nlp = ADNLPModels.ADNLPModel(x -> sum(x.^2), [1.0])

            Test.@test_throws Exceptions.NotImplemented solver(nlp)
            Test.@test_throws Exceptions.NotImplemented solver(nlp; display=false)
        end

        # ====================================================================
        # UNIT TESTS - KnitroSolver (knitro_solver.jl)
        # ====================================================================

        Test.@testset "KnitroSolver" begin
            # Type hierarchy
            Test.@test Solvers.KnitroSolver <: Solvers.AbstractOptimizationSolver
            Test.@test Solvers.KnitroSolver <: Strategies.AbstractStrategy
            Test.@test !isabstracttype(Solvers.KnitroSolver)

            # id() contract
            Test.@test Strategies.id(Solvers.KnitroSolver) === :knitro

            # Tag type
            Test.@test Solvers.KnitroTag <: Solvers.AbstractTag
            Test.@test !isabstracttype(Solvers.KnitroTag)
            Test.@test_nowarn Solvers.KnitroTag()

            # Struct fields
            Test.@test :options in fieldnames(Solvers.KnitroSolver)
            Test.@test length(fieldnames(Solvers.KnitroSolver)) == 1

            # Constructor throws ExtensionError (NLPModelsKnitro not loaded)
            Test.@test_throws Exceptions.ExtensionError Solvers.KnitroSolver()

            # build_knitro_solver stub throws ExtensionError
            Test.@test_throws Exceptions.ExtensionError Solvers.build_knitro_solver(Solvers.KnitroTag())

            # Verify error message content
            err = nothing
            try
                Solvers.build_knitro_solver(Solvers.KnitroTag())
            catch e
                err = e
            end
            Test.@test err isa Exceptions.ExtensionError
            err_str = string(err)
            Test.@test occursin("KnitroSolver", err_str)
            Test.@test occursin("NLPModelsKnitro", err_str)
        end

        # ====================================================================
        # UNIT TESTS - Solvers.IpoptSolver stub (ipopt_solver.jl)
        # ====================================================================

        Test.@testset "Solvers.IpoptSolver - ExtensionError on construct" begin
            # Without NLPModelsIpopt loaded, constructor should throw
            # (NLPModelsIpopt IS loaded in test env, so this tests the stub path)
            # We test the stub directly with a non-IpoptTag
            Test.@test_throws Exceptions.ExtensionError Solvers.build_ipopt_solver(Solvers.KnitroTag())
        end

        # ====================================================================
        # UNIT TESTS - MadNLPSolver stub (madnlp_solver.jl)
        # ====================================================================

        Test.@testset "MadNLPSolver - stub with wrong tag" begin
            Test.@test_throws Exceptions.ExtensionError Solvers.build_madnlp_solver(Solvers.KnitroTag())
        end

        # ====================================================================
        # UNIT TESTS - MadNCLSolver stub (madncl_solver.jl)
        # ====================================================================

        Test.@testset "MadNCLSolver - stub with wrong tag" begin
            Test.@test_throws Exceptions.ExtensionError Solvers.build_madncl_solver(Solvers.KnitroTag())
        end

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
            Test.@test Strategies.id(Solvers.IpoptSolver) === :ipopt
            Test.@test Strategies.id(Solvers.MadNLPSolver) === :madnlp
            Test.@test Strategies.id(Solvers.MadNCLSolver) === :madncl
            Test.@test Strategies.id(Solvers.KnitroSolver) === :knitro
        end

        # ====================================================================
        # UNIT TESTS - CommonSolve.solve(nlp, solver) generic overload
        # (common_solve_api.jl:112-117)
        # ====================================================================

        Test.@testset "CommonSolve.solve(nlp, solver) generic" begin
            opts = Strategies.StrategyOptions()
            solver = CovCallableSolver(opts)

            # Use a plain NamedTuple as "nlp" to hit the generic overload
            # (not AbstractNLPModel)
            fake_nlp = (name="fake",)
            result = CommonSolve.solve(fake_nlp, solver; display=false)
            Test.@test result.status === :ok
            Test.@test result.display === false

            result2 = CommonSolve.solve(fake_nlp, solver; display=true)
            Test.@test result2.display === true
        end
    end
end

end # module

test_coverage_solvers() = TestCoverageSolvers.test_coverage_solvers()
