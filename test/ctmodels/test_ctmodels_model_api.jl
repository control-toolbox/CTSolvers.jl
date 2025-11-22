struct DummyProblemAPI <: CTSolvers.AbstractOptimizationProblem end

struct DummyStatsAPI <: SolverCore.AbstractExecutionStats end

struct DummySolutionAPI end

struct FakeBackendAPI <: CTSolvers.AbstractOptimizationModeler
    model_calls::Base.RefValue{Int}
    solution_calls::Base.RefValue{Int}
end

function (b::FakeBackendAPI)(
    prob::CTSolvers.AbstractOptimizationProblem,
    initial_guess,
)::NLPModels.AbstractNLPModel
    b.model_calls[] += 1
    # Use a simple real ADNLPModel here so that we respect the declared
    # return type ::NLPModels.AbstractNLPModel without defining custom
    # subtypes of NLPModels internals.
    f(z) = sum(z .^ 2)
    return ADNLPModels.ADNLPModel(f, initial_guess)
end

function (b::FakeBackendAPI)(
    prob::CTSolvers.AbstractOptimizationProblem,
    nlp_solution::SolverCore.AbstractExecutionStats,
)
    b.solution_calls[] += 1
    return DummySolutionAPI()
end

function test_ctmodels_model_api()

    # ------------------------------------------------------------------
    # Unit tests for build_model and nlp_model delegation
    # ------------------------------------------------------------------
    # We construct a small fake backend that records how many times it is
    # called and returns a dummy NLP model type. This lets us test that
    # build_model and nlp_model both delegate correctly without depending
    # on any particular real backend.

    Test.@testset "ctmodels/model_api: build_model & nlp_model delegation" verbose=VERBOSE showtiming=SHOWTIMING begin
        prob = DummyProblemAPI()
        x0 = [1.0, 2.0]
        model_calls = Ref(0)
        solution_calls = Ref(0)
        backend = FakeBackendAPI(model_calls, solution_calls)

        # build_model should call the backend once and return an AbstractNLPModel
        nlp1 = CTSolvers.build_model(prob, x0, backend)
        Test.@test nlp1 isa NLPModels.AbstractNLPModel
        Test.@test model_calls[] == 1
        Test.@test solution_calls[] == 0

        # nlp_model should delegate to build_model and trigger a second call
        nlp2 = CTSolvers.nlp_model(prob, x0, backend)
        Test.@test nlp2 isa NLPModels.AbstractNLPModel
        Test.@test model_calls[] == 2
        Test.@test solution_calls[] == 0
    end

    # ------------------------------------------------------------------
    # Unit tests for build_solution(prob, stats, backend) delegation
    # ------------------------------------------------------------------
    # Here we verify that build_solution(prob, nlp_solution, backend)
    # calls the backend's (prob, nlp_solution) method and returns whatever
    # the backend returns (here a DummySolutionAPI instance).

    Test.@testset "ctmodels/model_api: build_solution(prob, stats, backend)" verbose=VERBOSE showtiming=SHOWTIMING begin
        prob = DummyProblemAPI()
        stats = DummyStatsAPI()
        model_calls = Ref(0)
        solution_calls = Ref(0)
        backend = FakeBackendAPI(model_calls, solution_calls)

        sol = CTSolvers.build_solution(prob, stats, backend)
        Test.@test sol isa DummySolutionAPI
        Test.@test model_calls[] == 0
        Test.@test solution_calls[] == 1
    end

end
