function test_solvers()

    # options
    ipopt_options = Dict(
        :max_iter => 100,
        :tol => 1e-6,
        :print_level => 0,
        :mu_strategy => "adaptive",
        :linear_solver => "Mumps",
        :sb => "yes",
    )

    madnlp_options = Dict(
        :max_iter => 100,
        :tol => 1e-6,
        :print_level => MadNLP.ERROR,
    )

    f_madncl_options(BaseType) = Dict(
        :max_iter => 100,
        :tol => 1e-6,
        :print_level => MadNLP.ERROR,
        :ncl_options => MadNCL.NCLOptions{BaseType}(; verbose=false),
    )

    # use specific function to solve problems
    Test.@testset "Solve (specific)" verbose=VERBOSE showtiming=SHOWTIMING begin

        # NLPModelsIpopt
        if :ipopt in SOLVERS_RUNTESTS[:specific]
            Test.@testset "NLPModelsIpopt" verbose=VERBOSE showtiming=SHOWTIMING begin

                modelers = [CTSolvers.ADNLPModelBackend(; backend=:manual), CTSolvers.ExaModelBackend()]
                modelers_names = ["ADNLPModelBackend (manual)", "ExaModelBackend (CPU)"]

                # Rosenbrock
                Test.@testset "Rosenbrock" verbose=VERBOSE showtiming=SHOWTIMING begin
                    # solve
                    for (modeler, modeler_name) in zip(modelers, modelers_names)
                        Test.@testset "$(modeler_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                            nlp_adnlp = CTSolvers.nlp_model(rosenbrock_prob, rosenbrock_init, modeler)
                            sol = CTSolvers.solve_with_ipopt(nlp_adnlp; ipopt_options...)
                            Test.@test sol.status == :first_order
                            Test.@test sol.solution ≈ rosenbrock_solu atol=1e-6
                            Test.@test sol.objective ≈ rosenbrock_objective(rosenbrock_solu) atol=1e-6
                        end
                    end
                end

                # Elec
                Test.@testset "Elec" verbose=VERBOSE showtiming=SHOWTIMING begin
                    # solve
                    for (modeler, modeler_name) in zip(modelers, modelers_names)
                        Test.@testset "$(modeler_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                            nlp_adnlp = CTSolvers.nlp_model(elec_prob, elec_init, modeler)
                            sol = CTSolvers.solve_with_ipopt(nlp_adnlp; ipopt_options...)
                            Test.@test sol.status == :first_order
                        end
                    end
                end
            end
        end

        # MadNLP
        if :madnlp in SOLVERS_RUNTESTS[:specific]
            Test.@testset "MadNLP" verbose=VERBOSE showtiming=SHOWTIMING begin

                BaseType = Float32
                modelers = [CTSolvers.ADNLPModelBackend(; backend=:manual), CTSolvers.ExaModelBackend(; base_type=BaseType)]
                modelers_names = ["ADNLPModelBackend (manual)", "ExaModelBackend (CPU)"]
                linear_solvers = [MadNLP.UmfpackSolver, MadNLPMumps.MumpsSolver]
                linear_solvers_names = ["Umfpack", "Mumps"]

                # Rosenbrock
                Test.@testset "Rosenbrock" verbose=VERBOSE showtiming=SHOWTIMING begin
                    # solve
                    for (modeler, modeler_name) in zip(modelers, modelers_names)
                        for (linear_solver, linear_solver_name) in zip(linear_solvers, linear_solvers_names)
                            Test.@testset "$(modeler_name), $(linear_solver_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                                nlp = CTSolvers.nlp_model(rosenbrock_prob, rosenbrock_init, modeler)
                                sol = CTSolvers.solve_with_madnlp(nlp; linear_solver=linear_solver, madnlp_options...)
                                Test.@test sol.status == MadNLP.SOLVE_SUCCEEDED
                                Test.@test sol.solution ≈ rosenbrock_solu atol=1e-6
                                Test.@test sol.objective ≈ rosenbrock_objective(rosenbrock_solu) atol=1e-6
                            end
                        end
                    end
                end

                # Elec
                Test.@testset "Elec" verbose=VERBOSE showtiming=SHOWTIMING begin
                    # solve
                    for (modeler, modeler_name) in zip(modelers, modelers_names)
                        for (linear_solver, linear_solver_name) in zip(linear_solvers, linear_solvers_names)
                            Test.@testset "$(modeler_name), $(linear_solver_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                                nlp = CTSolvers.nlp_model(elec_prob, elec_init, modeler)
                                sol = CTSolvers.solve_with_madnlp(nlp; linear_solver=linear_solver, madnlp_options...)
                                Test.@test sol.status == MadNLP.SOLVE_SUCCEEDED
                            end
                        end
                    end
                end
            end
        end

        # MadNCL
        if :madncl in SOLVERS_RUNTESTS[:specific]
            Test.@testset "MadNCL" verbose=VERBOSE showtiming=SHOWTIMING begin
                BaseType = Float64
                modelers = [CTSolvers.ADNLPModelBackend(; backend=:manual), CTSolvers.ExaModelBackend(; base_type=BaseType)]
                modelers_names = ["ADNLPModelBackend (manual)", "ExaModelBackend (CPU)"]
                linear_solvers = [MadNLP.UmfpackSolver, MadNLPMumps.MumpsSolver]
                linear_solvers_names = ["Umfpack", "Mumps"]
                madncl_options = f_madncl_options(BaseType)

                # Elec
                Test.@testset "Elec" verbose=VERBOSE showtiming=SHOWTIMING begin
                    # solve
                    for (modeler, modeler_name) in zip(modelers, modelers_names)
                        for (linear_solver, linear_solver_name) in zip(linear_solvers, linear_solvers_names)
                            Test.@testset "$(modeler_name), $(linear_solver_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                                nlp = CTSolvers.nlp_model(elec_prob, elec_init, modeler)
                                sol = CTSolvers.solve_with_madncl(nlp; linear_solver=linear_solver, madncl_options...)
                                Test.@test sol.status == MadNLP.SOLVE_SUCCEEDED
                            end
                        end
                    end
                end
            end
        end
    end

    # Generic solvers
    Test.@testset "Solve (generic)" verbose=VERBOSE showtiming=SHOWTIMING begin

        # NLPModelsIpopt
        if :ipopt in SOLVERS_RUNTESTS[:generic]
            Test.@testset "NLPModelsIpopt" verbose=VERBOSE showtiming=SHOWTIMING begin

                modelers = [CTSolvers.ADNLPModelBackend(; backend=:manual), CTSolvers.ExaModelBackend()]
                modelers_names = ["ADNLPModelBackend (manual)", "ExaModelBackend (CPU)"]

                # Rosenbrock
                Test.@testset "Rosenbrock" verbose=VERBOSE showtiming=SHOWTIMING begin
                    # solve
                    Test.@testset "solve" verbose=VERBOSE showtiming=SHOWTIMING begin
                        for (modeler, modeler_name) in zip(modelers, modelers_names)
                            Test.@testset "$(modeler_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                                sol = CommonSolve.solve(rosenbrock_prob, rosenbrock_init, modeler, CTSolvers.NLPModelsIpoptBackend(; ipopt_options...))
                                Test.@test sol.status == :first_order
                                Test.@test sol.solution ≈ rosenbrock_solu atol=1e-6
                                Test.@test sol.objective ≈ rosenbrock_objective(rosenbrock_solu) atol=1e-6
                            end
                        end
                    end
                    # initial_guess
                    Test.@testset "initial_guess" verbose=VERBOSE showtiming=SHOWTIMING begin
                        for (modeler, modeler_name) in zip(modelers, modelers_names)
                            Test.@testset "$(modeler_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                                sol = CommonSolve.solve(rosenbrock_prob, rosenbrock_solu, modeler, CTSolvers.NLPModelsIpoptBackend(; ipopt_options..., max_iter=0))
                                Test.@test sol.solution ≈ rosenbrock_solu atol=1e-6
                            end
                        end
                    end
                end

                # Elec
                Test.@testset "Elec" verbose=VERBOSE showtiming=SHOWTIMING begin
                    # solve
                    Test.@testset "solve" verbose=VERBOSE showtiming=SHOWTIMING begin
                        for (modeler, modeler_name) in zip(modelers, modelers_names)
                            Test.@testset "$(modeler_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                                sol = CommonSolve.solve(elec_prob, elec_init, modeler, CTSolvers.NLPModelsIpoptBackend(; ipopt_options...))
                                Test.@test sol.status == :first_order
                            end
                        end
                    end
                    # initial_guess
                    Test.@testset "initial_guess" verbose=VERBOSE showtiming=SHOWTIMING begin
                        for (modeler, modeler_name) in zip(modelers, modelers_names)
                            Test.@testset "$(modeler_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                                sol = CommonSolve.solve(elec_prob, elec_init, modeler, CTSolvers.NLPModelsIpoptBackend(; ipopt_options..., max_iter=0))
                                Test.@test sol.solution ≈ vcat(elec_init.x, elec_init.y, elec_init.z) atol=1e-6
                            end
                        end
                    end
                end
            end
        end

        # MadNLP
        if :madnlp in SOLVERS_RUNTESTS[:generic]
            Test.@testset "MadNLP" verbose=VERBOSE showtiming=SHOWTIMING begin

                BaseType = Float32
                modelers = [CTSolvers.ADNLPModelBackend(; backend=:manual), CTSolvers.ExaModelBackend(; base_type=BaseType)]
                modelers_names = ["ADNLPModelBackend (manual)", "ExaModelBackend (CPU)"]
                linear_solvers = [MadNLP.UmfpackSolver, MadNLPMumps.MumpsSolver]
                linear_solvers_names = ["Umfpack", "Mumps"]

                # Rosenbrock
                Test.@testset "Rosenbrock" verbose=VERBOSE showtiming=SHOWTIMING begin
                    # solve
                    Test.@testset "solve" verbose=VERBOSE showtiming=SHOWTIMING begin
                        for (modeler, modeler_name) in zip(modelers, modelers_names)
                            for (linear_solver, linear_solver_name) in zip(linear_solvers, linear_solvers_names)
                                Test.@testset "$(modeler_name), $(linear_solver_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                                    sol = CommonSolve.solve(rosenbrock_prob, rosenbrock_init, modeler, CTSolvers.MadNLPBackend(; madnlp_options..., linear_solver=linear_solver))
                                    Test.@test sol.status == MadNLP.SOLVE_SUCCEEDED
                                    Test.@test sol.solution ≈ rosenbrock_solu atol=1e-6
                                    Test.@test sol.objective ≈ rosenbrock_objective(rosenbrock_solu) atol=1e-6
                                end
                            end
                        end
                    end
                    # initial_guess
                    Test.@testset "initial_guess" verbose=VERBOSE showtiming=SHOWTIMING begin
                        for (modeler, modeler_name) in zip(modelers, modelers_names)
                            for (linear_solver, linear_solver_name) in zip(linear_solvers, linear_solvers_names)
                                Test.@testset "$(modeler_name), $(linear_solver_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                                    sol = CommonSolve.solve(rosenbrock_prob, rosenbrock_solu, modeler, CTSolvers.MadNLPBackend(; madnlp_options..., max_iter=0, linear_solver=linear_solver))
                                    Test.@test sol.solution ≈ rosenbrock_solu atol=1e-6
                                end
                            end
                        end
                    end
                end

                # Elec
                Test.@testset "Elec" verbose=VERBOSE showtiming=SHOWTIMING begin
                    # solve
                    Test.@testset "solve" verbose=VERBOSE showtiming=SHOWTIMING begin
                        for (modeler, modeler_name) in zip(modelers, modelers_names)
                            for (linear_solver, linear_solver_name) in zip(linear_solvers, linear_solvers_names)
                                Test.@testset "$(modeler_name), $(linear_solver_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                                    sol = CommonSolve.solve(elec_prob, elec_init, modeler, CTSolvers.MadNLPBackend(; madnlp_options..., linear_solver=linear_solver))
                                    Test.@test sol.status == MadNLP.SOLVE_SUCCEEDED
                                end
                            end
                        end
                    end
                    # initial_guess
                    Test.@testset "initial_guess" verbose=VERBOSE showtiming=SHOWTIMING begin
                        for (modeler, modeler_name) in zip(modelers, modelers_names)
                            for (linear_solver, linear_solver_name) in zip(linear_solvers, linear_solvers_names)
                                Test.@testset "$(modeler_name), $(linear_solver_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                                    sol = CommonSolve.solve(elec_prob, elec_init, modeler, CTSolvers.MadNLPBackend(; madnlp_options..., max_iter=0, linear_solver=linear_solver))
                                    Test.@test sol.solution ≈ vcat(elec_init.x, elec_init.y, elec_init.z) atol=1e-6
                                end
                            end
                        end
                    end
                end
            end
        end

        # MadNCL
        if :madncl in SOLVERS_RUNTESTS[:generic]
            Test.@testset "MadNCL" verbose=VERBOSE showtiming=SHOWTIMING begin
            
                BaseType = Float64
                modelers = [CTSolvers.ADNLPModelBackend(; backend=:manual), CTSolvers.ExaModelBackend(; base_type=BaseType)]
                modelers_names = ["ADNLPModelBackend (manual)", "ExaModelBackend (CPU)"]
                linear_solvers = [MadNLP.UmfpackSolver, MadNLPMumps.MumpsSolver]
                linear_solvers_names = ["Umfpack", "Mumps"]
                madncl_options = f_madncl_options(BaseType)

                # Elec
                Test.@testset "Elec" verbose=VERBOSE showtiming=SHOWTIMING begin
                    # solve
                    Test.@testset "solve" verbose=VERBOSE showtiming=SHOWTIMING begin
                        for (modeler, modeler_name) in zip(modelers, modelers_names)
                            for (linear_solver, linear_solver_name) in zip(linear_solvers, linear_solvers_names)
                                Test.@testset "$(modeler_name), $(linear_solver_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                                    sol = CommonSolve.solve(elec_prob, elec_init, modeler, CTSolvers.MadNCLBackend(; madncl_options..., linear_solver=linear_solver))
                                    Test.@test sol.status == MadNLP.SOLVE_SUCCEEDED
                                end
                            end
                        end
                    end
                    # initial_guess
                    Test.@testset "initial_guess" verbose=VERBOSE showtiming=SHOWTIMING begin
                        for (modeler, modeler_name) in zip(modelers, modelers_names)
                            for (linear_solver, linear_solver_name) in zip(linear_solvers, linear_solvers_names)
                                Test.@testset "$(modeler_name), $(linear_solver_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                                    sol = CommonSolve.solve(elec_prob, elec_init, modeler, CTSolvers.MadNCLBackend(; madncl_options..., max_iter=0, linear_solver=linear_solver))
                                    Test.@test sol.solution ≈ vcat(elec_init.x, elec_init.y, elec_init.z) atol=1e-6
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    # Default options
    Test.@testset "Default options" verbose=VERBOSE showtiming=SHOWTIMING begin

        if :ipopt in SOLVERS_RUNTESTS[:default]
            Test.@testset "NLPModelsIpopt" verbose=VERBOSE showtiming=SHOWTIMING begin
                solver = CTSolvers.NLPModelsIpoptBackend()
                modelers = [CTSolvers.ADNLPModelBackend(), CTSolvers.ExaModelBackend()]
                modelers_names = ["ADNLPModelBackend", "ExaModelBackend"]
                for (modeler, modeler_name) in zip(modelers, modelers_names)
                    Test.@testset "$(modeler_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                        sol = CommonSolve.solve(rosenbrock_prob, rosenbrock_init, modeler, solver; display=false)
                        Test.@test sol.status == :first_order
                        Test.@test sol.solution ≈ rosenbrock_solu atol=1e-6
                        Test.@test sol.objective ≈ rosenbrock_objective(rosenbrock_solu) atol=1e-6
                    end
                end
            end
        end

        if :madnlp in SOLVERS_RUNTESTS[:default]
            Test.@testset "MadNLP" verbose=VERBOSE showtiming=SHOWTIMING begin
                solver = CTSolvers.MadNLPBackend()
                modelers = [CTSolvers.ADNLPModelBackend(), CTSolvers.ExaModelBackend()]
                modelers_names = ["ADNLPModelBackend", "ExaModelBackend"]
                for (modeler, modeler_name) in zip(modelers, modelers_names)
                    Test.@testset "$(modeler_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                        sol = CommonSolve.solve(rosenbrock_prob, rosenbrock_init, modeler, solver; display=false)
                        Test.@test sol.status == MadNLP.SOLVE_SUCCEEDED
                        Test.@test sol.solution ≈ rosenbrock_solu atol=1e-6
                        Test.@test sol.objective ≈ rosenbrock_objective(rosenbrock_solu) atol=1e-6
                    end
                end
            end
        end

        if :madncl in SOLVERS_RUNTESTS[:default]
            Test.@testset "MadNCL" verbose=VERBOSE showtiming=SHOWTIMING begin
                solver = CTSolvers.MadNCLBackend()
                modelers = [CTSolvers.ADNLPModelBackend(), CTSolvers.ExaModelBackend()]
                modelers_names = ["ADNLPModelBackend", "ExaModelBackend"]
                for (modeler, modeler_name) in zip(modelers, modelers_names)
                    Test.@testset "$(modeler_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                        sol = CommonSolve.solve(rosenbrock_prob, rosenbrock_init, modeler, solver; display=false)
                        Test.@test sol.status == MadNLP.SOLVE_SUCCEEDED
                        Test.@test sol.solution ≈ rosenbrock_solu atol=1e-6
                        Test.@test sol.objective ≈ rosenbrock_objective(rosenbrock_solu) atol=1e-6
                    end
                end
            end
        end
    end

    # GPU
    if is_cuda_on()
        Test.@testset "GPU" verbose=VERBOSE showtiming=SHOWTIMING begin

            exa_backend = CUDA.CUDABackend()
            linear_solver = MadNLPGPU.CUDSSSolver
            modelers = [CTSolvers.ExaModelBackend(; backend=exa_backend)]
            modelers_names = ["ExaModelBackend (GPU)"]

            # MadNLP
            if :madnlp in SOLVERS_RUNTESTS[:gpu]
                solver = CTSolvers.MadNLPBackend(; linear_solver=linear_solver)
                for (modeler, modeler_name) in zip(modelers, modelers_names)
                    Test.@testset "$(modeler_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                        sol = CommonSolve.solve(elec_prob, elec_init, modeler, solver; display=false)
                        Test.@test sol.status == MadNLP.SOLVE_SUCCEEDED
                    end
                end
            end

            # MadNCL
            if :madncl in SOLVERS_RUNTESTS[:gpu]
                solver = CTSolvers.MadNCLBackend(; linear_solver=linear_solver)
                for (modeler, modeler_name) in zip(modelers, modelers_names)
                    Test.@testset "$(modeler_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                        sol = CommonSolve.solve(elec_prob, elec_init, modeler, solver; display=false)
                        Test.@test sol.status == MadNLP.SOLVE_SUCCEEDED
                    end
                end
            end
        end
    end

end