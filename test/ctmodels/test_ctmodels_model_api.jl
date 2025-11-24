# Unit tests for the generic optimization model API (model and solution builders).
struct DummyProblemAPI <: CTSolvers.AbstractOptimizationProblem end

struct DummyStatsAPI <: SolverCore.AbstractExecutionStats end

struct DummySolutionAPI <: CTModels.AbstractSolution end

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

struct DummyOCPForModelAPI <: CTModels.AbstractModel end

function make_dummy_docp_for_model_api()
    ocp = DummyOCPForModelAPI()
    adnlp_builder = CTSolvers.ADNLPModelBuilder((x; kwargs...) -> begin
        f(z) = sum(z .^ 2)
        # We deliberately ignore the extra keyword arguments such as
        # show_time, backend, and AD backend options here. For this
        # unit test we only need a valid ADNLPModel instance.
        return ADNLPModels.ADNLPModel(f, x)
    end)
    exa_builder = CTSolvers.ExaModelBuilder((T, x; kwargs...) -> :exa_model_dummy)
    adnlp_solution_builder = CTSolvers.ADNLPSolutionBuilder(s -> s)
    exa_solution_builder = CTSolvers.ExaSolutionBuilder(s -> s)
    return CTSolvers.DiscretizedOptimalControlProblem(
        ocp,
        adnlp_builder,
        exa_builder,
        adnlp_solution_builder,
        exa_solution_builder,
    )
end

function test_ctmodels_model_api()

    # ------------------------------------------------------------------
    # Unit tests for build_model delegation
    # ------------------------------------------------------------------
    Test.@testset "ctmodels/model_api: build_model delegation" verbose=VERBOSE showtiming=SHOWTIMING begin
        prob = DummyProblemAPI()
        x0 = [1.0, 2.0]
        model_calls = Ref(0)
        solution_calls = Ref(0)
        backend = FakeBackendAPI(model_calls, solution_calls)

        nlp = CTSolvers.build_model(prob, x0, backend)
        Test.@test nlp isa NLPModels.AbstractNLPModel
        Test.@test model_calls[] == 1
        Test.@test solution_calls[] == 0
    end

    # ------------------------------------------------------------------
    # Unit tests for nlp_model(DiscretizedOptimalControlProblem, ...)
    # ------------------------------------------------------------------
    Test.@testset "ctmodels/model_api: nlp_model(DiscretizedOptimalControlProblem, ...)" verbose=VERBOSE showtiming=SHOWTIMING begin
        docp = make_dummy_docp_for_model_api()
        x0 = [1.0, 2.0]
        empty_backends = (
            :hprod_backend, :jtprod_backend, :jprod_backend, :ghjvprod_backend
        )
        ad_opts = (
            :show_time => false,
            :backend => :optimized,
            :empty_backends => empty_backends,
        )
        modeler = CTSolvers.ADNLPModeler(ad_opts)

        nlp = CTSolvers.nlp_model(docp, x0, modeler)
        Test.@test nlp isa NLPModels.AbstractNLPModel
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

    # ------------------------------------------------------------------
    # Unit tests for ocp_solution(DiscretizedOptimalControlProblem, ...)
    # ------------------------------------------------------------------
    Test.@testset "ctmodels/model_api: ocp_solution(DiscretizedOptimalControlProblem, ...)" verbose=VERBOSE showtiming=SHOWTIMING begin
        docp = make_dummy_docp_for_model_api()
        stats = DummyStatsAPI()
        model_calls = Ref(0)
        solution_calls = Ref(0)
        backend = FakeBackendAPI(model_calls, solution_calls)

        sol = CTSolvers.ocp_solution(docp, stats, backend)
        Test.@test sol isa DummySolutionAPI
        Test.@test model_calls[] == 0
        Test.@test solution_calls[] == 1
    end

    # ------------------------------------------------------------------
    # Integration-style tests for build_model on real problems
    # ------------------------------------------------------------------
    Test.@testset "ctmodels/model_api: build_model on Rosenbrock and Elec" verbose=VERBOSE showtiming=SHOWTIMING begin
        Test.@testset "Rosenbrock" verbose=VERBOSE showtiming=SHOWTIMING begin
            ad_opts_rosen = (
                :show_time => false,
                :backend => :manual,
                :empty_backends => (
                    :hprod_backend, :jtprod_backend, :jprod_backend, :ghjvprod_backend
                ),
            )
            modeler_ad = CTSolvers.ADNLPModeler(ad_opts_rosen)
            nlp_ad = CTSolvers.build_model(rosenbrock_prob, rosenbrock_init, modeler_ad)
            Test.@test nlp_ad isa ADNLPModels.ADNLPModel
            Test.@test nlp_ad.meta.x0 == rosenbrock_init
            Test.@test NLPModels.obj(nlp_ad, nlp_ad.meta.x0) == rosenbrock_objective(rosenbrock_init)
            Test.@test NLPModels.cons(nlp_ad, nlp_ad.meta.x0)[1] == rosenbrock_constraint(rosenbrock_init)
            Test.@test nlp_ad.meta.minimize == rosenbrock_is_minimize()

            exa_opts_rosen = (
                :backend => nothing,
            )
            modeler_exa = CTSolvers.ExaModeler{Float64,typeof(exa_opts_rosen)}(exa_opts_rosen)
            nlp_exa = CTSolvers.build_model(rosenbrock_prob, rosenbrock_init, modeler_exa)
            Test.@test nlp_exa isa ExaModels.ExaModel
        end

        Test.@testset "Elec" verbose=VERBOSE showtiming=SHOWTIMING begin
            ad_opts_elec = (
                :show_time => false,
                :backend => :manual,
                :empty_backends => (
                    :hprod_backend, :jtprod_backend, :jprod_backend, :ghjvprod_backend
                ),
            )
            modeler_ad = CTSolvers.ADNLPModeler(ad_opts_elec)
            nlp_ad = CTSolvers.build_model(elec_prob, elec_init, modeler_ad)
            Test.@test nlp_ad isa ADNLPModels.ADNLPModel
            Test.@test nlp_ad.meta.x0 == vcat(elec_init.x, elec_init.y, elec_init.z)
            Test.@test NLPModels.obj(nlp_ad, nlp_ad.meta.x0) == elec_objective(elec_init.x, elec_init.y, elec_init.z)
            Test.@test NLPModels.cons(nlp_ad, nlp_ad.meta.x0) == elec_constraint(elec_init.x, elec_init.y, elec_init.z)
            Test.@test nlp_ad.meta.minimize == elec_is_minimize()

            BaseType = Float64
            exa_opts_elec = (
                :backend => nothing,
            )
            modeler_exa = CTSolvers.ExaModeler{BaseType,typeof(exa_opts_elec)}(exa_opts_elec)
            nlp_exa = CTSolvers.build_model(elec_prob, elec_init, modeler_exa)
            Test.@test nlp_exa isa ExaModels.ExaModel{BaseType}
        end
    end

end
