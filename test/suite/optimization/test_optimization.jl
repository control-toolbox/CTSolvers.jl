module TestOptimization

using Test: Test
import CTBase.Exceptions
using CTSolvers: CTSolvers
import CTSolvers.Optimization
import CTSolvers.Modelers
import CTSolvers.Solvers
using NLPModels: NLPModels
using SolverCore: SolverCore
using ADNLPModels: ADNLPModels
using ExaModels: ExaModels
using CTSolvers.Optimization  # For testing exported symbols

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true
const CurrentModule = TestOptimization

# ============================================================================
# FAKE TYPES FOR CONTRACT TESTING (TOP-LEVEL)
# ============================================================================

"""
Fake optimization problem implementing the build_model / build_solution contract.
"""
struct FakeOptimizationProblem <: Optimization.AbstractOptimizationProblem end

"""
Minimal problem for testing NotImplemented errors (no contract method defined).
"""
struct MinimalProblem <: Optimization.AbstractOptimizationProblem end

"""
Fake modeler for testing building functions; carries a backend selector.

Subtypes `AbstractNLPModeler` so that an unimplemented `(problem, modeler)` pair
falls through to the canonical `NotImplemented` contract stub in `Modelers`.
"""
struct FakeModeler <: Modelers.AbstractNLPModeler
    backend::Symbol
end

# Contract implementation by dispatch on (FakeOptimizationProblem, FakeModeler)
function Optimization.build_model(
    prob::FakeOptimizationProblem, initial_guess, modeler::FakeModeler
)
    if modeler.backend == :adnlp
        nlp = ADNLPModels.ADNLPModel(z -> sum(z .^ 2), initial_guess)
    else
        n = length(initial_guess)
        m = ExaModels.ExaCore(Float64; concrete=Val(true))
        ExaModels.@add_var(m, x_var, n; start=initial_guess)
        ExaModels.@add_obj(m, sum(x_var[i]^2 for i in 1:n))
        nlp = ExaModels.ExaModel(m)
    end
    return Optimization.BuiltModel(prob, nlp, Optimization.NoCache())
end

function Optimization.build_solution(
    ::Optimization.BuiltModel{<:FakeOptimizationProblem},
    nlp_solution::SolverCore.AbstractExecutionStats,
    ::FakeModeler,
)
    return (obj=nlp_solution.objective, iter=nlp_solution.iter, status=nlp_solution.status)
end

# TOP-LEVEL: Create GenericExecutionStats instances for testing
function create_mock_execution_stats(
    objective::Float64, iter::Int, primal_feas::Float64, status::Symbol
)
    return SolverCore.GenericExecutionStats{Float64,Vector{Float64},Vector{Float64},Any}(;
        status=status, objective=objective, iter=iter, primal_feas=primal_feas
    )
end

# ============================================================================
# TEST FUNCTION
# ============================================================================

