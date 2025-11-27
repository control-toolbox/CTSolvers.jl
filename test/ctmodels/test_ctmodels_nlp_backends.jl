# Unit tests for NLP backends (ADNLPModels and ExaModels) used by CTModels problems.
struct CM_DummyBackendStats <: SolverCore.AbstractExecutionStats end

struct CM_DummyModelerMissing <: CTSolvers.AbstractOptimizationModeler end

function test_ctmodels_nlp_backends()

    # ========================================================================
    # Problems
    # ========================================================================
    ros = Rosenbrock()
    elec = Elec()
    maxd = Max1MinusX2()

    # ------------------------------------------------------------------
    # Low-level defaults for ADNLPModeler / ExaModeler
    # ------------------------------------------------------------------
    Test.@testset "raw defaults" verbose=VERBOSE showtiming=SHOWTIMING begin
        # ADNLPModels defaults
        Test.@test CTSolvers.__adnlp_model_show_time() isa Bool
        Test.@test CTSolvers.__adnlp_model_backend() isa Symbol

        Test.@test CTSolvers.__adnlp_model_show_time() == false
        Test.@test CTSolvers.__adnlp_model_backend() == :optimized

        # ExaModels defaults
        Test.@test CTSolvers.__exa_model_base_type() isa DataType
        Test.@test CTSolvers.__exa_model_backend() isa Union{Nothing,Symbol}

        Test.@test CTSolvers.__exa_model_base_type() === Float64
        Test.@test CTSolvers.__exa_model_backend() === nothing
    end

    # ------------------------------------------------------------------
    # ADNLPModels backends (direct calls to ADNLPModeler)
    # ------------------------------------------------------------------
    # These tests exercise the call
    #   (modeler::ADNLPModeler)(prob, initial_guess)
    # directly, without going through the generic model API. We verify
    # that the resulting ADNLPModel has the correct initial point,
    # objective, constraints, and that the AD backends are configured as
    # expected when using the manual backend path.
    Test.@testset "ADNLPModels – Rosenbrock (direct call)" verbose=VERBOSE showtiming=SHOWTIMING begin
        modeler = CTSolvers.ADNLPModeler()
        nlp_adnlp = modeler(ros.prob, ros.init)
        Test.@test nlp_adnlp isa ADNLPModels.ADNLPModel
        Test.@test nlp_adnlp.meta.x0 == ros.init
        Test.@test NLPModels.obj(nlp_adnlp, nlp_adnlp.meta.x0) == rosenbrock_objective(ros.init)
        Test.@test NLPModels.cons(nlp_adnlp, nlp_adnlp.meta.x0)[1] == rosenbrock_constraint(ros.init)
        Test.@test nlp_adnlp.meta.minimize == rosenbrock_is_minimize()
    end

    # Different CTModels problem (Elec),
    # still calling the backend directly.
    Test.@testset "ADNLPModels – Elec (direct call)" verbose=VERBOSE showtiming=SHOWTIMING begin
        modeler = CTSolvers.ADNLPModeler()
        nlp_adnlp = modeler(elec.prob, elec.init)
        Test.@test nlp_adnlp isa ADNLPModels.ADNLPModel
        Test.@test nlp_adnlp.meta.x0 == vcat(elec.init.x, elec.init.y, elec.init.z)
        Test.@test NLPModels.obj(nlp_adnlp, nlp_adnlp.meta.x0) == elec_objective(elec.init.x, elec.init.y, elec.init.z)
        Test.@test NLPModels.cons(nlp_adnlp, nlp_adnlp.meta.x0) == elec_constraint(elec.init.x, elec.init.y, elec.init.z)
        Test.@test nlp_adnlp.meta.minimize == elec_is_minimize()
    end

    # 1D maximization problem: Max1MinusX2
    Test.@testset "ADNLPModels – Max1MinusX2 (direct call)" verbose=VERBOSE showtiming=SHOWTIMING begin
        modeler = CTSolvers.ADNLPModeler()
        nlp_adnlp = modeler(maxd.prob, maxd.init)
        Test.@test nlp_adnlp isa ADNLPModels.ADNLPModel
        Test.@test nlp_adnlp.meta.x0 == maxd.init
        Test.@test NLPModels.obj(nlp_adnlp, nlp_adnlp.meta.x0) == max1minusx2_objective(maxd.init)
        Test.@test NLPModels.cons(nlp_adnlp, nlp_adnlp.meta.x0)[1] == max1minusx2_constraint(maxd.init)
        Test.@test nlp_adnlp.meta.minimize == max1minusx2_is_minimize()
    end

    # For a problem without specialized get_* methods, ADNLPModeler
    # should surface the generic NotImplemented error from get_adnlp_model_builder
    # even when called directly.
    Test.@testset "ADNLPModels – DummyProblem (NotImplemented, direct call)" verbose=VERBOSE showtiming=SHOWTIMING begin
        modeler = CTSolvers.ADNLPModeler()
        Test.@test_throws CTBase.NotImplemented modeler(DummyProblem(), ros.init)
    end

    # ------------------------------------------------------------------
    # ExaModels backends (direct calls to ExaModeler, CPU)
    # ------------------------------------------------------------------
    # These tests exercise the call
    #   (modeler::ExaModeler)(prob, initial_guess)
    # directly, using a concrete BaseType (Float32).
    Test.@testset "ExaModels (CPU) – Rosenbrock (BaseType=Float32, direct call)" verbose=VERBOSE showtiming=SHOWTIMING begin
        BaseType = Float32
        modeler = CTSolvers.ExaModeler(; base_type=BaseType)
        nlp_exa_cpu = modeler(ros.prob, ros.init)
        Test.@test nlp_exa_cpu isa ExaModels.ExaModel{BaseType}
        Test.@test nlp_exa_cpu.meta.x0 == BaseType.(ros.init)
        Test.@test eltype(nlp_exa_cpu.meta.x0) == BaseType
        Test.@test NLPModels.obj(nlp_exa_cpu, nlp_exa_cpu.meta.x0) == rosenbrock_objective(BaseType.(ros.init))
        Test.@test NLPModels.cons(nlp_exa_cpu, nlp_exa_cpu.meta.x0)[1] == rosenbrock_constraint(BaseType.(ros.init))
        Test.@test nlp_exa_cpu.meta.minimize == rosenbrock_is_minimize()
    end

    # Same ExaModels backend but on the Elec problem, with direct backend call.
    Test.@testset "ExaModels (CPU) – Elec (BaseType=Float32, direct call)" begin
        BaseType = Float32
        modeler = CTSolvers.ExaModeler(; base_type=BaseType)
        nlp_exa_cpu = modeler(elec.prob, elec.init)
        Test.@test nlp_exa_cpu isa ExaModels.ExaModel{BaseType}
        Test.@test nlp_exa_cpu.meta.x0 == BaseType.(vcat(elec.init.x, elec.init.y, elec.init.z))
        Test.@test eltype(nlp_exa_cpu.meta.x0) == BaseType
        Test.@test NLPModels.obj(nlp_exa_cpu, nlp_exa_cpu.meta.x0) == elec_objective(BaseType.(elec.init.x), BaseType.(elec.init.y), BaseType.(elec.init.z))
        Test.@test NLPModels.cons(nlp_exa_cpu, nlp_exa_cpu.meta.x0) == elec_constraint(BaseType.(elec.init.x), BaseType.(elec.init.y), BaseType.(elec.init.z))
        Test.@test nlp_exa_cpu.meta.minimize == elec_is_minimize()
    end

    Test.@testset "ExaModels (CPU) – Max1MinusX2 (BaseType=Float32, direct call)" verbose=VERBOSE showtiming=SHOWTIMING begin
        BaseType = Float32
        modeler = CTSolvers.ExaModeler(; base_type=BaseType)
        nlp_exa_cpu = modeler(maxd.prob, maxd.init)
        Test.@test nlp_exa_cpu isa ExaModels.ExaModel{BaseType}
        Test.@test nlp_exa_cpu.meta.x0 == BaseType.(maxd.init)
        Test.@test eltype(nlp_exa_cpu.meta.x0) == BaseType
        Test.@test NLPModels.obj(nlp_exa_cpu, nlp_exa_cpu.meta.x0) == max1minusx2_objective(BaseType.(maxd.init))
        Test.@test NLPModels.cons(nlp_exa_cpu, nlp_exa_cpu.meta.x0)[1] == max1minusx2_constraint(BaseType.(maxd.init))
        Test.@test nlp_exa_cpu.meta.minimize == max1minusx2_is_minimize()
    end

    # For a problem without specialized get_* methods, ExaModeler
    # should surface the generic NotImplemented error from get_exa_model_builder
    # even when called directly.
    Test.@testset "ExaModels (CPU) – DummyProblem (NotImplemented, direct call)" verbose=VERBOSE showtiming=SHOWTIMING begin
        modeler = CTSolvers.ExaModeler()
        Test.@test_throws CTBase.NotImplemented modeler(DummyProblem(), ros.init)
    end

    # ------------------------------------------------------------------
    # Constructor-level tests for ADNLPModeler and ExaModeler
    # ------------------------------------------------------------------
    # These tests now focus on the options_values / options_sources
    # NamedTuples exposed via _options / _option_sources.

    Test.@testset "ADNLPModeler constructor" verbose=VERBOSE showtiming=SHOWTIMING begin
        # Default constructor should use the values from ctmodels/default.jl
        backend_default = CTSolvers.ADNLPModeler()
        vals_default = CTSolvers._options_values(backend_default)
        srcs_default = CTSolvers._option_sources(backend_default)

        Test.@test vals_default.show_time == CTSolvers.__adnlp_model_show_time()
        Test.@test vals_default.backend    == CTSolvers.__adnlp_model_backend()
        Test.@test all(srcs_default[k] == :ct_default for k in propertynames(srcs_default))

        # Custom backend and extra kwargs should be stored with provenance
        backend_manual = CTSolvers.ADNLPModeler(; backend=:toto, foo=1)
        vals_manual = CTSolvers._options_values(backend_manual)
        srcs_manual = CTSolvers._option_sources(backend_manual)

        Test.@test vals_manual.backend == :toto
        Test.@test srcs_manual.backend == :user
        Test.@test vals_manual.foo == 1
        Test.@test srcs_manual.foo == :user
    end

    Test.@testset "ExaModeler constructor" verbose=VERBOSE showtiming=SHOWTIMING begin
        # Default constructor should use backend from ctmodels/default.jl
        exa_default = CTSolvers.ExaModeler()
        vals_default = CTSolvers._options_values(exa_default)
        srcs_default = CTSolvers._option_sources(exa_default)

        Test.@test vals_default.backend === CTSolvers.__exa_model_backend()
        Test.@test srcs_default.backend == :ct_default

        # Custom base_type and kwargs: base_type is reflected in the modeler type,
        # while remaining options and their provenance are tracked as usual.
        exa_custom = CTSolvers.ExaModeler(; base_type=Float32)
        vals_custom = CTSolvers._options_values(exa_custom)
        srcs_custom = CTSolvers._option_sources(exa_custom)

        Test.@test exa_custom isa CTSolvers.ExaModeler{Float32}
        Test.@test vals_custom.backend === CTSolvers.__exa_model_backend()
        Test.@test srcs_custom.backend == :ct_default

        # Unknown options should now be rejected for ExaModeler (strict_keys=true).
        err = nothing
        try
            CTSolvers.ExaModeler(; base_type=Float32, foo=2)
        catch e
            err = e
        end
        Test.@test err isa CTBase.IncorrectArgument
        buf = sprint(showerror, err)
        Test.@test occursin("Unknown option foo", buf)
        Test.@test occursin("show_options(ExaModeler)", buf)
    end

    # ------------------------------------------------------------------
    # Options metadata and validation helpers for ADNLPModeler/ExaModeler
    # ------------------------------------------------------------------

    Test.@testset "ADNLPModeler options metadata and validation" verbose=VERBOSE showtiming=SHOWTIMING begin
        keys_ad = CTSolvers.options_keys(CTSolvers.ADNLPModeler)
        Test.@test :show_time in keys_ad
        Test.@test :backend   in keys_ad

        ad_backend = CTSolvers.ADNLPModeler()
        ad_type_from_instance = typeof(ad_backend)

        keys_ad_inst = CTSolvers.options_keys(ad_type_from_instance)
        Test.@test Set(keys_ad_inst) == Set(keys_ad)

        Test.@test CTSolvers.option_type(:show_time, CTSolvers.ADNLPModeler) == Bool
        Test.@test CTSolvers.option_type(:backend,   CTSolvers.ADNLPModeler) == Symbol

        Test.@test CTSolvers.option_type(:show_time, ad_type_from_instance) == Bool
        Test.@test CTSolvers.option_type(:backend,   ad_type_from_instance) == Symbol

        desc_backend = CTSolvers.option_description(:backend, CTSolvers.ADNLPModeler)
        Test.@test desc_backend isa AbstractString
        Test.@test !isempty(desc_backend)

        desc_backend_inst = CTSolvers.option_description(:backend, ad_type_from_instance)
        Test.@test desc_backend_inst isa AbstractString
        Test.@test !isempty(desc_backend_inst)

        # Invalid type for a known option should trigger a CTBase.IncorrectArgument
        Test.@test_throws CTBase.IncorrectArgument CTSolvers.ADNLPModeler(; show_time="yes")
    end

    Test.@testset "ExaModeler options metadata and validation" verbose=VERBOSE showtiming=SHOWTIMING begin
        keys_exa = CTSolvers.options_keys(CTSolvers.ExaModeler)
        Test.@test :base_type in keys_exa
        Test.@test :backend   in keys_exa
        Test.@test :minimize  in keys_exa

        exa_backend = CTSolvers.ExaModeler()
        exa_type_from_instance = typeof(exa_backend)

        keys_exa_inst = CTSolvers.options_keys(exa_type_from_instance)
        Test.@test Set(keys_exa_inst) == Set(keys_exa)

        Test.@test CTSolvers.option_type(:base_type, CTSolvers.ExaModeler) <: Type{<:AbstractFloat}
        Test.@test CTSolvers.option_type(:minimize,  CTSolvers.ExaModeler) == Bool

        Test.@test CTSolvers.option_type(:base_type, exa_type_from_instance) <: Type{<:AbstractFloat}
        Test.@test CTSolvers.option_type(:minimize,  exa_type_from_instance) == Bool

        # Invalid type for a known option should trigger a CTBase.IncorrectArgument
        Test.@test_throws CTBase.IncorrectArgument CTSolvers.ExaModeler(; minimize=1)
    end

    Test.@testset "ExaModeler unknown option suggestions" verbose=VERBOSE showtiming=SHOWTIMING begin
        err = nothing
        try
            CTSolvers._validate_option_kwargs((minimise=true,), CTSolvers.ExaModeler; strict_keys=true)
        catch e
            err = e
        end
        Test.@test err isa CTBase.IncorrectArgument
        buf = sprint(showerror, err)
        Test.@test occursin("Unknown option minimise", buf)
        Test.@test occursin("minimize", buf)
        Test.@test occursin("show_options(ExaModeler)", buf)
    end

    Test.@testset "default_options and option_default" verbose=VERBOSE showtiming=SHOWTIMING begin
        # ADNLPModeler defaults should be consistent between helpers and metadata.
        opts_ad = CTSolvers.default_options(CTSolvers.ADNLPModeler)
        Test.@test opts_ad.show_time == CTSolvers.__adnlp_model_show_time()
        Test.@test opts_ad.backend   == CTSolvers.__adnlp_model_backend()

        ad_backend = CTSolvers.ADNLPModeler()
        ad_type_from_instance = typeof(ad_backend)

        opts_ad_inst = CTSolvers.default_options(ad_type_from_instance)
        Test.@test opts_ad_inst == opts_ad

        Test.@test CTSolvers.option_default(:show_time, CTSolvers.ADNLPModeler) == CTSolvers.__adnlp_model_show_time()
        Test.@test CTSolvers.option_default(:backend,   CTSolvers.ADNLPModeler) == CTSolvers.__adnlp_model_backend()

        Test.@test CTSolvers.option_default(:show_time, ad_type_from_instance) == CTSolvers.__adnlp_model_show_time()
        Test.@test CTSolvers.option_default(:backend,   ad_type_from_instance) == CTSolvers.__adnlp_model_backend()

        # ExaModeler defaults: base_type and backend have defaults, minimize has none.
        opts_exa = CTSolvers.default_options(CTSolvers.ExaModeler)
        Test.@test opts_exa.base_type === CTSolvers.__exa_model_base_type()
        Test.@test opts_exa.backend   === CTSolvers.__exa_model_backend()
        Test.@test :minimize ∉ propertynames(opts_exa)

        exa_backend = CTSolvers.ExaModeler()
        exa_type_from_instance = typeof(exa_backend)

        opts_exa_inst = CTSolvers.default_options(exa_type_from_instance)
        Test.@test opts_exa_inst == opts_exa

        Test.@test CTSolvers.option_default(:base_type, CTSolvers.ExaModeler) === CTSolvers.__exa_model_base_type()
        Test.@test CTSolvers.option_default(:backend,   CTSolvers.ExaModeler) === CTSolvers.__exa_model_backend()
        Test.@test CTSolvers.option_default(:minimize,  CTSolvers.ExaModeler) === missing

        Test.@test CTSolvers.option_default(:base_type, exa_type_from_instance) === CTSolvers.__exa_model_base_type()
        Test.@test CTSolvers.option_default(:backend,   exa_type_from_instance) === CTSolvers.__exa_model_backend()
        Test.@test CTSolvers.option_default(:minimize,  exa_type_from_instance) === missing
    end

    Test.@testset "modeler symbols and registry" verbose=VERBOSE showtiming=SHOWTIMING begin
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
        vals_ad = CTSolvers._options_values(m_ad)
        Test.@test vals_ad.backend == :manual

        m_exa = CTSolvers.build_modeler_from_symbol(:exa; base_type=Float32)
        Test.@test m_exa isa CTSolvers.ExaModeler{Float32}
    end

    Test.@testset "build_modeler_from_symbol unknown symbol" verbose=VERBOSE showtiming=SHOWTIMING begin
        err = nothing
        try
            CTSolvers.build_modeler_from_symbol(:foo)
        catch e
            err = e
        end
        Test.@test err isa CTBase.IncorrectArgument

        buf = sprint(showerror, err)
        Test.@test occursin("Unknown NLP model symbol", buf)
        Test.@test occursin("foo", buf)
        # The message should list the supported symbols from modeler_symbols().
        for sym in CTSolvers.modeler_symbols()
            Test.@test occursin(string(sym), buf)
        end
    end

    Test.@testset "tool_package_name default implementation" verbose=VERBOSE showtiming=SHOWTIMING begin
        # For types without specialization, tool_package_name should return missing.
        dummy = CM_DummyModelerMissing()
        Test.@test CTSolvers.tool_package_name(CM_DummyModelerMissing) === missing
        Test.@test CTSolvers.tool_package_name(dummy) === missing
    end

    # ------------------------------------------------------------------
    # Solution-building via ADNLPModeler/ExaModeler(prob, nlp_solution)
    # ------------------------------------------------------------------
    # For OptimizationProblem (defined in test/problems/problems_definition.jl),
    # get_adnlp_solution_builder and get_exa_solution_builder return custom
    # solution builders (ADNLPSolutionBuilder, ExaSolutionBuilder) that are
    # callable on the nlp_solution and simply return it unchanged. Here we
    # verify that the backends correctly route through those builders.

    Test.@testset "ADNLPModeler solution building" verbose=VERBOSE showtiming=SHOWTIMING begin
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

        stats = CM_DummyBackendStats()
        modeler = CTSolvers.ADNLPModeler()
        # Should call get_adnlp_solution_builder(prob) and then
        # builder(stats), which is implemented in problems_definition.jl
        # to return stats unchanged.
        result = modeler(prob, stats)
        Test.@test result === stats
    end

    Test.@testset "ExaModeler solution building" verbose=VERBOSE showtiming=SHOWTIMING begin
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

        stats = CM_DummyBackendStats()
        modeler = CTSolvers.ExaModeler()
        # Should call get_exa_solution_builder(prob) and then
        # builder(stats), which returns stats.
        result = modeler(prob, stats)
        Test.@test result === stats
    end

end

