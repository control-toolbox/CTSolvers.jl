module TestKnitroExtension

using Test
using CTBase: CTBase, Exceptions
using CTSolvers
using CTSolvers.Solvers
using CTSolvers.Strategies
using CTSolvers.Options
using NLPModels
using ADNLPModels
using NLPModelsKnitro
using Main.TestProblems: Rosenbrock, Elec, rosenbrock_objective

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

"""
    test_knitro_extension()

Tests for KnitroSolver extension.

🧪 **Applying Testing Rule**: Unit Tests + Integration Tests

Tests the complete KnitroSolver functionality including metadata, constructor,
and problem solving. Note: Knitro is a commercial solver requiring a license.
"""
function test_knitro_extension()
    Test.@testset "Knitro Extension" verbose=VERBOSE showtiming=SHOWTIMING begin
        
        
        # ====================================================================
        # UNIT TESTS - Metadata and Options
        # ====================================================================
        
        Test.@testset "Metadata" begin
            meta = Strategies.metadata(Solvers.KnitroSolver)
            
            Test.@test meta isa Strategies.StrategyMetadata
            Test.@test length(meta) > 0
            
            # Test that key options are defined
            Test.@test :maxit in keys(meta)
            Test.@test :maxtime in keys(meta)
            Test.@test :feastol_abs in keys(meta)
            Test.@test :opttol_abs in keys(meta)
            Test.@test :outlev in keys(meta)
            
            # Test option types
            Test.@test meta[:maxit].type == Integer
            Test.@test meta[:maxtime].type == Real
            Test.@test meta[:feastol_abs].type == Real
            Test.@test meta[:opttol_abs].type == Real
            Test.@test meta[:outlev].type == Integer
            
            # Test default values exist
            Test.@test meta[:maxit].default isa Integer
            Test.@test meta[:maxtime].default isa Real
            Test.@test meta[:feastol_abs].default isa Real
        end
        
        # ====================================================================
        # UNIT TESTS - Constructor
        # ====================================================================
        
        Test.@testset "Constructor" begin
            # Default constructor
            solver = Solvers.KnitroSolver()
            Test.@test solver isa Solvers.KnitroSolver
            Test.@test solver isa Solvers.AbstractOptimizationSolver
            
            # Constructor with options
            solver_custom = Solvers.KnitroSolver(maxit=100, feastol_abs=1e-6)
            Test.@test solver_custom isa Solvers.KnitroSolver
            
            # Test Strategies.options() returns StrategyOptions
            opts = Strategies.options(solver)
            Test.@test opts isa Strategies.StrategyOptions
        end
        
        # ====================================================================
        # UNIT TESTS - Options Extraction
        # ====================================================================
        
        Test.@testset "Options Extraction" begin
            solver = Solvers.KnitroSolver(maxit=500, feastol_abs=1e-8)
            opts = Strategies.options(solver)
            
            # Extract raw options (returns NamedTuple)
            raw_opts = Options.extract_raw_options(opts.options)
            Test.@test raw_opts isa NamedTuple
            Test.@test haskey(raw_opts, :maxit)
            Test.@test haskey(raw_opts, :feastol_abs)
            Test.@test haskey(raw_opts, :outlev)
            
            # Verify values
            Test.@test raw_opts[:maxit] == 500
            Test.@test raw_opts[:feastol_abs] == 1e-8
            Test.@test raw_opts[:outlev] == 3
        end
        
        # ====================================================================
        # UNIT TESTS - Display Flag Handling
        # ====================================================================
        
        Test.@testset "Display Flag" begin
            # Create a simple problem
            nlp = ADNLPModels.ADNLPModel(x -> sum(x.^2), [1.0, 2.0])
            
            # Test with display=false sets outlev=0
            solver_verbose = Solvers.KnitroSolver(maxit=10, outlev=2)
            
            # Verify the solver accepts the display parameter
            Test.@test_nowarn solver_verbose(nlp; display=false)
            Test.@test_nowarn solver_verbose(nlp; display=true)
        end
        
        # ====================================================================
        # INTEGRATION TESTS - Solving Problems (if license available)
        # ====================================================================
        
        Test.@testset "Rosenbrock Problem - ADNLPModels" begin
            ros = Rosenbrock()
            
            # Build NLP model from problem
            adnlp_builder = CTSolvers.get_adnlp_model_builder(ros.prob)
            nlp = adnlp_builder(ros.init)
            
            # Create solver with appropriate options
            solver = Solvers.KnitroSolver(
                maxit=1000,
                feastol_abs=1e-6,
                opttol_abs=1e-6,
                outlev=0
            )
            
            # Solve the problem
            stats = solver(nlp; display=false)
            
            # Check convergence
            Test.@test stats.status == :first_order
            Test.@test stats.solution ≈ ros.sol atol=1e-6
            Test.@test stats.objective ≈ rosenbrock_objective(ros.sol) atol=1e-6
        end
        
        Test.@testset "Elec Problem - ADNLPModels" begin
            elec = Elec()
            
            # Build NLP model
            adnlp_builder = CTSolvers.get_adnlp_model_builder(elec.prob)
            nlp = adnlp_builder(elec.init)
            
            solver = Solvers.KnitroSolver(
                maxit=1000,
                feastol_abs=1e-6,
                opttol_abs=1e-6,
                outlev=0
            )
            
            stats = solver(nlp; display=false)
            
            # Just check it converges
            Test.@test stats.status == :first_order
        end
        
        # ====================================================================
        # INTEGRATION TESTS - Option Aliases
        # ====================================================================
        
        Test.@testset "Option Aliases" begin
            # Test that aliases work
            solver1 = Solvers.KnitroSolver(maxit=100)
            solver2 = Solvers.KnitroSolver(maxiter=100)
            
            opts1 = Strategies.options(solver1)
            opts2 = Strategies.options(solver2)
            
            raw1 = Options.extract_raw_options(opts1.options)
            raw2 = Options.extract_raw_options(opts2.options)
            
            # Both should set maxit
            Test.@test raw1[:maxit] == 100
            Test.@test raw2[:maxit] == 100
        end
    end
end

end # module

test_knitro_extension() = TestKnitroExtension.test_knitro_extension()
