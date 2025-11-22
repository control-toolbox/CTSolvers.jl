function test_direct()

    # Preliminary
    ocp, init = beam()
    discretizer = CTSolvers.Collocation()
    docp = CTSolvers.discretize(ocp, discretizer)

    # options
    ipopt_options = Dict(
        :max_iter => 100,
        :tol => 1e-6,
        :print_level => 0,
        :mu_strategy => "adaptive",
        :linear_solver => "Mumps",
        :sb => "yes",
    )

    madnlp_options = Dict(:max_iter => 100, :tol => 1e-6, :print_level => MadNLP.ERROR)

    # Tests
    Test.@testset "Discretized problem and types" begin
        Test.@test docp isa CTSolvers.AbstractOptimizationProblem
        Test.@test docp isa CTSolvers.DiscretizedOptimalControlProblem
        Test.@test CTSolvers.get_adnlp_model_builder(docp) isa CTSolvers.ADNLPModelBuilder
        Test.@test CTSolvers.get_exa_model_builder(docp) isa CTSolvers.ExaModelBuilder
    end

    Test.@testset "NLP model" begin
        # ADNLPModels
        modeler = CTSolvers.ADNLPModeler(; backend=:manual)
        nlp_adnlp = CTSolvers.nlp_model(docp, init, modeler)
        Test.@test nlp_adnlp isa ADNLPModels.ADNLPModel
        nlp_adnlp = CTSolvers.build_model(docp, init, modeler)
        Test.@test nlp_adnlp isa ADNLPModels.ADNLPModel
        # ExaModels
        modeler = CTSolvers.ExaModeler()
        nlp_exa = CTSolvers.nlp_model(docp, init, modeler)
        Test.@test nlp_exa isa ExaModels.ExaModel
        nlp_exa = CTSolvers.build_model(docp, init, modeler)
        Test.@test nlp_exa isa ExaModels.ExaModel
    end

    Test.@testset "Solvers" begin
        # ADNLPModels + Ipopt
        modeler = CTSolvers.ADNLPModeler(; backend=:manual)
        solver = CTSolvers.IpoptSolver(; ipopt_options...)
        sol_adnlp = CommonSolve.solve(docp, init, modeler, solver)
        Test.@test sol_adnlp.status == :first_order

        # ADNLPModels + MadNLP
        modeler = CTSolvers.ADNLPModeler(; backend=:manual)
        solver = CTSolvers.MadNLPSolver(; madnlp_options...)
        sol_adnlp = CommonSolve.solve(docp, init, modeler, solver)
        Test.@test sol_adnlp.status == MadNLP.SOLVE_SUCCEEDED

        # ExaModels + Ipopt
        modeler = CTSolvers.ExaModeler()
        solver = CTSolvers.IpoptSolver(; ipopt_options...)
        sol_exa = CommonSolve.solve(docp, init, modeler, solver)
        Test.@test sol_exa.status == :first_order

        # ExaModels + MadNLP
        modeler = CTSolvers.ExaModeler()
        solver = CTSolvers.MadNLPSolver(; madnlp_options...)
        sol_exa = CommonSolve.solve(docp, init, modeler, solver)
        Test.@test sol_exa.status == MadNLP.SOLVE_SUCCEEDED
    end

end