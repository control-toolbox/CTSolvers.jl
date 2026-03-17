# ============================================================================
# Test describe methods for parameters
# ============================================================================

module TestDescribeParameters

using Test: Test
import CTBase.Exceptions
using CTSolvers: CTSolvers
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

            # Test output contains expected elements
            Test.@test occursin("CPU (parameter)", output)
            Test.@test occursin("id: :cpu", output)
            Test.@test occursin("hierarchy: CPU → AbstractStrategyParameter", output)
            Test.@test occursin("description: CPU-based computation", output)
        end

        Test.@testset "describe(GPU) - type-direct" begin
            # Capture output
            io = IOBuffer()
            Strategies.describe(io, Strategies.GPU)
            output = String(take!(io))

            # Test output contains expected elements
            Test.@test occursin("GPU (parameter)", output)
            Test.@test occursin("id: :gpu", output)
            Test.@test occursin("hierarchy: GPU → AbstractStrategyParameter", output)
            Test.@test occursin("description: GPU-based computation", output)
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
                CTSolvers.AbstractNLPModeler =>
                    ((CTSolvers.Exa, [CTSolvers.CPU, CTSolvers.GPU]),),
            )

            # Capture output
            io = IOBuffer()
            Strategies.describe(io, :cpu, registry)
            output = String(take!(io))

            # Test output contains expected elements
            Test.@test occursin("CPU (parameter)", output)
            Test.@test occursin("id: :cpu", output)
            Test.@test occursin("hierarchy: CPU → AbstractStrategyParameter", output)
            Test.@test occursin("description: CPU-based computation", output)
            Test.@test occursin("used by strategies", output)
            Test.@test occursin(":exa", output)
        end

        Test.@testset "describe(:gpu, registry) - registry-aware" begin
            # Create a registry with parameterized strategies
            registry = CTSolvers.create_registry(
                CTSolvers.AbstractNLPModeler =>
                    ((CTSolvers.Exa, [CTSolvers.CPU, CTSolvers.GPU]),),
            )

            # Capture output
            io = IOBuffer()
            Strategies.describe(io, :gpu, registry)
            output = String(take!(io))

            # Test output contains expected elements
            Test.@test occursin("GPU (parameter)", output)
            Test.@test occursin("id: :gpu", output)
            Test.@test occursin("hierarchy: GPU → AbstractStrategyParameter", output)
            Test.@test occursin("description: GPU-based computation", output)
            Test.@test occursin("used by strategies", output)
            Test.@test occursin(":exa", output)
        end

        # ================================================================
        # ERROR TESTS
        # ================================================================

        Test.@testset "Unknown symbol error" begin
            # Create a registry
            registry = CTSolvers.create_registry(
                CTSolvers.AbstractNLPModeler => ((CTSolvers.ADNLP, [CTSolvers.CPU]),)
            )

            # Test unknown ID throws IncorrectArgument
            Test.@test_throws Exceptions.IncorrectArgument Strategies.describe(
                :unknown, registry
            )
        end
    end
end

end # module

test_describe_parameters() = TestDescribeParameters.test_describe_parameters()
