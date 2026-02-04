module TestMadNCLExtension

using Test
using CTBase: CTBase, Exceptions
using CTSolvers
using CTSolvers.Solvers
using CTSolvers.Strategies
using CTSolvers.Options
using MadNCL
using MadNLP
using MadNLPMumps
using NLPModels
using ADNLPModels
using Main.TestProblems: Rosenbrock, Elec, Max1MinusX2

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
            solver = Solvers.MadNCLSolver(
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
            Test.@test haskey(raw_opts, :ncl_options)
            
            # Verify values
            Test.@test raw_opts[:max_iter] == 500
            Test.@test raw_opts[:tol] == 1e-8
            Test.@test raw_opts[:print_level] == MadNLP.ERROR
            Test.@test raw_opts[:ncl_options] isa MadNCL.NCLOptions
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
            Test.@test raw_default[:ncl_options] isa MadNCL.NCLOptions
            
            # Test with custom ncl_options
            custom_ncl = MadNCL.NCLOptions{Float64}(
                verbose=false,
                opt_tol=1e-6,
                feas_tol=1e-6
            )
            solver_custom = Solvers.MadNCLSolver(ncl_options=custom_ncl)
            opts_custom = Strategies.options(solver_custom)
            raw_custom = Options.extract_raw_options(opts_custom.options)
            
            Test.@test raw_custom[:ncl_options] === custom_ncl
        end
        
        # ====================================================================
        # UNIT TESTS - Display Flag Handling (Special for MadNCL)
        # ====================================================================
        
        Test.@testset "Display Flag" begin
            # Create a simple problem
            nlp = ADNLPModels.ADNLPModel(x -> sum(x.^2), [1.0, 2.0])
            
            # Test with display=false sets print_level=MadNLP.ERROR
            # and reconstructs ncl_options with verbose=false
            solver_verbose = Solvers.MadNCLSolver(
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
            solver = Solvers.MadNCLSolver(
                max_iter=3000,
                tol=1e-6,
                print_level=MadNLP.ERROR,
                linear_solver=MadNLPMumps.MumpsSolver
            )
            
            # Solve the problem
            stats = solver(ros.nlp; display=false)
            
            # Check convergence
            Test.@test stats isa MadNCL.NCLStats
            Test.@test Symbol(stats.status) in (:SOLVE_SUCCEEDED, :SOLVED_TO_ACCEPTABLE_LEVEL)
            Test.@test stats.solution ≈ ros.sol atol=1e-4
        end
        
        Test.@testset "Elec Problem - CPU" begin
            elec = Elec()
            
            solver = Solvers.MadNCLSolver(
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
            
            solver = Solvers.MadNCLSolver(
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

test_madncl_extension() = TestMadNCLExtension.test_madncl_extension()
