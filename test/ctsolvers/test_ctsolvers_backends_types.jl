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

        # And all abstract tool families should be subtypes of AbstractOCPTool
        Test.@test CTSolvers.AbstractOptimalControlDiscretizer <: CTSolvers.AbstractOCPTool
        Test.@test CTSolvers.AbstractOptimizationModeler      <: CTSolvers.AbstractOCPTool
        Test.@test CTSolvers.AbstractOptimizationSolver       <: CTSolvers.AbstractOCPTool
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

        # Metadata helpers should expose the same keys and basic types
        keys_ipopt = CTSolvers.options_keys(CTSolvers.IpoptSolver)
        Test.@test :max_iter in keys_ipopt
        Test.@test CTSolvers.option_type(:max_iter, CTSolvers.IpoptSolver) <: Integer

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

        # Metadata should know about max_iter and tol
        keys_madnlp = CTSolvers.options_keys(CTSolvers.MadNLPSolver)
        Test.@test :max_iter in keys_madnlp
        Test.@test :tol in keys_madnlp
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

    # ========================================================================
    # Generic helpers: suggestions and option listing
    # ========================================================================

    Test.@testset "ctsolvers/backends_types: IpoptSolver unknown option suggestions" verbose=VERBOSE showtiming=SHOWTIMING begin
        err = nothing
        try
            # Misspelled option name to trigger suggestion logic.
            CTSolvers.IpoptSolver(; mx_iter=10)
        catch e
            err = e
        end
        Test.@test err !== nothing
        Test.@test err isa CTBase.IncorrectArgument

        buf = sprint(showerror, err)
        Test.@test occursin("mx_iter", buf)
        Test.@test occursin("max_iter", buf)
        Test.@test occursin("_show_options(IpoptSolver)", buf)
    end

    Test.@testset "ctsolvers/backends_types: IpoptSolver _show_options runs" verbose=VERBOSE showtiming=SHOWTIMING begin
        # Just ensure that _show_options does not throw and produces some text.
        buf = sprint() do io
            redirect_stdout(io) do
                CTSolvers._show_options(CTSolvers.IpoptSolver)
            end
        end
        Test.@test occursin("Options for", buf)
        Test.@test occursin("IpoptSolver", buf)
    end

end

