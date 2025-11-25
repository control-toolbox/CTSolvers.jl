# Unit tests for CTSolvers backend type hierarchy and solver option storage.
function test_ctsolvers_backends_types()

    # ========================================================================
    # TYPE HIERARCHY
    # ========================================================================

    Test.@testset "ctsolvers/backends_types: type hierarchy" verbose=VERBOSE showtiming=SHOWTIMING begin
        # All solver wrappers should be subtypes of AbstractOptimizationSolver
        Test.@test CTSolvers.IpoptSolver    <: CTSolvers.AbstractOptimizationSolver
        Test.@test CTSolvers.MadNLPSolver   <: CTSolvers.AbstractOptimizationSolver
        Test.@test CTSolvers.MadNCLSolver   <: CTSolvers.AbstractOptimizationSolver
        Test.@test CTSolvers.KnitroSolver   <: CTSolvers.AbstractOptimizationSolver
    end

    # ========================================================================
    # IPopt SOLVER options
    # ========================================================================

    Test.@testset "ctsolvers/backends_types: IpoptSolver options storage" verbose=VERBOSE showtiming=SHOWTIMING begin
        # Default constructor: all options should come from ct_default
        solver_default = CTSolvers.IpoptSolver()
        vals_default = CTSolvers._options(solver_default)
        srcs_default = CTSolvers._option_sources(solver_default)

        Test.@test all(srcs_default[k] == :ct_default for k in propertynames(srcs_default))

        # User overrides should be visible in both values and sources
        solver_user = CTSolvers.IpoptSolver(; max_iter=100, tol=1e-8)
        vals_user = CTSolvers._options(solver_user)
        srcs_user = CTSolvers._option_sources(solver_user)

        Test.@test vals_user.max_iter == 100
        Test.@test srcs_user.max_iter == :user
        Test.@test vals_user.tol == 1e-8
        Test.@test srcs_user.tol == :user
    end

    # ========================================================================
    # MadNLP SOLVER options
    # ========================================================================

    Test.@testset "ctsolvers/backends_types: MadNLPSolver options storage" verbose=VERBOSE showtiming=SHOWTIMING begin
        solver_user = CTSolvers.MadNLPSolver(; max_iter=500, tol=1e-6)
        vals_user = CTSolvers._options(solver_user)
        srcs_user = CTSolvers._option_sources(solver_user)

        Test.@test vals_user.max_iter == 500
        Test.@test srcs_user.max_iter == :user
        Test.@test vals_user.tol == 1e-6
        Test.@test srcs_user.tol == :user
    end

    # ========================================================================
    # MadNCL SOLVER options
    # ========================================================================

    Test.@testset "ctsolvers/backends_types: MadNCLSolver options storage" verbose=VERBOSE showtiming=SHOWTIMING begin
        solver_default = CTSolvers.MadNCLSolver()
        vals_default = CTSolvers._options(solver_default)
        srcs_default = CTSolvers._option_sources(solver_default)

        Test.@test vals_default.max_iter == CTSolversMadNCL.__mad_ncl_max_iter()
        Test.@test srcs_default.max_iter == :ct_default
    end

    # ========================================================================
    # Knitro SOLVER options
    # ========================================================================

    Test.@testset "ctsolvers/backends_types: KnitroSolver options storage" verbose=VERBOSE showtiming=SHOWTIMING begin
        solver_user = CTSolvers.KnitroSolver(; maxit=300, feastol_abs=1e-6)
        vals_user = CTSolvers._options(solver_user)
        srcs_user = CTSolvers._option_sources(solver_user)

        Test.@test vals_user.maxit == 300
        Test.@test srcs_user.maxit == :user
        Test.@test vals_user.feastol_abs == 1e-6
        Test.@test srcs_user.feastol_abs == :user
    end

end

