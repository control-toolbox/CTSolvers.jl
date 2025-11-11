function test_solvers()

    # use specific function to solve problems
    Test.@testset "Solve (specific)" verbose=VERBOSE showtiming=SHOWTIMING begin
        Test.@testset "NLPModelsIpopt" verbose=VERBOSE showtiming=SHOWTIMING begin
            Test.@testset "Rosenbrock" verbose=VERBOSE showtiming=SHOWTIMING begin
                modelers = [CTSolvers.ADNLPModelBackend(; backend=:manual), CTSolvers.ExaModelBackend()]
                modelers_names = ["ADNLPModelBackend (manual)", "ExaModelBackend (CPU)"]
                for (modeler, modeler_name) in zip(modelers, modelers_names)
                    Test.@testset "$(modeler_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                        nlp_adnlp = CTSolvers.build_model(rosenbrock_prob, rosenbrock_init, modeler)
                        sol = CTSolvers.solve_with_ipopt(nlp_adnlp;
                            max_iter=100,
                            tol=1e-6,
                            print_level=0,
                            mu_strategy="adaptive",
                            linear_solver="Mumps",
                            sb="yes", 
                        )
                        Test.@test sol.status == :first_order
                        Test.@test sol.solution ≈ rosenbrock_solu atol=1e-6
                        Test.@test sol.objective ≈ rosenbrock_objective(rosenbrock_solu) atol=1e-6
                    end
                end
            end
        end
        Test.@testset "MadNLP" verbose=VERBOSE showtiming=SHOWTIMING begin
            Test.@testset "Rosenbrock" verbose=VERBOSE showtiming=SHOWTIMING begin
                BaseType = Float32
                modelers = [CTSolvers.ADNLPModelBackend(; backend=:manual), CTSolvers.ExaModelBackend(; base_type=BaseType)]
                modelers_names = ["ADNLPModelBackend (manual)", "ExaModelBackend (CPU)"]
                linear_solvers = [MadNLP.UmfpackSolver, MadNLPMumps.MumpsSolver]
                linear_solvers_names = ["Umfpack", "Mumps"]
                for (modeler, modeler_name) in zip(modelers, modelers_names)
                    for (linear_solver, linear_solver_name) in zip(linear_solvers, linear_solvers_names)
                        Test.@testset "$(modeler_name), $(linear_solver_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                            nlp = CTSolvers.build_model(rosenbrock_prob, rosenbrock_init, modeler)
                            sol = CTSolvers.solve_with_madnlp(nlp;
                                max_iter=100,
                                tol=1e-6,
                                print_level=MadNLP.ERROR,
                                linear_solver=linear_solver,
                            )
                            Test.@test sol.status == MadNLP.SOLVE_SUCCEEDED
                            Test.@test sol.solution ≈ rosenbrock_solu atol=1e-6
                            Test.@test sol.objective ≈ rosenbrock_objective(rosenbrock_solu) atol=1e-6
                        end
                    end
                end
            end
        end
    end

    # Generic solvers
    Test.@testset "Solve (generic)" verbose=VERBOSE showtiming=SHOWTIMING begin
        Test.@testset "NLPModelsIpopt" verbose=VERBOSE showtiming=SHOWTIMING begin
            modelers = [CTSolvers.ADNLPModelBackend(; backend=:manual), CTSolvers.ExaModelBackend()]
            modelers_names = ["ADNLPModelBackend (manual)", "ExaModelBackend (CPU)"]
            Test.@testset "solve" verbose=VERBOSE showtiming=SHOWTIMING begin
                for (modeler, modeler_name) in zip(modelers, modelers_names)
                    Test.@testset "$(modeler_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                        sol = CommonSolve.solve(rosenbrock_prob, rosenbrock_init, modeler, CTSolvers.NLPModelsIpoptBackend(; print_level=0))
                        Test.@test sol.status == :first_order
                        Test.@test sol.solution ≈ rosenbrock_solu atol=1e-6
                        Test.@test sol.objective ≈ rosenbrock_objective(rosenbrock_solu) atol=1e-6
                    end
                end
            end
            Test.@testset "initial_guess" verbose=VERBOSE showtiming=SHOWTIMING begin
                for (modeler, modeler_name) in zip(modelers, modelers_names)
                    Test.@testset "$(modeler_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                        sol = CommonSolve.solve(rosenbrock_prob, rosenbrock_solu, modeler, CTSolvers.NLPModelsIpoptBackend(; print_level=0, max_iter=0))
                        Test.@test sol.solution ≈ rosenbrock_solu atol=1e-6
                    end
                end
            end
        end
        Test.@testset "MadNLP" verbose=VERBOSE showtiming=SHOWTIMING begin
            BaseType = Float32
            modelers = [CTSolvers.ADNLPModelBackend(; backend=:manual), CTSolvers.ExaModelBackend(; base_type=BaseType)]
            modelers_names = ["ADNLPModelBackend (manual)", "ExaModelBackend (CPU)"]
            linear_solvers = [MadNLP.UmfpackSolver, MadNLPMumps.MumpsSolver]
            linear_solvers_names = ["Umfpack", "Mumps"]
            Test.@testset "solve" verbose=VERBOSE showtiming=SHOWTIMING begin
                for (modeler, modeler_name) in zip(modelers, modelers_names)
                    for (linear_solver, linear_solver_name) in zip(linear_solvers, linear_solvers_names)
                        Test.@testset "$(modeler_name), $(linear_solver_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                            sol = CommonSolve.solve(rosenbrock_prob, rosenbrock_init, modeler, CTSolvers.MadNLPBackend(; print_level=MadNLP.ERROR, linear_solver=linear_solver))
                            Test.@test sol.status == MadNLP.SOLVE_SUCCEEDED
                            Test.@test sol.solution ≈ rosenbrock_solu atol=1e-6
                            Test.@test sol.objective ≈ rosenbrock_objective(rosenbrock_solu) atol=1e-6
                        end
                    end
                end
            end
            Test.@testset "initial_guess" verbose=VERBOSE showtiming=SHOWTIMING begin
                for (modeler, modeler_name) in zip(modelers, modelers_names)
                    for (linear_solver, linear_solver_name) in zip(linear_solvers, linear_solvers_names)
                        Test.@testset "$(modeler_name), $(linear_solver_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                            sol = CommonSolve.solve(rosenbrock_prob, rosenbrock_solu, modeler, CTSolvers.MadNLPBackend(; print_level=MadNLP.ERROR, max_iter=0, linear_solver=linear_solver))
                            Test.@test sol.solution ≈ rosenbrock_solu atol=1e-6
                        end
                    end
                end
            end
        end
    end

end