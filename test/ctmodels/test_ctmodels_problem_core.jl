function test_ctmodels_problem_core()

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

end
