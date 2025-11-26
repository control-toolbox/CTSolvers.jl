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
    Test.@testset "ctmodels/nlp_backends: ADNLPModels – Rosenbrock (direct call)" verbose=VERBOSE showtiming=SHOWTIMING begin
        modeler = CTSolvers.ADNLPModeler()
        nlp_adnlp = modeler(rosenbrock_prob, rosenbrock_init)
        Test.@test nlp_adnlp isa ADNLPModels.ADNLPModel
        Test.@test nlp_adnlp.meta.x0 == rosenbrock_init
        Test.@test NLPModels.obj(nlp_adnlp, nlp_adnlp.meta.x0) == rosenbrock_objective(rosenbrock_init)
        Test.@test NLPModels.cons(nlp_adnlp, nlp_adnlp.meta.x0)[1] == rosenbrock_constraint(rosenbrock_init)
        Test.@test nlp_adnlp.meta.minimize == rosenbrock_is_minimize()
    end

    # Different CTModels problem (Elec),
    # still calling the backend directly.
    Test.@testset "ctmodels/nlp_backends: ADNLPModels – Elec (direct call)" verbose=VERBOSE showtiming=SHOWTIMING begin
        modeler = CTSolvers.ADNLPModeler()
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
        modeler = CTSolvers.ADNLPModeler()
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
    # These tests now focus on the options_values / options_sources
    # NamedTuples exposed via _options / _option_sources.

    Test.@testset "ctmodels/nlp_backends: ADNLPModeler constructor" verbose=VERBOSE showtiming=SHOWTIMING begin
        # Default constructor should use the values from ctmodels/default.jl
        backend_default = CTSolvers.ADNLPModeler()
        vals_default = CTSolvers._options(backend_default)
        srcs_default = CTSolvers._option_sources(backend_default)

        Test.@test vals_default.show_time == CTSolvers.__adnlp_model_show_time()
        Test.@test vals_default.backend    == CTSolvers.__adnlp_model_backend()
        Test.@test all(srcs_default[k] == :ct_default for k in propertynames(srcs_default))

        # Custom backend and extra kwargs should be stored with provenance
        backend_manual = CTSolvers.ADNLPModeler(; backend=:toto, foo=1)
        vals_manual = CTSolvers._options(backend_manual)
        srcs_manual = CTSolvers._option_sources(backend_manual)

        Test.@test vals_manual.backend == :toto
        Test.@test srcs_manual.backend == :user
        Test.@test vals_manual.foo == 1
        Test.@test srcs_manual.foo == :user
    end

    Test.@testset "ctmodels/nlp_backends: ExaModeler constructor" verbose=VERBOSE showtiming=SHOWTIMING begin
        # Default constructor should use base_type and backend from ctmodels/default.jl
        exa_default = CTSolvers.ExaModeler()
        vals_default = CTSolvers._options(exa_default)
        srcs_default = CTSolvers._option_sources(exa_default)

        Test.@test vals_default.backend === CTSolvers.__exa_model_backend()
        Test.@test srcs_default.backend == :ct_default

        # Custom base_type and kwargs should be stored correctly with provenance
        exa_custom = CTSolvers.ExaModeler(; base_type=Float32, foo=2)
        vals_custom = CTSolvers._options(exa_custom)
        srcs_custom = CTSolvers._option_sources(exa_custom)

        Test.@test vals_custom.base_type === Float32
        Test.@test srcs_custom.base_type == :user
        Test.@test vals_custom.backend === CTSolvers.__exa_model_backend()
        Test.@test srcs_custom.backend == :ct_default
        Test.@test vals_custom.foo == 2
        Test.@test srcs_custom.foo == :user
    end

    # ------------------------------------------------------------------
    # Options metadata and validation helpers for ADNLPModeler/ExaModeler
    # ------------------------------------------------------------------

    Test.@testset "ctmodels/nlp_backends: ADNLPModeler options metadata and validation" verbose=VERBOSE showtiming=SHOWTIMING begin
        keys_ad = CTSolvers.options_keys(CTSolvers.ADNLPModeler)
        Test.@test :show_time in keys_ad
        Test.@test :backend   in keys_ad

        Test.@test CTSolvers.option_type(:show_time, CTSolvers.ADNLPModeler) == Bool
        Test.@test CTSolvers.option_type(:backend,   CTSolvers.ADNLPModeler) == Symbol

        desc_backend = CTSolvers.option_description(:backend, CTSolvers.ADNLPModeler)
        Test.@test desc_backend isa AbstractString
        Test.@test !isempty(desc_backend)

        # Invalid type for a known option should trigger a CTBase.IncorrectArgument
        Test.@test_throws CTBase.IncorrectArgument CTSolvers.ADNLPModeler(; show_time="yes")
    end

    Test.@testset "ctmodels/nlp_backends: ExaModeler options metadata and validation" verbose=VERBOSE showtiming=SHOWTIMING begin
        keys_exa = CTSolvers.options_keys(CTSolvers.ExaModeler)
        Test.@test :base_type in keys_exa
        Test.@test :backend   in keys_exa
        Test.@test :minimize  in keys_exa

        Test.@test CTSolvers.option_type(:base_type, CTSolvers.ExaModeler) <: Type{<:AbstractFloat}
        Test.@test CTSolvers.option_type(:minimize,  CTSolvers.ExaModeler) == Bool

        # Invalid type for a known option should trigger a CTBase.IncorrectArgument
        Test.@test_throws CTBase.IncorrectArgument CTSolvers.ExaModeler(; minimize=1)
    end

    Test.@testset "ctmodels/nlp_backends: modeler symbols and registry" verbose=VERBOSE showtiming=SHOWTIMING begin
        # get_symbol on types and instances
        Test.@test CTSolvers.get_symbol(CTSolvers.ADNLPModeler) == :adnlp
        Test.@test CTSolvers.get_symbol(CTSolvers.ExaModeler)   == :exa
        Test.@test CTSolvers.get_symbol(CTSolvers.ADNLPModeler()) == :adnlp
        Test.@test CTSolvers.get_symbol(CTSolvers.ExaModeler())   == :exa

        # tool_package_name on types and instances
        Test.@test CTSolvers.tool_package_name(CTSolvers.ADNLPModeler) == "ADNLPModels"
        Test.@test CTSolvers.tool_package_name(CTSolvers.ExaModeler)   == "ExaModels"
        Test.@test CTSolvers.tool_package_name(CTSolvers.ADNLPModeler()) == "ADNLPModels"
        Test.@test CTSolvers.tool_package_name(CTSolvers.ExaModeler())   == "ExaModels"

        regs = CTSolvers.registered_modeler_types()
        Test.@test CTSolvers.ADNLPModeler in regs
        Test.@test CTSolvers.ExaModeler in regs

        syms = CTSolvers.modeler_symbols()
        Test.@test :adnlp in syms
        Test.@test :exa   in syms

        # build_modeler_from_symbol should construct proper concrete modelers.
        m_ad = CTSolvers.build_modeler_from_symbol(:adnlp; backend=:manual)
        Test.@test m_ad isa CTSolvers.ADNLPModeler
        vals_ad = CTSolvers._options(m_ad)
        Test.@test vals_ad.backend == :manual

        m_exa = CTSolvers.build_modeler_from_symbol(:exa; base_type=Float32)
        Test.@test m_exa isa CTSolvers.ExaModeler
        vals_exa = CTSolvers._options(m_exa)
        Test.@test vals_exa.base_type === Float32
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
