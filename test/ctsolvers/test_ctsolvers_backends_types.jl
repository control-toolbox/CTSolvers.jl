# Unit tests for CTSolvers backend type hierarchy and solver option storage.
function test_ctsolvers_backends_types()

    # ========================================================================
    # Low-level defaults for solver backends
    # ========================================================================

    Test.@testset "raw backend defaults" verbose=VERBOSE showtiming=SHOWTIMING begin
        # NLPModelsIpopt
        Test.@test CTSolversIpopt.__nlp_models_ipopt_max_iter() isa Int
        Test.@test CTSolversIpopt.__nlp_models_ipopt_max_iter() > 0
        Test.@test CTSolversIpopt.__nlp_models_ipopt_tol() isa Float64
        Test.@test CTSolversIpopt.__nlp_models_ipopt_tol() > 0.0
        Test.@test CTSolversIpopt.__nlp_models_ipopt_print_level() isa Int
        Test.@test CTSolversIpopt.__nlp_models_ipopt_mu_strategy() isa String
        Test.@test CTSolversIpopt.__nlp_models_ipopt_linear_solver() isa String
        Test.@test CTSolversIpopt.__nlp_models_ipopt_sb() isa String

        # MadNLP
        Test.@test CTSolversMadNLP.__mad_nlp_max_iter() isa Int
        Test.@test CTSolversMadNLP.__mad_nlp_max_iter() > 0
        Test.@test CTSolversMadNLP.__mad_nlp_tol() isa Float64
        Test.@test CTSolversMadNLP.__mad_nlp_tol() > 0.0
        Test.@test CTSolversMadNLP.__mad_nlp_print_level() isa MadNLP.LogLevels
        Test.@test CTSolversMadNLP.__mad_nlp_linear_solver() isa Type

        # MadNCL
        Test.@test CTSolversMadNCL.__mad_ncl_max_iter() isa Int
        Test.@test CTSolversMadNCL.__mad_ncl_max_iter() > 0
        Test.@test CTSolversMadNCL.__mad_ncl_print_level() isa MadNLP.LogLevels
        Test.@test CTSolversMadNCL.__mad_ncl_linear_solver() isa Type
        Test.@test CTSolversMadNCL.__mad_ncl_linear_solver() <: MadNLP.AbstractLinearSolver
        Test.@test CTSolversMadNCL.__mad_ncl_ncl_options() isa MadNCL.NCLOptions{Float64}

        # Knitro
        Test.@test CTSolversKnitro.__nlp_models_knitro_max_iter() isa Int
        Test.@test CTSolversKnitro.__nlp_models_knitro_max_iter() > 0
        Test.@test CTSolversKnitro.__nlp_models_knitro_feastol_abs() isa Float64
        Test.@test CTSolversKnitro.__nlp_models_knitro_feastol_abs() > 0.0
        Test.@test CTSolversKnitro.__nlp_models_knitro_opttol_abs() isa Float64
        Test.@test CTSolversKnitro.__nlp_models_knitro_opttol_abs() > 0.0
        Test.@test CTSolversKnitro.__nlp_models_knitro_print_level() isa Int
    end

    # ========================================================================
    # TYPE HIERARCHY
    # ========================================================================

    Test.@testset "type hierarchy" verbose=VERBOSE showtiming=SHOWTIMING begin
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

    Test.@testset "solver symbols and registry" verbose=VERBOSE showtiming=SHOWTIMING begin
        # get_symbol on solver types
        Test.@test CTSolvers.get_symbol(CTSolvers.IpoptSolver)  == :ipopt
        Test.@test CTSolvers.get_symbol(CTSolvers.MadNLPSolver) == :madnlp
        Test.@test CTSolvers.get_symbol(CTSolvers.MadNCLSolver) == :madncl
        Test.@test CTSolvers.get_symbol(CTSolvers.KnitroSolver) == :knitro

        # get_symbol on solver instances should behave identically
        Test.@test CTSolvers.get_symbol(CTSolvers.IpoptSolver())  == :ipopt
        Test.@test CTSolvers.get_symbol(CTSolvers.MadNLPSolver()) == :madnlp
        Test.@test CTSolvers.get_symbol(CTSolvers.MadNCLSolver()) == :madncl
        Test.@test CTSolvers.get_symbol(CTSolvers.KnitroSolver()) == :knitro

        # tool_package_name on solver types
        Test.@test CTSolvers.tool_package_name(CTSolvers.IpoptSolver)   == "NLPModelsIpopt"
        Test.@test CTSolvers.tool_package_name(CTSolvers.MadNLPSolver)  == "MadNLP suite"
        Test.@test CTSolvers.tool_package_name(CTSolvers.MadNCLSolver)  == "MadNCL"
        Test.@test CTSolvers.tool_package_name(CTSolvers.KnitroSolver)  == "NLPModelsKnitro"

        # tool_package_name on solver instances
        Test.@test CTSolvers.tool_package_name(CTSolvers.IpoptSolver())   == "NLPModelsIpopt"
        Test.@test CTSolvers.tool_package_name(CTSolvers.MadNLPSolver())  == "MadNLP suite"
        Test.@test CTSolvers.tool_package_name(CTSolvers.MadNCLSolver())  == "MadNCL"
        Test.@test CTSolvers.tool_package_name(CTSolvers.KnitroSolver())  == "NLPModelsKnitro"

        regs = CTSolvers.registered_solver_types()
        Test.@test CTSolvers.IpoptSolver  in regs
        Test.@test CTSolvers.MadNLPSolver in regs
        Test.@test CTSolvers.MadNCLSolver in regs
        Test.@test CTSolvers.KnitroSolver in regs

        syms = CTSolvers.solver_symbols()
        Test.@test :ipopt  in syms
        Test.@test :madnlp in syms
        Test.@test :madncl in syms
        Test.@test :knitro in syms

        # build_solver_from_symbol should construct appropriate solvers and respect options.
        s_ipopt = CTSolvers.build_solver_from_symbol(:ipopt; max_iter=123)
        Test.@test s_ipopt isa CTSolvers.IpoptSolver
        vals_ipopt = CTSolvers._options_values(s_ipopt)
        Test.@test vals_ipopt.max_iter == 123
    end

    Test.@testset "build_solver_from_symbol unknown symbol" verbose=VERBOSE showtiming=SHOWTIMING begin
        err = nothing
        try
            CTSolvers.build_solver_from_symbol(:foo)
        catch e
            err = e
        end
        Test.@test err isa CTBase.IncorrectArgument

        buf = sprint(showerror, err)
        Test.@test occursin("Unknown solver symbol", buf)
        Test.@test occursin("foo", buf)
        for sym in CTSolvers.solver_symbols()
            Test.@test occursin(string(sym), buf)
        end
    end

    # ========================================================================
    # IPopt SOLVER options
    # ========================================================================

    Test.@testset "IpoptSolver options storage" verbose=VERBOSE showtiming=SHOWTIMING begin
        # Default constructor: all options should come from ct_default
        solver_default = CTSolvers.IpoptSolver()
        vals_default = CTSolvers._options_values(solver_default)
        srcs_default = CTSolvers._option_sources(solver_default)

        Test.@test all(srcs_default[k] == :ct_default for k in propertynames(srcs_default))

        # Metadata helpers should expose the same keys and basic types
        keys_ipopt = CTSolvers.options_keys(CTSolvers.IpoptSolver)
        Test.@test :max_iter in keys_ipopt
        Test.@test CTSolvers.option_type(:max_iter, CTSolvers.IpoptSolver) <: Integer

        # User overrides should be visible in both values and sources
        solver_user = CTSolvers.IpoptSolver(; max_iter=100, tol=1e-8)
        vals_user = CTSolvers._options_values(solver_user)
        srcs_user = CTSolvers._option_sources(solver_user)

        Test.@test vals_user.max_iter == 100
        Test.@test srcs_user.max_iter == :user
        Test.@test vals_user.tol == 1e-8
        Test.@test srcs_user.tol == :user
    end

    # ========================================================================
    # MadNLP SOLVER options
    # ========================================================================

    Test.@testset "MadNLPSolver options storage" verbose=VERBOSE showtiming=SHOWTIMING begin
        solver_user = CTSolvers.MadNLPSolver(; max_iter=500, tol=1e-6)
        vals_user = CTSolvers._options_values(solver_user)
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

    Test.@testset "MadNCLSolver options storage" verbose=VERBOSE showtiming=SHOWTIMING begin
        solver_default = CTSolvers.MadNCLSolver()
        vals_default = CTSolvers._options_values(solver_default)
        srcs_default = CTSolvers._option_sources(solver_default)

        Test.@test vals_default.max_iter == CTSolversMadNCL.__mad_ncl_max_iter()
        Test.@test srcs_default.max_iter == :ct_default
    end

    # ========================================================================
    # Knitro SOLVER options
    # ========================================================================

    Test.@testset "KnitroSolver options storage" verbose=VERBOSE showtiming=SHOWTIMING begin
        solver_user = CTSolvers.KnitroSolver(; maxit=300, feastol_abs=1e-6)
        vals_user = CTSolvers._options_values(solver_user)
        srcs_user = CTSolvers._option_sources(solver_user)

        Test.@test vals_user.maxit == 300
        Test.@test srcs_user.maxit == :user
        Test.@test vals_user.feastol_abs == 1e-6
        Test.@test srcs_user.feastol_abs == :user
    end

    # ========================================================================
    # Generic helpers: suggestions and option listing
    # ========================================================================

    Test.@testset "get_option_* helpers" verbose=VERBOSE showtiming=SHOWTIMING begin
        # For a solver with known metadata (IpoptSolver), the getters should
        # recover the same information as default_options / _option_sources.
        solver = CTSolvers.IpoptSolver()
        vals = CTSolvers._options_values(solver)
        srcs = CTSolvers._option_sources(solver)
        defaults = CTSolvers.default_options(CTSolvers.IpoptSolver)

        Test.@test CTSolvers.get_option_value(solver, :max_iter) == vals.max_iter == defaults.max_iter
        Test.@test CTSolvers.get_option_source(solver, :max_iter) == srcs.max_iter == :ct_default
        Test.@test CTSolvers.get_option_default(solver, :max_iter) == defaults.max_iter

        # Unknown option keys should trigger an IncorrectArgument with
        # suggestions based on the Levenshtein machinery.
        err = nothing
        try
            CTSolvers.get_option_value(solver, :mx_iter)
        catch e
            err = e
        end
        Test.@test err !== nothing
        Test.@test err isa CTBase.IncorrectArgument

        buf = sprint(showerror, err)
        Test.@test occursin("mx_iter", buf)
        Test.@test occursin("max_iter", buf)
        Test.@test occursin("show_options(IpoptSolver)", buf)
    end

    Test.@testset "IpoptSolver unknown option suggestions" verbose=VERBOSE showtiming=SHOWTIMING begin
        err = nothing
        try
            # Misspelled option name to trigger suggestion logic at the
            # validation layer, independently of constructor strictness.
            CTSolvers._validate_option_kwargs((mx_iter=10,), CTSolvers.IpoptSolver; strict_keys=true)
        catch e
            err = e
        end
        Test.@test err !== nothing
        Test.@test err isa CTBase.IncorrectArgument

        buf = sprint(showerror, err)
        Test.@test occursin("mx_iter", buf)
        Test.@test occursin("max_iter", buf)
        Test.@test occursin("show_options(IpoptSolver)", buf)
    end

    Test.@testset "IpoptSolver _show_options runs" verbose=VERBOSE showtiming=SHOWTIMING begin
        # Just ensure that _show_options does not throw when called on IpoptSolver.
        redirect_stdout(devnull) do
            CTSolvers.show_options(CTSolvers.IpoptSolver)
        end
        Test.@test true
    end

end

