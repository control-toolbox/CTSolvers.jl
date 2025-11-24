struct DummyOCPCollocation <: CTSolvers.AbstractOptimalControlProblem end

function test_ctdirect_collocation_impl()

    Test.@testset "ctdirect/collocation_impl: Collocation as discretizer" verbose=VERBOSE showtiming=SHOWTIMING begin
        ocp = DummyOCPCollocation()

        # Use the default Collocation discretizer to avoid relying on CTDirect
        discretizer = CTSolvers.__discretizer()
        Test.@test discretizer isa CTSolvers.Collocation

        docp = discretizer(ocp)

        # The call operator on Collocation should return a DiscretizedOptimalControlProblem
        Test.@test docp isa CTSolvers.DiscretizedOptimalControlProblem
        Test.@test CTSolvers.ocp_model(docp) === ocp

        # The model and solution builders should be correctly wired with both
        # ADNLP and Exa backends present.
        adnlp_builder = CTSolvers.get_adnlp_model_builder(docp)
        exa_builder   = CTSolvers.get_exa_model_builder(docp)
        adnlp_sol     = CTSolvers.get_adnlp_solution_builder(docp)
        exa_sol       = CTSolvers.get_exa_solution_builder(docp)

        Test.@test adnlp_builder isa CTSolvers.ADNLPModelBuilder
        Test.@test exa_builder   isa CTSolvers.ExaModelBuilder
        Test.@test adnlp_sol     isa CTSolvers.ADNLPSolutionBuilder
        Test.@test exa_sol       isa CTSolvers.ExaSolutionBuilder
    end

end

