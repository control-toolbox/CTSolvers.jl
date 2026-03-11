module TestADNLPParameterValidation

using Test
using CTSolvers
using CTSolvers.Modelers
using CTSolvers.Strategies
using CTBase.Exceptions
using Enzyme
using Zygote
using KernelAbstractions

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

# ============================================================================
# Fake types for testing (must be at module top-level)
# ============================================================================

struct FakeParam <: AbstractStrategyParameter end
Strategies.id(::Type{FakeParam}) = :fake

# Dummy tag for testing extension behavior
struct DummyTag <: Modelers.AbstractTag end

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

            # Test 1: ADNLP construction with enzyme backend works (Enzyme loaded)
            Test.@test_nowarn Modelers.ADNLP(backend=:enzyme)
            modeler_enzyme = Modelers.ADNLP(backend=:enzyme)
            Test.@test modeler_enzyme isa Modelers.ADNLP{Strategies.CPU}

            # Verify backend is set correctly
            opts_dict = Strategies.options_dict(modeler_enzyme)
            Test.@test opts_dict[:backend] === :enzyme

            # Test with zygote backend also works
            Test.@test_nowarn Modelers.ADNLP(backend=:zygote)
            modeler_zygote = Modelers.ADNLP(backend=:zygote)
            Test.@test modeler_zygote isa Modelers.ADNLP{Strategies.CPU}
            opts_dict_zygote = Strategies.options_dict(modeler_zygote)
            Test.@test opts_dict_zygote[:backend] === :zygote
        end

        Test.@testset "Extension-based validation tests" begin
            # Test 2: DummyTag throws ExtensionError for enzyme
            dummy_validator = Modelers.get_validate_adnlp_backend(DummyTag)
            Test.@test_throws Exceptions.ExtensionError dummy_validator(:enzyme)
            Test.@test_throws Exceptions.ExtensionError dummy_validator(:zygote)

            # Test 3: ADNLPTag works for enzyme/zygote when extensions loaded
            adnlp_validator = Modelers.get_validate_adnlp_backend(Modelers.ADNLPTag)
            Test.@test_nowarn adnlp_validator(:enzyme)
            Test.@test adnlp_validator(:enzyme) === :enzyme
            Test.@test_nowarn adnlp_validator(:zygote)
            Test.@test adnlp_validator(:zygote) === :zygote

            # Test 4: DummyTag throws IncorrectArgument for invalid backends
            Test.@test_throws Exceptions.IncorrectArgument dummy_validator(:invalid_backend)
            Test.@test_throws Exceptions.IncorrectArgument dummy_validator(:nonexistent)

            # Valid backends work for any tag
            Test.@test dummy_validator(:default) === :default
            Test.@test dummy_validator(:optimized) === :optimized
            Test.@test dummy_validator(:generic) === :generic
            Test.@test dummy_validator(:manual) === :manual
        end

        Test.@testset "Validator with wrong types" begin
            # Test that validators throw IncorrectArgument for wrong types, not MethodError
            adnlp_validator = Modelers.get_validate_adnlp_backend(Modelers.ADNLPTag)

            # Pass non-Symbol types - should get IncorrectArgument
            Test.@test_throws Exceptions.IncorrectArgument adnlp_validator(42)
            Test.@test_throws Exceptions.IncorrectArgument adnlp_validator("optimized")
            Test.@test_throws Exceptions.IncorrectArgument adnlp_validator(
                KernelAbstractions.CPU()
            )

            # Verify error message is helpful
            try
                adnlp_validator(KernelAbstractions.CPU())
                Test.@test false  # Should not reach here
            catch e
                Test.@test e isa Exceptions.IncorrectArgument
                Test.@test occursin("Symbol", e.msg) ||
                    occursin("Symbol", string(e.expected))
                Test.@test occursin("ADNLP", e.msg) || occursin("ADNLP", string(e.context))
            end
        end

        # ====================================================================
        # UNIT TESTS - Invalid Parameters
        # ====================================================================

        Test.@testset "Invalid GPU parameter" begin
            # GPU parameter should throw TypeError (compile-time validation)
            Test.@test_throws TypeError Modelers.ADNLP{Strategies.GPU}()
        end

        Test.@testset "Invalid custom parameter" begin
            # Custom parameter should throw TypeError (compile-time validation)
            Test.@test_throws TypeError Modelers.ADNLP{FakeParam}()
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
            # GPU parameter should throw TypeError (compile-time validation)
            Test.@test_throws TypeError Strategies.metadata(Modelers.ADNLP{Strategies.GPU})
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

function test_adnlp_parameter_validation()
    TestADNLPParameterValidation.test_adnlp_parameter_validation()
end
