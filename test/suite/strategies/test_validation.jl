module TestStrategiesValidation

using Test
using CTBase: CTBase
const Exceptions = CTBase.Exceptions
using CTSolvers
using CTSolvers.Strategies
using CTSolvers.Options
using CTSolvers.Options: OptionDefinition

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

# ============================================================================
# Valid test strategies
# ============================================================================

abstract type AbstractTestValidationStrategy <: Strategies.AbstractStrategy end

struct ValidTestStrategy <: AbstractTestValidationStrategy
    options::Strategies.StrategyOptions
end

struct AnotherValidStrategy <: AbstractTestValidationStrategy
    options::Strategies.StrategyOptions
end

# Valid implementations
Strategies.id(::Type{ValidTestStrategy}) = :valid_test
Strategies.id(::Type{AnotherValidStrategy}) = :another_valid

Strategies.metadata(::Type{ValidTestStrategy}) = Strategies.StrategyMetadata(
    OptionDefinition(
        name = :max_iter,
        type = Int,
        default = 100,
        description = "Maximum iterations",
        aliases = (:max,)
    ),
    OptionDefinition(
        name = :tolerance,
        type = Float64,
        default = 1e-6,
        description = "Convergence tolerance"
    )
)

Strategies.metadata(::Type{AnotherValidStrategy}) = Strategies.StrategyMetadata(
    OptionDefinition(
        name = :backend,
        type = Symbol,
        default = :default,
        description = "Backend to use"
    )
)

# Valid constructors using build_strategy_options
ValidTestStrategy(; kwargs...) = ValidTestStrategy(
    Strategies.build_strategy_options(ValidTestStrategy; kwargs...)
)

AnotherValidStrategy(; kwargs...) = AnotherValidStrategy(
    Strategies.build_strategy_options(AnotherValidStrategy; kwargs...)
)

Strategies.options(s::Union{ValidTestStrategy, AnotherValidStrategy}) = s.options

# ============================================================================
# Invalid test strategies
# ============================================================================

# Missing id
struct MissingIdStrategy <: AbstractTestValidationStrategy
    options::Strategies.StrategyOptions
end

Strategies.metadata(::Type{MissingIdStrategy}) = Strategies.StrategyMetadata(
    OptionDefinition(
        name = :param,
        type = Int,
        default = 1,
        description = "Parameter"
    )
)

MissingIdStrategy(; kwargs...) = MissingIdStrategy(
    Strategies.build_strategy_options(MissingIdStrategy; kwargs...)
)

Strategies.options(s::MissingIdStrategy) = s.options

# Wrong id return type
struct WrongIdTypeStrategy <: AbstractTestValidationStrategy
    options::Strategies.StrategyOptions
end

Strategies.id(::Type{WrongIdTypeStrategy}) = "wrong"  # String instead of Symbol
Strategies.metadata(::Type{WrongIdTypeStrategy}) = Strategies.StrategyMetadata(
    OptionDefinition(
        name = :param,
        type = Int,
        default = 1,
        description = "Parameter"
    )
)

WrongIdTypeStrategy(; kwargs...) = WrongIdTypeStrategy(
    Strategies.build_strategy_options(WrongIdTypeStrategy; kwargs...)
)

Strategies.options(s::WrongIdTypeStrategy) = s.options

# Missing metadata
struct MissingMetadataStrategy <: AbstractTestValidationStrategy
    options::Strategies.StrategyOptions
end

Strategies.id(::Type{MissingMetadataStrategy}) = :missing_meta

MissingMetadataStrategy(; kwargs...) = MissingMetadataStrategy(
    Strategies.build_strategy_options(MissingMetadataStrategy; kwargs...)
)

Strategies.options(s::MissingMetadataStrategy) = s.options

# Wrong metadata return type
struct WrongMetadataTypeStrategy <: AbstractTestValidationStrategy
    options::Strategies.StrategyOptions
end

Strategies.id(::Type{WrongMetadataTypeStrategy}) = :wrong_meta
Strategies.metadata(::Type{WrongMetadataTypeStrategy}) = "wrong"  # String instead of StrategyMetadata

WrongMetadataTypeStrategy(; kwargs...) = WrongMetadataTypeStrategy(
    Strategies.build_strategy_options(WrongMetadataTypeStrategy; kwargs...)
)

Strategies.options(s::WrongMetadataTypeStrategy) = s.options

# Missing constructor
struct MissingConstructorStrategy <: AbstractTestValidationStrategy
    options::Strategies.StrategyOptions
end

Strategies.id(::Type{MissingConstructorStrategy}) = :missing_constructor
Strategies.metadata(::Type{MissingConstructorStrategy}) = Strategies.StrategyMetadata(
    OptionDefinition(
        name = :param,
        type = Int,
        default = 1,
        description = "Parameter"
    )
)

