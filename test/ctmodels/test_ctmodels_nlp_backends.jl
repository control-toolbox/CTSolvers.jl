# Unit tests for NLP backends (ADNLPModels and ExaModels) used by CTModels problems.
struct CMDummyBackendStats <: SolverCore.AbstractExecutionStats end

struct CMOptionsCaptureProbAD  <: CTSolvers.AbstractOptimizationProblem end
struct CMOptionsCaptureProbExa <: CTSolvers.AbstractOptimizationProblem end

const captured_ad_kwargs  = Base.RefValue{Any}(nothing)
const captured_exa_kwargs = Base.RefValue{Any}(nothing)

function CTSolvers.get_adnlp_model_builder(::CMOptionsCaptureProbAD)
    return CTSolvers.ADNLPModelBuilder((x; kwargs...) -> begin
        captured_ad_kwargs[] = kwargs
        f(z) = sum(z .^ 2)
        return ADNLPModels.ADNLPModel(f, x)
    end)
end

function _exa_capture_builder(::Type{T}, x; kwargs...) where {T}
    captured_exa_kwargs[] = kwargs
    m = ExaModels.ExaCore(T)
    z = ExaModels.variable(m, length(x); start=x)
    ExaModels.objective(m, sum(z))
    return ExaModels.ExaModel(m)
end

function CTSolvers.get_exa_model_builder(::CMOptionsCaptureProbExa)
    return CTSolvers.ExaModelBuilder(_exa_capture_builder)
end

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
        modeler = CTSolvers.ADNLPModeler(())
        nlp_adnlp = modeler(rosenbrock_prob, rosenbrock_init)
        Test.@test nlp_adnlp isa ADNLPModels.ADNLPModel
        Test.@test nlp_adnlp.meta.x0 == rosenbrock_init
        Test.@test NLPModels.obj(nlp_adnlp, nlp_adnlp.meta.x0) == rosenbrock_objective(rosenbrock_init)
        Test.@test NLPModels.cons(nlp_adnlp, nlp_adnlp.meta.x0)[1] == rosenbrock_constraint(rosenbrock_init)
        Test.@test nlp_adnlp.meta.minimize == rosenbrock_is_minimize()
    end

    # Same backend=:manual path but on a different CTModels problem (Elec),
    # still calling the backend directly.
    Test.@testset "ctmodels/nlp_backends: ADNLPModels – Elec (backend=:manual, direct call)" begin
        modeler = CTSolvers.ADNLPModeler(())
        nlp_adnlp = modeler(elec_prob, elec_init)
        Test.@test nlp_adnlp isa ADNLPModels.ADNLPModel
        Test.@test nlp_adnlp.meta.x0 == vcat(elec_init.x, elec_init.y, elec_init.z)
        Test.@test NLPModels.obj(nlp_adnlp, nlp_adnlp.meta.x0) == elec_objective(elec_init.x, elec_init.y, elec_init.z)
        Test.@test NLPModels.cons(nlp_adnlp, nlp_adnlp.meta.x0) == elec_constraint(elec_init.x, elec_init.y, elec_init.z)
        Test.@test nlp_adnlp.meta.minimize == elec_is_minimize()
        modeler = CTSolvers.ADNLPModeler(())
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
        modeler = CTSolvers.ADNLPModeler(())
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
        modeler = CTSolvers.ExaModeler{BaseType}(())
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
        modeler = CTSolvers.ExaModeler{BaseType}(())
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
        modeler = CTSolvers.ExaModeler{Float64}(())
        Test.@test_throws CTBase.NotImplemented modeler(DummyProblem(), rosenbrock_init)
    end

    # ------------------------------------------------------------------
    # Constructor-level tests for ADNLPModeler and ExaModeler
    # ------------------------------------------------------------------
    # These tests focus on the fields set by the constructors, ensuring
    # defaults and keyword arguments are wired correctly.

    Test.@testset "ctmodels/nlp_backends: ADNLPModeler constructor" verbose=VERBOSE showtiming=SHOWTIMING begin
        # Explicit constructor with default (empty) options
        modeler = CTSolvers.ADNLPModeler(())
        Test.@test modeler isa CTSolvers.ADNLPModeler
        Test.@test modeler.options == ()
    end

    Test.@testset "ctmodels/nlp_backends: ExaModeler constructor" verbose=VERBOSE showtiming=SHOWTIMING begin
        # Explicit constructor with default (empty) options
        BaseType = Float64
        modeler = CTSolvers.ExaModeler{BaseType}(())
        Test.@test modeler isa CTSolvers.ExaModeler{BaseType}
        Test.@test modeler.options == ()
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

        stats = CMDummyBackendStats()
        modeler = CTSolvers.ADNLPModeler(())
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

        stats = CMDummyBackendStats()
        modeler = CTSolvers.ExaModeler{Float64}(())
        # Should call get_exa_solution_builder(prob) and then
        # builder(stats), which returns stats.
        result = modeler(prob, stats)
        Test.@test result === stats
    end

    Test.@testset "ctmodels/nlp_backends: ADNLPModeler options forwarding" verbose=VERBOSE showtiming=SHOWTIMING begin
        prob = CMOptionsCaptureProbAD()
        x0 = [1.0, 2.0]
        opts = (
            :alpha => 1.0,
            :beta  => 2,
        )
        modeler = CTSolvers.ADNLPModeler(opts)
        captured_ad_kwargs[] = nothing
        _ = modeler(prob, x0)
        kw = captured_ad_kwargs[]
        Test.@test kw !== nothing
        Test.@test kw[:alpha] == 1.0
        Test.@test kw[:beta] == 2
    end

    Test.@testset "ctmodels/nlp_backends: ExaModeler options forwarding" verbose=VERBOSE showtiming=SHOWTIMING begin
        prob = CMOptionsCaptureProbExa()
        BaseType = Float64
        x0 = [1.0, 2.0]
        opts = (
            :gamma => 3,
            :delta => 4,
        )
        modeler = CTSolvers.ExaModeler{BaseType}(opts)
        captured_exa_kwargs[] = nothing
        _ = modeler(prob, x0)
        kw = captured_exa_kwargs[]
        Test.@test kw !== nothing
        Test.@test kw[:gamma] == 3
        Test.@test kw[:delta] == 4
    end

end
