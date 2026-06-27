module TestOptimizationErrorCases

using Test: Test
import CTBase.Exceptions
using NLPModels: NLPModels
using SolverCore: SolverCore
using ADNLPModels: ADNLPModels
using ExaModels: ExaModels
const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

# Import from CTSolvers
import CTSolvers.Optimization
import CTSolvers.Modelers

# ============================================================================
# FAKE TYPES FOR ERROR TESTING (TOP-LEVEL)
# ============================================================================

"""
Minimal problem that doesn't implement the contract.
"""
struct MinimalProblemForErrors <: Optimization.AbstractOptimizationProblem end

"""
Problem with only partial contract implementation (ADNLP only, no Exa).
"""
struct PartialProblem <: Optimization.AbstractOptimizationProblem end

function Optimization.build_model(::PartialProblem, initial_guess, ::Modelers.ADNLP)
    return ADNLPModels.ADNLPModel(z -> sum(z .^ 2), initial_guess)
end

"""
Problem whose model builder always fails (to test error propagation).
"""
struct FailingProblem <: Optimization.AbstractOptimizationProblem end

function Optimization.build_model(::FailingProblem, initial_guess, ::Modelers.ADNLP)
    return error("Intentional error")
end

function Optimization.build_solution(
    ::FailingProblem, ::SolverCore.AbstractExecutionStats, ::Modelers.ADNLP
)
    return error("Intentional error")
end

"""
Sum-of-squares problem implementing both backends (for edge cases).
"""
struct SquaresProblem <: Optimization.AbstractOptimizationProblem end

function Optimization.build_model(::SquaresProblem, initial_guess, ::Modelers.ADNLP)
    return ADNLPModels.ADNLPModel(z -> sum(z .^ 2), initial_guess)
end

function Optimization.build_model(::SquaresProblem, initial_guess, modeler::Modelers.Exa)
    T = modeler[:base_type]
    x = T.(initial_guess)
    m = ExaModels.ExaCore(T; concrete=Val(true))
    ExaModels.@add_var(m, x_var, length(x); start=x)
    ExaModels.@add_obj(m, sum(x_var[i]^2 for i in 1:length(x)))
    return ExaModels.ExaModel(m)
end

"""
Mock stats for testing.
"""
mutable struct MockStats <: SolverCore.AbstractExecutionStats
    objective::Float64
end

