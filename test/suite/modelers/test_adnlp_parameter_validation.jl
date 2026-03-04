module TestADNLPParameterValidation

using Test
using CTSolvers
using CTSolvers.Modelers
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
    test_adnlp_parameter_validation()

Tests for ADNLP parameter validation.
"""
function test_adnlp_parameter_validation()
    Test.@testset "ADNLP Parameter Validation" verbose=VERBOSE showtiming=SHOWTIMING begin
        
        # ====================================================================
        # UNIT TESTS - Valid Parameters
        # ====================================================================
        
        Test.@testset "Valid CPU parameter" begin
            # Default constructor (should use CPU)
            Test.@test_nowarn Modelers.ADNLP()
            modeler = Modelers.ADNLP()
            Test.@test modeler isa Modelers.ADNLP{Strategies.CPU}
            
            # Explicit CPU constructor
            Test.@test_nowarn Modelers.ADNLP{Strategies.CPU}()
            modeler_cpu = Modelers.ADNLP{Strategies.CPU}()
            Test.@test modeler_cpu isa Modelers.ADNLP{Strategies.CPU}
        end
        
        Test.@testset "Valid CPU parameter with options" begin
            # Default constructor with options
            Test.@test_nowarn Modelers.ADNLP(backend=:optimized, matrix_free=true)
            modeler = Modelers.ADNLP(backend=:optimized, matrix_free=true)
            Test.@test modeler isa Modelers.ADNLP{Strategies.CPU}
            
            # Explicit CPU constructor with options
            Test.@test_nowarn Modelers.ADNLP{Strategies.CPU}(backend=:optimized)
            modeler_cpu = Modelers.ADNLP{Strategies.CPU}(backend=:optimized)
            Test.@test modeler_cpu isa Modelers.ADNLP{Strategies.CPU}
        end
        
        # ====================================================================
        # UNIT TESTS - Invalid Parameters
        # ====================================================================
        
        Test.@testset "Invalid GPU parameter" begin
            # GPU parameter should throw IncorrectArgument
            Test.@test_throws Exceptions.IncorrectArgument Modelers.ADNLP{Strategies.GPU}()
        end
        
        Test.@testset "Invalid custom parameter" begin
            # Custom parameter should throw IncorrectArgument
            Test.@test_throws Exceptions.IncorrectArgument Modelers.ADNLP{FakeParam}()
        end
        
        # ====================================================================
        # UNIT TESTS - Metadata Validation
        # ====================================================================
        
        Test.@testset "metadata() with valid parameters" begin
            # Non-parameterized type should work (delegates to CPU)
            Test.@test_nowarn Strategies.metadata(Modelers.ADNLP)
            meta = Strategies.metadata(Modelers.ADNLP)
            Test.@test meta isa Strategies.StrategyMetadata
            
            # CPU parameter should work
            Test.@test_nowarn Strategies.metadata(Modelers.ADNLP{Strategies.CPU})
            meta_cpu = Strategies.metadata(Modelers.ADNLP{Strategies.CPU})
            Test.@test meta_cpu isa Strategies.StrategyMetadata
        end
        
        Test.@testset "metadata() with invalid parameters" begin
            # GPU parameter should throw IncorrectArgument
            Test.@test_throws Exceptions.IncorrectArgument Strategies.metadata(Modelers.ADNLP{Strategies.GPU})
        end
        
        # ====================================================================
        # UNIT TESTS - id() Function
        # ====================================================================
        
        Test.@testset "id() with parameters" begin
            # id() should work regardless of parameter
            Test.@test Strategies.id(Modelers.ADNLP) == :adnlp
            Test.@test Strategies.id(Modelers.ADNLP{Strategies.CPU}) == :adnlp
            
            # Note: id() doesn't validate parameters, only metadata() and constructors do
        end
        
        # ====================================================================
        # UNIT TESTS - Supported Parameters
        # ====================================================================
        
        Test.@testset "_supported_parameters" begin
            supported = Strategies._supported_parameters(Modelers.ADNLP)
            Test.@test supported == (Strategies.CPU,)
            Test.@test Strategies.CPU in supported
            Test.@test Strategies.GPU ∉ supported
        end
        
        Test.@testset "validate_supported_parameter" begin
            # CPU should be valid
            Test.@test_nowarn Strategies.validate_supported_parameter(
                Modelers.ADNLP, Strategies.CPU
            )
            
            # GPU should be invalid
            Test.@test_throws Exceptions.IncorrectArgument Strategies.validate_supported_parameter(
                Modelers.ADNLP, Strategies.GPU
            )
        end
        
        # ====================================================================
        # INTEGRATION TESTS
        # ====================================================================
        
        Test.@testset "Complete workflow with CPU" begin
            # Create modeler with default constructor
            modeler = Modelers.ADNLP()
            Test.@test modeler isa Modelers.ADNLP{Strategies.CPU}
            
            # Access metadata
            meta = Strategies.metadata(typeof(modeler))
            Test.@test meta isa Strategies.StrategyMetadata
            Test.@test :backend in keys(meta)
            
            # Access options
            opts = Strategies.options(modeler)
            Test.@test opts isa Strategies.StrategyOptions
        end
        
        # Note: Testing ADNLP{GPU}() without kwargs is not possible because
        # Julia's default constructor bypasses our validation. The important
        # validation happens in ADNLP{GPU}(; kwargs...) which is tested above.
    end
end

end # module

test_adnlp_parameter_validation() = TestADNLPParameterValidation.test_adnlp_parameter_validation()
