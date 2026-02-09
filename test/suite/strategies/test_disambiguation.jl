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
            routes = (solver=100,)
            opt = Strategies.RoutedOption(routes)
            @test opt isa Strategies.RoutedOption
            @test collect(pairs(opt)) == collect(pairs(routes))
            
            # Empty routes should throw
            @test_throws Exception Strategies.RoutedOption(NamedTuple())
        end
        
        # ====================================================================
        # UNIT TESTS - route_to() Basic Functionality
        # ====================================================================
        
        @testset "route_to() Single Strategy" begin
            result = Strategies.route_to(solver=100)
            @test result isa Strategies.RoutedOption
            @test length(result) == 1
            @test result[:solver] == 100
        end
        
        @testset "route_to() Multiple Strategies" begin
            result = Strategies.route_to(solver=100, modeler=50)
            @test result isa Strategies.RoutedOption
            @test length(result) == 2
            @test result[:solver] == 100
            @test result[:modeler] == 50
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
            @test result[:modeler] == 42
            
            # Float value
            result = Strategies.route_to(solver=1.5e-6)
            @test result[:solver] == 1.5e-6
            
            # String value
            result = Strategies.route_to(optimizer="ipopt")
            @test result[:optimizer] == "ipopt"
            
            # Boolean value
            result = Strategies.route_to(solver=true)
            @test result[:solver] == true
            
            # Symbol value
            result = Strategies.route_to(modeler=:auto)
            @test result[:modeler] == :auto
        end
        
        @testset "Different Strategy Identifiers" begin
            # Common strategy identifiers
            @test Strategies.route_to(solver=100)[:solver] == 100
            @test Strategies.route_to(modeler=100)[:modeler] == 100
            @test Strategies.route_to(optimizer=100)[:optimizer] == 100
            @test Strategies.route_to(discretizer=100)[:discretizer] == 100
        end
        
        # ====================================================================
        # UNIT TESTS - Complex Values
        # ====================================================================
        
        @testset "Complex Value Types" begin
            # Array value
            result = Strategies.route_to(solver=[1, 2, 3])
            @test result[:solver] == [1, 2, 3]
            
            # Tuple value
            result = Strategies.route_to(modeler=(1, 2))
            @test result[:modeler] == (1, 2)
            
            # NamedTuple value
            result = Strategies.route_to(solver=(a=1, b=2))
            @test result[:solver] == (a=1, b=2)
        end
        
        # ====================================================================
        # UNIT TESTS - Multiple Strategies Use Cases
        # ====================================================================
        
        @testset "Multiple Strategies with Same Option" begin
            # Different values for different strategies
            result = Strategies.route_to(solver=100, modeler=50, discretizer=200)
            @test length(result) == 3
            @test result[:solver] == 100
            @test result[:modeler] == 50
            @test result[:discretizer] == 200
        end
        
        # ====================================================================
        # UNIT TESTS - Edge Cases
        # ====================================================================
        
        @testset "Edge Cases" begin
            # Nothing value
            result = Strategies.route_to(solver=nothing)
            @test result[:solver] === nothing
            
            # Missing value
            result = Strategies.route_to(solver=missing)
            @test result[:solver] === missing
        end

        # ====================================================================
        # UNIT TESTS - Collection Interface
        # ====================================================================

        @testset "Collection Interface - Iteration" begin
            opt = Strategies.route_to(solver=100, modeler=50)

            # Test keys()
            @test :solver in keys(opt)
            @test :modeler in keys(opt)
            @test collect(keys(opt)) == [:solver, :modeler]

            # Test values()
            @test 100 in values(opt)
            @test 50 in values(opt)
            @test collect(values(opt)) == [100, 50]

            # Test pairs()
            pairs_collected = collect(pairs(opt))
            @test length(pairs_collected) == 2
            @test pairs_collected[1] == (:solver => 100)
            @test pairs_collected[2] == (:modeler => 50)

            # Test direct iteration (should yield pairs)
            for (id, val) in opt
                @test id in (:solver, :modeler)
                @test val in (100, 50)
            end

            # Test getindex[]
            @test opt[:solver] == 100
            @test opt[:modeler] == 50

            # Test haskey
            @test haskey(opt, :solver)
            @test haskey(opt, :modeler)
            @test !haskey(opt, :discretizer)

            # Test length
            @test length(opt) == 2
            @test length(Strategies.route_to(solver=1)) == 1
        end
    end
end

end # module

# Export test function to outer scope
test_disambiguation() = TestDisambiguation.test_disambiguation()