# TOP-LEVEL: Create GenericExecutionStats instances for testing edge cases
function create_edge_case_stats(
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
    test_error_cases()

Tests for error cases and edge cases in the Optimization contract.
"""
function test_error_cases()
    Test.@testset "Error Cases and Edge Cases" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ====================================================================
        # CONTRACT NOT IMPLEMENTED ERRORS
        # ====================================================================

        Test.@testset "NotImplemented Errors" begin
            prob = MinimalProblemForErrors()

            Test.@testset "build_model - NotImplemented" begin
                Test.@test_throws Exceptions.NotImplemented Optimization.build_model(
                    prob, [1.0, 2.0], Modelers.ADNLP()
                )
            end

            Test.@testset "build_solution - NotImplemented" begin
                stats = create_edge_case_stats(1.0, 1, 1e-6, :first_order)
                Test.@test_throws Exceptions.NotImplemented Optimization.build_solution(
                    prob, stats, Modelers.ADNLP()
                )
            end
        end

        # ====================================================================
        # PARTIAL CONTRACT IMPLEMENTATION
        # ====================================================================

        Test.@testset "Partial Contract Implementation" begin
            prob = PartialProblem()

            Test.@testset "Implemented backend works" begin
                x0 = [1.0, 2.0]
                nlp = Optimization.build_model(prob, x0, Modelers.ADNLP())
                Test.@test nlp isa ADNLPModels.ADNLPModel
            end

            Test.@testset "Non-implemented backend throws NotImplemented" begin
                Test.@test_throws Exceptions.NotImplemented Optimization.build_model(
                    prob, [1.0, 2.0], Modelers.Exa()
                )
            end
        end

        # ====================================================================
        # BUILDER ERRORS (error propagation through the contract)
        # ====================================================================

        Test.@testset "Builder Errors" begin
            prob = FailingProblem()

            Test.@testset "build_model with failing implementation" begin
                Test.@test_throws ErrorException Optimization.build_model(
                    prob, [1.0, 2.0], Modelers.ADNLP()
                )
            end

            Test.@testset "build_solution with failing implementation" begin
                stats = MockStats(1.0)
                Test.@test_throws ErrorException Optimization.build_solution(
                    prob, stats, Modelers.ADNLP()
                )
            end
        end

        # ====================================================================
        # EDGE CASES
        # ====================================================================

        Test.@testset "Edge Cases" begin
            prob = SquaresProblem()

            Test.@testset "Single variable problem" begin
                x0 = [1.0]
                nlp = Optimization.build_model(prob, x0, Modelers.ADNLP())
                Test.@test nlp isa ADNLPModels.ADNLPModel
                Test.@test nlp.meta.nvar == 1
                Test.@test NLPModels.obj(nlp, x0) ≈ 1.0
            end

            Test.@testset "Large dimension problem" begin
                n = 1000
                x0 = ones(n)
                nlp = Optimization.build_model(prob, x0, Modelers.ADNLP())
                Test.@test nlp isa ADNLPModels.ADNLPModel
                Test.@test nlp.meta.nvar == n
            end

            Test.@testset "Different numeric types" begin
                nlp32 = Optimization.build_model(
                    prob, Float32[1.0, 2.0], Modelers.Exa(; base_type=Float32)
                )
                Test.@test nlp32 isa ExaModels.ExaModel{Float32}
                Test.@test eltype(nlp32.meta.x0) == Float32

                nlp64 = Optimization.build_model(
                    prob, Float64[1.0, 2.0], Modelers.Exa(; base_type=Float64)
                )
                Test.@test nlp64 isa ExaModels.ExaModel{Float64}
                Test.@test eltype(nlp64.meta.x0) == Float64
            end
        end

        # ====================================================================
        # SOLVER INFO EDGE CASES
        # ====================================================================

        Test.@testset "Solver Info Edge Cases" begin
            Test.@testset "Zero iterations" begin
                stats = create_edge_case_stats(0.0, 0, 0.0, :first_order)
                obj, iter, viol, msg, status, success = Optimization.extract_solver_infos(
                    stats
                )
                Test.@test iter == 0
                Test.@test success == true
            end

            Test.@testset "Very large objective" begin
                stats = create_edge_case_stats(1e100, 10, 1e-6, :first_order)
                obj, iter, viol, msg, status, success = Optimization.extract_solver_infos(
                    stats
                )
                Test.@test obj ≈ 1e100
                Test.@test success == true
            end

            Test.@testset "Very small constraint violation" begin
                stats = create_edge_case_stats(1.0, 10, 1e-15, :first_order)
                obj, iter, viol, msg, status, success = Optimization.extract_solver_infos(
                    stats
                )
                Test.@test viol ≈ 1e-15
                Test.@test success == true
            end

            Test.@testset "Unknown status" begin
                stats = create_edge_case_stats(1.0, 10, 1e-6, :unknown_status)
                obj, iter, viol, msg, status, success = Optimization.extract_solver_infos(
                    stats
                )
                Test.@test status == :unknown_status
                Test.@test success == false  # Not :first_order or :acceptable
            end
        end

        # ====================================================================
        # TYPE STABILITY TESTS
        # ====================================================================

        Test.@testset "Type Stability" begin
            prob = SquaresProblem()

            Test.@testset "build_model return type" begin
                x0 = [1.0, 2.0]
                nlp = Optimization.build_model(prob, x0, Modelers.ADNLP())
                Test.@test nlp isa ADNLPModels.ADNLPModel
                Test.@test typeof(nlp) <: ADNLPModels.ADNLPModel
            end
        end
    end
end

end # module

test_error_cases() = TestOptimizationErrorCases.test_error_cases()
