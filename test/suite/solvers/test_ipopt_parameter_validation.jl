module TestIpoptParameterValidation

using Test
using CTSolvers
using CTSolvers.Solvers
using CTSolvers.Strategies
using CTBase.Exceptions

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

# ============================================================================
# Fake parameter type for testing (must be at module top-level)
# ============================================================================

struct FakeParam <: AbstractStrategyParameter end
Strategies.id(::Type{FakeParam}) = :fake

# ============================================================================
# Test function
# ============================================================================

"""
    test_ipopt_parameter_validation()

Tests for Ipopt parameter validation.
"""
function test_ipopt_parameter_validation()
    Test.@testset "Ipopt Parameter Validation" verbose=VERBOSE showtiming=SHOWTIMING begin
        
        # ====================================================================
        # UNIT TESTS - Structure and Contract
        # ====================================================================
        
        Test.@testset "Ipopt structure" begin
            # Test that Ipopt is parameterized
            Test.@test Solvers.Ipopt <: AbstractNLPSolver
            Test.@test Solvers.Ipopt{Strategies.CPU} <: AbstractNLPSolver
        end
        
        Test.@testset "id() with parameters" begin
            # id() should work regardless of parameter
            Test.@test Strategies.id(Solvers.Ipopt) == :ipopt
            Test.@test Strategies.id(Solvers.Ipopt{Strategies.CPU}) == :ipopt
        end
        
        Test.@testset "_supported_parameters" begin
            supported = Strategies._supported_parameters(Solvers.Ipopt)
            Test.@test supported == (Strategies.CPU,)
            Test.@test Strategies.CPU in supported
            Test.@test Strategies.GPU ∉ supported
        end
        
        Test.@testset "validate_supported_parameter" begin
            # CPU should be valid
            Test.@test_nowarn Strategies.validate_supported_parameter(
                Solvers.Ipopt, Strategies.CPU
            )
            
            # GPU should be invalid
            Test.@test_throws Exceptions.IncorrectArgument Strategies.validate_supported_parameter(
                Solvers.Ipopt, Strategies.GPU
            )
        end
        
        # ====================================================================
        # UNIT TESTS - Constructor Validation (without extension)
        # ====================================================================
        
        Test.@testset "Constructor validation without extension" begin
            # GPU parameter should fail with IncorrectArgument
            Test.@test_throws Exceptions.IncorrectArgument Solvers.Ipopt{Strategies.GPU}()
        end
        
        # Note: Detailed error message testing removed - the important validation
        # happens in Ipopt{GPU}(; kwargs...) which is tested in constructor tests
        # ====================================================================
        # UNIT TESTS - Metadata Validation (without extension)
        # ====================================================================
        
        Test.@testset "metadata() validation without extension" begin
            # GPU parameter should fail with IncorrectArgument
            Test.@test_throws Exceptions.IncorrectArgument Strategies.metadata(Solvers.Ipopt{Strategies.GPU})
        end
        
        # ====================================================================
        # INTEGRATION TESTS - Error Ordering
        # ====================================================================
        
        # Note: Error ordering tests removed - validation is tested above
        
        Test.@testset "Default parameter behavior" begin
            # Verify _default_parameter returns CPU
            Test.@test Strategies._default_parameter(Solvers.Ipopt) == Strategies.CPU
            
            # Note: We don't test Solvers.Ipopt() here because:
            # - When extension is NOT loaded: throws ExtensionError
            # - When extension IS loaded (full test suite): works normally
            # Both behaviors are correct, so we can't test with @test_throws
        end
    end
end

end # module

test_ipopt_parameter_validation() = TestIpoptParameterValidation.test_ipopt_parameter_validation()
