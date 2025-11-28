# Unit tests for the CommonSolve API across OCP, discretized problems, and NLP models.
struct CSDummyOCP <: CTSolvers.AbstractOptimalControlProblem end

struct CSDummyDiscretizedOCP <: CTSolvers.AbstractOptimizationProblem end

struct CSDummyInit <: CTSolvers.AbstractOptimalControlInitialGuess
    x0::Vector{Float64}
end

struct CSDummyStats <: SolverCore.AbstractExecutionStats
    tag::Symbol
end

struct CSDummySolution <: CTSolvers.AbstractOptimalControlSolution end

struct CSFakeDiscretizer <: CTSolvers.AbstractOptimalControlDiscretizer
    calls::Base.RefValue{Int}
end

function (d::CSFakeDiscretizer)(ocp::CTSolvers.AbstractOptimalControlProblem)
    d.calls[] += 1
    return CSDummyDiscretizedOCP()
end

struct CSFakeModeler <: CTSolvers.AbstractOptimizationModeler
    model_calls::Base.RefValue{Int}
    solution_calls::Base.RefValue{Int}
end

function (m::CSFakeModeler)(
    prob::CTSolvers.AbstractOptimizationProblem, init::CSDummyInit
)::NLPModels.AbstractNLPModel
    m.model_calls[] += 1
    f(z) = sum(z .^ 2)
    return ADNLPModels.ADNLPModel(f, init.x0)
end

function (m::CSFakeModeler)(
    prob::CTSolvers.AbstractOptimizationProblem,
    nlp_solution::SolverCore.AbstractExecutionStats,
)
    m.solution_calls[] += 1
    return CSDummySolution()
end

struct CSFakeSolverNLP <: CTSolvers.AbstractOptimizationSolver
    calls::Base.RefValue{Int}
end

function (s::CSFakeSolverNLP)(
    nlp::NLPModels.AbstractNLPModel; display::Bool
)::SolverCore.AbstractExecutionStats
    s.calls[] += 1
    return CSDummyStats(:solver_called)
end

struct CSFakeSolverAny <: CTSolvers.AbstractOptimizationSolver
    calls::Base.RefValue{Int}
end

function (s::CSFakeSolverAny)(nlp; display::Bool)
    s.calls[] += 1
    return CSDummyStats(:solver_any_called)
end

function test_ctsolvers_common_solve_api()

    # ========================================================================
    # Low-level default display flag
    # ========================================================================

    Test.@testset "raw defaults" verbose=VERBOSE showtiming=SHOWTIMING begin
        Test.@test CTSolvers.__display() isa Bool
    end

    # ========================================================================
    # solve(problem, init, modeler, solver)
    # ========================================================================

    Test.@testset "solve(problem, init, modeler, solver)" verbose=VERBOSE showtiming=SHOWTIMING begin
        prob = CSDummyDiscretizedOCP()
        init = CSDummyInit([3.0, 4.0])

        model_calls = Ref(0)
        solution_calls = Ref(0)
        solver_calls = Ref(0)

        modeler = CSFakeModeler(model_calls, solution_calls)
        solver = CSFakeSolverNLP(solver_calls)

        sol = CommonSolve.solve(prob, init, modeler, solver; display=true)

        Test.@test sol isa CSDummySolution
        Test.@test model_calls[] == 1
        Test.@test solver_calls[] == 1
        Test.@test solution_calls[] == 1
    end

    # ========================================================================
    # solve(nlp::AbstractNLPModel, solver)
    # ========================================================================

    Test.@testset "solve(nlp::AbstractNLPModel, solver)" verbose=VERBOSE showtiming=SHOWTIMING begin
        f(z) = sum(z .^ 2)
        nlp = ADNLPModels.ADNLPModel(f, [1.0, 2.0])

        solver_calls = Ref(0)
        solver = CSFakeSolverNLP(solver_calls)

        stats = CommonSolve.solve(nlp, solver; display=true)

        Test.@test stats isa CSDummyStats
        Test.@test stats.tag == :solver_called
        Test.@test solver_calls[] == 1
    end

    # ========================================================================
    # solve(nlp, solver) generic fallback
    # ========================================================================

    Test.@testset "solve(nlp, solver) generic" verbose=VERBOSE showtiming=SHOWTIMING begin
        nlp = :dummy_nlp

        solver_calls = Ref(0)
        solver = CSFakeSolverAny(solver_calls)

        stats = CommonSolve.solve(nlp, solver; display=false)

        Test.@test stats isa CSDummyStats
        Test.@test stats.tag == :solver_any_called
        Test.@test solver_calls[] == 1
    end
end
