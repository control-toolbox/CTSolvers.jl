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

    Test.@testset "ctsolvers_ext: initial_guess with MadNCL" verbose=VERBOSE showtiming=SHOWTIMING begin
        BaseType = Float64
        modelers = [
            CTSolvers.ADNLPModeler(; backend=:manual),
            CTSolvers.ExaModeler(; base_type=BaseType),
        ]
        modelers_names = ["ADNLPModeler (manual)", "ExaModeler (CPU)"]
        linear_solvers = [MadNLP.UmfpackSolver, MadNLPMumps.MumpsSolver]
        linear_solvers_names = ["Umfpack", "Mumps"]
        madncl_options = f_madncl_options(BaseType)

        Test.@testset "Elec" verbose=VERBOSE showtiming=SHOWTIMING begin
            for (modeler, modeler_name) in zip(modelers, modelers_names)
                for (linear_solver, linear_solver_name) in zip(linear_solvers, linear_solvers_names)
                    Test.@testset "$(modeler_name), $(linear_solver_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                        local opts = copy(madncl_options)
                        opts[:max_iter] = 0
                        sol = CommonSolve.solve(
                            elec_prob,
                            elec_init,
                            modeler,
                            CTSolvers.MadNCLSolver(; opts..., linear_solver=linear_solver),
                        )
                        Test.@test sol.status == MadNLP.MAXIMUM_ITERATIONS_EXCEEDED
                        Test.@test sol.solution ≈ vcat(elec_init.x, elec_init.y, elec_init.z) atol=1e-6
                    end
                end
            end
        end
    end

    # ------------------------------------------------------------------
    # Initial guess tests (max_iter = 0) for Rosenbrock and Elec
    # ------------------------------------------------------------------

    Test.@testset "ctsolvers_ext: initial_guess with Ipopt" verbose=VERBOSE showtiming=SHOWTIMING begin
        modelers = [
            CTSolvers.ADNLPModeler(; backend=:manual),
            CTSolvers.ExaModeler(),
        ]
        modelers_names = ["ADNLPModeler (manual)", "ExaModeler (CPU)"]

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

    Test.@testset "ctsolvers_ext: initial_guess with MadNLP" verbose=VERBOSE showtiming=SHOWTIMING begin
        BaseType = Float32
        modelers = [
            CTSolvers.ADNLPModeler(; backend=:manual),
            CTSolvers.ExaModeler(; base_type=BaseType),
        ]
        modelers_names = ["ADNLPModeler (manual)", "ExaModeler (CPU)"]
        linear_solvers = [MadNLP.UmfpackSolver, MadNLPMumps.MumpsSolver]
        linear_solvers_names = ["Umfpack", "Mumps"]

        # Rosenbrock
        Test.@testset "Rosenbrock" verbose=VERBOSE showtiming=SHOWTIMING begin
            for (modeler, modeler_name) in zip(modelers, modelers_names)
                for (linear_solver, linear_solver_name) in zip(linear_solvers, linear_solvers_names)
                    Test.@testset "$(modeler_name), $(linear_solver_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                        local opts = copy(madnlp_options)
                        opts[:max_iter] = 0
                        sol = CommonSolve.solve(
                            rosenbrock_prob,
                            rosenbrock_solu,
                            modeler,
                            CTSolvers.MadNLPSolver(; opts..., linear_solver=linear_solver),
                        )
                        Test.@test sol.status == MadNLP.MAXIMUM_ITERATIONS_EXCEEDED
                        Test.@test sol.solution ≈ rosenbrock_solu atol=1e-6
                    end
                end
            end
        end

        # Elec
        Test.@testset "Elec" verbose=VERBOSE showtiming=SHOWTIMING begin
            for (modeler, modeler_name) in zip(modelers, modelers_names)
                for (linear_solver, linear_solver_name) in zip(linear_solvers, linear_solvers_names)
                    Test.@testset "$(modeler_name), $(linear_solver_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                        local opts = copy(madnlp_options)
                        opts[:max_iter] = 0
                        sol = CommonSolve.solve(
                            elec_prob,
                            elec_init,
                            modeler,
                            CTSolvers.MadNLPSolver(; opts..., linear_solver=linear_solver),
                        )
                        Test.@test sol.status == MadNLP.MAXIMUM_ITERATIONS_EXCEEDED
                        Test.@test sol.solution ≈ vcat(elec_init.x, elec_init.y, elec_init.z) atol=1e-6
                    end
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
        linear_solvers = [MadNLP.UmfpackSolver, MadNLPMumps.MumpsSolver]
        linear_solvers_names = ["Umfpack", "Mumps"]

        Test.@testset "Rosenbrock" verbose=VERBOSE showtiming=SHOWTIMING begin
            for (modeler, modeler_name) in zip(modelers, modelers_names)
                for (linear_solver, linear_solver_name) in zip(linear_solvers, linear_solvers_names)
                    Test.@testset "$(modeler_name), $(linear_solver_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                        nlp = CTSolvers.build_model(rosenbrock_prob, rosenbrock_init, modeler)
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
                        nlp = CTSolvers.build_model(elec_prob, elec_init, modeler)
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
                        nlp = CTSolvers.build_model(elec_prob, elec_init, modeler)
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
        linear_solvers = [MadNLP.UmfpackSolver, MadNLPMumps.MumpsSolver]
        linear_solvers_names = ["Umfpack", "Mumps"]

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
        linear_solvers = [MadNLP.UmfpackSolver, MadNLPMumps.MumpsSolver]
        linear_solvers_names = ["Umfpack", "Mumps"]
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
            CTSolvers.ExaModeler(),
        ]
        modelers_names = ["ADNLPModeler (manual)", "ExaModeler (CPU)"]

        Test.@testset "NLP model (Beam DOCP)" verbose=VERBOSE showtiming=SHOWTIMING begin
            for (modeler, modeler_name) in zip(modelers, modelers_names)
                Test.@testset "$(modeler_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                    nlp = CTSolvers.nlp_model(docp, init, modeler)
                    Test.@test nlp isa NLPModels.AbstractNLPModel
                end
            end
        end

        Test.@testset "NLP model (Beam DOCP) with @init" verbose=VERBOSE showtiming=SHOWTIMING begin
            # Build an initial guess for the beam OCP via the @init macro
            init_macro = CTSolvers.@init ocp begin
                x := [0.05, 0.1]
                u := 0.1
            end

            for (modeler, modeler_name) in zip(modelers, modelers_names)
                Test.@testset "$(modeler_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                    nlp = CTSolvers.nlp_model(docp, init_macro, modeler)
                    Test.@test nlp isa NLPModels.AbstractNLPModel
                end
            end
        end

        # Explicit ocp_solution tests on the DOCP, using direct solve_with_* calls
        Test.@testset "ocp_solution from DOCP" verbose=VERBOSE showtiming=SHOWTIMING begin

            # Ipopt
            Test.@testset "Ipopt" verbose=VERBOSE showtiming=SHOWTIMING begin
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

            # MadNLP
            Test.@testset "MadNLP" verbose=VERBOSE showtiming=SHOWTIMING begin
                for (modeler, modeler_name) in zip(modelers, modelers_names)
                    Test.@testset "$(modeler_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                        nlp = CTSolvers.nlp_model(docp, init, modeler)
                        stats = CTSolvers.solve_with_madnlp(nlp; madnlp_options...)
                        sol = CTSolvers.ocp_solution(docp, stats, modeler)
                        Test.@test sol isa CTModels.Solution
                        Test.@test CTModels.successful(sol)
                        Test.@test isfinite(CTModels.objective(sol))
                    end
                end
            end

        end

        # DOCP level: CommonSolve.solve(docp, init, modeler, solver)
        Test.@testset "DOCP level" verbose=VERBOSE showtiming=SHOWTIMING begin
            Test.@testset "Ipopt" verbose=VERBOSE showtiming=SHOWTIMING begin
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

            Test.@testset "MadNLP" verbose=VERBOSE showtiming=SHOWTIMING begin
                for (modeler, modeler_name) in zip(modelers, modelers_names)
                    Test.@testset "$(modeler_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                        solver = CTSolvers.MadNLPSolver(; madnlp_options...)
                        sol = CommonSolve.solve(docp, init, modeler, solver; display=false)
                        Test.@test sol isa CTModels.Solution
                        Test.@test CTModels.successful(sol)
                        Test.@test isfinite(CTModels.objective(sol))
                        Test.@test CTModels.iterations(sol) <= madnlp_options[:max_iter]
                        Test.@test CTModels.constraints_violation(sol) <= 1e-6
                    end
                end
            end
        end

        # OCP level: CommonSolve.solve(ocp, init, discretizer, modeler, solver)
        Test.@testset "OCP level" verbose=VERBOSE showtiming=SHOWTIMING begin
            Test.@testset "Ipopt" verbose=VERBOSE showtiming=SHOWTIMING begin
                for (modeler, modeler_name) in zip(modelers, modelers_names)
                    Test.@testset "$(modeler_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                        solver = CTSolvers.IpoptSolver(; ipopt_options...)
                        sol = CommonSolve.solve(ocp, init, discretizer, modeler, solver; display=false)
                        Test.@test sol isa CTModels.Solution
                        Test.@test CTModels.successful(sol)
                        Test.@test isfinite(CTModels.objective(sol))
                        Test.@test CTModels.iterations(sol) <= ipopt_options[:max_iter]
                        Test.@test CTModels.constraints_violation(sol) <= 1e-6
                    end
                end
            end

            Test.@testset "MadNLP" verbose=VERBOSE showtiming=SHOWTIMING begin
                for (modeler, modeler_name) in zip(modelers, modelers_names)
                    Test.@testset "$(modeler_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                        solver = CTSolvers.MadNLPSolver(; madnlp_options...)
                        sol = CommonSolve.solve(ocp, init, discretizer, modeler, solver; display=false)
                        Test.@test sol isa CTModels.Solution
                        Test.@test CTModels.successful(sol)
                        Test.@test isfinite(CTModels.objective(sol))
                        Test.@test CTModels.iterations(sol) <= madnlp_options[:max_iter]
                        Test.@test CTModels.constraints_violation(sol) <= 1e-6
                    end
                end
            end

            Test.@testset "OCP level with @init (Ipopt, ADNLPModeler)" verbose=VERBOSE showtiming=SHOWTIMING begin
                # Use @init to define the initial guess for the beam OCP, then solve end-to-end.
                init_macro = CTSolvers.@init ocp begin
                    x := [0.05, 0.1]
                    u := 0.1
                end
                modeler = CTSolvers.ADNLPModeler(; backend=:manual)
                solver = CTSolvers.IpoptSolver(; ipopt_options...)
                sol = CommonSolve.solve(ocp, init_macro, discretizer, modeler, solver; display=false)
                Test.@test sol isa CTModels.Solution
                Test.@test CTModels.successful(sol)
                Test.@test isfinite(CTModels.objective(sol))
            end
        end
    end
end
