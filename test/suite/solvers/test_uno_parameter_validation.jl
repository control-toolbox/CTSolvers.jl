module TestUnoParameterValidation

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
    test_uno_parameter_validation()

Tests for Uno parameter validation.

🧪 **Applying Testing Rule**: Unit Tests for parameter validation
"""
function test_uno_parameter_validation()
    Test.@testset "Uno Parameter Validation" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ====================================================================
        # UNIT TESTS - Structure and Contract
        # ====================================================================

        Test.@testset "Uno structure" begin
            # Test that Uno is parameterized
            Test.@test Solvers.Uno <: AbstractNLPSolver
            Test.@test Solvers.Uno{Strategies.CPU} <: AbstractNLPSolver
        end

        Test.@testset "id() with parameters" begin
            # id() should work regardless of parameter
            Test.@test Strategies.id(Solvers.Uno) == :uno
            Test.@test Strategies.id(Solvers.Uno{Strategies.CPU}) == :uno
        end

        # ====================================================================
        # UNIT TESTS - Constructor Validation (without extension)
        # ====================================================================

        Test.@testset "Constructor validation without extension" begin
            # GPU parameter should fail with TypeError (compile-time validation)
            Test.@test_throws TypeError Solvers.Uno{Strategies.GPU}()
        end

        # ====================================================================
        # UNIT TESTS - Metadata Validation (without extension)
        # ====================================================================

        Test.@testset "metadata() validation without extension" begin
            # GPU parameter should fail with TypeError (compile-time validation)
            Test.@test_throws TypeError Strategies.metadata(Solvers.Uno{Strategies.GPU})
        end

        # ====================================================================
        # INTEGRATION TESTS - Default Parameter Behavior
        # ====================================================================

        Test.@testset "Default parameter behavior" begin
            # Verify _default_parameter returns CPU
            Test.@test Strategies._default_parameter(Solvers.Uno) == Strategies.CPU

            # Note: We don't test Solvers.Uno() here because:
            # - When extension is NOT loaded: throws ExtensionError
            # - When extension IS loaded (full test suite): works normally
            # Both behaviors are correct, so we can't test with @test_throws
        end
    end
end

end # module

function test_uno_parameter_validation()
    TestUnoParameterValidation.test_uno_parameter_validation()
end
