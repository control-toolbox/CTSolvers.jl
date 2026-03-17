# ============================================================================
# Test describe methods for parameters
# ============================================================================

module TestDescribeParameters

import Test
import CTBase.Exceptions
import CTSolvers
import CTSolvers.Strategies

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

function test_describe_parameters()
    Test.@testset "Parameter Describe" verbose=VERBOSE showtiming=SHOWTIMING begin
        
        # ================================================================
        # UNIT TESTS - Type-direct describe
        # ================================================================
        
        Test.@testset "describe(CPU) - type-direct" begin
            # Capture output
            io = IOBuffer()
            Strategies.describe(io, Strategies.CPU)
            output = String(take!(io))
            
            # Test individual components without relying on exact color formatting
            Test.@test occursin("CPU", output)
            Test.@test occursin("parameter", output)
            Test.@test occursin("id", output)
            Test.@test occursin("cpu", output)
            Test.@test occursin("hierarchy", output)
            Test.@test occursin("AbstractStrategyParameter", output)
            Test.@test occursin("description", output)
            Test.@test occursin("CPU-based", output)
            Test.@test occursin("computation", output)
        end
        
        Test.@testset "describe(GPU) - type-direct" begin
            # Capture output
            io = IOBuffer()
            Strategies.describe(io, Strategies.GPU)
            output = String(take!(io))
            
            # Test individual components without relying on exact color formatting
            Test.@test occursin("GPU", output)
            Test.@test occursin("parameter", output)
            Test.@test occursin("id", output)
            Test.@test occursin("gpu", output)
            Test.@test occursin("hierarchy", output)
            Test.@test occursin("AbstractStrategyParameter", output)
            Test.@test occursin("description", output)
            Test.@test occursin("GPU-based", output)
            Test.@test occursin("computation", output)
        end
        
        # ================================================================
        # UNIT TESTS - description contract
        # ================================================================
        
        Test.@testset "description contract" begin
            # Test built-in implementations
            Test.@test Strategies.description(Strategies.CPU) == "CPU-based computation"
            Test.@test Strategies.description(Strategies.GPU) == "GPU-based computation"
        end
        
        # ================================================================
        # UNIT TESTS - Registry-aware describe
        # ================================================================
        
        Test.@testset "describe(:cpu, registry) - registry-aware" begin
            # Create a registry with parameterized strategies
            registry = CTSolvers.create_registry(
                CTSolvers.AbstractNLPModeler => (
                    (CTSolvers.Exa, [CTSolvers.CPU, CTSolvers.GPU]),
                )
            )
            
            # Capture output
            io = IOBuffer()
            Strategies.describe(io, :cpu, registry)
            output = String(take!(io))
            
            # Test individual components without relying on exact color formatting
            Test.@test occursin("CPU", output)
            Test.@test occursin("parameter", output)
            Test.@test occursin("id", output)
            Test.@test occursin("cpu", output)
            Test.@test occursin("hierarchy", output)
            Test.@test occursin("AbstractStrategyParameter", output)
            Test.@test occursin("description", output)
            Test.@test occursin("CPU-based", output)
            Test.@test occursin("computation", output)
            Test.@test occursin("used", output)
            Test.@test occursin("strategies", output)
            Test.@test occursin("exa", output)
        end
        
        Test.@testset "describe(:gpu, registry) - registry-aware" begin
            # Create a registry with parameterized strategies
            registry = CTSolvers.create_registry(
                CTSolvers.AbstractNLPModeler => (
                    (CTSolvers.Exa, [CTSolvers.CPU, CTSolvers.GPU]),
                )
            )
            
            # Capture output
            io = IOBuffer()
            Strategies.describe(io, :gpu, registry)
            output = String(take!(io))
            
            # Test individual components without relying on exact color formatting
            Test.@test occursin("GPU", output)
            Test.@test occursin("parameter", output)
            Test.@test occursin("id", output)
            Test.@test occursin("gpu", output)
            Test.@test occursin("hierarchy", output)
            Test.@test occursin("AbstractStrategyParameter", output)
            Test.@test occursin("description", output)
            Test.@test occursin("GPU-based", output)
            Test.@test occursin("computation", output)
            Test.@test occursin("used", output)
            Test.@test occursin("strategies", output)
            Test.@test occursin("exa", output)
        end
        
        # ================================================================
        # ERROR TESTS
        # ================================================================
        
        Test.@testset "Unknown symbol error" begin
            # Create a registry
            registry = CTSolvers.create_registry(
                CTSolvers.AbstractNLPModeler => (
                    (CTSolvers.ADNLP, [CTSolvers.CPU]),
                )
            )
            
            # Test unknown ID throws IncorrectArgument
            Test.@test_throws Exceptions.IncorrectArgument Strategies.describe(:unknown, registry)
        end
    end
end

end # module

test_describe_parameters() = TestDescribeParameters.test_describe_parameters()
