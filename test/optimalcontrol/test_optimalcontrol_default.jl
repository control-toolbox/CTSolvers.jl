function test_optimalcontrol_default()

    Test.@testset "Common" verbose=VERBOSE showtiming=SHOWTIMING begin
        Test.@test CTSolvers.__initial_guess() === nothing

        modeler = CTSolvers.__modeler()
        solver = CTSolvers.__solver()

        Test.@test modeler isa CTSolvers.AbstractOptimizationModeler
        Test.@test modeler isa CTSolvers.ADNLPModeler
        Test.@test solver isa CTSolvers.AbstractOptimizationSolver
        Test.@test solver isa CTSolvers.IpoptSolver
    end

end

