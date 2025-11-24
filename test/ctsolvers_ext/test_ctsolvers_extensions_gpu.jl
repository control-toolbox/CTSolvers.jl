function test_ctsolvers_extensions_gpu()

    if !is_cuda_on()
        @info "CUDA not functional, skipping CTSolvers GPU extension tests"
        return
    end

    exa_backend = CUDA.CUDABackend()
    linear_solver = MadNLPGPU.CUDSSSolver
    modelers = [CTSolvers.ExaModeler(; backend=exa_backend)]
    modelers_names = ["ExaModeler (GPU)"]

    madnlp_options = Dict(
        :max_iter => 1000,
        :tol => 1e-6,
        :print_level => MadNLP.ERROR,
    )

    # ------------------------------------------------------------------
    # MadNLP GPU: solve_with_madnlp on Rosenbrock and Elec
    # ------------------------------------------------------------------

    if VERBOSE
        println("[GPU] ctsonlvers_ext: MadNLP GPU (solve_with_madnlp)")
    end
    Test.@testset "ctsolvers_ext: MadNLP GPU (solve_with_madnlp)" verbose=VERBOSE showtiming=SHOWTIMING begin
        solver = CTSolvers.MadNLPSolver(; linear_solver=linear_solver)

        # Rosenbrock
        Test.@testset "Rosenbrock" verbose=VERBOSE showtiming=SHOWTIMING begin
            for (modeler, modeler_name) in zip(modelers, modelers_names)
                Test.@testset "$(modeler_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                    nlp = CTSolvers.build_model(rosenbrock_prob, rosenbrock_init, modeler)
                    stats = CTSolvers.solve_with_madnlp(nlp; madnlp_options..., linear_solver=linear_solver)
                    Test.@test stats isa MadNLP.MadNLPExecutionStats
                    Test.@test stats.status == MadNLP.SOLVE_SUCCEEDED
                    Test.@test isfinite(stats.objective)
                    Test.@test stats.objective ≈ rosenbrock_objective(rosenbrock_solu) atol=1e-6
                    Test.@test stats.solution isa CuArray{Float64,1}
                    Test.@test length(stats.solution) == length(rosenbrock_init)
                end
            end
        end

        # Elec
        Test.@testset "Elec" verbose=VERBOSE showtiming=SHOWTIMING begin
            for (modeler, modeler_name) in zip(modelers, modelers_names)
                Test.@testset "$(modeler_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                    nlp = CTSolvers.build_model(elec_prob, elec_init, modeler)
                    stats = CTSolvers.solve_with_madnlp(nlp; madnlp_options..., linear_solver=linear_solver)
                    Test.@test stats isa MadNLP.MadNLPExecutionStats
                    Test.@test stats.status == MadNLP.SOLVE_SUCCEEDED
                    Test.@test isfinite(stats.objective)
                    Test.@test stats.solution isa CuArray{Float64,1}
                    Test.@test length(stats.solution) == length(vcat(elec_init.x, elec_init.y, elec_init.z))
                end
            end
        end
    end

    # ------------------------------------------------------------------
    # MadNLP GPU: initial_guess (max_iter = 0) for Rosenbrock and Elec
    # ------------------------------------------------------------------

    if VERBOSE
        println("[GPU] ctsolvers_ext: MadNLP GPU initial_guess")
    end
    Test.@testset "ctsolvers_ext: MadNLP GPU initial_guess" verbose=VERBOSE showtiming=SHOWTIMING begin
        # Rosenbrock: start at the known solution and enforce max_iter=0
        Test.@testset "Rosenbrock" verbose=VERBOSE showtiming=SHOWTIMING begin
            for (modeler, modeler_name) in zip(modelers, modelers_names)
                Test.@testset "$(modeler_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                    local opts = copy(madnlp_options)
                    opts[:max_iter] = 0
                    stats = CommonSolve.solve(
                        rosenbrock_prob,
                        rosenbrock_solu,
                        modeler,
                        CTSolvers.MadNLPSolver(; opts..., linear_solver=linear_solver);
                        display=false,
                    )
                    Test.@test stats isa MadNLP.MadNLPExecutionStats
                    Test.@test stats.status == MadNLP.SOLVE_SUCCEEDED
                    Test.@test stats.solution isa CuArray{Float64,1}
                    Test.@test length(stats.solution) == length(rosenbrock_solu)
                    Test.@test Array(stats.solution) ≈ rosenbrock_solu atol=1e-6
                end
            end
        end

        # Elec: expect solution to remain equal to the initial guess vector
        Test.@testset "Elec" verbose=VERBOSE showtiming=SHOWTIMING begin
            for (modeler, modeler_name) in zip(modelers, modelers_names)
                Test.@testset "$(modeler_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                    local opts = copy(madnlp_options)
                    opts[:max_iter] = 0
                    stats = CommonSolve.solve(
                        elec_prob,
                        elec_init,
                        modeler,
                        CTSolvers.MadNLPSolver(; opts..., linear_solver=linear_solver);
                        display=false,
                    )
                    Test.@test stats isa MadNLP.MadNLPExecutionStats
                    Test.@test stats.status == MadNLP.SOLVE_SUCCEEDED
                    Test.@test stats.solution isa CuArray{Float64,1}
                    Test.@test length(stats.solution) == length(vcat(elec_init.x, elec_init.y, elec_init.z))
                    Test.@test Array(stats.solution) ≈ vcat(elec_init.x, elec_init.y, elec_init.z) atol=1e-6
                end
            end
        end
    end
    # MadNLP on Rosenbrock and Elec (GPU execution stats)
    if VERBOSE
        println("[GPU] ctsolvers_ext: MadNLP GPU (CommonSolve)")
    end
    Test.@testset "ctsolvers_ext: MadNLP GPU" verbose=VERBOSE showtiming=SHOWTIMING begin
        solver = CTSolvers.MadNLPSolver(; linear_solver=linear_solver)

        # Rosenbrock: check that the GPU run reaches the optimal objective
        Test.@testset "Rosenbrock" verbose=VERBOSE showtiming=SHOWTIMING begin
            for (modeler, modeler_name) in zip(modelers, modelers_names)
                Test.@testset "$(modeler_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                    stats = CommonSolve.solve(
                        rosenbrock_prob,
                        rosenbrock_init,
                        modeler,
                        solver;
                        display=false,
                    )
                    Test.@test stats isa MadNLP.MadNLPExecutionStats
                    Test.@test stats.status == MadNLP.SOLVE_SUCCEEDED
                    Test.@test isfinite(stats.objective)
                    Test.@test stats.objective ≈ rosenbrock_objective(rosenbrock_solu) atol=1e-6
                    Test.@test stats.solution isa CuArray{Float64,1}
                    Test.@test length(stats.solution) == length(rosenbrock_init)
                end
            end
        end

        # Elec: check status, objective finiteness, and GPU solution vector shape/type
        Test.@testset "Elec" verbose=VERBOSE showtiming=SHOWTIMING begin
            for (modeler, modeler_name) in zip(modelers, modelers_names)
                Test.@testset "$(modeler_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                    stats = CommonSolve.solve(
                        elec_prob,
                        elec_init,
                        modeler,
                        solver;
                        display=false,
                    )
                    Test.@test stats isa MadNLP.MadNLPExecutionStats
                    Test.@test stats.status == MadNLP.SOLVE_SUCCEEDED
                    Test.@test isfinite(stats.objective)
                    Test.@test stats.solution isa CuArray{Float64,1}
                    Test.@test length(stats.solution) == length(vcat(elec_init.x, elec_init.y, elec_init.z))
                end
            end
        end
    end

    # MadNCL on Elec (GPU execution stats)
    if VERBOSE
        println("[GPU] ctsolvers_ext: MadNCL GPU")
    end
    Test.@testset "ctsolvers_ext: MadNCL GPU" verbose=VERBOSE showtiming=SHOWTIMING begin
        solver = CTSolvers.MadNCLSolver(; linear_solver=linear_solver)
        for (modeler, modeler_name) in zip(modelers, modelers_names)
            Test.@testset "$(modeler_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                stats = CommonSolve.solve(elec_prob, elec_init, modeler, solver; display=false)
                Test.@test stats isa MadNCL.NCLStats
                Test.@test stats.status == MadNLP.SOLVE_SUCCEEDED
            end
        end
    end

    # ------------------------------------------------------------------
    # MadNLP GPU: Beam DOCP with Collocation
    # ------------------------------------------------------------------

    if VERBOSE
        println("[GPU] ctsolvers_ext: MadNLP GPU Beam DOCP")
    end
    Test.@testset "ctsolvers_ext: MadNLP GPU Beam DOCP" verbose=VERBOSE showtiming=SHOWTIMING begin
        ocp, init = beam()
        discretizer = CTSolvers.Collocation()
        docp = CTSolvers.discretize(ocp, discretizer)

        Test.@test docp isa CTSolvers.DiscretizedOptimalControlProblem

        for (modeler, modeler_name) in zip(modelers, modelers_names)
            Test.@testset "$(modeler_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                solver = CTSolvers.MadNLPSolver(; madnlp_options..., linear_solver=linear_solver)
                sol = CommonSolve.solve(docp, init, modeler, solver; display=false)
                Test.@test sol isa CTModels.Solution
                Test.@test CTModels.successful(sol)
                Test.@test isfinite(CTModels.objective(sol))
            end
        end
    end

end
