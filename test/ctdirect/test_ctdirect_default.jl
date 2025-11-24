# Unit tests for CTDirect default discretization parameters (grid size, scheme, discretizer).
function test_ctdirect_default()

    Test.@test CTSolvers.__grid_size() isa Int
    Test.@test CTSolvers.__grid_size() > 0
    Test.@test CTSolvers.__scheme() isa CTSolvers.AbstractIntegratorScheme
    Test.@test CTSolvers.__scheme() isa CTSolvers.Midpoint
    Test.@test CTSolvers.__discretizer() isa CTSolvers.AbstractOptimalControlDiscretizer
    Test.@test CTSolvers.__discretizer() isa CTSolvers.Collocation

end
