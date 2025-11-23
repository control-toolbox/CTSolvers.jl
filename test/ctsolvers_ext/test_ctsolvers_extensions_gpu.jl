function test_ctsolvers_extensions_gpu()

    if !is_cuda_on()
        @info "CUDA not functional, skipping CTSolvers GPU extension tests"
        return
    end

    exa_backend = CUDA.CUDABackend()
    linear_solver = MadNLPGPU.CUDSSSolver
    modelers = [CTSolvers.ExaModeler(; backend=exa_backend)]
    modelers_names = ["ExaModeler (GPU)"]

    # MadNLP on Elec
    Test.@testset "ctsolvers_ext: MadNLP GPU" verbose=VERBOSE showtiming=SHOWTIMING begin
        solver = CTSolvers.MadNLPSolver(; linear_solver=linear_solver)
        for (modeler, modeler_name) in zip(modelers, modelers_names)
            Test.@testset "$(modeler_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                sol = CommonSolve.solve(elec_prob, elec_init, modeler, solver; display=false)
                Test.@test sol isa CTModels.Solution
                Test.@test CTModels.successful(sol)
                Test.@test isfinite(CTModels.objective(sol))
            end
        end
    end

    # MadNCL on Elec
    Test.@testset "ctsolvers_ext: MadNCL GPU" verbose=VERBOSE showtiming=SHOWTIMING begin
        solver = CTSolvers.MadNCLSolver(; linear_solver=linear_solver)
        for (modeler, modeler_name) in zip(modelers, modelers_names)
            Test.@testset "$(modeler_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                sol = CommonSolve.solve(elec_prob, elec_init, modeler, solver; display=false)
                Test.@test sol isa CTModels.Solution
                Test.@test CTModels.successful(sol)
                Test.@test isfinite(CTModels.objective(sol))
            end
        end
    end

end
