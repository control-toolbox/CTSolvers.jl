function test_ctsolvers_extensions_gpu()

    if !is_cuda_on()
        @info "CUDA not functional, skipping CTSolvers GPU extension tests"
        return
    end

    exa_backend = CUDA.CUDABackend()
    linear_solver = MadNLPGPU.CUDSSSolver
    modelers = [CTSolvers.ExaModeler(; backend=exa_backend)]
    modelers_names = ["ExaModeler (GPU)"]

    # MadNLP on Rosenbrock and Elec (GPU execution stats)
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

end