Strategies.options(s::MissingConstructorStrategy) = s.options

# Missing options method
struct MissingOptionsStrategy <: AbstractTestValidationStrategy
    # No options field - should cause validation to fail
    dummy::Int
end

Strategies.id(::Type{MissingOptionsStrategy}) = :missing_options
Strategies.metadata(::Type{MissingOptionsStrategy}) = Strategies.StrategyMetadata(
    OptionDefinition(
        name = :param,
        type = Int,
        default = 1,
        description = "Parameter"
    )
)

# Constructor without options field
MissingOptionsStrategy(; kwargs...) = MissingOptionsStrategy(1)

# No options method defined - this should cause validation to fail

# Wrong options return type
struct WrongOptionsTypeStrategy <: AbstractTestValidationStrategy
    options::Strategies.StrategyOptions
end

Strategies.id(::Type{WrongOptionsTypeStrategy}) = :wrong_options
Strategies.metadata(::Type{WrongOptionsTypeStrategy}) = Strategies.StrategyMetadata(
    OptionDefinition(
        name = :param,
        type = Int,
        default = 1,
        description = "Parameter"
    )
)

WrongOptionsTypeStrategy(; kwargs...) = WrongOptionsTypeStrategy(
    Strategies.build_strategy_options(WrongOptionsTypeStrategy; kwargs...)
)

Strategies.options(s::WrongOptionsTypeStrategy) = "wrong"  # String instead of StrategyOptions

# ============================================================================
# Advanced test strategies for metadata-options consistency
# ============================================================================

# Strategy with missing key in options
struct MissingKeyStrategy <: AbstractTestValidationStrategy
    options::Strategies.StrategyOptions
end

Strategies.id(::Type{MissingKeyStrategy}) = :missing_key
Strategies.metadata(::Type{MissingKeyStrategy}) = Strategies.StrategyMetadata(
    OptionDefinition(
        name = :param1,
        type = Int,
        default = 1,
        description = "Parameter 1"
    ),
    OptionDefinition(
        name = :param2,
        type = Int,
        default = 2,
        description = "Parameter 2"
    )
)

MissingKeyStrategy(; kwargs...) = MissingKeyStrategy(
    Strategies.StrategyOptions((param1=Options.OptionValue(1, :user),))  # Missing param2!
)

Strategies.options(s::MissingKeyStrategy) = s.options

# Strategy with extra key in options
struct ExtraKeyStrategy <: AbstractTestValidationStrategy
    options::Strategies.StrategyOptions
end

Strategies.id(::Type{ExtraKeyStrategy}) = :extra_key
Strategies.metadata(::Type{ExtraKeyStrategy}) = Strategies.StrategyMetadata(
    OptionDefinition(
        name = :param1,
        type = Int,
        default = 1,
        description = "Parameter 1"
    )
)

ExtraKeyStrategy(; kwargs...) = ExtraKeyStrategy(
    Strategies.StrategyOptions((
        param1=Options.OptionValue(1, :user),
        extra=Options.OptionValue(999, :user)  # Extra key!
    ))
)

Strategies.options(s::ExtraKeyStrategy) = s.options

# ============================================================================
# Advanced test strategies for constructor behavior
# ============================================================================

# Strategy that ignores kwargs
struct IgnoresKwargsStrategy <: AbstractTestValidationStrategy
    options::Strategies.StrategyOptions
end

Strategies.id(::Type{IgnoresKwargsStrategy}) = :ignores_kwargs
Strategies.metadata(::Type{IgnoresKwargsStrategy}) = Strategies.StrategyMetadata(
    OptionDefinition(
        name = :value,
        type = Int,
        default = 100,
        description = "A value"
    )
)

IgnoresKwargsStrategy(; kwargs...) = IgnoresKwargsStrategy(
    Strategies.StrategyOptions((value=Options.OptionValue(100, :user),))  # Always 100, ignores kwargs!
)

Strategies.options(s::IgnoresKwargsStrategy) = s.options

# Strategy with Bool option
struct BoolOptionStrategy <: AbstractTestValidationStrategy
    options::Strategies.StrategyOptions
end

Strategies.id(::Type{BoolOptionStrategy}) = :bool_option
Strategies.metadata(::Type{BoolOptionStrategy}) = Strategies.StrategyMetadata(
    OptionDefinition(
        name = :enabled,
        type = Bool,
        default = false,
        description = "Enable feature"
    )
)

BoolOptionStrategy(; kwargs...) = BoolOptionStrategy(
    Strategies.build_strategy_options(BoolOptionStrategy; kwargs...)
)

Strategies.options(s::BoolOptionStrategy) = s.options

# Strategy with Symbol option
struct SymbolOptionStrategy <: AbstractTestValidationStrategy
    options::Strategies.StrategyOptions