"""
    test_optimization()

Tests for the Optimization module:
- Abstract type (`AbstractOptimizationProblem`)
- Building contract (`build_model`, `build_solution`) by multiple dispatch
- NotImplemented stubs for unregistered (problem, modeler) pairs
- Solver utilities (`extract_solver_infos` — lives in `Solvers`, tested here for workflow integration)
"""
function test_optimization()
    Test.@testset "Optimization Module" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ====================================================================
        # META TESTS - Exports / Public API surface
        # ====================================================================

        Test.@testset "Exports verification" begin
            Test.@testset "Optimization Module" begin
                Test.@test isdefined(CTSolvers, :Optimization)
                Test.@test CTSolvers.Optimization isa Module
            end

            Test.@testset "Exported Abstract Types" begin
                for T in (AbstractOptimizationProblem,)
                    Test.@testset "$(nameof(T))" begin
                        Test.@test isdefined(Optimization, nameof(T))
                        Test.@test isdefined(CurrentModule, nameof(T))
                        Test.@test T isa DataType || T isa UnionAll
                    end
                end
            end

            Test.@testset "Exported Functions - Optimization" begin
                for f in (:build_model, :build_solution)
                    Test.@testset "$f" begin
                        Test.@test isdefined(Optimization, f)
                        Test.@test isdefined(CurrentModule, f)
                        Test.@test getfield(CurrentModule, f) isa Function
                    end
                end
            end

            Test.@testset "Exported Functions - Solvers" begin
                Test.@test isdefined(Solvers, :extract_solver_infos)
                Test.@test Solvers.extract_solver_infos isa Function
            end
        end

        # ====================================================================
        # UNIT TESTS - Contract stubs (NotImplemented)
        # ====================================================================

        Test.@testset "Contract stubs - NotImplemented errors" begin
            prob = MinimalProblem()

            Test.@test_throws Exceptions.NotImplemented Optimization.build_model(
                prob, [1.0], FakeModeler(:adnlp)
            )
            built = Optimization.BuiltModel(prob, nothing, Optimization.NoCache())
            Test.@test_throws Exceptions.NotImplemented Optimization.build_solution(
                built,
                create_mock_execution_stats(1.0, 1, 1e-6, :first_order),
                FakeModeler(:adnlp),
            )
        end

        # ====================================================================
        # UNIT TESTS - Building Functions (build_model / build_solution)
        # ====================================================================

        Test.@testset "Building Functions" begin
            prob = FakeOptimizationProblem()

            Test.@testset "build_model with ADNLP backend" begin
                modeler = FakeModeler(:adnlp)
                x0 = [1.0, 2.0]
                nlp = Optimization.build_model(prob, x0, modeler).nlp
                Test.@test nlp isa ADNLPModels.ADNLPModel
                Test.@test nlp.meta.x0 == x0
            end

            Test.@testset "build_model with Exa backend" begin
                modeler = FakeModeler(:exa)
                x0 = [1.0, 2.0]
                nlp = Optimization.build_model(prob, x0, modeler).nlp
                Test.@test nlp isa ExaModels.ExaModel{Float64}
            end

            Test.@testset "build_solution with ADNLP backend" begin
                modeler = FakeModeler(:adnlp)
                built = Optimization.BuiltModel(prob, nothing, Optimization.NoCache())
                stats = create_mock_execution_stats(1.23, 10, 1e-6, :first_order)
                sol = Optimization.build_solution(built, stats, modeler)
                Test.@test sol.obj ≈ 1.23
                Test.@test sol.status == :first_order
            end

            Test.@testset "build_solution with Exa backend" begin
                modeler = FakeModeler(:exa)
                built = Optimization.BuiltModel(prob, nothing, Optimization.NoCache())
                stats = create_mock_execution_stats(2.34, 15, 1e-5, :acceptable)
                sol = Optimization.build_solution(built, stats, modeler)
                Test.@test sol.obj ≈ 2.34
                Test.@test sol.iter == 15
            end
        end

        # ====================================================================
        # UNIT TESTS - Solver Info Extraction
        # ====================================================================

        Test.@testset "Solver Info Extraction" begin
            Test.@testset "extract_solver_infos - first_order status" begin
                stats = create_mock_execution_stats(1.23, 15, 1.0e-6, :first_order)
                obj, iter, viol, msg, status, success = Solvers.extract_solver_infos(stats)
                Test.@test obj ≈ 1.23
                Test.@test iter == 15
                Test.@test viol ≈ 1.0e-6
                Test.@test msg == "Ipopt/generic"
                Test.@test status == :first_order
                Test.@test success == true
                Test.@test_nowarn Test.@inferred Solvers.extract_solver_infos(stats)
            end

            Test.@testset "extract_solver_infos - acceptable status" begin
                stats = create_mock_execution_stats(2.34, 20, 1.0e-5, :acceptable)
                obj, iter, viol, msg, status, success = Solvers.extract_solver_infos(stats)
                Test.@test obj ≈ 2.34
                Test.@test status == :acceptable
                Test.@test success == true
            end

            Test.@testset "extract_solver_infos - failure status" begin
                stats = create_mock_execution_stats(3.45, 5, 1.0e-3, :max_iter)
                obj, iter, viol, msg, status, success = Solvers.extract_solver_infos(stats)
                Test.@test obj ≈ 3.45
                Test.@test status == :max_iter
                Test.@test success == false
            end
        end

        # ====================================================================
        # INTEGRATION TESTS
        # ====================================================================

        Test.@testset "Integration Tests" begin
            Test.@testset "Complete workflow - ADNLP" begin
                prob = FakeOptimizationProblem()
                modeler = FakeModeler(:adnlp)
                x0 = [1.0, 2.0]
                built = Optimization.build_model(prob, x0, modeler)
                nlp = built.nlp
                Test.@test nlp isa ADNLPModels.ADNLPModel
                Test.@test NLPModels.obj(nlp, x0) ≈ 5.0

                stats = create_mock_execution_stats(5.0, 10, 1e-6, :first_order)
                sol = Optimization.build_solution(built, stats, modeler)
                Test.@test sol.obj ≈ 5.0
                Test.@test sol.status == :first_order

                obj, iter, viol, msg, status, success = Solvers.extract_solver_infos(stats)
                Test.@test obj ≈ 5.0
                Test.@test success == true
            end

            Test.@testset "Complete workflow - Exa" begin
                prob = FakeOptimizationProblem()
                modeler = FakeModeler(:exa)
                x0 = [1.0, 2.0]
                built = Optimization.build_model(prob, x0, modeler)
                nlp = built.nlp
                Test.@test nlp isa ExaModels.ExaModel{Float64}
                Test.@test NLPModels.obj(nlp, x0) ≈ 5.0

                stats = create_mock_execution_stats(5.0, 15, 1e-5, :acceptable)
                sol = Optimization.build_solution(built, stats, modeler)
                Test.@test sol.obj ≈ 5.0
                Test.@test sol.iter == 15
            end
        end
    end
end

end # module

test_optimization() = TestOptimization.test_optimization()
