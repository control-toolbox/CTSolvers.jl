function test_models()

    # use specific function from the problems to build models
    Test.@testset "Build models (specific)" verbose=VERBOSE showtiming=SHOWTIMING begin
        Test.@testset "ADNLPModels" verbose=VERBOSE showtiming=SHOWTIMING begin
            Test.@testset "Rosenbrock" verbose=VERBOSE showtiming=SHOWTIMING begin
                nlp_adnlp = rosenbrock_prob.build_adnlp_model(
                    rosenbrock_init; show_time=false
                )
                Test.@test nlp_adnlp isa ADNLPModels.ADNLPModel
                Test.@test nlp_adnlp.meta.x0 == rosenbrock_init
                Test.@test NLPModels.obj(nlp_adnlp, nlp_adnlp.meta.x0) ==
                    rosenbrock_objective(rosenbrock_init)
                Test.@test NLPModels.cons(nlp_adnlp, nlp_adnlp.meta.x0)[1] ==
                    rosenbrock_constraint(rosenbrock_init)
                Test.@test nlp_adnlp.meta.minimize == rosenbrock_is_minimize()
            end
        end
        Test.@testset "ExaModels (CPU)" verbose=VERBOSE showtiming=SHOWTIMING begin
            Test.@testset "Rosenbrock" verbose=VERBOSE showtiming=SHOWTIMING begin
                BaseType = Float32
                nlp_exa_cpu = rosenbrock_prob.build_exa_model(BaseType, rosenbrock_init)
                Test.@test nlp_exa_cpu isa ExaModels.ExaModel{BaseType}
                Test.@test nlp_exa_cpu.meta.x0 == BaseType.(rosenbrock_init)
                Test.@test eltype(nlp_exa_cpu.meta.x0) == BaseType
                Test.@test NLPModels.obj(nlp_exa_cpu, nlp_exa_cpu.meta.x0) ==
                    rosenbrock_objective(BaseType.(rosenbrock_init))
                Test.@test NLPModels.cons(nlp_exa_cpu, nlp_exa_cpu.meta.x0)[1] ==
                    rosenbrock_constraint(BaseType.(rosenbrock_init))
                Test.@test nlp_exa_cpu.meta.minimize == rosenbrock_is_minimize()
            end
        end
    end

    # use generic function to build models
    Test.@testset "Build models (generic)" verbose=VERBOSE showtiming=SHOWTIMING begin
        Test.@testset "ADNLPModels" verbose=VERBOSE showtiming=SHOWTIMING begin
            Test.@testset "Rosenbrock" verbose=VERBOSE showtiming=SHOWTIMING begin
                nlp_adnlp = CTSolvers.build_model(
                    rosenbrock_prob,
                    rosenbrock_init,
                    CTSolvers.ADNLPModelBackend(; backend=:manual),
                )
                Test.@test nlp_adnlp isa ADNLPModels.ADNLPModel
                Test.@test nlp_adnlp.meta.x0 == rosenbrock_init
                Test.@test NLPModels.obj(nlp_adnlp, nlp_adnlp.meta.x0) ==
                    rosenbrock_objective(rosenbrock_init)
                Test.@test NLPModels.cons(nlp_adnlp, nlp_adnlp.meta.x0)[1] ==
                    rosenbrock_constraint(rosenbrock_init)
                Test.@test nlp_adnlp.meta.minimize == rosenbrock_is_minimize()
                ad_backends = ADNLPModels.get_adbackend(nlp_adnlp)
                Test.@test ad_backends.gradient_backend isa
                    ADNLPModels.ReverseDiffADGradient
                Test.@test ad_backends.jacobian_backend isa ADNLPModels.SparseADJacobian
                Test.@test ad_backends.hessian_backend isa
                    ADNLPModels.SparseReverseADHessian
                Test.@test ad_backends.jtprod_backend isa ADNLPModels.EmptyADbackend
                Test.@test ad_backends.jprod_backend isa ADNLPModels.EmptyADbackend
                Test.@test ad_backends.ghjvprod_backend isa ADNLPModels.EmptyADbackend
                Test.@test ad_backends.hprod_backend isa ADNLPModels.EmptyADbackend
            end
        end
        Test.@testset "ExaModels (CPU)" verbose=VERBOSE showtiming=SHOWTIMING begin
            Test.@testset "Rosenbrock" verbose=VERBOSE showtiming=SHOWTIMING begin
                BaseType = Float32
                nlp_exa_cpu = CTSolvers.build_model(
                    rosenbrock_prob,
                    rosenbrock_init,
                    CTSolvers.ExaModelBackend(; base_type=BaseType),
                )
                Test.@test nlp_exa_cpu isa ExaModels.ExaModel{BaseType}
                Test.@test nlp_exa_cpu.meta.x0 == BaseType.(rosenbrock_init)
                Test.@test eltype(nlp_exa_cpu.meta.x0) == BaseType
                Test.@test NLPModels.obj(nlp_exa_cpu, nlp_exa_cpu.meta.x0) ==
                    rosenbrock_objective(BaseType.(rosenbrock_init))
                Test.@test NLPModels.cons(nlp_exa_cpu, nlp_exa_cpu.meta.x0)[1] ==
                    rosenbrock_constraint(BaseType.(rosenbrock_init))
                Test.@test nlp_exa_cpu.meta.minimize == rosenbrock_is_minimize()
            end
        end
    end
end
