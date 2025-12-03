# single solve to test ctdirect update
# NB. optimalcontrol tests solve all modeler/solver pairs for beam and goddard

function test_ctdirect_solve()
    Test.@testset "solve(ocp)" verbose=VERBOSE showtiming=SHOWTIMING begin
        prob = Beam()
        sol = CommonSolve.solve(prob.ocp)
        Test.@test sol.objective ≈ prob.obj rtol = 1e-2
    end
end