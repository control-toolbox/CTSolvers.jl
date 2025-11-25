# Unit tests for the CommonSolve API across OCP, discretized problems, and NLP models.
struct DummyOCPCommon <: CTSolvers.AbstractOptimalControlProblem end

struct DummyDiscretizedOCPCommon <: CTSolvers.AbstractOptimizationProblem end

struct DummyInitCommon <: CTSolvers.AbstractOptimalControlInitialGuess
    x0::Vector{Float64}
end

struct DummyStatsCommon <: SolverCore.AbstractExecutionStats
    tag::Symbol
end

struct DummySolutionCommon <: CTSolvers.AbstractOptimalControlSolution end

struct FakeDiscretizerCommon <: CTSolvers.AbstractOptimalControlDiscretizer
    calls::Base.RefValue{Int}
end

function (d::FakeDiscretizerCommon)(ocp::CTSolvers.AbstractOptimalControlProblem)
    d.calls[] += 1
    return DummyDiscretizedOCPCommon()
end

struct FakeModelerCommon <: CTSolvers.AbstractOptimizationModeler
    model_calls::Base.RefValue{Int}
    solution_calls::Base.RefValue{Int}
end

function (m::FakeModelerCommon)(
    prob::CTSolvers.AbstractOptimizationProblem, init::DummyInitCommon
)::NLPModels.AbstractNLPModel
    m.model_calls[] += 1
    f(z) = sum(z .^ 2)
    return ADNLPModels.ADNLPModel(f, init.x0)
end

function (m::FakeModelerCommon)(
    prob::CTSolvers.AbstractOptimizationProblem,
    nlp_solution::SolverCore.AbstractExecutionStats,
)
    m.solution_calls[] += 1
    return DummySolutionCommon()
end

struct FakeSolverNLPCommon <: CTSolvers.AbstractOptimizationSolver
    calls::Base.RefValue{Int}
end

function (s::FakeSolverNLPCommon)(
    nlp::NLPModels.AbstractNLPModel; display::Bool
)::SolverCore.AbstractExecutionStats
    s.calls[] += 1
    return DummyStatsCommon(:solver_called)
end

struct FakeSolverAnyCommon <: CTSolvers.AbstractOptimizationSolver
    calls::Base.RefValue{Int}
end

function (s::FakeSolverAnyCommon)(nlp; display::Bool)
    s.calls[] += 1
    return DummyStatsCommon(:solver_any_called)
end

function test_ctsolvers_common_solve_api()

    # ========================================================================
    # solve(ocp, init, discretizer, modeler, solver)
    # ========================================================================

    Test.@testset "ctsolvers/common_solve_api: solve(ocp, init, discretizer, modeler, solver)" verbose=VERBOSE showtiming=SHOWTIMING begin
        prob = DummyOCPCommon()
        init = DummyInitCommon([1.0, 2.0])

        discretizer_calls = Ref(0)
        model_calls = Ref(0)
        solution_calls = Ref(0)
        solver_calls = Ref(0)

        discretizer = FakeDiscretizerCommon(discretizer_calls)
        modeler = FakeModelerCommon(model_calls, solution_calls)
        solver = FakeSolverNLPCommon(solver_calls)

        sol = CommonSolve.solve(prob, init, discretizer, modeler, solver; display=false)

        Test.@test sol isa DummySolutionCommon
        Test.@test discretizer_calls[] == 1
        Test.@test model_calls[] == 1
        Test.@test solver_calls[] == 1
        Test.@test solution_calls[] == 1
    end

    # ========================================================================
    # solve(problem, init, modeler, solver)
    # ========================================================================

    Test.@testset "ctsolvers/common_solve_api: solve(problem, init, modeler, solver)" verbose=VERBOSE showtiming=SHOWTIMING begin
        prob = DummyDiscretizedOCPCommon()
        init = DummyInitCommon([3.0, 4.0])

        model_calls = Ref(0)
        solution_calls = Ref(0)
        solver_calls = Ref(0)

        modeler = FakeModelerCommon(model_calls, solution_calls)
        solver = FakeSolverNLPCommon(solver_calls)

        sol = CommonSolve.solve(prob, init, modeler, solver; display=true)

        Test.@test sol isa DummySolutionCommon
        Test.@test model_calls[] == 1
        Test.@test solver_calls[] == 1
        Test.@test solution_calls[] == 1
    end

    # ========================================================================
    # solve(nlp::AbstractNLPModel, solver)
    # ========================================================================

    Test.@testset "ctsolvers/common_solve_api: solve(nlp::AbstractNLPModel, solver)" verbose=VERBOSE showtiming=SHOWTIMING begin
        f(z) = sum(z .^ 2)
        nlp = ADNLPModels.ADNLPModel(f, [1.0, 2.0])

        solver_calls = Ref(0)
        solver = FakeSolverNLPCommon(solver_calls)

        stats = CommonSolve.solve(nlp, solver; display=true)

        Test.@test stats isa DummyStatsCommon
        Test.@test stats.tag == :solver_called
        Test.@test solver_calls[] == 1
    end

    # ========================================================================
    # solve(nlp, solver) generic fallback
    # ========================================================================

    Test.@testset "ctsolvers/common_solve_api: solve(nlp, solver) generic" verbose=VERBOSE showtiming=SHOWTIMING begin
        nlp = :dummy_nlp

        solver_calls = Ref(0)
        solver = FakeSolverAnyCommon(solver_calls)

        stats = CommonSolve.solve(nlp, solver; display=false)

        Test.@test stats isa DummyStatsCommon
        Test.@test stats.tag == :solver_any_called
        Test.@test solver_calls[] == 1
    end
end
