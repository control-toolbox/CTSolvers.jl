module TestCoverageValidation

import Test
import CTBase.Exceptions
import CTSolvers.Modelers
import ADNLPModels

# Fake ADBackend for testing (must be at top-level)
struct FakeCoverageBackend <: ADNLPModels.ADBackend end

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

# ============================================================================
# Fake types for testing (must be at module top-level)
# ============================================================================

# Dummy tag for testing extension behavior
struct DummyTag <: Modelers.AbstractTag end

function test_coverage_validation()
    Test.@testset "Coverage: Modelers Validation" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ====================================================================
        # UNIT TESTS - validate_adnlp_backend
        # ====================================================================

        Test.@testset "validate_adnlp_backend" begin
            # Valid backends with DummyTag (always available)
            dummy_tag = DummyTag()
            Test.@test Modelers.validate_adnlp_backend(dummy_tag, Val(:default)) == :default
            Test.@test Modelers.validate_adnlp_backend(dummy_tag, Val(:optimized)) == :optimized
            Test.@test Modelers.validate_adnlp_backend(dummy_tag, Val(:generic)) == :generic
            Test.@test Modelers.validate_adnlp_backend(dummy_tag, Val(:manual)) == :manual

            Test.@test_nowarn Test.@inferred Modelers.validate_adnlp_backend(dummy_tag, Val(:default))

            # Enzyme/Zygote throw ExtensionError (extensions not loaded for DummyTag)
            Test.@test_throws Exceptions.ExtensionError Modelers.validate_adnlp_backend(dummy_tag, Val(:enzyme))
            Test.@test_throws Exceptions.ExtensionError Modelers.validate_adnlp_backend(dummy_tag, Val(:zygote))

            # Invalid backend
            Test.@test_throws Exceptions.IncorrectArgument Modelers.validate_adnlp_backend(dummy_tag, Val(:invalid))
            Test.@test_throws Exceptions.IncorrectArgument Modelers.validate_adnlp_backend(dummy_tag, Val(:foo))
        end

        # ====================================================================
        # UNIT TESTS - validate_exa_base_type
        # ====================================================================

        Test.@testset "validate_exa_base_type" begin
            # Valid types
            Test.@test Modelers.validate_exa_base_type(Float64) == Float64
            Test.@test Modelers.validate_exa_base_type(Float32) == Float32
            Test.@test Modelers.validate_exa_base_type(Float16) == Float16
            Test.@test Modelers.validate_exa_base_type(BigFloat) == BigFloat

            Test.@test_nowarn Test.@inferred Modelers.validate_exa_base_type(Float64)

            # Invalid types
            Test.@test_throws Exceptions.IncorrectArgument Modelers.validate_exa_base_type(Int)
            Test.@test_throws Exceptions.IncorrectArgument Modelers.validate_exa_base_type(String)
            Test.@test_throws Exceptions.IncorrectArgument Modelers.validate_exa_base_type(Bool)
            Test.@test_throws Exceptions.IncorrectArgument Modelers.validate_exa_base_type(Function)
        end

        # ====================================================================
        # UNIT TESTS - validate_model_name
        # ====================================================================

        Test.@testset "validate_model_name" begin
            # Valid names
            Test.@test Modelers.validate_model_name("MyModel") == "MyModel"
            Test.@test Modelers.validate_model_name("test-name") == "test-name"
            Test.@test Modelers.validate_model_name("name_123") == "name_123"

            Test.@test_nowarn Test.@inferred Modelers.validate_model_name("MyModel")

            # Empty name
            Test.@test_throws Exceptions.IncorrectArgument Modelers.validate_model_name("")

            # Special characters warning
            Test.@test_logs (:warn,) Modelers.validate_model_name("name with spaces")
            Test.@test_logs (:warn,) Modelers.validate_model_name("name.with.dots")
        end

        # ====================================================================
        # UNIT TESTS - validate_matrix_free
        # ====================================================================

        Test.@testset "validate_matrix_free" begin
            # Basic validation
            Test.@test Modelers.validate_matrix_free(true) == true
            Test.@test Modelers.validate_matrix_free(false) == false

            Test.@test_nowarn Test.@inferred Modelers.validate_matrix_free(true)

            # Large problem recommendation
            Test.@test_logs (:info,) Modelers.validate_matrix_free(false, 200_000)

            # Small problem with matrix_free=true recommendation
            Test.@test_logs (:info,) Modelers.validate_matrix_free(true, 500)

            # No recommendation for normal sizes
            Test.@test Modelers.validate_matrix_free(true, 5000) == true
            Test.@test Modelers.validate_matrix_free(false, 5000) == false
        end

        # ====================================================================
        # UNIT TESTS - validate_optimization_direction
        # ====================================================================

        Test.@testset "validate_optimization_direction" begin
            Test.@test Modelers.validate_optimization_direction(true) == true
            Test.@test Modelers.validate_optimization_direction(false) == false

            Test.@test_nowarn Test.@inferred Modelers.validate_optimization_direction(true)
        end

        # ====================================================================
        # UNIT TESTS - validate_backend_override
        # ====================================================================

        Test.@testset "validate_backend_override" begin
            # Valid overrides: nothing
            Test.@test Modelers.validate_backend_override(nothing) === nothing

            Test.@test_nowarn Test.@inferred Modelers.validate_backend_override(nothing)
            # Valid overrides: Type{<:ADBackend}
            Test.@test Modelers.validate_backend_override(FakeCoverageBackend) == FakeCoverageBackend
            # Valid overrides: ADBackend instance
            Test.@test Modelers.validate_backend_override(FakeCoverageBackend()) isa ADNLPModels.ADBackend

            # Invalid overrides: non-ADBackend types
            Test.@test_throws Exceptions.IncorrectArgument Modelers.validate_backend_override(Float64)
            Test.@test_throws Exceptions.IncorrectArgument Modelers.validate_backend_override(Int)
            # Invalid overrides: other values
            Test.@test_throws Exceptions.IncorrectArgument Modelers.validate_backend_override("invalid")
            Test.@test_throws Exceptions.IncorrectArgument Modelers.validate_backend_override(123)
            Test.@test_throws Exceptions.IncorrectArgument Modelers.validate_backend_override(:symbol)
        end
    end
end

end # module

test_coverage_validation() = TestCoverageValidation.test_coverage_validation()
