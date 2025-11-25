# Unit tests for CTSolvers extension wrappers (default options and constructors for each backend).
function test_ctsolvers_extensions_unit()

    Test.@testset "ctsolvers_ext: Ipopt defaults and constructor" verbose=VERBOSE showtiming=SHOWTIMING begin
        Test.@test CTSolversIpopt.__nlp_models_ipopt_max_iter() == 1000
        Test.@test CTSolversIpopt.__nlp_models_ipopt_tol() == 1e-8
        Test.@test CTSolversIpopt.__nlp_models_ipopt_print_level() == 5
        Test.@test CTSolversIpopt.__nlp_models_ipopt_mu_strategy() == "adaptive"
        Test.@test CTSolversIpopt.__nlp_models_ipopt_linear_solver() == "Mumps"
        Test.@test CTSolversIpopt.__nlp_models_ipopt_sb() == "yes"

        solver = CTSolvers.IpoptSolver()
        opts = Dict(CTSolvers._options(solver))

        Test.@test opts[:max_iter] == CTSolversIpopt.__nlp_models_ipopt_max_iter()
        Test.@test opts[:tol] == CTSolversIpopt.__nlp_models_ipopt_tol()
        Test.@test opts[:print_level] == CTSolversIpopt.__nlp_models_ipopt_print_level()
        Test.@test opts[:mu_strategy] == CTSolversIpopt.__nlp_models_ipopt_mu_strategy()
        Test.@test opts[:linear_solver] == CTSolversIpopt.__nlp_models_ipopt_linear_solver()
        Test.@test opts[:sb] == CTSolversIpopt.__nlp_models_ipopt_sb()
    end

    Test.@testset "ctsolvers_ext: Knitro defaults and constructor" verbose=VERBOSE showtiming=SHOWTIMING begin
        Test.@test CTSolversKnitro.__nlp_models_knitro_max_iter() == 1000
        Test.@test CTSolversKnitro.__nlp_models_knitro_feastol_abs() == 1e-8
        Test.@test CTSolversKnitro.__nlp_models_knitro_opttol_abs() == 1e-8
        Test.@test CTSolversKnitro.__nlp_models_knitro_print_level() == 3

        solver = CTSolvers.KnitroSolver()
        opts = Dict(CTSolvers._options(solver))

        Test.@test opts[:maxit] == CTSolversKnitro.__nlp_models_knitro_max_iter()
        Test.@test opts[:feastol_abs] == CTSolversKnitro.__nlp_models_knitro_feastol_abs()
        Test.@test opts[:opttol_abs] == CTSolversKnitro.__nlp_models_knitro_opttol_abs()
        Test.@test opts[:print_level] == CTSolversKnitro.__nlp_models_knitro_print_level()
    end

    Test.@testset "ctsolvers_ext: MadNLP defaults and constructor" verbose=VERBOSE showtiming=SHOWTIMING begin
        Test.@test CTSolversMadNLP.__mad_nlp_max_iter() == 1000
        Test.@test CTSolversMadNLP.__mad_nlp_tol() == 1e-8
        Test.@test CTSolversMadNLP.__mad_nlp_print_level() == MadNLP.INFO
        Test.@test CTSolversMadNLP.__mad_nlp_linear_solver() == MadNLPMumps.MumpsSolver

        solver = CTSolvers.MadNLPSolver()
        opts = Dict(CTSolvers._options(solver))

        Test.@test opts[:max_iter] == CTSolversMadNLP.__mad_nlp_max_iter()
        Test.@test opts[:tol] == CTSolversMadNLP.__mad_nlp_tol()
        Test.@test opts[:print_level] == CTSolversMadNLP.__mad_nlp_print_level()
        Test.@test opts[:linear_solver] == CTSolversMadNLP.__mad_nlp_linear_solver()
    end

    Test.@testset "ctsolvers_ext: MadNCL defaults and constructor" verbose=VERBOSE showtiming=SHOWTIMING begin
        Test.@test CTSolversMadNCL.__mad_ncl_max_iter() == 1000
        Test.@test CTSolversMadNCL.__mad_ncl_print_level() == MadNLP.INFO
        Test.@test CTSolversMadNCL.__mad_ncl_linear_solver() == MadNLPMumps.MumpsSolver

        ref_opts = CTSolversMadNCL.__mad_ncl_ncl_options()

        solver = CTSolvers.MadNCLSolver()
        opts = Dict(CTSolvers._options(solver))

        Test.@test opts[:max_iter] == CTSolversMadNCL.__mad_ncl_max_iter()
        Test.@test opts[:print_level] == CTSolversMadNCL.__mad_ncl_print_level()
        Test.@test opts[:linear_solver] == CTSolversMadNCL.__mad_ncl_linear_solver()

        ncl_opts = opts[:ncl_options]
        Test.@test ncl_opts isa MadNCL.NCLOptions{Float64}

        for field in fieldnames(MadNCL.NCLOptions)
            Test.@test getfield(ncl_opts, field) == getfield(ref_opts, field)
        end
    end
end
