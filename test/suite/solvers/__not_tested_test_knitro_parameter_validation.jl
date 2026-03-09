module TestKnitroParameterValidation

using Test
using CTSolvers
using CTSolvers.Solvers
using CTSolvers.Strategies
using CTBase.Exceptions

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

# ============================================================================
# Fake parameter type for testing (must be at module top-level)
# ============================================================================

struct FakeParam <: AbstractStrategyParameter end
Strategies.id(::Type{FakeParam}) = :fake

# ============================================================================
# Test function
# ============================================================================

"""
    test_knitro_parameter_validation()

Tests for Knitro parameter validation.
"""
function test_knitro_parameter_validation()
    Test.@testset "Knitro Parameter Validation" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ====================================================================
        # UNIT TESTS - Structure and Contract
        # ====================================================================

        Test.@testset "Knitro structure" begin
            # Test that Knitro is parameterized
            Test.@test Solvers.Knitro <: AbstractNLPSolver
            Test.@test Solvers.Knitro{Strategies.CPU} <: AbstractNLPSolver
        end

        Test.@testset "id() with parameters" begin
            # id() should work regardless of parameter
            Test.@test Strategies.id(Solvers.Knitro) == :knitro
            Test.@test Strategies.id(Solvers.Knitro{Strategies.CPU}) == :knitro
        end

        Test.@testset "_supported_parameters" begin
            supported = Solvers._supported_parameters(Solvers.Knitro)
            Test.@test supported == (Strategies.CPU,)
            Test.@test Strategies.CPU in supported
            Test.@test Strategies.GPU ∉ supported
        end

        Test.@testset "validate_supported_parameter" begin
            # CPU should be valid
            Test.@test_nowarn Strategies.validate_supported_parameter(
                Solvers.Knitro, Strategies.CPU
            )

            # GPU should be invalid
            Test.@test_throws Exceptions.IncorrectArgument begin
                Strategies.validate_supported_parameter(Solvers.Knitro, Strategies.GPU)
            end

            # Custom parameter should be invalid
            Test.@test_throws Exceptions.IncorrectArgument begin
                Strategies.validate_supported_parameter(Solvers.Knitro, FakeParam)
            end
        end

        # ====================================================================
        # UNIT TESTS - Constructor Validation (without extension)
        # ====================================================================

        Test.@testset "Constructor validation without extension" begin
            # These tests check parameter validation before extension loading
            # They should throw ExtensionError, not IncorrectArgument for invalid params

            # CPU parameter should attempt to build (will fail with ExtensionError)
            Test.@test_throws Exceptions.ExtensionError Solvers.Knitro{Strategies.CPU}()

            # GPU parameter should fail with IncorrectArgument BEFORE ExtensionError
            Test.@test_throws Exceptions.IncorrectArgument Solvers.Knitro{Strategies.GPU}()

            # Custom parameter should fail with IncorrectArgument
            Test.@test_throws Exceptions.IncorrectArgument Solvers.Knitro{FakeParam}()
        end

        Test.@testset "Error message quality for invalid parameters" begin
            # Test GPU parameter error message
            err_gpu = try
                Solvers.Knitro{Strategies.GPU}()
            catch e
                e
            end

            Test.@test err_gpu isa Exceptions.IncorrectArgument
            Test.@test occursin("CPU", err_gpu.expected)
            Test.@test occursin("GPU", err_gpu.got)
            Test.@test occursin("Unsupported parameter", err_gpu.msg)
            Test.@test err_gpu.suggestion !== nothing

            # Test custom parameter error message
            err_fake = try
                Solvers.Knitro{FakeParam}()
            catch e
                e
            end

            Test.@test err_fake isa Exceptions.IncorrectArgument
            Test.@test occursin("CPU", err_fake.expected)
            Test.@test occursin("FakeParam", err_fake.got)
        end

        # ====================================================================
        # UNIT TESTS - Metadata Validation (without extension)
        # ====================================================================

        Test.@testset "metadata() validation without extension" begin
            # CPU parameter should fail with ExtensionError (extension not loaded)
            Test.@test_throws Exceptions.ExtensionError begin
                Strategies.metadata(Solvers.Knitro{Strategies.CPU})
            end

            # GPU parameter should fail with IncorrectArgument BEFORE ExtensionError
            Test.@test_throws Exceptions.IncorrectArgument begin
                Strategies.metadata(Solvers.Knitro{Strategies.GPU})
            end

            # Non-parameterized should fail with ExtensionError (delegates to CPU)
            Test.@test_throws Exceptions.ExtensionError begin
                Strategies.metadata(Solvers.Knitro)
            end
        end

        # ====================================================================
        # INTEGRATION TESTS - Error Ordering
        # ====================================================================

        Test.@testset "Error ordering: parameter validation before extension" begin
            # When GPU is used, IncorrectArgument should be thrown
            # BEFORE ExtensionError (parameter validation happens first)

            err = try
                Solvers.Knitro{Strategies.GPU}()
            catch e
                e
            end

            # Should be IncorrectArgument, not ExtensionError
            Test.@test err isa Exceptions.IncorrectArgument
            Test.@test !(err isa Exceptions.ExtensionError)
        end

        Test.@testset "Default parameter behavior" begin
            # Default constructor should use CPU
            # Will fail with ExtensionError since extension not loaded,
            # but we can verify it attempts to use CPU parameter

            Test.@test_throws Exceptions.ExtensionError Solvers.Knitro()

            # Verify _default_parameter returns CPU
            Test.@test Solvers._default_parameter(Solvers.Knitro) == Strategies.CPU
        end
    end
end

end # module

function test_knitro_parameter_validation()
    TestKnitroParameterValidation.test_knitro_parameter_validation()
end
