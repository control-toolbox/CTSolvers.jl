function test_ctmodels_nlp_backends()

    # ADNLPModels
    Test.@testset "ctmodels/nlp_backends: ADNLPModels – Rosenbrock (generic nlp_model, backend=:manual)" verbose=VERBOSE showtiming=SHOWTIMING begin
        nlp_adnlp = CTSolvers.nlp_model(
            rosenbrock_prob,
            rosenbrock_init,
            CTSolvers.ADNLPModelBackend(; backend=:manual),
        )
        Test.@test nlp_adnlp isa ADNLPModels.ADNLPModel
        Test.@test nlp_adnlp.meta.x0 == rosenbrock_init
        Test.@test NLPModels.obj(nlp_adnlp, nlp_adnlp.meta.x0) == rosenbrock_objective(rosenbrock_init)
        Test.@test NLPModels.cons(nlp_adnlp, nlp_adnlp.meta.x0)[1] == rosenbrock_constraint(rosenbrock_init)
        Test.@test nlp_adnlp.meta.minimize == rosenbrock_is_minimize()

        # Automatic Differentiation backends
        ad_backends = ADNLPModels.get_adbackend(nlp_adnlp)
        Test.@test ad_backends.gradient_backend isa ADNLPModels.ReverseDiffADGradient
        Test.@test ad_backends.jacobian_backend isa ADNLPModels.SparseADJacobian
        Test.@test ad_backends.hessian_backend isa ADNLPModels.SparseReverseADHessian
        Test.@test ad_backends.jtprod_backend isa ADNLPModels.EmptyADbackend
        Test.@test ad_backends.jprod_backend isa ADNLPModels.EmptyADbackend
        Test.@test ad_backends.ghjvprod_backend isa ADNLPModels.EmptyADbackend
        Test.@test ad_backends.hprod_backend isa ADNLPModels.EmptyADbackend
    end

    Test.@testset "ctmodels/nlp_backends: ADNLPModels – Elec (generic nlp_model, backend=:manual)" begin
        nlp_adnlp = CTSolvers.nlp_model(
            elec_prob, elec_init, CTSolvers.ADNLPModelBackend(; backend=:manual)
        )
        Test.@test nlp_adnlp isa ADNLPModels.ADNLPModel
        Test.@test nlp_adnlp.meta.x0 == vcat(elec_init.x, elec_init.y, elec_init.z)
        Test.@test NLPModels.obj(nlp_adnlp, nlp_adnlp.meta.x0) == elec_objective(elec_init.x, elec_init.y, elec_init.z)
        Test.@test NLPModels.cons(nlp_adnlp, nlp_adnlp.meta.x0) == elec_constraint(elec_init.x, elec_init.y, elec_init.z)
        Test.@test nlp_adnlp.meta.minimize == elec_is_minimize()
    end

    Test.@testset "ctmodels/nlp_backends: ADNLPModels – DummyProblem (NotImplemented)" verbose=VERBOSE showtiming=SHOWTIMING begin
        Test.@test_throws CTBase.NotImplemented CTSolvers.nlp_model(
            DummyProblem(),
            rosenbrock_init,
            CTSolvers.ADNLPModelBackend(; backend=:manual),
        )
    end

    # ExaModels (CPU)
    Test.@testset "ctmodels/nlp_backends: ExaModels (CPU) – Rosenbrock (generic nlp_model, BaseType=Float32)" verbose=VERBOSE showtiming=SHOWTIMING begin
        BaseType = Float32
        nlp_exa_cpu = CTSolvers.nlp_model(
            rosenbrock_prob,
            rosenbrock_init,
            CTSolvers.ExaModelBackend(; base_type=BaseType),
        )
        Test.@test nlp_exa_cpu isa ExaModels.ExaModel{BaseType}
        Test.@test nlp_exa_cpu.meta.x0 == BaseType.(rosenbrock_init)
        Test.@test eltype(nlp_exa_cpu.meta.x0) == BaseType
        Test.@test NLPModels.obj(nlp_exa_cpu, nlp_exa_cpu.meta.x0) == rosenbrock_objective(BaseType.(rosenbrock_init))
        Test.@test NLPModels.cons(nlp_exa_cpu, nlp_exa_cpu.meta.x0)[1] == rosenbrock_constraint(BaseType.(rosenbrock_init))
        Test.@test nlp_exa_cpu.meta.minimize == rosenbrock_is_minimize()
    end

    Test.@testset "ctmodels/nlp_backends: ExaModels (CPU) – Elec (generic nlp_model, BaseType=Float32)" begin
        BaseType = Float32
        nlp_exa_cpu = CTSolvers.nlp_model(
            elec_prob, elec_init, CTSolvers.ExaModelBackend(; base_type=BaseType)
        )
        Test.@test nlp_exa_cpu isa ExaModels.ExaModel{BaseType}
        Test.@test nlp_exa_cpu.meta.x0 == BaseType.(vcat(elec_init.x, elec_init.y, elec_init.z))
        Test.@test eltype(nlp_exa_cpu.meta.x0) == BaseType
        Test.@test NLPModels.obj(nlp_exa_cpu, nlp_exa_cpu.meta.x0) == elec_objective(BaseType.(elec_init.x), BaseType.(elec_init.y), BaseType.(elec_init.z))
        Test.@test NLPModels.cons(nlp_exa_cpu, nlp_exa_cpu.meta.x0) == elec_constraint(BaseType.(elec_init.x), BaseType.(elec_init.y), BaseType.(elec_init.z))
        Test.@test nlp_exa_cpu.meta.minimize == elec_is_minimize()
    end

    Test.@testset "ctmodels/nlp_backends: ExaModels (CPU) – DummyProblem (NotImplemented)" verbose=VERBOSE showtiming=SHOWTIMING begin
        Test.@test_throws CTBase.NotImplemented CTSolvers.nlp_model(
            DummyProblem(), rosenbrock_init, CTSolvers.ExaModelBackend()
        )
    end

end
