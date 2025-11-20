function test_default()

    # ADNLPModels
    Test.@testset "ADNLPModels" verbose=VERBOSE showtiming=SHOWTIMING begin
        Test.@test CTSolvers.__adnlp_model_show_time() isa Bool
        Test.@test CTSolvers.__adnlp_model_backend() isa Symbol
        Test.@test CTSolvers.__adnlp_model_empty_backends() isa Tuple{Vararg{Symbol}}
    end

    # ExaModels
    Test.@testset "ExaModels" verbose=VERBOSE showtiming=SHOWTIMING begin
        Test.@test CTSolvers.__exa_model_base_type() isa DataType
        Test.@test CTSolvers.__exa_model_backend() isa Union{Nothing,Symbol}
    end

    # Common
    Test.@testset "Common" verbose=VERBOSE showtiming=SHOWTIMING begin
        Test.@test CTSolvers.__display() isa Bool
    end

    # NLPModelsIpopt
    Test.@testset "NLPModelsIpopt" verbose=VERBOSE showtiming=SHOWTIMING begin
        Test.@test CTSolversIpopt.__nlp_models_ipopt_max_iter() isa Int
        Test.@test CTSolversIpopt.__nlp_models_ipopt_max_iter() > 0
        Test.@test CTSolversIpopt.__nlp_models_ipopt_tol() isa Float64
        Test.@test CTSolversIpopt.__nlp_models_ipopt_tol() > 0.0
        Test.@test CTSolversIpopt.__nlp_models_ipopt_print_level() isa Int
        Test.@test CTSolversIpopt.__nlp_models_ipopt_mu_strategy() isa String
        Test.@test CTSolversIpopt.__nlp_models_ipopt_linear_solver() isa String
        Test.@test CTSolversIpopt.__nlp_models_ipopt_sb() isa String
    end

    # MadNLP
    Test.@testset "MadNLP" verbose=VERBOSE showtiming=SHOWTIMING begin
        Test.@test CTSolversMadNLP.__mad_nlp_max_iter() isa Int
        Test.@test CTSolversMadNLP.__mad_nlp_max_iter() > 0
        Test.@test CTSolversMadNLP.__mad_nlp_tol() isa Float64
        Test.@test CTSolversMadNLP.__mad_nlp_tol() > 0.0
        Test.@test CTSolversMadNLP.__mad_nlp_print_level() isa MadNLP.LogLevels
        Test.@test CTSolversMadNLP.__mad_nlp_linear_solver() isa Type
    end

    # MadNCL
    Test.@testset "MadNCL" verbose=VERBOSE showtiming=SHOWTIMING begin
        Test.@test CTSolversMadNCL.__mad_ncl_max_iter() isa Int
        Test.@test CTSolversMadNCL.__mad_ncl_max_iter() > 0
        Test.@test CTSolversMadNCL.__mad_ncl_print_level() isa MadNLP.LogLevels
        Test.@test CTSolversMadNCL.__mad_ncl_ncl_options() isa MadNCL.NCLOptions{Float64}
    end

    # Knitro
    Test.@testset "Knitro" verbose=VERBOSE showtiming=SHOWTIMING begin
        Test.@test CTSolversKnitro.__nlp_models_knitro_max_iter() isa Int
        Test.@test CTSolversKnitro.__nlp_models_knitro_max_iter() > 0
        Test.@test CTSolversKnitro.__nlp_models_knitro_feastol_abs() isa Float64
        Test.@test CTSolversKnitro.__nlp_models_knitro_feastol_abs() > 0.0
        Test.@test CTSolversKnitro.__nlp_models_knitro_opttol_abs() isa Float64
        Test.@test CTSolversKnitro.__nlp_models_knitro_opttol_abs() > 0.0
        Test.@test CTSolversKnitro.__nlp_models_knitro_print_level() isa Int
    end
end
