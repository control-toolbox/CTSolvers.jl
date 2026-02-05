module TestMadNLPExtension

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
using MadNLP
using MadNLPMumps
using Main.TestProblems: Rosenbrock, Elec, Max1MinusX2, rosenbrock_objective, max1minusx2_objective

# Trigger extension loading
const CTSolversMadNLP = Base.get_extension(CTSolvers, :CTSolversMadNLP)

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

"""
    test_madnlp_extension()

Tests for MadNLPSolver extension.

🧪 **Applying Testing Rule**: Unit Tests + Integration Tests

Tests the complete MadNLPSolver functionality including metadata, constructor,
options handling, display flag, and problem solving on CPU (and GPU if available).
"""
function test_madnlp_extension()
    Test.@testset "MadNLP Extension" verbose=VERBOSE showtiming=SHOWTIMING begin
        
        
        # ====================================================================
        # UNIT TESTS - Metadata and Options
        # ====================================================================
        
        Test.@testset "Metadata" begin
            meta = Strategies.metadata(Solvers.MadNLPSolver)
            
            Test.@test meta isa Strategies.StrategyMetadata
            Test.@test length(meta) > 0
            
            # Test that key options are defined
            Test.@test :max_iter in keys(meta)
            Test.@test :tol in keys(meta)
            Test.@test :print_level in keys(meta)
            Test.@test :linear_solver in keys(meta)
            
            # Test option types
            Test.@test meta[:max_iter].type == Integer
            Test.@test meta[:tol].type == Real
            Test.@test meta[:print_level].type == MadNLP.LogLevels
            Test.@test meta[:linear_solver].type == Type{<:MadNLP.AbstractLinearSolver}
            
            # Test default values
            Test.@test meta[:max_iter].default isa Integer
            Test.@test meta[:tol].default isa Real
            Test.@test meta[:print_level].default isa MadNLP.LogLevels
            Test.@test meta[:linear_solver].default == MadNLPMumps.MumpsSolver
        end
        
        # ====================================================================
        # UNIT TESTS - Constructor
        # ====================================================================
        
        Test.@testset "Constructor" begin
            # Default constructor
            solver = Solvers.MadNLPSolver()
            Test.@test solver isa Solvers.MadNLPSolver
            Test.@test solver isa Solvers.AbstractOptimizationSolver
            
            # Constructor with options
            solver_custom = Solvers.MadNLPSolver(max_iter=100, tol=1e-6)
            Test.@test solver_custom isa Solvers.MadNLPSolver
            
            # Test Strategies.options() returns StrategyOptions
            opts = Strategies.options(solver)
            Test.@test opts isa Strategies.StrategyOptions
        end
        
        # ====================================================================
        # UNIT TESTS - Options Extraction
        # ====================================================================
        
        Test.@testset "Options Extraction" begin
            solver = Solvers.MadNLPSolver(max_iter=500, tol=1e-8)
            opts = Strategies.options(solver)
            
            # Extract raw options (returns NamedTuple)
            raw_opts = Options.extract_raw_options(opts.options)
            Test.@test raw_opts isa NamedTuple
            Test.@test haskey(raw_opts, :max_iter)
            Test.@test haskey(raw_opts, :tol)
            Test.@test haskey(raw_opts, :print_level)
            
            # Verify values
            Test.@test raw_opts.max_iter == 500
            Test.@test raw_opts.tol == 1e-8
            Test.@test raw_opts.print_level == MadNLP.INFO
        end
        
        # ====================================================================
        # UNIT TESTS - Display Flag Handling
        # ====================================================================
        
        Test.@testset "Display Flag" begin
            # Create a simple problem
            nlp = ADNLPModels.ADNLPModel(x -> sum(x.^2), [1.0, 2.0])
            
            # Test with display=false sets print_level=MadNLP.ERROR
            solver_verbose = Solvers.MadNLPSolver(
                max_iter=10,
                print_level=MadNLP.INFO
            )
            
            # Verify the solver accepts the display parameter
            Test.@test_nowarn solver_verbose(nlp; display=false)
            Test.@test_nowarn solver_verbose(nlp; display=true)
        end
        
        # ====================================================================
        # INTEGRATION TESTS - Solving Problems (CPU)
        # ====================================================================
        
        Test.@testset "Rosenbrock Problem - CPU" begin
            ros = Rosenbrock()
            
            # Build NLP model
            adnlp_builder = CTSolvers.get_adnlp_model_builder(ros.prob)
            nlp = adnlp_builder(ros.init)
            
            solver = Solvers.MadNLPSolver(
                max_iter=1000,
                tol=1e-6,
                print_level=MadNLP.ERROR,
                linear_solver=MadNLPMumps.MumpsSolver
            )
            
            stats = solver(nlp; display=false)
            
            # Check convergence
            Test.@test stats isa MadNLP.MadNLPExecutionStats
            Test.@test Symbol(stats.status) in (:SOLVE_SUCCEEDED, :SOLVED_TO_ACCEPTABLE_LEVEL)
            Test.@test stats.solution ≈ ros.sol atol=1e-4
        end
        
        Test.@testset "Elec Problem - CPU" begin
            elec = Elec()
            
            # Build NLP model
            adnlp_builder = CTSolvers.get_adnlp_model_builder(elec.prob)
            nlp = adnlp_builder(elec.init)
            
            solver = Solvers.MadNLPSolver(
                max_iter=1000,
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
            
            solver = Solvers.MadNLPSolver(
                max_iter=1000,
                tol=1e-6,
                print_level=MadNLP.ERROR
            )
            
            stats = solver(nlp; display=false)
            
            # Check convergence
            Test.@test Symbol(stats.status) in (:SOLVE_SUCCEEDED, :SOLVED_TO_ACCEPTABLE_LEVEL)
            Test.@test length(stats.solution) == 1
            Test.@test stats.solution[1] ≈ max_prob.sol[1] atol=1e-6
            # Note: MadNLP 0.8 inverts the sign for maximization problems
            Test.@test -stats.objective ≈ max1minusx2_objective(max_prob.sol) atol=1e-6
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
                    solver = Solvers.MadNLPSolver(
                        max_iter=1000,
                        tol=1e-6,
                        print_level=MadNLP.ERROR
                    )
                    
                    Test.@test solver isa Solvers.MadNLPSolver
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
            solver1 = Solvers.MadNLPSolver(max_iter=100)
            solver2 = Solvers.MadNLPSolver(maxiter=100)
            
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
            solver = Solvers.MadNLPSolver(
                max_iter=1000,
                tol=1e-6,
                print_level=MadNLP.ERROR
            )
            
            # Solve different problems with same solver
            ros = Rosenbrock()
            max_prob = Max1MinusX2()
            
            # Build NLP models
            adnlp_builder = CTSolvers.get_adnlp_model_builder(ros.prob)
            nlp1 = adnlp_builder(ros.init)
            
            adnlp_builder2 = CTSolvers.get_adnlp_model_builder(max_prob.prob)
            nlp2 = adnlp_builder2(max_prob.init)
            
            stats1 = solver(nlp1; display=false)
            stats2 = solver(nlp2; display=false)
            
            Test.@test Symbol(stats1.status) in (:SOLVE_SUCCEEDED, :SOLVED_TO_ACCEPTABLE_LEVEL)
            Test.@test Symbol(stats2.status) in (:SOLVE_SUCCEEDED, :SOLVED_TO_ACCEPTABLE_LEVEL)
        end
        
        # ====================================================================
        # INTEGRATION TESTS - Initial Guess with Linear Solvers (max_iter=0)
        # ====================================================================
        
        Test.@testset "Initial Guess - Linear Solvers" begin
            BaseType = Float32
            modelers = [Modelers.ADNLPModeler(), Modelers.ExaModeler(; base_type=BaseType)]
            modelers_names = ["ADNLPModeler", "ExaModeler (CPU)"]
            linear_solvers = [MadNLP.UmfpackSolver, MadNLPMumps.MumpsSolver]
            linear_solver_names = ["Umfpack", "Mumps"]
            
            # Rosenbrock: start at the known solution and enforce max_iter=0
            Test.@testset "Rosenbrock" verbose=VERBOSE showtiming=SHOWTIMING begin
                ros = Rosenbrock()
                for (modeler, modeler_name) in zip(modelers, modelers_names)
                    for (linear_solver, linear_solver_name) in zip(linear_solvers, linear_solver_names)
                        Test.@testset "$(modeler_name), $(linear_solver_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                            local opts = Dict(:max_iter => 0, :print_level => MadNLP.ERROR)
                            sol = CommonSolve.solve(
                                ros.prob,
                                ros.sol,
                                modeler,
                                Solvers.MadNLPSolver(; opts..., linear_solver=linear_solver),
                            )
                            Test.@test sol.status == MadNLP.MAXIMUM_ITERATIONS_EXCEEDED
                            Test.@test sol.solution ≈ ros.sol atol=1e-6
                        end
                    end
                end
            end
            
            # Elec
            Test.@testset "Elec" verbose=VERBOSE showtiming=SHOWTIMING begin
                elec = Elec()
                for (modeler, modeler_name) in zip(modelers, modelers_names)
                    for (linear_solver, linear_solver_name) in zip(linear_solvers, linear_solver_names)
                        Test.@testset "$(modeler_name), $(linear_solver_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                            local opts = Dict(:max_iter => 0, :print_level => MadNLP.ERROR)
                            sol = CommonSolve.solve(
                                elec.prob,
                                elec.init,
                                modeler,
                                Solvers.MadNLPSolver(; opts..., linear_solver=linear_solver),
                            )
                            Test.@test sol.status == MadNLP.MAXIMUM_ITERATIONS_EXCEEDED
                            Test.@test sol.solution ≈ vcat(elec.init.x, elec.init.y, elec.init.z) atol=1e-6
                        end
                    end
                end
            end
        end
        
        # ====================================================================
        # INTEGRATION TESTS - solve_with_madnlp (direct function)
        # ====================================================================
        
        Test.@testset "solve_with_madnlp Function" begin
            BaseType = Float32
            modelers = [Modelers.ADNLPModeler(), Modelers.ExaModeler(; base_type=BaseType)]
            modelers_names = ["ADNLPModeler", "ExaModeler (CPU)"]
            madnlp_options = Dict(:max_iter => 1000, :tol => 1e-6, :print_level => MadNLP.ERROR)
            linear_solvers = [MadNLP.UmfpackSolver, MadNLPMumps.MumpsSolver]
            linear_solver_names = ["Umfpack", "Mumps"]
            
            Test.@testset "Rosenbrock" verbose=VERBOSE showtiming=SHOWTIMING begin
                ros = Rosenbrock()
                for (modeler, modeler_name) in zip(modelers, modelers_names)
                    for (linear_solver, linear_solver_name) in zip(linear_solvers, linear_solver_names)
                        Test.@testset "$(modeler_name), $(linear_solver_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                            nlp = Optimization.build_model(ros.prob, ros.init, modeler)
                            sol = CTSolversMadNLP.solve_with_madnlp(nlp; linear_solver=linear_solver, madnlp_options...)
                            Test.@test sol.status == MadNLP.SOLVE_SUCCEEDED
                            Test.@test sol.solution ≈ ros.sol atol=1e-6
                            Test.@test sol.objective ≈ rosenbrock_objective(ros.sol) atol=1e-6
                        end
                    end
                end
            end
            
            Test.@testset "Elec" verbose=VERBOSE showtiming=SHOWTIMING begin
                elec = Elec()
                for (modeler, modeler_name) in zip(modelers, modelers_names)
                    for (linear_solver, linear_solver_name) in zip(linear_solvers, linear_solver_names)
                        Test.@testset "$(modeler_name), $(linear_solver_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                            nlp = Optimization.build_model(elec.prob, elec.init, modeler)
                            sol = CTSolversMadNLP.solve_with_madnlp(nlp; linear_solver=linear_solver, madnlp_options...)
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
                            sol = CTSolversMadNLP.solve_with_madnlp(nlp; linear_solver=linear_solver, madnlp_options...)
                            Test.@test sol.status == MadNLP.SOLVE_SUCCEEDED
                            Test.@test length(sol.solution) == 1
                            Test.@test sol.solution[1] ≈ max_prob.sol[1] atol=1e-6
                            # MadNLP inverts sign for maximization
                            Test.@test -sol.objective ≈ max1minusx2_objective(max_prob.sol) atol=1e-6
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
                madnlp_options = Dict(:max_iter => 1000, :tol => 1e-6, :print_level => MadNLP.ERROR)
                
                Test.@testset "solve_with_madnlp - GPU" begin
                    Test.@testset "Rosenbrock - GPU" begin
                        ros = Rosenbrock()
                        
                        # Build NLP model
                        adnlp_builder = CTSolvers.get_adnlp_model_builder(ros.prob)
                        nlp = adnlp_builder(ros.init)
                        
                        # Solve with GPU
                        stats = CTSolvers.solve_with_madnlp(nlp; linear_solver=linear_solver_gpu, madnlp_options...)
                        
                        Test.@test stats isa MadNLP.MadNLPExecutionStats
                        Test.@test stats.status == MadNLP.SOLVE_SUCCEEDED
                        Test.@test isfinite(stats.objective)
                        Test.@test stats.objective ≈ rosenbrock_objective(ros.sol) atol=1e-6
                    end
                    
                    Test.@testset "Elec - GPU" begin
                        elec = Elec()
                        
                        # Build NLP model
                        adnlp_builder = CTSolvers.get_adnlp_model_builder(elec.prob)
                        nlp = adnlp_builder(elec.init)
                        
                        # Solve with GPU
                        stats = CTSolvers.solve_with_madnlp(nlp; linear_solver=linear_solver_gpu, madnlp_options...)
                        
                        Test.@test stats isa MadNLP.MadNLPExecutionStats
                        Test.@test stats.status == MadNLP.SOLVE_SUCCEEDED
                        Test.@test isfinite(stats.objective)
                    end
                end
                
                Test.@testset "Initial Guess - GPU (max_iter=0)" begin
                    Test.@testset "Rosenbrock - GPU" begin
                        ros = Rosenbrock()
                        
                        # Build NLP starting at solution
                        adnlp_builder = CTSolvers.get_adnlp_model_builder(ros.prob)
                        nlp = adnlp_builder(ros.sol)
                        
                        # Solver with max_iter=0
                        solver = Solvers.MadNLPSolver(
                            max_iter=0,
                            print_level=MadNLP.ERROR,
                            linear_solver=linear_solver_gpu
                        )
                        
                        stats = solver(nlp; display=false)
                        
                        Test.@test stats.status == MadNLP.MAXIMUM_ITERATIONS_EXCEEDED
                        Test.@test stats.solution ≈ ros.sol atol=1e-6
                    end
                    
                    Test.@testset "Elec - GPU" begin
                        elec = Elec()
                        
                        # Build NLP with initial guess
                        adnlp_builder = CTSolvers.get_adnlp_model_builder(elec.prob)
                        nlp = adnlp_builder(elec.init)
                        
                        # Solver with max_iter=0
                        solver = Solvers.MadNLPSolver(
                            max_iter=0,
                            print_level=MadNLP.ERROR,
                            linear_solver=linear_solver_gpu
                        )
                        
                        stats = solver(nlp; display=false)
                        
                        Test.@test stats.status == MadNLP.MAXIMUM_ITERATIONS_EXCEEDED
                        expected = vcat(elec.init.x, elec.init.y, elec.init.z)
                        Test.@test stats.solution ≈ expected atol=1e-6
                    end
                end
                
                Test.@testset "CommonSolve.solve - GPU" begin
                    solver = Solvers.MadNLPSolver(
                        max_iter=1000,
                        tol=1e-6,
                        print_level=MadNLP.ERROR,
                        linear_solver=linear_solver_gpu
                    )
                    
                    Test.@testset "Rosenbrock - GPU" begin
                        ros = Rosenbrock()
                        
                        # Build NLP model
                        adnlp_builder = CTSolvers.get_adnlp_model_builder(ros.prob)
                        nlp = adnlp_builder(ros.init)
                        
                        stats = solver(nlp; display=false)
                        
                        Test.@test stats isa MadNLP.MadNLPExecutionStats
                        Test.@test stats.status == MadNLP.SOLVE_SUCCEEDED
                        Test.@test isfinite(stats.objective)
                        Test.@test stats.objective ≈ rosenbrock_objective(ros.sol) atol=1e-6
                    end
                    
                    Test.@testset "Elec - GPU" begin
                        elec = Elec()
                        
                        # Build NLP model
                        adnlp_builder = CTSolvers.get_adnlp_model_builder(elec.prob)
                        nlp = adnlp_builder(elec.init)
                        
                        stats = solver(nlp; display=false)
                        
                        Test.@test stats isa MadNLP.MadNLPExecutionStats
                        Test.@test stats.status == MadNLP.SOLVE_SUCCEEDED
                        Test.@test isfinite(stats.objective)
                    end
                end
            else
                @test_skip "CUDA not functional, GPU tests skipped"
            end
        end
    end
end

end # module

test_madnlp_extension() = TestMadNLPExtension.test_madnlp_extension()
