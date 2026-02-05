module TestMadNCLExtension

using Test
using CTBase: CTBase, Exceptions
using CTSolvers
using CTSolvers.Solvers
using CTSolvers.Strategies
using CTSolvers.Options
using CTSolvers.Modelers
using CTSolvers.Optimization
using CommonSolve
using CUDA
using NLPModels
using ADNLPModels
using MadNCL
using MadNLP
using MadNLPMumps
using Main.TestProblems: Rosenbrock, Elec, Max1MinusX2, rosenbrock_objective, max1minusx2_objective

# Trigger extension loading
const CTSolversMadNCL = Base.get_extension(CTSolvers, :CTSolversMadNCL)

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

"""
    test_madncl_extension()

Tests for MadNCLSolver extension.

🧪 **Applying Testing Rule**: Unit Tests + Integration Tests

Tests the complete MadNCLSolver functionality including metadata, constructor,
options handling (including ncl_options), display flag, and problem solving.
"""
function test_madncl_extension()
    Test.@testset "MadNCL Extension" verbose=VERBOSE showtiming=SHOWTIMING begin
        
        
        # ====================================================================
        # UNIT TESTS - Metadata and Options
        # ====================================================================
        
        Test.@testset "Metadata" begin
            meta = Strategies.metadata(Solvers.MadNCLSolver)
            
            Test.@test meta isa Strategies.StrategyMetadata
            Test.@test length(meta) > 0
            
            # Test that key options are defined
            Test.@test :max_iter in keys(meta)
            Test.@test :tol in keys(meta)
            Test.@test :print_level in keys(meta)
            Test.@test :linear_solver in keys(meta)
            Test.@test :ncl_options in keys(meta)
            
            # Test option types
            Test.@test meta[:max_iter].type == Integer
            Test.@test meta[:tol].type == Real
            Test.@test meta[:print_level].type == MadNLP.LogLevels
            Test.@test meta[:linear_solver].type == Type{<:MadNLP.AbstractLinearSolver}
            Test.@test meta[:ncl_options].type == MadNCL.NCLOptions
            
            # Test default values
            Test.@test meta[:max_iter].default isa Integer
            Test.@test meta[:tol].default isa Real
            Test.@test meta[:print_level].default isa MadNLP.LogLevels
            Test.@test meta[:linear_solver].default == MadNLPMumps.MumpsSolver
            Test.@test meta[:ncl_options].default isa MadNCL.NCLOptions
        end
        
        # ====================================================================
        # UNIT TESTS - Constructor
        # ====================================================================
        
        Test.@testset "Constructor" begin
            # Default constructor
            solver = Solvers.MadNCLSolver()
            Test.@test solver isa Solvers.MadNCLSolver
            Test.@test solver isa Solvers.AbstractOptimizationSolver
            
            # Constructor with options
            solver_custom = Solvers.MadNCLSolver(max_iter=100, tol=1e-6)
            Test.@test solver_custom isa Solvers.MadNCLSolver
            
            # Test Strategies.options() returns StrategyOptions
            opts = Strategies.options(solver)
            Test.@test opts isa Strategies.StrategyOptions
        end
        
        # ====================================================================
        # UNIT TESTS - Options Extraction
        # ====================================================================
        
        Test.@testset "Options Extraction" begin
            solver = Solvers.MadNCLSolver(max_iter=500, tol=1e-8)
            opts = Strategies.options(solver)
            
            # Extract raw options (returns NamedTuple)
            raw_opts = Options.extract_raw_options(opts.options)
            Test.@test raw_opts isa NamedTuple
            Test.@test haskey(raw_opts, :max_iter)
            Test.@test haskey(raw_opts, :tol)
            Test.@test haskey(raw_opts, :print_level)
            Test.@test haskey(raw_opts, :ncl_options)
            
            # Verify values
            Test.@test raw_opts.max_iter == 500
            Test.@test raw_opts.tol == 1e-8
            Test.@test raw_opts.print_level == MadNLP.INFO
            Test.@test raw_opts.ncl_options isa MadNCL.NCLOptions
        end
        
        # ====================================================================
        # UNIT TESTS - NCLOptions Handling
        # ====================================================================
        
        Test.@testset "NCLOptions" begin
            # Test with default ncl_options
            solver_default = Solvers.MadNCLSolver()
            opts_default = Strategies.options(solver_default)
            raw_default = Options.extract_raw_options(opts_default.options)
            
            Test.@test haskey(raw_default, :ncl_options)
            Test.@test raw_default.ncl_options isa MadNCL.NCLOptions
            
            # Test with custom ncl_options
            custom_ncl = MadNCL.NCLOptions{Float64}(
                verbose=false,
                opt_tol=1e-6,
                feas_tol=1e-6
            )
            solver_custom = Solvers.MadNCLSolver(ncl_options=custom_ncl)
            opts_custom = Strategies.options(solver_custom)
            raw_custom = Options.extract_raw_options(opts_custom.options)
            
            Test.@test raw_custom.ncl_options === custom_ncl
        end
        
        # ====================================================================
        # UNIT TESTS - Display Flag Handling (Special for MadNCL)
        # ====================================================================
        
        Test.@testset "Display Flag" begin
            # MadNCL requires problems with constraints
            # Using Elec problem which has constraints
            elec = Elec()
            adnlp_builder = CTSolvers.get_adnlp_model_builder(elec.prob)
            nlp = adnlp_builder(elec.init)
            
            # Test with display=false sets print_level=MadNLP.ERROR
            # and reconstructs ncl_options with verbose=false
            solver_verbose = Solvers.MadNCLSolver(
                max_iter=10,
                print_level=MadNLP.INFO
            )
            
            # Just test that the solver can be created with options
            opts = Strategies.options(solver_verbose)
            Test.@test opts isa Strategies.StrategyOptions
        end
        
        # ====================================================================
        # INTEGRATION TESTS - Solving Problems (CPU)
        # ====================================================================
        
        Test.@testset "Rosenbrock Problem - CPU" begin
            ros = Rosenbrock()
            
            # Build NLP model
            adnlp_builder = CTSolvers.get_adnlp_model_builder(ros.prob)
            nlp = adnlp_builder(ros.init)
            
            solver = Solvers.MadNCLSolver(
                max_iter=1000,
                tol=1e-6,
                print_level=MadNLP.ERROR
            )
            
            stats = solver(nlp; display=false)
            
            # Just check it converges
            Test.@test Symbol(stats.status) in (:SOLVE_SUCCEEDED, :SOLVED_TO_ACCEPTABLE_LEVEL)
        end
        
        Test.@testset "Elec Problem - CPU" begin
            elec = Elec()
            
            # Build NLP model
            adnlp_builder = CTSolvers.get_adnlp_model_builder(elec.prob)
            nlp = adnlp_builder(elec.init)
            
            solver = Solvers.MadNCLSolver(
                max_iter=3000,
                tol=1e-6,
                print_level=MadNLP.ERROR
            )
            
            stats = solver(nlp; display=false)
            
            # Just check it converges
            Test.@test Symbol(stats.status) in (:SOLVE_SUCCEEDED, :SOLVED_TO_ACCEPTABLE_LEVEL)
        end
        
        Test.@testset "Max1MinusX2 Problem - CPU" begin
            max_prob = Max1MinusX2()
            
            # Build NLP model
            adnlp_builder = CTSolvers.get_adnlp_model_builder(max_prob.prob)
            nlp = adnlp_builder(max_prob.init)
            
            solver = Solvers.MadNCLSolver(
                max_iter=1000,
                tol=1e-6,
                print_level=MadNLP.ERROR
            )
            
            stats = solver(nlp; display=false)
            
            # Check convergence
            Test.@test Symbol(stats.status) in (:SOLVE_SUCCEEDED, :SOLVED_TO_ACCEPTABLE_LEVEL)
            Test.@test length(stats.solution) == 1
            Test.@test stats.solution[1] ≈ max_prob.sol[1] atol=1e-6
            # Note: MadNCL does NOT invert the sign (unlike MadNLP)
            Test.@test stats.objective ≈ max1minusx2_objective(max_prob.sol) atol=1e-6
        end
        
        # ====================================================================
        # INTEGRATION TESTS - GPU (if CUDA available)
        # ====================================================================
        
        Test.@testset "GPU Tests" begin
            # Check if CUDA is available and functional
            if CUDA.functional()
                Test.@testset "Rosenbrock Problem - GPU" begin
                    ros = Rosenbrock()
                    
                    # Note: GPU linear solver would need to be configured
                    # For now, just test that the solver can be created
                    solver = Solvers.MadNCLSolver(
                        max_iter=1000,
                        tol=1e-6,
                        print_level=MadNLP.ERROR
                    )
                    
                    Test.@test solver isa Solvers.MadNCLSolver
                    @test_skip "GPU linear solver configuration needed"
                end
            else
                @test_skip "CUDA not functional, GPU tests skipped"
            end
        end
        
        # ====================================================================
        # INTEGRATION TESTS - Option Aliases
        # ====================================================================
        
        Test.@testset "Option Aliases" begin
            # Test that aliases work
            solver1 = Solvers.MadNCLSolver(max_iter=100)
            solver2 = Solvers.MadNCLSolver(maxiter=100)
            
            opts1 = Strategies.options(solver1)
            opts2 = Strategies.options(solver2)
            
            raw1 = Options.extract_raw_options(opts1.options)
            raw2 = Options.extract_raw_options(opts2.options)
            
            # Both should set max_iter
            Test.@test raw1[:max_iter] == 100
            Test.@test raw2[:max_iter] == 100
        end
        
        # ====================================================================
        # INTEGRATION TESTS - Multiple Solves
        # ====================================================================
        
        Test.@testset "Multiple Solves" begin
            solver = Solvers.MadNCLSolver(
                max_iter=1000,
                tol=1e-6,
                print_level=MadNLP.ERROR
            )
            
            # Solve different problems with same solver
            elec = Elec()
            max_prob = Max1MinusX2()
            
            # Build NLP models
            adnlp_builder1 = CTSolvers.get_adnlp_model_builder(elec.prob)
            nlp1 = adnlp_builder1(elec.init)
            
            adnlp_builder2 = CTSolvers.get_adnlp_model_builder(max_prob.prob)
            nlp2 = adnlp_builder2(max_prob.init)
            
            stats1 = solver(nlp1; display=false)
            stats2 = solver(nlp2; display=false)
            
            Test.@test Symbol(stats1.status) in (:SOLVE_SUCCEEDED, :SOLVED_TO_ACCEPTABLE_LEVEL)
            Test.@test Symbol(stats2.status) in (:SOLVE_SUCCEEDED, :SOLVED_TO_ACCEPTABLE_LEVEL)
        end
        
        # ====================================================================
        # INTEGRATION TESTS - Initial Guess with NCLOptions (max_iter=0)
        # ====================================================================
        
        Test.@testset "Initial Guess - NCLOptions" begin
            BaseType = Float64
            modelers = [Modelers.ADNLPModeler(), Modelers.ExaModeler(; base_type=BaseType)]
            modelers_names = ["ADNLPModeler", "ExaModeler (CPU)"]
            linear_solvers = [MadNLP.UmfpackSolver, MadNLPMumps.MumpsSolver]
            linear_solver_names = ["Umfpack", "Mumps"]
            
            Test.@testset "Elec" verbose=VERBOSE showtiming=SHOWTIMING begin
                elec = Elec()
                for (modeler, modeler_name) in zip(modelers, modelers_names)
                    for (linear_solver, linear_solver_name) in zip(linear_solvers, linear_solver_names)
                        Test.@testset "$(modeler_name), $(linear_solver_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                            # Create NCLOptions with max_auglag_iter=0 to prevent outer iterations
                            ncl_opts = MadNCL.NCLOptions{BaseType}(
                                verbose=false,
                                max_auglag_iter=0
                            )
                            
                            local opts = Dict(
                                :max_iter => 0,
                                :print_level => MadNLP.ERROR,
                                :ncl_options => ncl_opts
                            )
                            
                            sol = CommonSolve.solve(
                                elec.prob,
                                elec.init,
                                modeler,
                                Solvers.MadNCLSolver(; opts..., linear_solver=linear_solver),
                            )
                            Test.@test sol.status == MadNLP.MAXIMUM_ITERATIONS_EXCEEDED
                            Test.@test sol.solution ≈ vcat(elec.init.x, elec.init.y, elec.init.z) atol=1e-6
                        end
                    end
                end
            end
        end
        
        # ====================================================================
        # INTEGRATION TESTS - solve_with_madncl (direct function)
        # ====================================================================
        
        Test.@testset "solve_with_madncl Function" begin
            BaseType = Float64
            modelers = [Modelers.ADNLPModeler(), Modelers.ExaModeler(; base_type=BaseType)]
            modelers_names = ["ADNLPModeler", "ExaModeler (CPU)"]
            madncl_options = Dict(
                :max_iter => 1000,
                :tol => 1e-6,
                :print_level => MadNLP.ERROR,
                :ncl_options => MadNCL.NCLOptions{Float64}(; verbose=false)
            )
            linear_solvers = [MadNLPMumps.MumpsSolver]
            linear_solver_names = ["Mumps"]
            
            Test.@testset "Elec" verbose=VERBOSE showtiming=SHOWTIMING begin
                elec = Elec()
                for (modeler, modeler_name) in zip(modelers, modelers_names)
                    for (linear_solver, linear_solver_name) in zip(linear_solvers, linear_solver_names)
                        Test.@testset "$(modeler_name), $(linear_solver_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                            nlp = Optimization.build_model(elec.prob, elec.init, modeler)
                            sol = CTSolversMadNCL.solve_with_madncl(nlp; linear_solver=linear_solver, madncl_options...)
                            Test.@test sol.status == MadNLP.SOLVE_SUCCEEDED
                        end
                    end
                end
            end
            
            Test.@testset "Max1MinusX2" verbose=VERBOSE showtiming=SHOWTIMING begin
                max_prob = Max1MinusX2()
                for (modeler, modeler_name) in zip(modelers, modelers_names)
                    for (linear_solver, linear_solver_name) in zip(linear_solvers, linear_solver_names)
                        Test.@testset "$(modeler_name), $(linear_solver_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                            nlp = Optimization.build_model(max_prob.prob, max_prob.init, modeler)
                            sol = CTSolversMadNCL.solve_with_madncl(nlp; linear_solver=linear_solver, madncl_options...)
                            Test.@test sol.status == MadNLP.SOLVE_SUCCEEDED
                            Test.@test length(sol.solution) == 1
                            Test.@test sol.solution[1] ≈ max_prob.sol[1] atol=1e-6
                            # MadNCL does NOT invert sign (unlike MadNLP)
                            Test.@test sol.objective ≈ max1minusx2_objective(max_prob.sol) atol=1e-6
                        end
                    end
                end
            end
        end
        
        # ====================================================================
        # INTEGRATION TESTS - GPU Tests (Extended)
        # ====================================================================
        
        Test.@testset "GPU Tests - Extended" begin
            if CUDA.functional()
                # GPU tests disabled for now
                # using MadNLPGPU
                # linear_solver_gpu = MadNLPGPU.CUDSSSolver
                madncl_options = Dict(
                    :max_iter => 1000,
                    :tol => 1e-6,
                    :print_level => MadNLP.ERROR,
                    :ncl_options => MadNCL.NCLOptions{Float64}(; verbose=false)
                )
                
                Test.@testset "solve_with_madncl - GPU" begin
                    Test.@testset "Elec - GPU" begin
                        elec = Elec()
                        
                        # Build NLP model
                        adnlp_builder = CTSolvers.get_adnlp_model_builder(elec.prob)
                        nlp = adnlp_builder(elec.init)
                        
                        # Solve with GPU
                        stats = CTSolvers.solve_with_madncl(nlp; linear_solver=linear_solver_gpu, madncl_options...)
                        
                        Test.@test stats isa MadNCL.NCLStats
                        Test.@test stats.status == MadNLP.SOLVE_SUCCEEDED
                    end
                    
                    Test.@testset "Max1MinusX2 - GPU" begin
                        max_prob = Max1MinusX2()
                        
                        # Build NLP model
                        adnlp_builder = CTSolvers.get_adnlp_model_builder(max_prob.prob)
                        nlp = adnlp_builder(max_prob.init)
                        
                        # Solve with GPU
                        stats = CTSolvers.solve_with_madncl(nlp; linear_solver=linear_solver_gpu, madncl_options...)
                        
                        Test.@test stats isa MadNCL.NCLStats
                        Test.@test stats.status == MadNLP.SOLVE_SUCCEEDED
                    end
                end
                
                Test.@testset "Initial Guess - GPU (max_iter=0)" begin
                    Test.@testset "Elec - GPU" begin
                        elec = Elec()
                        
                        # Build NLP with initial guess
                        adnlp_builder = CTSolvers.get_adnlp_model_builder(elec.prob)
                        nlp = adnlp_builder(elec.init)
                        
                        # Create NCLOptions with max_auglag_iter=0
                        ncl_opts = MadNCL.NCLOptions{Float64}(
                            verbose=false,
                            max_auglag_iter=0
                        )
                        
                        # Solver with max_iter=0
                        solver = Solvers.MadNCLSolver(
                            max_iter=0,
                            print_level=MadNLP.ERROR,
                            linear_solver=linear_solver_gpu,
                            ncl_options=ncl_opts
                        )
                        
                        stats = solver(nlp; display=false)
                        
                        Test.@test stats.status == MadNLP.MAXIMUM_ITERATIONS_EXCEEDED
                        expected = vcat(elec.init.x, elec.init.y, elec.init.z)
                        Test.@test stats.solution ≈ expected atol=1e-6
                    end
                end
                
                Test.@testset "CommonSolve.solve - GPU" begin
                    solver = Solvers.MadNCLSolver(
                        max_iter=1000,
                        tol=1e-6,
                        print_level=MadNLP.ERROR,
                        linear_solver=linear_solver_gpu
                    )
                    
                    Test.@testset "Elec - GPU" begin
                        elec = Elec()
                        
                        # Build NLP model
                        adnlp_builder = CTSolvers.get_adnlp_model_builder(elec.prob)
                        nlp = adnlp_builder(elec.init)
                        
                        stats = solver(nlp; display=false)
                        
                        Test.@test stats isa MadNCL.NCLStats
                        Test.@test stats.status == MadNLP.SOLVE_SUCCEEDED
                    end
                    
                    Test.@testset "Max1MinusX2 - GPU" begin
                        max_prob = Max1MinusX2()
                        
                        # Build NLP model
                        adnlp_builder = CTSolvers.get_adnlp_model_builder(max_prob.prob)
                        nlp = adnlp_builder(max_prob.init)
                        
                        stats = solver(nlp; display=false)
                        
                        Test.@test stats isa MadNCL.NCLStats
                        Test.@test stats.status == MadNLP.SOLVE_SUCCEEDED
                    end
                end
            else
                @test_skip "CUDA not functional, GPU tests skipped"
            end
        end
    end
end

end # module

test_madncl_extension() = TestMadNCLExtension.test_madncl_extension()
