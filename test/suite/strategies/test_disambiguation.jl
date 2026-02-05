"""
Unit tests for option disambiguation helper route_to().

Tests the behavior of the route_to() helper function for creating
disambiguated option values with strategy routing tags.
"""
module TestDisambiguation

using Test
using CTSolvers
using CTSolvers.Strategies

# Test options for verbose output
const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

function test_disambiguation()
    @testset "Option Disambiguation" verbose=VERBOSE showtiming=SHOWTIMING begin
        
        # ====================================================================
        # UNIT TESTS - Basic Functionality
        # ====================================================================
        
        @testset "Basic Tuple Creation" begin
            result = Strategies.route_to(:solver, 100)
            @test result isa Tuple
            @test length(result) == 2
            @test result[1] == 100
            @test result[2] == :solver
        end
        
        @testset "Different Value Types" begin
            # Integer value
            result = Strategies.route_to(:modeler, 42)
            @test result == (42, :modeler)
            
            # Float value
            result = Strategies.route_to(:solver, 1.5e-6)
            @test result == (1.5e-6, :solver)
            
            # String value
            result = Strategies.route_to(:optimizer, "ipopt")
            @test result == ("ipopt", :optimizer)
            
            # Boolean value
            result = Strategies.route_to(:solver, true)
            @test result == (true, :solver)
            
            # Symbol value
            result = Strategies.route_to(:modeler, :auto)
            @test result == (:auto, :modeler)
        end
        
        @testset "Different Strategy Identifiers" begin
            # Common strategy identifiers
            @test Strategies.route_to(:solver, 100) == (100, :solver)
            @test Strategies.route_to(:modeler, 100) == (100, :modeler)
            @test Strategies.route_to(:optimizer, 100) == (100, :optimizer)
            @test Strategies.route_to(:discretizer, 100) == (100, :discretizer)
        end
        
        # ====================================================================
        # UNIT TESTS - Complex Values
        # ====================================================================
        
        @testset "Complex Value Types" begin
            # Array value
            result = Strategies.route_to(:solver, [1, 2, 3])
            @test result == ([1, 2, 3], :solver)
            
            # Tuple value
            result = Strategies.route_to(:modeler, (1, 2))
            @test result == ((1, 2), :modeler)
            
            # NamedTuple value
            result = Strategies.route_to(:solver, (a=1, b=2))
            @test result == ((a=1, b=2), :solver)
        end
        
        # ====================================================================
        # UNIT TESTS - Equivalence with Manual Tuple
        # ====================================================================
        
        @testset "Equivalence with Manual Tuple Creation" begin
            value = 100
            strategy = :solver
            
            # route_to should be equivalent to manual tuple creation
            @test Strategies.route_to(strategy, value) == (value, strategy)
            @test Strategies.route_to(:modeler, 1e-6) == (1e-6, :modeler)
        end
        
        # ====================================================================
        # UNIT TESTS - Type Stability
        # ====================================================================
        
        @testset "Type Stability" begin
            # Test that route_to is type-stable
            @test @inferred(Strategies.route_to(:solver, 100)) == (100, :solver)
            @test @inferred(Strategies.route_to(:modeler, 1.5)) == (1.5, :modeler)
        end
        
        # ====================================================================
        # UNIT TESTS - Edge Cases
        # ====================================================================
        
        @testset "Edge Cases" begin
            # Nothing value
            result = Strategies.route_to(:solver, nothing)
            @test result == (nothing, :solver)
            
            # Missing value
            result = Strategies.route_to(:solver, missing)
            @test result[1] === missing
            @test result[2] == :solver
        end
    end
end

end # module

# Export test function to outer scope
test_disambiguation() = TestDisambiguation.test_disambiguation()
