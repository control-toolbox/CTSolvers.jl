# Unit, integration, and GPU tests for MadNCL CTSolvers extensions.
function test_ctsolvers_extensions_madncl()

    # ========================================================================
    # UNIT: defaults and constructor
    # ========================================================================
    Test.@testset "unit: defaults and constructor" verbose=VERBOSE showtiming=SHOWTIMING begin
        Test.@test CTSolversMadNCL.__mad_ncl_max_iter() == 1000
        Test.@test CTSolversMadNCL.__mad_ncl_print_level() == MadNLP.INFO
        Test.@test CTSolversMadNCL.__mad_ncl_linear_solver() == MadNLPMumps.MumpsSolver

        ref_opts = CTSolversMadNCL.__mad_ncl_ncl_options()

        solver = CTSolvers.MadNCLSolver()
        opts = Dict(CTSolvers._options_values(solver))

        Test.@test opts[:max_iter] == CTSolversMadNCL.__mad_ncl_max_iter()
        Test.@test opts[:print_level] == CTSolversMadNCL.__mad_ncl_print_level()
        Test.@test opts[:linear_solver] == CTSolversMadNCL.__mad_ncl_linear_solver()

        ncl_opts = opts[:ncl_options]
        Test.@test ncl_opts isa MadNCL.NCLOptions{Float64}

        for field in fieldnames(MadNCL.NCLOptions)
            Test.@test getfield(ncl_opts, field) == getfield(ref_opts, field)
        end
    end

    # ========================================================================
    # UNIT: metadata defaults (default_options and option_default)
    # ========================================================================
    Test.@testset "unit: metadata defaults" verbose=VERBOSE showtiming=SHOWTIMING begin
        opts_ncl = CTSolvers.default_options(CTSolvers.MadNCLSolver)
        Test.@test opts_ncl.max_iter == CTSolversMadNCL.__mad_ncl_max_iter()
        Test.@test opts_ncl.print_level == CTSolversMadNCL.__mad_ncl_print_level()
        Test.@test opts_ncl.linear_solver == CTSolversMadNCL.__mad_ncl_linear_solver()
        Test.@test CTSolvers.option_default(:max_iter,    CTSolvers.MadNCLSolver) == CTSolversMadNCL.__mad_ncl_max_iter()
        Test.@test CTSolvers.option_default(:print_level, CTSolvers.MadNCLSolver) == CTSolversMadNCL.__mad_ncl_print_level()
    end

    # ========================================================================
    # Common MadNCL options for integration tests
    # ========================================================================
    f_madncl_options(BaseType) = Dict(
        :max_iter => 1000,
        :tol => 1e-6,
        :print_level => MadNLP.ERROR,
        :ncl_options => MadNCL.NCLOptions{BaseType}(; verbose=false),
    )

    # ========================================================================
    # INTEGRATION: initial_guess with MadNCL (max_iter = 0)
    # ========================================================================
    Test.@testset "integration: initial_guess" verbose=VERBOSE showtiming=SHOWTIMING begin
        BaseType = Float64
        modelers = [
            CTSolvers.ADNLPModeler(),
            CTSolvers.ExaModeler(; base_type=BaseType),
        ]
        modelers_names = ["ADNLPModeler", "ExaModeler (CPU)"]
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

    # ========================================================================
    # INTEGRATION: solve_with_madncl (specific)
    # ========================================================================
    Test.@testset "integration: solve_with_madncl" verbose=VERBOSE showtiming=SHOWTIMING begin
        BaseType = Float64
        modelers = [
            CTSolvers.ADNLPModeler(),
            CTSolvers.ExaModeler(; base_type=BaseType),
        ]
        modelers_names = ["ADNLPModeler", "ExaModeler (CPU)"]
        linear_solvers = [MadNLPMumps.MumpsSolver]
        linear_solvers_names = ["Mumps"]
        madncl_options = f_madncl_options(BaseType)

        Test.@testset "Elec" verbose=VERBOSE showtiming=SHOWTIMING begin
            for (modeler, modeler_name) in zip(modelers, modelers_names)
                for (linear_solver, linear_solver_name) in zip(linear_solvers, linear_solvers_names)
                    Test.@testset "$(modeler_name), $(linear_solver_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                        nlp = CTSolvers.build_model(elec_prob, elec_init, modeler)
                        sol = CTSolvers.solve_with_madncl(
                            nlp; linear_solver=linear_solver, madncl_options...,
                        )
                        Test.@test sol.status == MadNLP.SOLVE_SUCCEEDED
                    end
                end
            end
        end
    end

    # ========================================================================
    # INTEGRATION: CommonSolve.solve with MadNCL
    # ========================================================================
    Test.@testset "integration: CommonSolve.solve" verbose=VERBOSE showtiming=SHOWTIMING begin
        BaseType = Float64
        modelers = [
            CTSolvers.ADNLPModeler(),
            CTSolvers.ExaModeler(; base_type=BaseType),
        ]
        modelers_names = ["ADNLPModeler", "ExaModeler (CPU)"]
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

    # ========================================================================
    # GPU TESTS (only if CUDA functional)
    # ========================================================================
    if !is_cuda_on()
        @info "CUDA not functional, skipping CTSolvers MadNCL GPU extension tests"
        return
    end

    exa_backend = CUDA.CUDABackend()
    linear_solver_gpu = MadNLPGPU.CUDSSSolver
    modelers_gpu = [CTSolvers.ExaModeler(; backend=exa_backend)]
    modelers_gpu_names = ["ExaModeler (GPU)"]

    Test.@testset "gpu" verbose=VERBOSE showtiming=SHOWTIMING begin
        solver = CTSolvers.MadNCLSolver(; linear_solver=linear_solver_gpu)
        for (modeler, modeler_name) in zip(modelers_gpu, modelers_gpu_names)
            Test.@testset "$(modeler_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                stats = CommonSolve.solve(elec_prob, elec_init, modeler, solver; display=false)
                Test.@test stats isa MadNCL.NCLStats
                Test.@test stats.status == MadNLP.SOLVE_SUCCEEDED
            end
        end
    end

end
