module TestIpoptExtension

using Test
using CTBase: CTBase, Exceptions
using CTSolvers
using CTSolvers.Solvers
using CTSolvers.Strategies
using CTSolvers.Options
using NLPModelsIpopt  # Charge l'extension
using NLPModels
using ADNLPModels
using Main.TestProblems: Rosenbrock, Elec, Max1MinusX2

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

"""
    test_ipopt_extension()

Tests for IpoptSolver extension.

🧪 **Applying Testing Rule**: Unit Tests + Integration Tests

Tests the complete IpoptSolver functionality including metadata, constructor,
options handling, display flag, and problem solving.
"""
function test_ipopt_extension()
    Test.@testset "Ipopt Extension" verbose=VERBOSE showtiming=SHOWTIMING begin
        
        # ====================================================================
        # UNIT TESTS - Metadata and Options
        # ====================================================================
        
        Test.@testset "Metadata" begin
            meta = Strategies.metadata(Solvers.IpoptSolver)
            
            Test.@test meta isa Strategies.StrategyMetadata
            Test.@test length(meta) > 0
            
            # Test that key options are defined
            Test.@test :max_iter in keys(meta)
            Test.@test :tol in keys(meta)
            Test.@test :print_level in keys(meta)
            Test.@test :mu_strategy in keys(meta)
            Test.@test :linear_solver in keys(meta)
            Test.@test :sb in keys(meta)
            
            # Test option types
            Test.@test meta[:max_iter].type == Integer
            Test.@test meta[:tol].type == Real
            Test.@test meta[:print_level].type == Integer
            
            # Test default values exist
            Test.@test meta[:max_iter].default isa Integer
            Test.@test meta[:tol].default isa Real
            Test.@test meta[:print_level].default isa Integer
        end
        
        # ====================================================================
        # UNIT TESTS - Constructor
        # ====================================================================
        
        Test.@testset "Constructor" begin
            # Default constructor
            solver = Solvers.IpoptSolver()
            Test.@test solver isa Solvers.IpoptSolver
            Test.@test solver isa Solvers.AbstractOptimizationSolver
            
            # Constructor with options
            solver_custom = Solvers.IpoptSolver(max_iter=100, tol=1e-6)
            Test.@test solver_custom isa Solvers.IpoptSolver
            
            # Test Strategies.options() returns StrategyOptions
            opts = Strategies.options(solver)
            Test.@test opts isa Strategies.StrategyOptions
            
            opts_custom = Strategies.options(solver_custom)
            Test.@test opts_custom isa Strategies.StrategyOptions
        end
        
        # ====================================================================
        # UNIT TESTS - Options Extraction
        # ====================================================================
        
        Test.@testset "Options Extraction" begin
            solver = Solvers.IpoptSolver(max_iter=500, tol=1e-8, print_level=0)
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
            Test.@test raw_opts[:print_level] == 0
        end
        
        # ====================================================================
        # UNIT TESTS - Display Flag Handling
        # ====================================================================
        
        Test.@testset "Display Flag" begin
            # Create a simple problem
            nlp = ADNLPModels.ADNLPModel(x -> sum(x.^2), [1.0, 2.0])
            
            # Test with display=false sets print_level=0
            solver_verbose = Solvers.IpoptSolver(max_iter=10, print_level=5)
            
            # Note: We can't easily test the internal behavior without actually solving,
            # but we can verify the solver accepts the display parameter
            Test.@test_nowarn solver_verbose(nlp; display=false)
            Test.@test_nowarn solver_verbose(nlp; display=true)
        end
        
        # ====================================================================
        # INTEGRATION TESTS - Solving Problems
        # ====================================================================
        
        Test.@testset "Rosenbrock Problem" begin
            ros = Rosenbrock()
            
            # Create solver with appropriate options
            solver = Solvers.IpoptSolver(
                max_iter=1000,
                tol=1e-6,
                print_level=0,
                mu_strategy="adaptive"
            )
            
            # Solve the problem
            stats = solver(ros.nlp; display=false)
            
            # Check convergence
            Test.@test stats.status == :first_order
            Test.@test stats.solution ≈ ros.sol atol=1e-4
            Test.@test stats.objective ≈ 0.0 atol=1e-6
        end
        
        Test.@testset "Elec Problem" begin
            elec = Elec()
            
            solver = Solvers.IpoptSolver(
                max_iter=1000,
                tol=1e-6,
                print_level=0
            )
            
            stats = solver(elec.nlp; display=false)
            
            # Just check it converges
            Test.@test stats.status == :first_order
        end
        
        Test.@testset "Max1MinusX2 Problem" begin
            max_prob = Max1MinusX2()
            
            solver = Solvers.IpoptSolver(
                max_iter=100,
                tol=1e-6,
                print_level=0
            )
            
            stats = solver(max_prob.nlp; display=false)
            
            # Check convergence
            Test.@test stats.status == :first_order
        end
        
        # ====================================================================
        # INTEGRATION TESTS - Option Aliases
        # ====================================================================
        
        Test.@testset "Option Aliases" begin
            # Test that aliases work
            solver1 = Solvers.IpoptSolver(max_iter=100)
            solver2 = Solvers.IpoptSolver(maxiter=100)
            
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
            solver = Solvers.IpoptSolver(max_iter=100, tol=1e-6, print_level=0)
            
            # Solve different problems with same solver
            ros = Rosenbrock()
            max_prob = Max1MinusX2()
            
            stats1 = solver(ros.nlp; display=false)
            stats2 = solver(max_prob.nlp; display=false)
            
            Test.@test stats1.status == :first_order
            Test.@test stats2.status == :first_order
        end
    end
end

end # module

test_ipopt_extension() = TestIpoptExtension.test_ipopt_extension()
