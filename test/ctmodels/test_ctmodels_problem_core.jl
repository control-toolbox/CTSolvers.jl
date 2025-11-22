function test_ctmodels_problem_core()

    # Tests for problem-specific model builders provided by CTModels problems
    # (here the Rosenbrock problem exposes its own build_adnlp_model/build_exa_model).
    Test.@testset "ctmodels/problem_core: ADNLPModels – Rosenbrock (specific builder)" verbose=VERBOSE showtiming=SHOWTIMING begin
        nlp_adnlp = rosenbrock_prob.build_adnlp_model(rosenbrock_init; show_time=false)
        Test.@test nlp_adnlp isa ADNLPModels.ADNLPModel
        Test.@test nlp_adnlp.meta.x0 == rosenbrock_init
        Test.@test NLPModels.obj(nlp_adnlp, nlp_adnlp.meta.x0) == rosenbrock_objective(rosenbrock_init)
        Test.@test NLPModels.cons(nlp_adnlp, nlp_adnlp.meta.x0)[1] == rosenbrock_constraint(rosenbrock_init)
        Test.@test nlp_adnlp.meta.minimize == rosenbrock_is_minimize()
    end

    Test.@testset "ctmodels/problem_core: ExaModels (CPU) – Rosenbrock (specific builder, BaseType=Float32)" verbose=VERBOSE showtiming=SHOWTIMING begin
        BaseType = Float32
        nlp_exa_cpu = rosenbrock_prob.build_exa_model(BaseType, rosenbrock_init)
        Test.@test nlp_exa_cpu isa ExaModels.ExaModel{BaseType}
        Test.@test nlp_exa_cpu.meta.x0 == BaseType.(rosenbrock_init)
        Test.@test eltype(nlp_exa_cpu.meta.x0) == BaseType
        Test.@test NLPModels.obj(nlp_exa_cpu, nlp_exa_cpu.meta.x0) == rosenbrock_objective(BaseType.(rosenbrock_init))
        Test.@test NLPModels.cons(nlp_exa_cpu, nlp_exa_cpu.meta.x0)[1] == rosenbrock_constraint(BaseType.(rosenbrock_init))
        Test.@test nlp_exa_cpu.meta.minimize == rosenbrock_is_minimize()
    end

    # Tests for the generic ADNLPModelBuilder wrapper (higher-order function
    # that delegates to an arbitrary callable). Here we build a simple
    # ADNLPModel to respect the return type annotation ::ADNLPModels.ADNLPModel
    # and we verify that the inner builder is called exactly once with the
    # expected initial guess.
    Test.@testset "ctmodels/problem_core: ADNLPModelBuilder wrapper" verbose=VERBOSE showtiming=SHOWTIMING begin
        calls = Ref(0)
        last_x = Ref{Any}(nothing)
        function local_ad_builder(x; kwargs...)
            calls[] += 1
            last_x[] = x
            f(z) = sum(z .^ 2)
            return ADNLPModels.ADNLPModel(f, x)
        end

        builder = CTSolvers.ADNLPModelBuilder(local_ad_builder)
        x0 = rosenbrock_init
        nlp = builder(x0)  # no extra kwargs to keep ADNLPModel signature simple

        Test.@test nlp isa ADNLPModels.ADNLPModel
        Test.@test calls[] == 1
        Test.@test last_x[] == x0
    end

    # Tests for the generic ExaModelBuilder wrapper. Constructing a full
    # ExaModels.ExaModel instance in isolation is non-trivial, and the
    # call operator is annotated to return ::ExaModels.ExaModel. To avoid
    # fragile tests that depend on ExaModels internals, we limit ourselves
    # to checking that the wrapped callable is correctly stored inside
    # ExaModelBuilder.
    Test.@testset "ctmodels/problem_core: ExaModelBuilder wrapper" verbose=VERBOSE showtiming=SHOWTIMING begin
        function local_exa_builder(::Type{BaseType}, x; foo=1) where {BaseType}
            return (:exa_builder_called, BaseType, x, foo)
        end

        builder = CTSolvers.ExaModelBuilder(local_exa_builder)

        Test.@test builder.f === local_exa_builder
        Test.@test builder isa CTSolvers.ExaModelBuilder{typeof(local_exa_builder)}
    end

    # Tests for the type hierarchy (abstract base types and concrete subtypes).
    Test.@testset "ctmodels/problem_core: type hierarchy" verbose=VERBOSE showtiming=SHOWTIMING begin
        Test.@test isabstracttype(CTSolvers.AbstractModelBuilder)
        Test.@test isabstracttype(CTSolvers.AbstractCTHelper)
        Test.@test isabstracttype(CTSolvers.AbstractOptimizationProblem)

        Test.@test CTSolvers.ADNLPModelBuilder <: CTSolvers.AbstractModelBuilder
        Test.@test CTSolvers.ExaModelBuilder  <: CTSolvers.AbstractModelBuilder
    end

    # Tests for the generic "NotImplemented" behaviour of the get_* functions
    # when called on a problem type that has no specialized implementation.
    Test.@testset "ctmodels/problem_core: generic get_* NotImplemented" verbose=VERBOSE showtiming=SHOWTIMING begin
        dummy = DummyProblem()

        Test.@test_throws CTBase.NotImplemented CTSolvers.get_adnlp_model_builder(dummy)
        Test.@test_throws CTBase.NotImplemented CTSolvers.get_exa_model_builder(dummy)
        Test.@test_throws CTBase.NotImplemented CTSolvers.get_adnlp_solution_helper(dummy)
        Test.@test_throws CTBase.NotImplemented CTSolvers.get_exa_solution_helper(dummy)
    end

end
