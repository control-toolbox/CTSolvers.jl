"""
Unit tests for option disambiguation with RoutedOption and route_to().

Tests the behavior of the route_to() helper function and RoutedOption type
for creating disambiguated option values with strategy routing.
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
        # UNIT TESTS - RoutedOption Type
        # ====================================================================
        
        @testset "RoutedOption Type" begin
            # Create RoutedOption directly
            routes = Pair{Symbol, Any}[:solver => 100]
            opt = Strategies.RoutedOption(routes)
            @test opt isa Strategies.RoutedOption
            @test opt.routes == routes
            
            # Empty routes should throw
            @test_throws Exception Strategies.RoutedOption(Pair{Symbol, Any}[])
        end
        
        # ====================================================================
        # UNIT TESTS - route_to() Basic Functionality
        # ====================================================================
        
        @testset "route_to() Single Strategy" begin
            result = Strategies.route_to(solver=100)
            @test result isa Strategies.RoutedOption
            @test length(result.routes) == 1
            @test result.routes[1] == (:solver => 100)
        end
        
        @testset "route_to() Multiple Strategies" begin
            result = Strategies.route_to(solver=100, modeler=50)
            @test result isa Strategies.RoutedOption
            @test length(result.routes) == 2
            @test (:solver => 100) in result.routes
            @test (:modeler => 50) in result.routes
        end
        
        @testset "route_to() No Arguments Error" begin
            @test_throws Exception Strategies.route_to()
        end
        
        # ====================================================================
        # UNIT TESTS - Different Value Types
        # ====================================================================
        
        @testset "Different Value Types" begin
            # Integer value
            result = Strategies.route_to(modeler=42)
            @test result.routes[1] == (:modeler => 42)
            
            # Float value
            result = Strategies.route_to(solver=1.5e-6)
            @test result.routes[1] == (:solver => 1.5e-6)
            
            # String value
            result = Strategies.route_to(optimizer="ipopt")
            @test result.routes[1] == (:optimizer => "ipopt")
            
            # Boolean value
            result = Strategies.route_to(solver=true)
            @test result.routes[1] == (:solver => true)
            
            # Symbol value
            result = Strategies.route_to(modeler=:auto)
            @test result.routes[1] == (:modeler => :auto)
        end
        
        @testset "Different Strategy Identifiers" begin
            # Common strategy identifiers
            @test Strategies.route_to(solver=100).routes[1] == (:solver => 100)
            @test Strategies.route_to(modeler=100).routes[1] == (:modeler => 100)
            @test Strategies.route_to(optimizer=100).routes[1] == (:optimizer => 100)
            @test Strategies.route_to(discretizer=100).routes[1] == (:discretizer => 100)
        end
        
        # ====================================================================
        # UNIT TESTS - Complex Values
        # ====================================================================
        
        @testset "Complex Value Types" begin
            # Array value
            result = Strategies.route_to(solver=[1, 2, 3])
            @test result.routes[1] == (:solver => [1, 2, 3])
            
            # Tuple value
            result = Strategies.route_to(modeler=(1, 2))
            @test result.routes[1] == (:modeler => (1, 2))
            
            # NamedTuple value
            result = Strategies.route_to(solver=(a=1, b=2))
            @test result.routes[1] == (:solver => (a=1, b=2))
        end
        
        # ====================================================================
        # UNIT TESTS - Multiple Strategies Use Cases
        # ====================================================================
        
        @testset "Multiple Strategies with Same Option" begin
            # Different values for different strategies
            result = Strategies.route_to(solver=100, modeler=50, discretizer=200)
            @test length(result.routes) == 3
            @test (:solver => 100) in result.routes
            @test (:modeler => 50) in result.routes
            @test (:discretizer => 200) in result.routes
        end
        
        # ====================================================================
        # UNIT TESTS - Edge Cases
        # ====================================================================
        
        @testset "Edge Cases" begin
            # Nothing value
            result = Strategies.route_to(solver=nothing)
            @test result.routes[1] == (:solver => nothing)
            
            # Missing value
            result = Strategies.route_to(solver=missing)
            @test result.routes[1].first == :solver
            @test result.routes[1].second === missing
        end
    end
end

end # module

# Export test function to outer scope
test_disambiguation() = TestDisambiguation.test_disambiguation()
