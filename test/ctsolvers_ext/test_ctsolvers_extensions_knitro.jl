# Unit tests for Knitro CTSolvers extensions.
function test_ctsolvers_extensions_knitro()

    # ========================================================================
    # UNIT: defaults and constructor
    # ========================================================================
    Test.@testset "unit: defaults and constructor" verbose=VERBOSE showtiming=SHOWTIMING begin
        Test.@test CTSolversKnitro.__nlp_models_knitro_max_iter() == 1000
        Test.@test CTSolversKnitro.__nlp_models_knitro_feastol_abs() == 1e-8
        Test.@test CTSolversKnitro.__nlp_models_knitro_opttol_abs() == 1e-8
        Test.@test CTSolversKnitro.__nlp_models_knitro_print_level() == 3

        solver = CTSolvers.KnitroSolver()
        opts = Dict(pairs(CTSolvers._options_values(solver)))

        Test.@test opts[:maxit] == CTSolversKnitro.__nlp_models_knitro_max_iter()
        Test.@test opts[:feastol_abs] == CTSolversKnitro.__nlp_models_knitro_feastol_abs()
        Test.@test opts[:opttol_abs] == CTSolversKnitro.__nlp_models_knitro_opttol_abs()
        Test.@test opts[:print_level] == CTSolversKnitro.__nlp_models_knitro_print_level()
    end

    # ========================================================================
    # UNIT: metadata defaults (default_options and option_default)
    # ========================================================================
    Test.@testset "unit: metadata defaults" verbose=VERBOSE showtiming=SHOWTIMING begin
        opts_k = CTSolvers.default_options(CTSolvers.KnitroSolver)
        Test.@test opts_k.maxit == CTSolversKnitro.__nlp_models_knitro_max_iter()
        Test.@test opts_k.feastol_abs == CTSolversKnitro.__nlp_models_knitro_feastol_abs()
        Test.@test opts_k.opttol_abs == CTSolversKnitro.__nlp_models_knitro_opttol_abs()

        solver_inst = CTSolvers.KnitroSolver()
        knitro_type = typeof(solver_inst)

        opts_k_from_inst = CTSolvers.default_options(knitro_type)
        Test.@test opts_k_from_inst == opts_k

        keys_type = CTSolvers.options_keys(CTSolvers.KnitroSolver)
        keys_inst = CTSolvers.options_keys(knitro_type)
        Test.@test Set(keys_inst) == Set(keys_type)

        Test.@test CTSolvers.option_default(:maxit,       CTSolvers.KnitroSolver) == CTSolversKnitro.__nlp_models_knitro_max_iter()
        Test.@test CTSolvers.option_default(:feastol_abs, CTSolvers.KnitroSolver) == CTSolversKnitro.__nlp_models_knitro_feastol_abs()
        Test.@test CTSolvers.option_default(:opttol_abs,  CTSolvers.KnitroSolver) == CTSolversKnitro.__nlp_models_knitro_opttol_abs()

        Test.@test CTSolvers.option_default(:maxit,       knitro_type) == CTSolversKnitro.__nlp_models_knitro_max_iter()
        Test.@test CTSolvers.option_default(:feastol_abs, knitro_type) == CTSolversKnitro.__nlp_models_knitro_feastol_abs()
        Test.@test CTSolvers.option_default(:opttol_abs,  knitro_type) == CTSolversKnitro.__nlp_models_knitro_opttol_abs()
    end

end
