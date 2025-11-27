# Unit and integration tests for Ipopt CTSolvers extensions.
function test_ctsolvers_extensions_ipopt()

    # ========================================================================
    # UNIT: defaults and constructor
    # ========================================================================
    Test.@testset "unit: defaults and constructor" verbose=VERBOSE showtiming=SHOWTIMING begin
        Test.@test CTSolversIpopt.__nlp_models_ipopt_max_iter() == 1000
        Test.@test CTSolversIpopt.__nlp_models_ipopt_tol() == 1e-8
        Test.@test CTSolversIpopt.__nlp_models_ipopt_print_level() == 5
        Test.@test CTSolversIpopt.__nlp_models_ipopt_mu_strategy() == "adaptive"
        Test.@test CTSolversIpopt.__nlp_models_ipopt_linear_solver() == "Mumps"
        Test.@test CTSolversIpopt.__nlp_models_ipopt_sb() == "yes"

        solver = CTSolvers.IpoptSolver()
        opts = Dict(pairs(CTSolvers._options_values(solver)))

        Test.@test opts[:max_iter] == CTSolversIpopt.__nlp_models_ipopt_max_iter()
        Test.@test opts[:tol] == CTSolversIpopt.__nlp_models_ipopt_tol()
        Test.@test opts[:print_level] == CTSolversIpopt.__nlp_models_ipopt_print_level()
        Test.@test opts[:mu_strategy] == CTSolversIpopt.__nlp_models_ipopt_mu_strategy()
        Test.@test opts[:linear_solver] == CTSolversIpopt.__nlp_models_ipopt_linear_solver()
        Test.@test opts[:sb] == CTSolversIpopt.__nlp_models_ipopt_sb()
    end

    # ========================================================================
    # UNIT: metadata defaults (default_options and option_default)
    # ========================================================================
    Test.@testset "unit: metadata defaults" verbose=VERBOSE showtiming=SHOWTIMING begin
        opts_ipopt = CTSolvers.default_options(CTSolvers.IpoptSolver)
        Test.@test opts_ipopt.max_iter == CTSolversIpopt.__nlp_models_ipopt_max_iter()
        Test.@test opts_ipopt.tol == CTSolversIpopt.__nlp_models_ipopt_tol()
        Test.@test opts_ipopt.print_level == CTSolversIpopt.__nlp_models_ipopt_print_level()

        solver_inst = CTSolvers.IpoptSolver()
        ipopt_type = typeof(solver_inst)

        opts_ipopt_from_inst = CTSolvers.default_options(ipopt_type)
        Test.@test opts_ipopt_from_inst == opts_ipopt

        keys_type = CTSolvers.options_keys(CTSolvers.IpoptSolver)
        keys_inst = CTSolvers.options_keys(ipopt_type)
        Test.@test Set(keys_inst) == Set(keys_type)

        Test.@test CTSolvers.option_default(:max_iter, CTSolvers.IpoptSolver) == CTSolversIpopt.__nlp_models_ipopt_max_iter()
        Test.@test CTSolvers.option_default(:tol,      CTSolvers.IpoptSolver) == CTSolversIpopt.__nlp_models_ipopt_tol()

        Test.@test CTSolvers.option_default(:max_iter, ipopt_type) == CTSolversIpopt.__nlp_models_ipopt_max_iter()
        Test.@test CTSolvers.option_default(:tol,      ipopt_type) == CTSolversIpopt.__nlp_models_ipopt_tol()
    end

    # ========================================================================
    # Common Ipopt options for integration tests
    # ========================================================================
    ipopt_options = Dict(
        :max_iter => 1000,
        :tol => 1e-6,
        :print_level => 0,
        :mu_strategy => "adaptive",
        :linear_solver => "Mumps",
        :sb => "yes",
    )

    # ========================================================================
    # INTEGRATION: solve_with_ipopt (specific)
    # ========================================================================
    Test.@testset "integration: solve_with_ipopt" verbose=VERBOSE showtiming=SHOWTIMING begin
        modelers = [
            CTSolvers.ADNLPModeler(),
            CTSolvers.ExaModeler(),
        ]
        modelers_names = ["ADNLPModeler", "ExaModeler (CPU)"]

        Test.@testset "Rosenbrock" verbose=VERBOSE showtiming=SHOWTIMING begin
            for (modeler, modeler_name) in zip(modelers, modelers_names)
                Test.@testset "$(modeler_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                    nlp = CTSolvers.build_model(rosenbrock_prob, rosenbrock_init, modeler)
                    sol = CTSolvers.solve_with_ipopt(nlp; ipopt_options...)
                    Test.@test sol.status == :first_order
                    Test.@test sol.solution ≈ rosenbrock_solu atol=1e-6
                    Test.@test sol.objective ≈ rosenbrock_objective(rosenbrock_solu) atol=1e-6
                end
            end
        end

        Test.@testset "Elec" verbose=VERBOSE showtiming=SHOWTIMING begin
            for (modeler, modeler_name) in zip(modelers, modelers_names)
                Test.@testset "$(modeler_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                    nlp = CTSolvers.build_model(elec_prob, elec_init, modeler)
                    sol = CTSolvers.solve_with_ipopt(nlp; ipopt_options...)
                    Test.@test sol.status == :first_order
                end
            end
        end
    end

    # ========================================================================
    # INTEGRATION: initial_guess with Ipopt (max_iter = 0)
    # ========================================================================
    Test.@testset "integration: initial_guess" verbose=VERBOSE showtiming=SHOWTIMING begin
        modelers = [
            CTSolvers.ADNLPModeler(),
            CTSolvers.ExaModeler(),
        ]
        modelers_names = ["ADNLPModeler", "ExaModeler (CPU)"]

        # Rosenbrock: start at the known solution and enforce max_iter=0
        Test.@testset "Rosenbrock" verbose=VERBOSE showtiming=SHOWTIMING begin
            for (modeler, modeler_name) in zip(modelers, modelers_names)
                Test.@testset "$(modeler_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                    local opts = copy(ipopt_options)
                    opts[:max_iter] = 0
                    sol = CommonSolve.solve(
                        rosenbrock_prob,
                        rosenbrock_solu,
                        modeler,
                        CTSolvers.IpoptSolver(; opts...),
                    )
                    Test.@test sol.status == :max_iter
                    Test.@test sol.solution ≈ rosenbrock_solu atol=1e-6
                end
            end
        end

        # Elec: expect solution to remain equal to the initial guess vector
        Test.@testset "Elec" verbose=VERBOSE showtiming=SHOWTIMING begin
            for (modeler, modeler_name) in zip(modelers, modelers_names)
                Test.@testset "$(modeler_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                    local opts = copy(ipopt_options)
                    opts[:max_iter] = 0
                    sol = CommonSolve.solve(
                        elec_prob,
                        elec_init,
                        modeler,
                        CTSolvers.IpoptSolver(; opts...),
                    )
                    Test.@test sol.status == :max_iter
                    Test.@test sol.solution ≈ vcat(elec_init.x, elec_init.y, elec_init.z) atol=1e-6
                end
            end
        end
    end

    # ========================================================================
    # INTEGRATION: CommonSolve.solve with Ipopt
    # ========================================================================
    Test.@testset "integration: CommonSolve.solve" verbose=VERBOSE showtiming=SHOWTIMING begin
        modelers = [
            CTSolvers.ADNLPModeler(),
            CTSolvers.ExaModeler(),
        ]
        modelers_names = ["ADNLPModeler", "ExaModeler (CPU)"]

        Test.@testset "Rosenbrock" verbose=VERBOSE showtiming=SHOWTIMING begin
            for (modeler, modeler_name) in zip(modelers, modelers_names)
                Test.@testset "$(modeler_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                    sol = CommonSolve.solve(
                        rosenbrock_prob,
                        rosenbrock_init,
                        modeler,
                        CTSolvers.IpoptSolver(; ipopt_options...),
                    )
                    Test.@test sol.status == :first_order
                    Test.@test sol.solution ≈ rosenbrock_solu atol=1e-6
                    Test.@test sol.objective ≈ rosenbrock_objective(rosenbrock_solu) atol=1e-6
                end
            end
        end

        Test.@testset "Elec" verbose=VERBOSE showtiming=SHOWTIMING begin
            for (modeler, modeler_name) in zip(modelers, modelers_names)
                Test.@testset "$(modeler_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                    sol = CommonSolve.solve(
                        elec_prob,
                        elec_init,
                        modeler,
                        CTSolvers.IpoptSolver(; ipopt_options...),
                    )
                    Test.@test sol.status == :first_order
                end
            end
        end
    end

    # ========================================================================
    # INTEGRATION: Direct beam OCP with Collocation (Ipopt pieces)
    # ========================================================================
    Test.@testset "integration: beam_docp" verbose=VERBOSE showtiming=SHOWTIMING begin
        ocp, init = beam()
        discretizer = CTSolvers.Collocation()
        docp = CTSolvers.discretize(ocp, discretizer)

        Test.@test docp isa CTSolvers.DiscretizedOptimalControlProblem

        modelers = [
            CTSolvers.ADNLPModeler(),
            CTSolvers.ExaModeler(),
        ]
        modelers_names = ["ADNLPModeler", "ExaModeler (CPU)"]

        # ocp_solution from DOCP using solve_with_ipopt
        Test.@testset "ocp_solution from DOCP (Ipopt)" verbose=VERBOSE showtiming=SHOWTIMING begin
            for (modeler, modeler_name) in zip(modelers, modelers_names)
                Test.@testset "$(modeler_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                    nlp = CTSolvers.nlp_model(docp, init, modeler)
                    stats = CTSolvers.solve_with_ipopt(nlp; ipopt_options...)
                    sol = CTSolvers.ocp_solution(docp, stats, modeler)
                    Test.@test sol isa CTModels.Solution
                    Test.@test CTModels.successful(sol)
                    Test.@test isfinite(CTModels.objective(sol))
                end
            end
        end

        # DOCP level: CommonSolve.solve(docp, init, modeler, solver)
        Test.@testset "DOCP level (Ipopt)" verbose=VERBOSE showtiming=SHOWTIMING begin
            for (modeler, modeler_name) in zip(modelers, modelers_names)
                Test.@testset "$(modeler_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                    solver = CTSolvers.IpoptSolver(; ipopt_options...)
                    sol = CommonSolve.solve(docp, init, modeler, solver; display=false)
                    Test.@test sol isa CTModels.Solution
                    Test.@test CTModels.successful(sol)
                    Test.@test isfinite(CTModels.objective(sol))
                    Test.@test CTModels.iterations(sol) <= ipopt_options[:max_iter]
                    Test.@test CTModels.constraints_violation(sol) <= 1e-6
                end
            end
        end
    end

end
