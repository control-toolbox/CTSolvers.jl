# Unit, integration, and GPU tests for MadNLP CTSolvers extensions.
function test_ctsolvers_extensions_madnlp()

    # ========================================================================
    # Problems
    # ========================================================================
    ros = Rosenbrock()
    elec = Elec()
    maxd = Max1MinusX2()

    # ========================================================================
    # UNIT: defaults and constructor
    # ========================================================================
    Test.@testset "unit: defaults and constructor" verbose=VERBOSE showtiming=SHOWTIMING begin
        Test.@test CTSolversMadNLP.__mad_nlp_max_iter() == 1000
        Test.@test CTSolversMadNLP.__mad_nlp_tol() == 1e-8
        Test.@test CTSolversMadNLP.__mad_nlp_print_level() == MadNLP.INFO
        Test.@test CTSolversMadNLP.__mad_nlp_linear_solver() == MadNLPMumps.MumpsSolver

        solver = CTSolvers.MadNLPSolver()
        opts = Dict(pairs(CTSolvers._options_values(solver)))

        Test.@test opts[:max_iter] == CTSolversMadNLP.__mad_nlp_max_iter()
        Test.@test opts[:tol] == CTSolversMadNLP.__mad_nlp_tol()
        Test.@test opts[:print_level] == CTSolversMadNLP.__mad_nlp_print_level()
        Test.@test opts[:linear_solver] == CTSolversMadNLP.__mad_nlp_linear_solver()
    end

    # ========================================================================
    # UNIT: metadata defaults (default_options and option_default)
    # ========================================================================
    Test.@testset "unit: metadata defaults" verbose=VERBOSE showtiming=SHOWTIMING begin
        opts_mad = CTSolvers.default_options(CTSolvers.MadNLPSolver)
        Test.@test opts_mad.max_iter == CTSolversMadNLP.__mad_nlp_max_iter()
        Test.@test opts_mad.tol == CTSolversMadNLP.__mad_nlp_tol()
        Test.@test opts_mad.print_level == CTSolversMadNLP.__mad_nlp_print_level()

        solver_inst = CTSolvers.MadNLPSolver()
        madnlp_type = typeof(solver_inst)

        opts_mad_from_inst = CTSolvers.default_options(madnlp_type)
        Test.@test opts_mad_from_inst == opts_mad

        keys_type = CTSolvers.options_keys(CTSolvers.MadNLPSolver)
        keys_inst = CTSolvers.options_keys(madnlp_type)
        Test.@test Set(keys_inst) == Set(keys_type)

        Test.@test CTSolvers.option_default(:max_iter, CTSolvers.MadNLPSolver) == CTSolversMadNLP.__mad_nlp_max_iter()
        Test.@test CTSolvers.option_default(:tol,      CTSolvers.MadNLPSolver) == CTSolversMadNLP.__mad_nlp_tol()

        Test.@test CTSolvers.option_default(:max_iter, madnlp_type) == CTSolversMadNLP.__mad_nlp_max_iter()
        Test.@test CTSolvers.option_default(:tol,      madnlp_type) == CTSolversMadNLP.__mad_nlp_tol()
    end

    # ========================================================================
    # Common MadNLP options for integration tests
    # ========================================================================
    madnlp_options = Dict(
        :max_iter => 1000,
        :tol => 1e-6,
        :print_level => MadNLP.ERROR,
    )

    # ========================================================================
    # INTEGRATION: initial_guess with MadNLP (max_iter = 0)
    # ========================================================================
    Test.@testset "integration: initial_guess" verbose=VERBOSE showtiming=SHOWTIMING begin
        BaseType = Float32
        modelers = [
            CTSolvers.ADNLPModeler(),
            CTSolvers.ExaModeler(; base_type=BaseType),
        ]
        modelers_names = ["ADNLPModeler", "ExaModeler (CPU)"]
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
                            ros.prob,
                            ros.sol,
                            modeler,
                            CTSolvers.MadNLPSolver(; opts..., linear_solver=linear_solver),
                        )
                        Test.@test sol.status == MadNLP.MAXIMUM_ITERATIONS_EXCEEDED
                        Test.@test sol.solution ≈ ros.sol atol=1e-6
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
                            elec.prob,
                            elec.init,
                            modeler,
                            CTSolvers.MadNLPSolver(; opts..., linear_solver=linear_solver),
                        )
                        Test.@test sol.status == MadNLP.MAXIMUM_ITERATIONS_EXCEEDED
                        Test.@test sol.solution ≈ vcat(elec.init.x, elec.init.y, elec.init.z) atol=1e-6
                    end
                end
            end
        end
    end

    # ========================================================================
    # INTEGRATION: solve_with_madnlp (specific)
    # ========================================================================
    Test.@testset "integration: solve_with_madnlp" verbose=VERBOSE showtiming=SHOWTIMING begin
        BaseType = Float32
        modelers = [
            CTSolvers.ADNLPModeler(),
            CTSolvers.ExaModeler(; base_type=BaseType),
        ]
        modelers_names = ["ADNLPModeler", "ExaModeler (CPU)"]
        linear_solvers = [MadNLP.UmfpackSolver, MadNLPMumps.MumpsSolver]
        linear_solvers_names = ["Umfpack", "Mumps"]

        Test.@testset "Rosenbrock" verbose=VERBOSE showtiming=SHOWTIMING begin
            for (modeler, modeler_name) in zip(modelers, modelers_names)
                for (linear_solver, linear_solver_name) in zip(linear_solvers, linear_solvers_names)
                    Test.@testset "$(modeler_name), $(linear_solver_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                        nlp = CTSolvers.build_model(ros.prob, ros.init, modeler)
                        sol = CTSolvers.solve_with_madnlp(
                            nlp; linear_solver=linear_solver, madnlp_options...,
                        )
                        Test.@test sol.status == MadNLP.SOLVE_SUCCEEDED
                        Test.@test sol.solution ≈ ros.sol atol=1e-6
                        Test.@test sol.objective ≈ rosenbrock_objective(ros.sol) atol=1e-6
                    end
                end
            end
        end

        Test.@testset "Elec" verbose=VERBOSE showtiming=SHOWTIMING begin
            for (modeler, modeler_name) in zip(modelers, modelers_names)
                for (linear_solver, linear_solver_name) in zip(linear_solvers, linear_solvers_names)
                    Test.@testset "$(modeler_name), $(linear_solver_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                        nlp = CTSolvers.build_model(elec.prob, elec.init, modeler)
                        sol = CTSolvers.solve_with_madnlp(
                            nlp; linear_solver=linear_solver, madnlp_options...,
                        )
                        Test.@test sol.status == MadNLP.SOLVE_SUCCEEDED
                    end
                end
            end
        end

        Test.@testset "Max1MinusX2" verbose=VERBOSE showtiming=SHOWTIMING begin
            for (modeler, modeler_name) in zip(modelers, modelers_names)
                for (linear_solver, linear_solver_name) in zip(linear_solvers, linear_solvers_names)
                    Test.@testset "$(modeler_name), $(linear_solver_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                        nlp = CTSolvers.build_model(maxd.prob, maxd.init, modeler)
                        sol = CTSolvers.solve_with_madnlp(
                            nlp; linear_solver=linear_solver, madnlp_options...,
                        )
                        Test.@test sol.status == MadNLP.SOLVE_SUCCEEDED
                        Test.@test length(sol.solution) == 1
                        Test.@test sol.solution[1] ≈ maxd.sol[1] atol=1e-6
                        Test.@test -sol.objective ≈ max1minusx2_objective(maxd.sol) atol=1e-6
                    end
                end
            end
        end
    end

    # ========================================================================
    # INTEGRATION: CommonSolve.solve with MadNLP
    # ========================================================================
    Test.@testset "integration: CommonSolve.solve" verbose=VERBOSE showtiming=SHOWTIMING begin
        BaseType = Float32
        modelers = [
            CTSolvers.ADNLPModeler(),
            CTSolvers.ExaModeler(; base_type=BaseType),
        ]
        modelers_names = ["ADNLPModeler", "ExaModeler (CPU)"]
        linear_solvers = [MadNLP.UmfpackSolver, MadNLPMumps.MumpsSolver]
        linear_solvers_names = ["Umfpack", "Mumps"]

        Test.@testset "Rosenbrock" verbose=VERBOSE showtiming=SHOWTIMING begin
            for (modeler, modeler_name) in zip(modelers, modelers_names)
                for (linear_solver, linear_solver_name) in zip(linear_solvers, linear_solvers_names)
                    Test.@testset "$(modeler_name), $(linear_solver_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                        sol = CommonSolve.solve(
                            ros.prob,
                            ros.init,
                            modeler,
                            CTSolvers.MadNLPSolver(; madnlp_options..., linear_solver=linear_solver),
                        )
                        Test.@test sol.status == MadNLP.SOLVE_SUCCEEDED
                        Test.@test sol.solution ≈ ros.sol atol=1e-6
                        Test.@test sol.objective ≈ rosenbrock_objective(ros.sol) atol=1e-6
                    end
                end
            end
        end

        Test.@testset "Elec" verbose=VERBOSE showtiming=SHOWTIMING begin
            for (modeler, modeler_name) in zip(modelers, modelers_names)
                for (linear_solver, linear_solver_name) in zip(linear_solvers, linear_solvers_names)
                    Test.@testset "$(modeler_name), $(linear_solver_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                        sol = CommonSolve.solve(
                            elec.prob,
                            elec.init,
                            modeler,
                            CTSolvers.MadNLPSolver(; madnlp_options..., linear_solver=linear_solver),
                        )
                        Test.@test sol.status == MadNLP.SOLVE_SUCCEEDED
                    end
                end
            end
        end

        Test.@testset "Max1MinusX2" verbose=VERBOSE showtiming=SHOWTIMING begin
            for (modeler, modeler_name) in zip(modelers, modelers_names)
                for (linear_solver, linear_solver_name) in zip(linear_solvers, linear_solvers_names)
                    Test.@testset "$(modeler_name), $(linear_solver_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                        sol = CommonSolve.solve(
                            maxd.prob,
                            maxd.init,
                            modeler,
                            CTSolvers.MadNLPSolver(; madnlp_options..., linear_solver=linear_solver),
                        )
                        Test.@test sol.status == MadNLP.SOLVE_SUCCEEDED
                        Test.@test length(sol.solution) == 1
                        Test.@test sol.solution[1] ≈ maxd.sol[1] atol=1e-6
                        Test.@test -sol.objective ≈ max1minusx2_objective(maxd.sol) atol=1e-6
                    end
                end
            end
        end
    end

    # ========================================================================
    # INTEGRATION: Direct beam OCP with Collocation (MadNLP pieces)
    # ========================================================================
    Test.@testset "integration: beam_docp" verbose=VERBOSE showtiming=SHOWTIMING begin
        beam_data = Beam()
        ocp = beam_data.ocp
        init = CTSolvers.initial_guess(ocp; beam_data.init...)
        discretizer = CTSolvers.Collocation()
        docp = CTSolvers.discretize(ocp, discretizer)

        Test.@test docp isa CTSolvers.DiscretizedOptimalControlProblem

        modelers = [
            CTSolvers.ADNLPModeler(),
            CTSolvers.ExaModeler(),
        ]
        modelers_names = ["ADNLPModeler", "ExaModeler (CPU)"]

        # ocp_solution from DOCP using solve_with_madnlp
        Test.@testset "ocp_solution from DOCP (MadNLP)" verbose=VERBOSE showtiming=SHOWTIMING begin
            for (modeler, modeler_name) in zip(modelers, modelers_names)
                Test.@testset "$(modeler_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                    nlp = CTSolvers.nlp_model(docp, init, modeler)
                    stats = CTSolvers.solve_with_madnlp(nlp; madnlp_options...)
                    sol = CTSolvers.ocp_solution(docp, stats, modeler)
                    Test.@test sol isa CTModels.Solution
                    Test.@test CTModels.successful(sol)
                    Test.@test isfinite(CTModels.objective(sol))
                    Test.@test CTModels.objective(sol) ≈ beam_data.obj atol=1e-2
                end
            end
        end

        # DOCP level: CommonSolve.solve(docp, init, modeler, solver)
        Test.@testset "DOCP level (MadNLP)" verbose=VERBOSE showtiming=SHOWTIMING begin
            for (modeler, modeler_name) in zip(modelers, modelers_names)
                Test.@testset "$(modeler_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                    solver = CTSolvers.MadNLPSolver(; madnlp_options...)
                    sol = CommonSolve.solve(docp, init, modeler, solver; display=false)
                    Test.@test sol isa CTModels.Solution
                    Test.@test CTModels.successful(sol)
                    Test.@test isfinite(CTModels.objective(sol))
                    Test.@test CTModels.objective(sol) ≈ beam_data.obj atol=1e-2
                    Test.@test CTModels.iterations(sol) <= madnlp_options[:max_iter]
                    Test.@test CTModels.constraints_violation(sol) <= 1e-6
                end
            end
        end
    end

    # ========================================================================
    # INTEGRATION: Direct Goddard OCP with Collocation (MadNLP pieces)
    # ========================================================================
    Test.@testset "integration: goddard_docp" verbose=VERBOSE showtiming=SHOWTIMING begin
        gdata = Goddard()
        ocp_g = gdata.ocp
        init_g = CTSolvers.initial_guess(ocp_g; gdata.init...)
        discretizer_g = CTSolvers.Collocation()
        docp_g = CTSolvers.discretize(ocp_g, discretizer_g)

        Test.@test docp_g isa CTSolvers.DiscretizedOptimalControlProblem

        modelers = [
            CTSolvers.ADNLPModeler(),
            CTSolvers.ExaModeler(),
        ]
        modelers_names = ["ADNLPModeler", "ExaModeler (CPU)"]

        # ocp_solution from DOCP using solve_with_madnlp
        Test.@testset "ocp_solution from DOCP (MadNLP)" verbose=VERBOSE showtiming=SHOWTIMING begin
            for (modeler, modeler_name) in zip(modelers, modelers_names)
                Test.@testset "$(modeler_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                    nlp = CTSolvers.nlp_model(docp_g, init_g, modeler)
                    stats = CTSolvers.solve_with_madnlp(nlp; madnlp_options...)
                    sol = CTSolvers.ocp_solution(docp_g, stats, modeler)
                    Test.@test sol isa CTModels.Solution
                    Test.@test CTModels.successful(sol)
                    Test.@test isfinite(CTModels.objective(sol))
                    Test.@test CTModels.objective(sol) ≈ gdata.obj atol=1e-4
                end
            end
        end

        # DOCP level: CommonSolve.solve(docp_g, init_g, modeler, solver)
        Test.@testset "DOCP level (MadNLP)" verbose=VERBOSE showtiming=SHOWTIMING begin
            for (modeler, modeler_name) in zip(modelers, modelers_names)
                Test.@testset "$(modeler_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                    solver = CTSolvers.MadNLPSolver(; madnlp_options...)
                    sol = CommonSolve.solve(docp_g, init_g, modeler, solver; display=false)
                    Test.@test sol isa CTModels.Solution
                    Test.@test CTModels.successful(sol)
                    Test.@test isfinite(CTModels.objective(sol))
                    Test.@test CTModels.objective(sol) ≈ gdata.obj atol=1e-4
                    Test.@test CTModels.iterations(sol) <= madnlp_options[:max_iter]
                    Test.@test CTModels.constraints_violation(sol) <= 1e-6
                end
            end
        end
    end

    # ========================================================================
    # GPU TESTS (only if CUDA functional)
    # ========================================================================
    if !is_cuda_on()
        @info "CUDA not functional, skipping CTSolvers MadNLP GPU extension tests"
        return
    end

    exa_backend = CUDA.CUDABackend()
    linear_solver_gpu = MadNLPGPU.CUDSSSolver
    modelers_gpu = [CTSolvers.ExaModeler(; backend=exa_backend)]
    modelers_gpu_names = ["ExaModeler (GPU)"]

    Test.@testset "gpu: solve_with_madnlp" verbose=VERBOSE showtiming=SHOWTIMING begin
        solver = CTSolvers.MadNLPSolver(; linear_solver=linear_solver_gpu)

        # Rosenbrock
        Test.@testset "Rosenbrock" verbose=VERBOSE showtiming=SHOWTIMING begin
            for (modeler, modeler_name) in zip(modelers_gpu, modelers_gpu_names)
                Test.@testset "$(modeler_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                    nlp = CTSolvers.build_model(ros.prob, ros.init, modeler)
                    stats = CTSolvers.solve_with_madnlp(nlp; madnlp_options..., linear_solver=linear_solver_gpu)
                    Test.@test stats isa MadNLP.MadNLPExecutionStats
                    Test.@test stats.status == MadNLP.SOLVE_SUCCEEDED
                    Test.@test isfinite(stats.objective)
                    Test.@test stats.objective ≈ rosenbrock_objective(ros.sol) atol=1e-6
                    Test.@test stats.solution isa CuArray{Float64,1}
                    Test.@test length(stats.solution) == length(ros.init)
                end
            end
        end

        # Elec
        Test.@testset "Elec" verbose=VERBOSE showtiming=SHOWTIMING begin
            for (modeler, modeler_name) in zip(modelers_gpu, modelers_gpu_names)
                Test.@testset "$(modeler_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                    nlp = CTSolvers.build_model(elec.prob, elec.init, modeler)
                    stats = CTSolvers.solve_with_madnlp(nlp; madnlp_options..., linear_solver=linear_solver_gpu)
                    Test.@test stats isa MadNLP.MadNLPExecutionStats
                    Test.@test stats.status == MadNLP.SOLVE_SUCCEEDED
                    Test.@test isfinite(stats.objective)
                    Test.@test stats.solution isa CuArray{Float64,1}
                    Test.@test length(stats.solution) == length(vcat(elec.init.x, elec.init.y, elec.init.z))
                end
            end
        end

        # Max1MinusX2 (GPU tests disabled: MadNLP treats max problems as min on GPU)
        # Test.@testset "Max1MinusX2" verbose=VERBOSE showtiming=SHOWTIMING begin
        #     for (modeler, modeler_name) in zip(modelers_gpu, modelers_gpu_names)
        #         Test.@testset "$(modeler_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
        #             nlp = CTSolvers.build_model(maxd.prob, maxd.init, modeler)
        #             stats = CTSolvers.solve_with_madnlp(nlp; madnlp_options..., linear_solver=linear_solver_gpu)
        #             Test.@test stats isa MadNLP.MadNLPExecutionStats
        #             Test.@test stats.status == MadNLP.SOLVE_SUCCEEDED
        #             Test.@test isfinite(stats.objective)
        #             Test.@test stats.solution isa CuArray{Float64,1}
        #             Test.@test length(stats.solution) == 1
        #         end
        #     end
        # end
    end

    Test.@testset "gpu: initial_guess" verbose=VERBOSE showtiming=SHOWTIMING begin
        # Rosenbrock: start at the known solution and enforce max_iter=0
        Test.@testset "Rosenbrock" verbose=VERBOSE showtiming=SHOWTIMING begin
            for (modeler, modeler_name) in zip(modelers_gpu, modelers_gpu_names)
                Test.@testset "$(modeler_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                    local opts = copy(madnlp_options)
                    opts[:max_iter] = 0
                    stats = CommonSolve.solve(
                        ros.prob,
                        ros.sol,
                        modeler,
                        CTSolvers.MadNLPSolver(; opts..., linear_solver=linear_solver_gpu);
                        display=false,
                    )
                    Test.@test stats isa MadNLP.MadNLPExecutionStats
                    Test.@test stats.status == MadNLP.MAXIMUM_ITERATIONS_EXCEEDED
                    Test.@test stats.solution isa CuArray{Float64,1}
                    Test.@test length(stats.solution) == length(ros.sol)
                    Test.@test Array(stats.solution) ≈ ros.sol atol=1e-6
                end
            end
        end

        # Elec: expect solution to remain equal to the initial guess vector
        Test.@testset "Elec" verbose=VERBOSE showtiming=SHOWTIMING begin
            for (modeler, modeler_name) in zip(modelers_gpu, modelers_gpu_names)
                Test.@testset "$(modeler_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                    local opts = copy(madnlp_options)
                    opts[:max_iter] = 0
                    stats = CommonSolve.solve(
                        elec.prob,
                        elec.init,
                        modeler,
                        CTSolvers.MadNLPSolver(; opts..., linear_solver=linear_solver_gpu);
                        display=false,
                    )
                    Test.@test stats isa MadNLP.MadNLPExecutionStats
                    Test.@test stats.status == MadNLP.MAXIMUM_ITERATIONS_EXCEEDED
                    Test.@test stats.solution isa CuArray{Float64,1}
                    Test.@test length(stats.solution) == length(vcat(elec.init.x, elec.init.y, elec.init.z))
                    Test.@test Array(stats.solution) ≈ vcat(elec.init.x, elec.init.y, elec.init.z) atol=1e-6
                end
            end
        end
    end

    Test.@testset "gpu: CommonSolve.solve" verbose=VERBOSE showtiming=SHOWTIMING begin
        solver = CTSolvers.MadNLPSolver(; linear_solver=linear_solver_gpu)

        # Rosenbrock
        Test.@testset "Rosenbrock" verbose=VERBOSE showtiming=SHOWTIMING begin
            for (modeler, modeler_name) in zip(modelers_gpu, modelers_gpu_names)
                Test.@testset "$(modeler_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                    stats = CommonSolve.solve(
                        ros.prob,
                        ros.init,
                        modeler,
                        solver;
                        display=false,
                    )
                    Test.@test stats isa MadNLP.MadNLPExecutionStats
                    Test.@test stats.status == MadNLP.SOLVE_SUCCEEDED
                    Test.@test isfinite(stats.objective)
                    Test.@test stats.objective ≈ rosenbrock_objective(ros.sol) atol=1e-6
                    Test.@test stats.solution isa CuArray{Float64,1}
                    Test.@test length(stats.solution) == length(ros.init)
                end
            end
        end

        # Elec
        Test.@testset "Elec" verbose=VERBOSE showtiming=SHOWTIMING begin
            for (modeler, modeler_name) in zip(modelers_gpu, modelers_gpu_names)
                Test.@testset "$(modeler_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                    stats = CommonSolve.solve(
                        elec.prob,
                        elec.init,
                        modeler,
                        solver;
                        display=false,
                    )
                    Test.@test stats isa MadNLP.MadNLPExecutionStats
                    Test.@test stats.status == MadNLP.SOLVE_SUCCEEDED
                    Test.@test isfinite(stats.objective)
                    Test.@test stats.solution isa CuArray{Float64,1}
                    Test.@test length(stats.solution) == length(vcat(elec.init.x, elec.init.y, elec.init.z))
                end
            end
        end

        # Max1MinusX2 (GPU tests disabled: MadNLP treats max problems as min on GPU)
        # Test.@testset "Max1MinusX2" verbose=VERBOSE showtiming=SHOWTIMING begin
        #     for (modeler, modeler_name) in zip(modelers_gpu, modelers_gpu_names)
        #         Test.@testset "$(modeler_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
        #             stats = CommonSolve.solve(
        #                 maxd.prob,
        #                 maxd.init,
        #                 modeler,
        #                 solver;
        #                 display=false,
        #             )
        #             Test.@test stats isa MadNLP.MadNLPExecutionStats
        #             Test.@test stats.status == MadNLP.SOLVE_SUCCEEDED
        #             Test.@test isfinite(stats.objective)
        #             Test.@test stats.solution isa CuArray{Float64,1}
        #             Test.@test length(stats.solution) == 1
        #         end
        #     end
        # end
    end

    Test.@testset "gpu: beam_docp" verbose=VERBOSE showtiming=SHOWTIMING begin
        beam_data = Beam()
        ocp = beam_data.ocp
        init = CTSolvers.initial_guess(ocp; beam_data.init...)
        discretizer = CTSolvers.Collocation()
        docp = CTSolvers.discretize(ocp, discretizer)

        Test.@test docp isa CTSolvers.DiscretizedOptimalControlProblem

        for (modeler, modeler_name) in zip(modelers_gpu, modelers_gpu_names)
            Test.@testset "$(modeler_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                solver = CTSolvers.MadNLPSolver(; madnlp_options..., linear_solver=linear_solver_gpu)
                sol = CommonSolve.solve(docp, init, modeler, solver; display=false)
                Test.@test sol isa CTModels.Solution
                Test.@test CTModels.successful(sol)
                Test.@test isfinite(CTModels.objective(sol))
            end
        end
    end

    # gpu: goddard_docp (GPU tests disabled: max problem currently works as min)
    # Test.@testset "gpu: goddard_docp" verbose=VERBOSE showtiming=SHOWTIMING begin
    #     gdata = Goddard()
    #     ocp_g = gdata.ocp
    #     init_g = CTSolvers.initial_guess(ocp_g; gdata.init...)
    #     discretizer_g = CTSolvers.Collocation()
    #     docp_g = CTSolvers.discretize(ocp_g, discretizer_g)
    #
    #     Test.@test docp_g isa CTSolvers.DiscretizedOptimalControlProblem
    #
    #     for (modeler, modeler_name) in zip(modelers_gpu, modelers_gpu_names)
    #         Test.@testset "$(modeler_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
    #             solver = CTSolvers.MadNLPSolver(; madnlp_options..., linear_solver=linear_solver_gpu)
    #             sol = CommonSolve.solve(docp_g, init_g, modeler, solver; display=false)
    #             Test.@test sol isa CTModels.Solution
    #             Test.@test CTModels.successful(sol)
    #             Test.@test isfinite(CTModels.objective(sol))
    #         end
    #     end
    # end

end
