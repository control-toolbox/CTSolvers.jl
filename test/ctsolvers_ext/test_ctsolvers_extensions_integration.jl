function test_ctsolvers_extensions_integration()

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

    Test.@testset "ctsolvers_ext: Solve with Ipopt (specific)" verbose=VERBOSE showtiming=SHOWTIMING begin
        modelers = [
            CTSolvers.ADNLPModeler(; backend=:manual),
            CTSolvers.ExaModeler(),
        ]
        modelers_names = ["ADNLPModeler (manual)", "ExaModeler (CPU)"]

        Test.@testset "Rosenbrock" verbose=VERBOSE showtiming=SHOWTIMING begin
            for (modeler, modeler_name) in zip(modelers, modelers_names)
                Test.@testset "$(modeler_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                    nlp = CTSolvers.nlp_model(rosenbrock_prob, rosenbrock_init, modeler)
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
                    nlp = CTSolvers.nlp_model(elec_prob, elec_init, modeler)
                    sol = CTSolvers.solve_with_ipopt(nlp; ipopt_options...)
                    Test.@test sol.status == :first_order
                end
            end
        end
    end

    Test.@testset "ctsolvers_ext: Solve with MadNLP (specific)" verbose=VERBOSE showtiming=SHOWTIMING begin
        BaseType = Float32
        modelers = [
            CTSolvers.ADNLPModeler(; backend=:manual),
            CTSolvers.ExaModeler(; base_type=BaseType),
        ]
        modelers_names = ["ADNLPModeler (manual)", "ExaModeler (CPU)"]
        linear_solvers = [MadNLPMumps.MumpsSolver]
        linear_solvers_names = ["Mumps"]

        Test.@testset "Rosenbrock" verbose=VERBOSE showtiming=SHOWTIMING begin
            for (modeler, modeler_name) in zip(modelers, modelers_names)
                for (linear_solver, linear_solver_name) in zip(linear_solvers, linear_solvers_names)
                    Test.@testset "$(modeler_name), $(linear_solver_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                        nlp = CTSolvers.nlp_model(rosenbrock_prob, rosenbrock_init, modeler)
                        sol = CTSolvers.solve_with_madnlp(
                            nlp; linear_solver=linear_solver, madnlp_options...
                        )
                        Test.@test sol.status == MadNLP.SOLVE_SUCCEEDED
                        Test.@test sol.solution ≈ rosenbrock_solu atol=1e-6
                        Test.@test sol.objective ≈ rosenbrock_objective(rosenbrock_solu) atol=1e-6
                    end
                end
            end
        end

        Test.@testset "Elec" verbose=VERBOSE showtiming=SHOWTIMING begin
            for (modeler, modeler_name) in zip(modelers, modelers_names)
                for (linear_solver, linear_solver_name) in zip(linear_solvers, linear_solvers_names)
                    Test.@testset "$(modeler_name), $(linear_solver_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                        nlp = CTSolvers.nlp_model(elec_prob, elec_init, modeler)
                        sol = CTSolvers.solve_with_madnlp(
                            nlp; linear_solver=linear_solver, madnlp_options...
                        )
                        Test.@test sol.status == MadNLP.SOLVE_SUCCEEDED
                    end
                end
            end
        end
    end

    Test.@testset "ctsolvers_ext: Solve with MadNCL (specific)" verbose=VERBOSE showtiming=SHOWTIMING begin
        BaseType = Float64
        modelers = [
            CTSolvers.ADNLPModeler(; backend=:manual),
            CTSolvers.ExaModeler(; base_type=BaseType),
        ]
        modelers_names = ["ADNLPModeler (manual)", "ExaModeler (CPU)"]
        linear_solvers = [MadNLPMumps.MumpsSolver]
        linear_solvers_names = ["Mumps"]
        madncl_options = f_madncl_options(BaseType)

        Test.@testset "Elec" verbose=VERBOSE showtiming=SHOWTIMING begin
            for (modeler, modeler_name) in zip(modelers, modelers_names)
                for (linear_solver, linear_solver_name) in zip(linear_solvers, linear_solvers_names)
                    Test.@testset "$(modeler_name), $(linear_solver_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                        nlp = CTSolvers.nlp_model(elec_prob, elec_init, modeler)
                        sol = CTSolvers.solve_with_madncl(
                            nlp; linear_solver=linear_solver, madncl_options...
                        )
                        Test.@test sol.status == MadNLP.SOLVE_SUCCEEDED
                    end
                end
            end
        end
    end

    Test.@testset "ctsolvers_ext: CommonSolve.solve with Ipopt" verbose=VERBOSE showtiming=SHOWTIMING begin
        modelers = [
            CTSolvers.ADNLPModeler(; backend=:manual),
            CTSolvers.ExaModeler(),
        ]
        modelers_names = ["ADNLPModeler (manual)", "ExaModeler (CPU)"]

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

    Test.@testset "ctsolvers_ext: CommonSolve.solve with MadNLP" verbose=VERBOSE showtiming=SHOWTIMING begin
        BaseType = Float32
        modelers = [
            CTSolvers.ADNLPModeler(; backend=:manual),
            CTSolvers.ExaModeler(; base_type=BaseType),
        ]
        modelers_names = ["ADNLPModeler (manual)", "ExaModeler (CPU)"]
        linear_solvers = [MadNLPMumps.MumpsSolver]
        linear_solvers_names = ["Mumps"]

        Test.@testset "Rosenbrock" verbose=VERBOSE showtiming=SHOWTIMING begin
            for (modeler, modeler_name) in zip(modelers, modelers_names)
                for (linear_solver, linear_solver_name) in zip(linear_solvers, linear_solvers_names)
                    Test.@testset "$(modeler_name), $(linear_solver_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                        sol = CommonSolve.solve(
                            rosenbrock_prob,
                            rosenbrock_init,
                            modeler,
                            CTSolvers.MadNLPSolver(; madnlp_options..., linear_solver=linear_solver),
                        )
                        Test.@test sol.status == MadNLP.SOLVE_SUCCEEDED
                        Test.@test sol.solution ≈ rosenbrock_solu atol=1e-6
                        Test.@test sol.objective ≈ rosenbrock_objective(rosenbrock_solu) atol=1e-6
                    end
                end
            end
        end

        Test.@testset "Elec" verbose=VERBOSE showtiming=SHOWTIMING begin
            for (modeler, modeler_name) in zip(modelers, modelers_names)
                for (linear_solver, linear_solver_name) in zip(linear_solvers, linear_solvers_names)
                    Test.@testset "$(modeler_name), $(linear_solver_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                        sol = CommonSolve.solve(
                            elec_prob,
                            elec_init,
                            modeler,
                            CTSolvers.MadNLPSolver(; madnlp_options..., linear_solver=linear_solver),
                        )
                        Test.@test sol.status == MadNLP.SOLVE_SUCCEEDED
                    end
                end
            end
        end
    end

    Test.@testset "ctsolvers_ext: CommonSolve.solve with MadNCL" verbose=VERBOSE showtiming=SHOWTIMING begin
        BaseType = Float64
        modelers = [
            CTSolvers.ADNLPModeler(; backend=:manual),
            CTSolvers.ExaModeler(; base_type=BaseType),
        ]
        modelers_names = ["ADNLPModeler (manual)", "ExaModeler (CPU)"]
        linear_solvers = [MadNLPMumps.MumpsSolver]
        linear_solvers_names = ["Mumps"]
        madncl_options = f_madncl_options(BaseType)

        Test.@testset "Elec" verbose=VERBOSE showtiming=SHOWTIMING begin
            for (modeler, modeler_name) in zip(modelers, modelers_names)
                for (linear_solver, linear_solver_name) in zip(linear_solvers, linear_solvers_names)
                    Test.@testset "$(modeler_name), $(linear_solver_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                        sol = CommonSolve.solve(
                            elec_prob,
                            elec_init,
                            modeler,
                            CTSolvers.MadNCLSolver(; madncl_options..., linear_solver=linear_solver),
                        )
                        Test.@test sol.status == MadNLP.SOLVE_SUCCEEDED
                    end
                end
            end
        end
    end

    Test.@testset "ctsolvers_ext: Direct beam OCP with Collocation" verbose=VERBOSE showtiming=SHOWTIMING begin
        ocp, init = beam()
        discretizer = CTSolvers.Collocation()
        docp = CTSolvers.discretize(ocp, discretizer)

        Test.@test docp isa CTSolvers.DiscretizedOptimalControlProblem

        modelers = [
            CTSolvers.ADNLPModeler(; backend=:manual),
        ]
        modelers_names = ["ADNLPModeler (manual)"]

        Test.@testset "Ipopt" verbose=VERBOSE showtiming=SHOWTIMING begin
            for (modeler, modeler_name) in zip(modelers, modelers_names)
                Test.@testset "$(modeler_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                    solver = CTSolvers.IpoptSolver(; ipopt_options...)
                    sol = CommonSolve.solve(docp, init, modeler, solver)
                    Test.@test sol isa CTModels.Solution
                    Test.@test isfinite(sol.objective)
                end
            end
        end

        Test.@testset "MadNLP" verbose=VERBOSE showtiming=SHOWTIMING begin
            modelers_madnlp = [
                CTSolvers.ADNLPModeler(; backend=:manual),
            ]
            modelers_madnlp_names = ["ADNLPModeler (manual)"]

            for (modeler, modeler_name) in zip(modelers_madnlp, modelers_madnlp_names)
                Test.@testset "$(modeler_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                    solver = CTSolvers.MadNLPSolver(; madnlp_options...)
                    sol = CommonSolve.solve(docp, init, modeler, solver)
                    Test.@test sol isa CTModels.Solution
                    Test.@test isfinite(sol.objective)
                end
            end
        end
    end
end