end

Strategies.id(::Type{SymbolOptionStrategy}) = :symbol_option
Strategies.metadata(::Type{SymbolOptionStrategy}) = Strategies.StrategyMetadata(
    OptionDefinition(
        name=:op_mode,
        type = Symbol,
        default = :default,
        description = "Operation mode"
    )
)

SymbolOptionStrategy(; kwargs...) = SymbolOptionStrategy(
    Strategies.build_strategy_options(SymbolOptionStrategy; kwargs...)
)

Strategies.options(s::SymbolOptionStrategy) = s.options

# Strategy with no options
struct NoOptionsStrategy <: AbstractTestValidationStrategy
    options::Strategies.StrategyOptions
end

Strategies.id(::Type{NoOptionsStrategy}) = :no_options
Strategies.metadata(::Type{NoOptionsStrategy}) = Strategies.StrategyMetadata()

NoOptionsStrategy(; kwargs...) = NoOptionsStrategy(
    Strategies.build_strategy_options(NoOptionsStrategy; kwargs...)
)

Strategies.options(s::NoOptionsStrategy) = s.options

# ============================================================================
# Test function
# ============================================================================

"""
    test_validation()

Tests for strategy validation API.
"""
function test_validation()
    Test.@testset "Strategy Validation" verbose=VERBOSE showtiming=SHOWTIMING begin
        
        # ====================================================================
        # Valid strategies
        # ====================================================================
        
        Test.@testset "Valid strategies" begin
            # Completely valid strategy
            Test.@test Strategies.validate_strategy_contract(ValidTestStrategy) == true
            
            # Another valid strategy
            Test.@test Strategies.validate_strategy_contract(AnotherValidStrategy) == true
            
            # Test that we can actually create instances
            instance1 = ValidTestStrategy()
            Test.@test instance1 isa ValidTestStrategy
            Test.@test Strategies.options(instance1) isa Strategies.StrategyOptions
            
            instance2 = AnotherValidStrategy(backend=:sparse)
            Test.@test instance2 isa AnotherValidStrategy
            Test.@test Strategies.options(instance2) isa Strategies.StrategyOptions
            Test.@test instance2.options[:backend] == :sparse
        end
        
        # ====================================================================
        # Invalid strategies - Missing methods
        # ====================================================================
        
        Test.@testset "Invalid strategies - Missing methods" begin
            # Missing id method
            Test.@test_throws Exceptions.NotImplemented Strategies.validate_strategy_contract(MissingIdStrategy)
            
            # Missing metadata method
            Test.@test_throws Exceptions.NotImplemented Strategies.validate_strategy_contract(MissingMetadataStrategy)
            
            # Missing constructor
            Test.@test_throws Exceptions.NotImplemented Strategies.validate_strategy_contract(MissingConstructorStrategy)
            
            # Missing options method
            Test.@test_throws Exceptions.NotImplemented Strategies.validate_strategy_contract(MissingOptionsStrategy)
        end
        
        # ====================================================================
        # Invalid strategies - Wrong return types
        # ====================================================================
        
        Test.@testset "Invalid strategies - Wrong return types" begin
            # Wrong id return type (String instead of Symbol)
            Test.@test_throws Exceptions.IncorrectArgument Strategies.validate_strategy_contract(WrongIdTypeStrategy)
            
            # Wrong metadata return type (String instead of StrategyMetadata)
            Test.@test_throws Exceptions.IncorrectArgument Strategies.validate_strategy_contract(WrongMetadataTypeStrategy)
            
            # Wrong options return type (String instead of StrategyOptions)
            Test.@test_throws Exceptions.IncorrectArgument Strategies.validate_strategy_contract(WrongOptionsTypeStrategy)
        end
        
        # ====================================================================
        # Error message validation
        # ====================================================================
        
        Test.@testset "Error message validation" begin
            # Test that error messages contain useful information
            try
                Strategies.validate_strategy_contract(WrongIdTypeStrategy)
                Test.@test false  # Should not reach here
            catch e
                Test.@test e isa Exceptions.IncorrectArgument
                Test.@test occursin("Invalid strategy ID type", string(e))
                Test.@test occursin("WrongIdTypeStrategy", string(e))
            end
            
            try
                Strategies.validate_strategy_contract(MissingIdStrategy)
                Test.@test false  # Should not reach here
            catch e
                Test.@test e isa Exceptions.NotImplemented
                Test.@test occursin("Strategy ID method not implemented", string(e))
                Test.@test occursin("MissingIdStrategy", string(e))
            end
        end
        
        # ====================================================================
        # Validation order
        # ====================================================================
        
        Test.@testset "Validation order" begin
            # Test that validation stops at first error
            # MissingIdStrategy should fail at step 1 (id check)
            # even though it has other issues
            try
                Strategies.validate_strategy_contract(MissingIdStrategy)
                Test.@test false  # Should not reach here
            catch e
                Test.@test e isa Exceptions.NotImplemented
                Test.@test occursin("Strategy ID method not implemented", string(e))
            end
            
            # WrongIdTypeStrategy should fail at step 1 (id type check)
            # even though it might have other valid methods
            try
                Strategies.validate_strategy_contract(WrongIdTypeStrategy)
                Test.@test false  # Should not reach here
            catch e
                Test.@test e isa Exceptions.IncorrectArgument
                Test.@test occursin("Invalid strategy ID type", string(e))
            end
        end
        
        # ====================================================================
        # Integration: Full validation pipeline
        # ====================================================================
        
        Test.@testset "Integration: Full validation pipeline" begin
            # Validate that all components work together
            Test.@test Strategies.validate_strategy_contract(ValidTestStrategy) == true
            
            # Create instance with custom options
            instance = ValidTestStrategy(max_iter=200, tolerance=1e-8)
            Test.@test instance isa ValidTestStrategy
            Test.@test instance.options[:max_iter] == 200
            Test.@test instance.options[:tolerance] == 1e-8
            
            # Validate that the instance still works
            Test.@test Strategies.validate_strategy_contract(typeof(instance)) == true
            
            # Validate with alias usage
            instance2 = ValidTestStrategy(max=150)  # Using alias
            Test.@test instance2.options[:max_iter] == 150
            Test.@test Strategies.validate_strategy_contract(typeof(instance2)) == true
        end
        
        # ====================================================================
        # Return value
        # ====================================================================
        
        Test.@testset "Return value" begin
            # Validate that the function returns exactly true
            result = Strategies.validate_strategy_contract(ValidTestStrategy)
            Test.@test result === true
            Test.@test typeof(result) === Bool
            
            # Multiple validations should all return true
            Test.@test Strategies.validate_strategy_contract(ValidTestStrategy) === true
            Test.@test Strategies.validate_strategy_contract(AnotherValidStrategy) === true
        end
        
        # ====================================================================
        # Advanced: Metadata-Options consistency
        # ====================================================================
        
        Test.@testset "Metadata-Options consistency" begin
            # Strategy with mismatched options (missing key)
            # Should fail with missing options error
            Test.@test_throws Exceptions.IncorrectArgument Strategies.validate_strategy_contract(MissingKeyStrategy)
            
            try
                Strategies.validate_strategy_contract(MissingKeyStrategy)
                Test.@test false
            catch e
                Test.@test e isa Exceptions.IncorrectArgument
                Test.@test occursin("missing options", string(e))
                Test.@test occursin("param2", string(e))
            end
            
            # Strategy with extra options
            # Should fail with unexpected options error
            Test.@test_throws Exceptions.IncorrectArgument Strategies.validate_strategy_contract(ExtraKeyStrategy)
            
            try
                Strategies.validate_strategy_contract(ExtraKeyStrategy)
                Test.@test false
            catch e
                Test.@test e isa Exceptions.IncorrectArgument
                Test.@test occursin("unexpected options", string(e))
                Test.@test occursin("extra", string(e))
            end
        end
        
        # ====================================================================
        # Advanced: Constructor behavior
        # ====================================================================
        
        Test.@testset "Constructor behavior" begin
            # Strategy that ignores kwargs
            # Should fail because constructor doesn't use kwargs
            Test.@test_throws Exceptions.IncorrectArgument Strategies.validate_strategy_contract(IgnoresKwargsStrategy)
            
            try
                Strategies.validate_strategy_contract(IgnoresKwargsStrategy)
                Test.@test false
            catch e
                Test.@test e isa Exceptions.IncorrectArgument
                Test.@test occursin("Constructor does not use keyword arguments properly", string(e))
                Test.@test occursin("build_strategy_options", string(e))
            end
            
            # Strategy with Bool option (tests negation)
            # Should pass - constructor uses build_strategy_options
            Test.@test Strategies.validate_strategy_contract(BoolOptionStrategy) === true
            
            # Strategy with Symbol option (tests string concatenation)
            # Should pass
            Test.@test Strategies.validate_strategy_contract(SymbolOptionStrategy) === true
        end
        
        # ====================================================================
        # Edge cases: Empty metadata
        # ====================================================================
        
        Test.@testset "Edge cases: Empty metadata" begin
            # Strategy with no options
            # Should pass - empty metadata is valid
            Test.@test Strategies.validate_strategy_contract(NoOptionsStrategy) === true
            
            # Verify instance has no options
            instance = NoOptionsStrategy()
            Test.@test isempty(instance.options.options)
        end
    end
end

end # module

test_validation() = TestStrategiesValidation.test_validation()
