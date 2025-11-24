# Unit tests for NLP backends (ADNLPModels and ExaModels) used by CTModels problems.
struct DummyBackendStats <: SolverCore.AbstractExecutionStats end

function test_ctmodels_nlp_backends()

    # ------------------------------------------------------------------
    # ADNLPModels backends (direct calls to ADNLPModeler)
    # ------------------------------------------------------------------
    # These tests exercise the call
    #   (modeler::ADNLPModeler)(prob, initial_guess)
    # directly, without going through the generic model API. We verify
    # that the resulting ADNLPModel has the correct initial point,
    # objective, constraints, and that the AD backends are configured as
    # expected when using the manual backend path.
    Test.@testset "ctmodels/nlp_backends: ADNLPModels – Rosenbrock (backend=:manual, direct call)" verbose=VERBOSE showtiming=SHOWTIMING begin
        modeler = CTSolvers.ADNLPModeler(; backend=:manual)
        nlp_adnlp = modeler(rosenbrock_prob, rosenbrock_init)
        Test.@test nlp_adnlp isa ADNLPModels.ADNLPModel
        Test.@test nlp_adnlp.meta.x0 == rosenbrock_init
        Test.@test NLPModels.obj(nlp_adnlp, nlp_adnlp.meta.x0) == rosenbrock_objective(rosenbrock_init)
        Test.@test NLPModels.cons(nlp_adnlp, nlp_adnlp.meta.x0)[1] == rosenbrock_constraint(rosenbrock_init)
        Test.@test nlp_adnlp.meta.minimize == rosenbrock_is_minimize()

        # Automatic Differentiation backends configured by backend_options
        ad_backends = ADNLPModels.get_adbackend(nlp_adnlp)
        Test.@test ad_backends.gradient_backend isa ADNLPModels.ReverseDiffADGradient
        Test.@test ad_backends.jacobian_backend isa ADNLPModels.SparseADJacobian
        Test.@test ad_backends.hessian_backend isa ADNLPModels.SparseReverseADHessian
        Test.@test ad_backends.jtprod_backend isa ADNLPModels.EmptyADbackend
        Test.@test ad_backends.jprod_backend isa ADNLPModels.EmptyADbackend
        Test.@test ad_backends.ghjvprod_backend isa ADNLPModels.EmptyADbackend
        Test.@test ad_backends.hprod_backend isa ADNLPModels.EmptyADbackend
    end

    # Same backend=:manual path but on a different CTModels problem (Elec),
    # still calling the backend directly.
    Test.@testset "ctmodels/nlp_backends: ADNLPModels – Elec (backend=:manual, direct call)" begin
        modeler = CTSolvers.ADNLPModeler(; backend=:manual)
        nlp_adnlp = modeler(elec_prob, elec_init)
        Test.@test nlp_adnlp isa ADNLPModels.ADNLPModel
        Test.@test nlp_adnlp.meta.x0 == vcat(elec_init.x, elec_init.y, elec_init.z)
        Test.@test NLPModels.obj(nlp_adnlp, nlp_adnlp.meta.x0) == elec_objective(elec_init.x, elec_init.y, elec_init.z)
        Test.@test NLPModels.cons(nlp_adnlp, nlp_adnlp.meta.x0) == elec_constraint(elec_init.x, elec_init.y, elec_init.z)
        Test.@test nlp_adnlp.meta.minimize == elec_is_minimize()
    end

    # For a problem without specialized get_* methods, ADNLPModeler
    # should surface the generic NotImplemented error from get_adnlp_model_builder
    # even when called directly.
    Test.@testset "ctmodels/nlp_backends: ADNLPModels – DummyProblem (NotImplemented, direct call)" verbose=VERBOSE showtiming=SHOWTIMING begin
        modeler = CTSolvers.ADNLPModeler(; backend=:manual)
        Test.@test_throws CTBase.NotImplemented modeler(DummyProblem(), rosenbrock_init)
    end

    # ------------------------------------------------------------------
    # ExaModels backends (direct calls to ExaModeler, CPU)
    # ------------------------------------------------------------------
    # These tests exercise the call
    #   (modeler::ExaModeler)(prob, initial_guess)
    # directly, using a concrete BaseType (Float32).
    Test.@testset "ctmodels/nlp_backends: ExaModels (CPU) – Rosenbrock (BaseType=Float32, direct call)" verbose=VERBOSE showtiming=SHOWTIMING begin
        BaseType = Float32
        modeler = CTSolvers.ExaModeler(; base_type=BaseType)
        nlp_exa_cpu = modeler(rosenbrock_prob, rosenbrock_init)
        Test.@test nlp_exa_cpu isa ExaModels.ExaModel{BaseType}
        Test.@test nlp_exa_cpu.meta.x0 == BaseType.(rosenbrock_init)
        Test.@test eltype(nlp_exa_cpu.meta.x0) == BaseType
        Test.@test NLPModels.obj(nlp_exa_cpu, nlp_exa_cpu.meta.x0) == rosenbrock_objective(BaseType.(rosenbrock_init))
        Test.@test NLPModels.cons(nlp_exa_cpu, nlp_exa_cpu.meta.x0)[1] == rosenbrock_constraint(BaseType.(rosenbrock_init))
        Test.@test nlp_exa_cpu.meta.minimize == rosenbrock_is_minimize()
    end

    # Same ExaModels backend but on the Elec problem, with direct backend call.
    Test.@testset "ctmodels/nlp_backends: ExaModels (CPU) – Elec (BaseType=Float32, direct call)" begin
        BaseType = Float32
        modeler = CTSolvers.ExaModeler(; base_type=BaseType)
        nlp_exa_cpu = modeler(elec_prob, elec_init)
        Test.@test nlp_exa_cpu isa ExaModels.ExaModel{BaseType}
        Test.@test nlp_exa_cpu.meta.x0 == BaseType.(vcat(elec_init.x, elec_init.y, elec_init.z))
        Test.@test eltype(nlp_exa_cpu.meta.x0) == BaseType
        Test.@test NLPModels.obj(nlp_exa_cpu, nlp_exa_cpu.meta.x0) == elec_objective(BaseType.(elec_init.x), BaseType.(elec_init.y), BaseType.(elec_init.z))
        Test.@test NLPModels.cons(nlp_exa_cpu, nlp_exa_cpu.meta.x0) == elec_constraint(BaseType.(elec_init.x), BaseType.(elec_init.y), BaseType.(elec_init.z))
        Test.@test nlp_exa_cpu.meta.minimize == elec_is_minimize()
    end

    # For a problem without specialized get_* methods, ExaModeler
    # should surface the generic NotImplemented error from get_exa_model_builder
    # even when called directly.
    Test.@testset "ctmodels/nlp_backends: ExaModels (CPU) – DummyProblem (NotImplemented, direct call)" verbose=VERBOSE showtiming=SHOWTIMING begin
        modeler = CTSolvers.ExaModeler()
        Test.@test_throws CTBase.NotImplemented modeler(DummyProblem(), rosenbrock_init)
    end

    # ------------------------------------------------------------------
    # Constructor-level tests for ADNLPModeler and ExaModeler
    # ------------------------------------------------------------------
    # These tests focus on the fields set by the constructors, ensuring
    # defaults and keyword arguments are wired correctly.

    Test.@testset "ctmodels/nlp_backends: ADNLPModeler constructor" verbose=VERBOSE showtiming=SHOWTIMING begin
        # Default constructor should use the values from ctmodels/default.jl
        backend_default = CTSolvers.ADNLPModeler()
        Test.@test backend_default.show_time == CTSolvers.__adnlp_model_show_time()
        Test.@test backend_default.backend    == CTSolvers.__adnlp_model_backend()
        Test.@test backend_default.empty_backends == CTSolvers.__adnlp_model_empty_backends()
        Test.@test length(keys(backend_default.kwargs)) == 0

        # Custom backend and extra kwargs should be stored as-is
        backend_manual = CTSolvers.ADNLPModeler(; backend=:manual, foo=1)
        Test.@test backend_manual.backend == :manual
        Test.@test backend_manual.kwargs[:foo] == 1
    end

    Test.@testset "ctmodels/nlp_backends: ExaModeler constructor" verbose=VERBOSE showtiming=SHOWTIMING begin
        # Default constructor should use base_type and backend from ctmodels/default.jl
        exa_default = CTSolvers.ExaModeler()
        Test.@test exa_default.backend === CTSolvers.__exa_model_backend()
        Test.@test length(keys(exa_default.kwargs)) == 0

        # Custom base_type and kwargs should be stored correctly
        exa_custom = CTSolvers.ExaModeler(; base_type=Float32, foo=2)
        Test.@test exa_custom.backend === CTSolvers.__exa_model_backend()
        Test.@test exa_custom.kwargs[:foo] == 2
    end

    # ------------------------------------------------------------------
    # Solution-building via ADNLPModeler/ExaModeler(prob, nlp_solution)
    # ------------------------------------------------------------------
    # For OptimizationProblem (defined in test/problems/problems_definition.jl),
    # get_adnlp_solution_builder and get_exa_solution_builder return custom
    # solution builders (ADNLPSolutionBuilder, ExaSolutionBuilder) that are
    # callable on the nlp_solution and simply return it unchanged. Here we
    # verify that the backends correctly route through those builders.

    Test.@testset "ctmodels/nlp_backends: ADNLPModeler solution building" verbose=VERBOSE showtiming=SHOWTIMING begin
        # Build an OptimizationProblem with dummy builders (unused in this test)
        dummy_ad_builder = CTSolvers.ADNLPModelBuilder(x -> error("unused"))
        function dummy_exa_builder_f(::Type{T}, x; kwargs...) where {T}
            error("unused")
        end
        dummy_exa_builder = CTSolvers.ExaModelBuilder(dummy_exa_builder_f)
        prob = OptimizationProblem(
            dummy_ad_builder,
            dummy_exa_builder,
            ADNLPSolutionBuilder(),
            ExaSolutionBuilder(),
        )

        stats = DummyBackendStats()
        modeler = CTSolvers.ADNLPModeler()
        # Should call get_adnlp_solution_builder(prob) and then
        # builder(stats), which is implemented in problems_definition.jl
        # to return stats unchanged.
        result = modeler(prob, stats)
        Test.@test result === stats
    end

    Test.@testset "ctmodels/nlp_backends: ExaModeler solution building" verbose=VERBOSE showtiming=SHOWTIMING begin
        dummy_ad_builder = CTSolvers.ADNLPModelBuilder(x -> error("unused"))
        function dummy_exa_builder_f2(::Type{T}, x; kwargs...) where {T}
            error("unused")
        end
        dummy_exa_builder = CTSolvers.ExaModelBuilder(dummy_exa_builder_f2)
        prob = OptimizationProblem(
            dummy_ad_builder,
            dummy_exa_builder,
            ADNLPSolutionBuilder(),
            ExaSolutionBuilder(),
        )

        stats = DummyBackendStats()
        modeler = CTSolvers.ExaModeler()
        # Should call get_exa_solution_builder(prob) and then
        # builder(stats), which returns stats.
        result = modeler(prob, stats)
        Test.@test result === stats
    end

end
