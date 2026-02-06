module TestSolverTypes

using Test
using CTBase: CTBase, Exceptions
using CTSolvers
using CTSolvers.Solvers
using CTSolvers.Strategies

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

"""
    test_solver_types()

Tests for solver type hierarchy and contracts.

🧪 **Applying Testing Rule**: Contract-First Testing

Tests the basic type hierarchy and Strategies.id() contract for all solvers
without requiring extensions to be loaded.
"""
function test_solver_types()
    Test.@testset "Solver Types and Contracts" verbose=VERBOSE showtiming=SHOWTIMING begin
        
        # ====================================================================
        # UNIT TESTS - Type Hierarchy
        # ====================================================================
        
        Test.@testset "Type Hierarchy" begin
            # All solver types should inherit from AbstractOptimizationSolver
            Test.@test Solvers.IpoptSolver <: Solvers.AbstractOptimizationSolver
            Test.@test Solvers.MadNLPSolver <: Solvers.AbstractOptimizationSolver
            Test.@test Solvers.MadNCLSolver <: Solvers.AbstractOptimizationSolver
            # Commented out - no Knitro license available
            # Test.@test Solvers.KnitroSolver <: Solvers.AbstractOptimizationSolver
            
            # AbstractOptimizationSolver should be abstract
            Test.@test isabstracttype(Solvers.AbstractOptimizationSolver)
            
            # Concrete solver types should not be abstract
            Test.@test !isabstracttype(Solvers.IpoptSolver)
            Test.@test !isabstracttype(Solvers.MadNLPSolver)
            Test.@test !isabstracttype(Solvers.MadNCLSolver)
            # Commented out - no Knitro license available
            # Test.@test !isabstracttype(Solvers.KnitroSolver)
        end
        
        # ====================================================================
        # UNIT TESTS - Strategies.id() Contract
        # ====================================================================
        
            Test.@testset "Strategies.id() Contract" begin
                # Test that each solver type has a unique identifier
                Test.@test Strategies.id(Solvers.IpoptSolver) === :ipopt
                # Commented out - no Knitro license available
                # Test.@test Strategies.id(Solvers.KnitroSolver) === :knitro
                Test.@test Strategies.id(Solvers.MadNLPSolver) === :madnlp
                Test.@test Strategies.id(Solvers.MadNCLSolver) === :madncl
                
                # Test that all IDs are unique
                ids = [
                    Strategies.id(Solvers.IpoptSolver),
                    # Commented out - no Knitro license available
                    # Strategies.id(Solvers.KnitroSolver),
                    Strategies.id(Solvers.MadNLPSolver),
                    Strategies.id(Solvers.MadNCLSolver)
                ]
            Test.@test length(unique(ids)) == 3
            
            # Test that IDs are Symbols
            Test.@test Strategies.id(Solvers.IpoptSolver) isa Symbol
            # Commented out - no Knitro license available
            # Test.@test Strategies.id(Solvers.KnitroSolver) isa Symbol
            Test.@test Strategies.id(Solvers.MadNLPSolver) isa Symbol
            Test.@test Strategies.id(Solvers.MadNCLSolver) isa Symbol
        end
        
        # ====================================================================
        # UNIT TESTS - Tag Types
        # ====================================================================
        
        Test.@testset "Tag Types" begin
            # Test that tag types exist and inherit from AbstractTag
            Test.@test Solvers.IpoptTag <: Solvers.AbstractTag
            # Commented out - no Knitro license available
            # Test.@test Solvers.KnitroTag <: Solvers.AbstractTag
            Test.@test Solvers.MadNLPTag <: Solvers.AbstractTag
            Test.@test Solvers.MadNCLTag <: Solvers.AbstractTag
            
            # Test that AbstractTag is abstract
            Test.@test isabstracttype(Solvers.AbstractTag)
            
            # Test that concrete tag types are not abstract
            Test.@test !isabstracttype(Solvers.IpoptTag)
            # Commented out - no Knitro license available
            # Test.@test !isabstracttype(Solvers.KnitroTag)
            Test.@test !isabstracttype(Solvers.MadNLPTag)
            Test.@test !isabstracttype(Solvers.MadNCLTag)
            
            # Test that tag types can be instantiated
            Test.@test_nowarn Solvers.IpoptTag()
            # Commented out - no Knitro license available
            # Test.@test_nowarn Solvers.KnitroTag()
            Test.@test_nowarn Solvers.MadNLPTag()
            Test.@test_nowarn Solvers.MadNCLTag()
        end
        
        # ====================================================================
        # UNIT TESTS - Struct Fields
        # ====================================================================
        
        Test.@testset "Struct Fields" begin
            # All solver structs should have an 'options' field of type StrategyOptions
            # Note: We can't construct solvers without extensions, but we can check field names
            Test.@test :options in fieldnames(Solvers.IpoptSolver)
            # Commented out - no Knitro license available
            # Test.@test :options in fieldnames(Solvers.KnitroSolver)
            Test.@test :options in fieldnames(Solvers.MadNLPSolver)
            Test.@test :options in fieldnames(Solvers.MadNCLSolver)
            
            # Check that there's only one field
            Test.@test length(fieldnames(Solvers.IpoptSolver)) == 1
            # Commented out - no Knitro license available
            # Test.@test length(fieldnames(Solvers.KnitroSolver)) == 1
            Test.@test length(fieldnames(Solvers.MadNLPSolver)) == 1
            Test.@test length(fieldnames(Solvers.MadNCLSolver)) == 1
        end
    end
end

end # module

test_solver_types() = TestSolverTypes.test_solver_types()
