module TestParameters

using Test
using CTSolvers.Strategies
using Main.TestOptions: VERBOSE, SHOWTIMING

function test_parameters()
    @testset "AbstractStrategyParameter Contract" verbose=VERBOSE showtiming=SHOWTIMING begin
        
        # ====================================================================
        # UNIT TESTS - Contract Implementation
        # ====================================================================
        
        @testset "Built-in parameter IDs" begin
            @test Strategies.id(CPU) == :cpu
            @test Strategies.id(GPU) == :gpu
        end
        
        @testset "NotImplemented for parameter without id()" begin
            struct BadParam <: AbstractStrategyParameter end
            @test_throws CTBase.Exceptions.NotImplemented Strategies.id(BadParam)
        end
        
        @testset "Singleton types (no state)" begin
            @test sizeof(CPU) == 0
            @test sizeof(GPU) == 0
            @test fieldcount(CPU) == 0
            @test fieldcount(GPU) == 0
        end
        
        @testset "Parameter inheritance" begin
            @test CPU <: AbstractStrategyParameter
            @test GPU <: AbstractStrategyParameter
            @test AbstractStrategyParameter isa Type
        end
        
        @testset "Parameter type stability" begin
            @test_nowarn @inferred Strategies.id(CPU)
            @test_nowarn @inferred Strategies.id(GPU)
        end
        
        # ====================================================================
        # INTEGRATION TESTS
        # ====================================================================
        
        @testset "Parameter uniqueness" begin
            # CPU and GPU should have different IDs
            @test Strategies.id(CPU) != Strategies.id(GPU)
        end
        
        @testset "Parameter in registry context" begin
            # Test that parameters can be used in registry creation
            # This will be tested more thoroughly in registry tests
            @test Strategies.id(CPU) isa Symbol
            @test Strategies.id(GPU) isa Symbol
        end
    end
end

end # module

# Redefine in outer scope for TestRunner
test_parameters() = TestParameters.test_parameters()
