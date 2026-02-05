module TestMadNLPExtension

using Test
using CTBase: CTBase, Exceptions
using CTSolvers
using CTSolvers.Solvers
using CTSolvers.Strategies
using CTSolvers.Options
using NLPModels
using ADNLPModels

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

# MadNLP availability will be checked at test runtime

"""
    test_madnlp_extension()

Tests for MadNLPSolver extension.

🧪 **Applying Testing Rule**: Unit Tests + Integration Tests

Tests the complete MadNLPSolver functionality including metadata, constructor,
options handling, display flag, and problem solving on CPU (and GPU if available).
"""
function test_madnlp_extension()
    Test.@testset "MadNLP Extension" verbose=VERBOSE showtiming=SHOWTIMING begin
        
        # Check if MadNLP packages are available
        madnlp_available = try
            @eval using MadNLP
            @eval using MadNLPMumps
            @eval using Main.TestProblems: Rosenbrock, Elec, Max1MinusX2
            true
        catch
            false
        end
        
        if !madnlp_available
            @test_skip "MadNLP/MadNLPMumps not available - install with: using Pkg; Pkg.add([\"MadNLP\", \"MadNLPMumps\"])"
            return
        end
        
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
            solver = Solvers.MadNLPSolver(
                max_iter=500,
                tol=1e-8,
                print_level=MadNLP.ERROR
            )
            opts = Strategies.options(solver)
            
            # Extract raw options
            raw_opts = Options.extract_raw_options(opts.options)
            Test.@test raw_opts isa Dict
            Test.@test haskey(raw_opts, :max_iter)
            Test.@test haskey(raw_opts, :tol)
            Test.@test haskey(raw_opts, :print_level)
            
            # Verify values
            Test.@test raw_opts[:max_iter] == 500
            Test.@test raw_opts[:tol] == 1e-8
            Test.@test raw_opts[:print_level] == MadNLP.ERROR
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
            
            # Create solver with appropriate options
            solver = Solvers.MadNLPSolver(
                max_iter=3000,
                tol=1e-6,
                print_level=MadNLP.ERROR,
                linear_solver=MadNLPMumps.MumpsSolver
            )
            
            # Solve the problem
            stats = solver(ros.nlp; display=false)
            
            # Check convergence
            Test.@test stats isa MadNLP.MadNLPExecutionStats
            Test.@test Symbol(stats.status) in (:SOLVE_SUCCEEDED, :SOLVED_TO_ACCEPTABLE_LEVEL)
            Test.@test stats.solution ≈ ros.sol atol=1e-4
        end
        
        Test.@testset "Elec Problem - CPU" begin
            elec = Elec()
            
            solver = Solvers.MadNLPSolver(
                max_iter=3000,
                tol=1e-6,
                print_level=MadNLP.ERROR
            )
            
            stats = solver(elec.nlp; display=false)
            
            # Just check it converges
            Test.@test Symbol(stats.status) in (:SOLVE_SUCCEEDED, :SOLVED_TO_ACCEPTABLE_LEVEL)
        end
        
        Test.@testset "Max1MinusX2 Problem - CPU" begin
            max_prob = Max1MinusX2()
            
            solver = Solvers.MadNLPSolver(
                max_iter=1000,
                tol=1e-6,
                print_level=MadNLP.ERROR
            )
            
            stats = solver(max_prob.nlp; display=false)
            
            # Check convergence
            Test.@test Symbol(stats.status) in (:SOLVE_SUCCEEDED, :SOLVED_TO_ACCEPTABLE_LEVEL)
        end
        
        # ====================================================================
        # INTEGRATION TESTS - GPU (if CUDA available)
        # ====================================================================
        
        Test.@testset "GPU Tests" begin
            # Check if CUDA is available
            using CUDA
            
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
            
            stats1 = solver(ros.nlp; display=false)
            stats2 = solver(max_prob.nlp; display=false)
            
            Test.@test Symbol(stats1.status) in (:SOLVE_SUCCEEDED, :SOLVED_TO_ACCEPTABLE_LEVEL)
            Test.@test Symbol(stats2.status) in (:SOLVE_SUCCEEDED, :SOLVED_TO_ACCEPTABLE_LEVEL)
        end
    end
end

end # module

test_madnlp_extension() = TestMadNLPExtension.test_madnlp_extension()
