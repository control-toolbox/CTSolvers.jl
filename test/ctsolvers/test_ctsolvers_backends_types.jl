# Unit tests for CTSolvers backend type hierarchy and solver option storage.
function test_ctsolvers_backends_types()

    # ========================================================================
    # TYPE HIERARCHY
    # ========================================================================

    Test.@testset "ctsolvers/backends_types: type hierarchy" verbose=VERBOSE showtiming=SHOWTIMING begin
        # All solver wrappers should be subtypes of AbstractOptimizationSolver
        Test.@test CTSolvers.IpoptSolver <: CTSolvers.AbstractOptimizationSolver
        Test.@test CTSolvers.MadNLPSolver <: CTSolvers.AbstractOptimizationSolver
        Test.@test CTSolvers.MadNCLSolver <: CTSolvers.AbstractOptimizationSolver
        Test.@test CTSolvers.KnitroSolver <: CTSolvers.AbstractOptimizationSolver
    end

    # ========================================================================
    # IPopt SOLVER
    # ========================================================================

    Test.@testset "ctsolvers/backends_types: IpoptSolver options storage" verbose=VERBOSE showtiming=SHOWTIMING begin
        # Minimal options tuple of pairs
        opts = (:max_iter => 100, :tol => 1e-8)

        solver = CTSolvers.IpoptSolver(opts)

        # The struct should store the tuple unchanged and parameterize on its type
        Test.@test solver isa CTSolvers.IpoptSolver{typeof(opts)}
        Test.@test solver.options === opts
    end

    # ========================================================================
    # MadNLP SOLVER
    # ========================================================================

    Test.@testset "ctsolvers/backends_types: MadNLPSolver options storage" verbose=VERBOSE showtiming=SHOWTIMING begin
        opts = (:max_iter => 500, :tol => 1e-6)

        solver = CTSolvers.MadNLPSolver(opts)

        Test.@test solver isa CTSolvers.MadNLPSolver{typeof(opts)}
        Test.@test solver.options === opts
    end

    # ========================================================================
    # MadNCL SOLVER
    # ========================================================================

    Test.@testset "ctsolvers/backends_types: MadNCLSolver options storage" verbose=VERBOSE showtiming=SHOWTIMING begin
        opts = (:max_iter => 200, :print_level => :info)

        # MadNCLSolver has a BaseType type parameter in addition to the tuple type
        solver = CTSolvers.MadNCLSolver{Float64,typeof(opts)}(opts)

        Test.@test solver isa CTSolvers.MadNCLSolver{Float64,typeof(opts)}
        Test.@test solver.options === opts
    end

    # ========================================================================
    # Knitro SOLVER
    # ========================================================================

    Test.@testset "ctsolvers/backends_types: KnitroSolver options storage" verbose=VERBOSE showtiming=SHOWTIMING begin
        opts = (:max_iter => 300, :feastol => 1e-6)

        solver = CTSolvers.KnitroSolver(opts)

        Test.@test solver isa CTSolvers.KnitroSolver{typeof(opts)}
        Test.@test solver.options === opts
    end
end
