"""
Integration tests for mode parameter propagation through the builder chain.

Tests that the mode parameter propagates correctly from high-level functions
down to build_strategy_options() and that strict/permissive behavior works
end-to-end.
"""

module TestModePropagation

using Test
using CTSolvers
using CTSolvers.Strategies
using CTSolvers.Options

# Test options for verbose output
const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

# ============================================================================
# TOP-LEVEL: Fake strategy types for testing
# ============================================================================

"""Fake strategy for testing mode propagation."""
struct FakeStrategy <: Strategies.AbstractStrategy
    options::Strategies.StrategyOptions
end

# Required method for strategy registration
Strategies.id(::Type{FakeStrategy}) = :fake

"""Fake strategy metadata for testing."""
function Strategies.metadata(::Type{FakeStrategy})
    return Strategies.StrategyMetadata(
        Options.OptionDefinition(
            name=:known_option,
            type=Int,
            default=100,
            description="A known option for testing"
        )
    )
end

"""Fake strategy constructor."""
function FakeStrategy(; mode::Symbol = :strict, kwargs...)
    # Redirect warnings to avoid polluting test output
    opts = redirect_stderr(devnull) do
        Strategies.build_strategy_options(FakeStrategy; mode=mode, kwargs...)
    end
    return FakeStrategy(opts)
end

# ============================================================================
# Test Function
# ============================================================================

function test_mode_propagation()
    @testset "Mode Propagation Integration" verbose=VERBOSE showtiming=SHOWTIMING begin
        
        # ====================================================================
        # INTEGRATION TESTS - Direct Constructor
        # ====================================================================
        
        @testset "Direct Constructor Propagation" begin
            
            @testset "Strict mode rejects unknown options" begin
                # Should throw error for unknown option
                @test_throws Exception FakeStrategy(unknown_option=123)
                
                # Verify it's the right kind of error
                try
                    FakeStrategy(unknown_option=123)
                    @test false  # Should not reach here
                catch e
                    @test occursin("Unknown", string(e)) || occursin("Unrecognized", string(e))
                end
            end
            
            @testset "Strict mode accepts known options" begin
                # Should work with known option
                strategy = FakeStrategy(known_option=200)
                @test strategy isa FakeStrategy
                @test Strategies.option_value(strategy, :known_option) == 200
                @test Strategies.option_source(strategy, :known_option) == :user
            end
            
            @testset "Permissive mode accepts unknown options" begin
                # Should work with warning
                strategy = FakeStrategy(unknown_option=123; mode=:permissive)
                @test strategy isa FakeStrategy
                
                # Unknown option should be stored
                @test Strategies.has_option(strategy, :unknown_option)
                @test Strategies.option_value(strategy, :unknown_option) == 123
                @test Strategies.option_source(strategy, :unknown_option) == :user
            end
            
            @testset "Permissive mode validates known options" begin
                # Type validation should still work
                @test_throws Exception FakeStrategy(known_option="invalid"; mode=:permissive)
            end
        end
        
        # ====================================================================
        # INTEGRATION TESTS - build_strategy()
        # ====================================================================
        
        @testset "build_strategy() Propagation" begin
            # Create a fake registry
            registry = Strategies.create_registry(
                Strategies.AbstractStrategy => (FakeStrategy,)
            )
            
            @testset "Strict mode via build_strategy()" begin
                # Should throw for unknown option
                @test_throws Exception Strategies.build_strategy(
                    :fake, 
                    Strategies.AbstractStrategy, 
                    registry; 
                    unknown_option=123
                )
            end
            
            @testset "Permissive mode via build_strategy()" begin
                # Should work with warning
                strategy = Strategies.build_strategy(
                    :fake, 
                    Strategies.AbstractStrategy, 
                    registry; 
                    unknown_option=123,
                    mode=:permissive
                )
                @test strategy isa FakeStrategy
                @test Strategies.has_option(strategy, :unknown_option)
            end
            
            @testset "Known options work in both modes" begin
                # Strict mode
                strategy1 = Strategies.build_strategy(
                    :fake, 
                    Strategies.AbstractStrategy, 
                    registry; 
                    known_option=200
                )
                @test Strategies.option_value(strategy1, :known_option) == 200
                
                # Permissive mode
                strategy2 = Strategies.build_strategy(
                    :fake, 
                    Strategies.AbstractStrategy, 
                    registry; 
                    known_option=300,
                    mode=:permissive
                )
                @test Strategies.option_value(strategy2, :known_option) == 300
            end
        end
        
        # ====================================================================
        # INTEGRATION TESTS - build_strategy_from_method()
        # ====================================================================
        
        @testset "build_strategy_from_method() Propagation" begin
            # Create a fake registry
            registry = Strategies.create_registry(
                Strategies.AbstractStrategy => (FakeStrategy,)
            )
            
            method = (:fake,)
            
            @testset "Strict mode via build_strategy_from_method()" begin
                # Should throw for unknown option
                @test_throws Exception Strategies.build_strategy_from_method(
                    method,
                    Strategies.AbstractStrategy, 
                    registry; 
                    unknown_option=123
                )
            end
            
            @testset "Permissive mode via build_strategy_from_method()" begin
                # Should work with warning
                strategy = Strategies.build_strategy_from_method(
                    method,
                    Strategies.AbstractStrategy, 
                    registry; 
                    unknown_option=123,
                    mode=:permissive
                )
                @test strategy isa FakeStrategy
                @test Strategies.has_option(strategy, :unknown_option)
            end
            
            @testset "Mode propagates through method extraction" begin
                # Test that mode is preserved when extracting ID from method
                strategy = Strategies.build_strategy_from_method(
                    method,
                    Strategies.AbstractStrategy, 
                    registry; 
                    known_option=400,
                    unknown_option=456,
                    mode=:permissive
                )
                @test strategy isa FakeStrategy
                @test Strategies.option_value(strategy, :known_option) == 400
                @test Strategies.option_value(strategy, :unknown_option) == 456
            end
        end
        
        # ====================================================================
        # INTEGRATION TESTS - Orchestration Wrapper
        # ====================================================================
        
        @testset "Orchestration Wrapper Propagation" begin
            # Create a fake registry
            registry = Strategies.create_registry(
                Strategies.AbstractStrategy => (FakeStrategy,)
            )
            
            method = (:fake,)
            
            @testset "Strict mode via Orchestration wrapper" begin
                # Should throw for unknown option
                @test_throws Exception CTSolvers.Orchestration.build_strategy_from_method(
                    method,
                    Strategies.AbstractStrategy, 
                    registry; 
                    unknown_option=123
                )
            end
            
            @testset "Permissive mode via Orchestration wrapper" begin
                # Should work with warning
                strategy = CTSolvers.Orchestration.build_strategy_from_method(
                    method,
                    Strategies.AbstractStrategy, 
                    registry; 
                    unknown_option=123,
                    mode=:permissive
                )
                @test strategy isa FakeStrategy
                @test Strategies.has_option(strategy, :unknown_option)
            end
        end
        
        # ====================================================================
        # INTEGRATION TESTS - Mixed Options
        # ====================================================================
        
        @testset "Mixed Known/Unknown Options" begin
            registry = Strategies.create_registry(
                Strategies.AbstractStrategy => (FakeStrategy,)
            )
            
            @testset "Strict mode rejects mix" begin
                # Should throw even with known options present
                @test_throws Exception Strategies.build_strategy(
                    :fake, 
                    Strategies.AbstractStrategy, 
                    registry; 
                    known_option=200,
                    unknown_option=123
                )
            end
            
            @testset "Permissive mode accepts mix" begin
                # Should work with both known and unknown
                strategy = Strategies.build_strategy(
                    :fake, 
                    Strategies.AbstractStrategy, 
                    registry; 
                    known_option=200,
                    unknown_option=123,
                    another_unknown="test",
                    mode=:permissive
                )
                @test strategy isa FakeStrategy
                @test Strategies.option_value(strategy, :known_option) == 200
                @test Strategies.option_value(strategy, :unknown_option) == 123
                @test Strategies.option_value(strategy, :another_unknown) == "test"
            end
            
            @testset "Known options still validated in permissive" begin
                # Type validation should still work for known options
                @test_throws Exception Strategies.build_strategy(
                    :fake, 
                    Strategies.AbstractStrategy, 
                    registry; 
                    known_option="invalid",  # Wrong type
                    unknown_option=123,
                    mode=:permissive
                )
            end
        end
        
        # ====================================================================
        # INTEGRATION TESTS - Default Behavior
        # ====================================================================
        
        @testset "Default Mode Behavior" begin
            registry = Strategies.create_registry(
                Strategies.AbstractStrategy => (FakeStrategy,)
            )
            
            @testset "Default is strict" begin
                # Without specifying mode, should be strict
                @test_throws Exception Strategies.build_strategy(
                    :fake, 
                    Strategies.AbstractStrategy, 
                    registry; 
                    unknown_option=123
                )
            end
            
            @testset "Explicit strict same as default" begin
                # Explicit :strict should behave same as default
                error1 = nothing
                error2 = nothing
                
                try
                    Strategies.build_strategy(
                        :fake, 
                        Strategies.AbstractStrategy, 
                        registry; 
                        unknown_option=123
                    )
                catch e
                    error1 = e
                end
                
                try
                    Strategies.build_strategy(
                        :fake, 
                        Strategies.AbstractStrategy, 
                        registry; 
                        unknown_option=123,
                        mode=:strict
                    )
                catch e
                    error2 = e
                end
                
                @test error1 !== nothing
                @test error2 !== nothing
                @test typeof(error1) == typeof(error2)
            end
        end
        
        # ====================================================================
        # INTEGRATION TESTS - Option Sources
        # ====================================================================
        
        @testset "Option Source Tracking" begin
            registry = Strategies.create_registry(
                Strategies.AbstractStrategy => (FakeStrategy,)
            )
            
            @testset "Known options have :user source" begin
                strategy = Strategies.build_strategy(
                    :fake, 
                    Strategies.AbstractStrategy, 
                    registry; 
                    known_option=200
                )
                @test Strategies.option_source(strategy, :known_option) == :user
            end
            
            @testset "Unknown options have :user source in permissive" begin
                strategy = Strategies.build_strategy(
                    :fake, 
                    Strategies.AbstractStrategy, 
                    registry; 
                    unknown_option=123,
                    mode=:permissive
                )
                @test Strategies.option_source(strategy, :unknown_option) == :user
            end
            
            @testset "Default options have :default source" begin
                strategy = Strategies.build_strategy(
                    :fake, 
                    Strategies.AbstractStrategy, 
                    registry
                )
                @test Strategies.option_source(strategy, :known_option) == :default
            end
        end
        
        # ====================================================================
        # INTEGRATION TESTS - Complete Workflow
        # ====================================================================
        
        @testset "Complete Workflow End-to-End" begin
            registry = Strategies.create_registry(
                Strategies.AbstractStrategy => (FakeStrategy,)
            )
            
            method = (:fake,)
            
            @testset "Full chain: Orchestration → Strategies → Options" begin
                # Test complete propagation chain with known options first
                strategy = CTSolvers.Orchestration.build_strategy_from_method(
                    method,
                    Strategies.AbstractStrategy, 
                    registry; 
                    known_option=500,
                    mode=:permissive
                )

                # Verify strategy created
                @test strategy isa FakeStrategy

                # Test with unknown options in permissive mode
                strategy2 = CTSolvers.Orchestration.build_strategy_from_method(
                    method,
                    Strategies.AbstractStrategy,
                    registry;
                    known_option=500,
                    custom_backend_option="advanced",
                    experimental_feature=true,
                    mode=:permissive
                )
                
                @test strategy2 isa FakeStrategy
                
                # Verify known option validated
                @test Strategies.option_value(strategy, :known_option) == 500
                @test Strategies.option_source(strategy, :known_option) == :user
                
                # Verify unknown options accepted
                @test Strategies.has_option(strategy2, :custom_backend_option)
                @test Strategies.option_value(strategy2, :custom_backend_option) == "advanced"
                @test Strategies.has_option(strategy2, :experimental_feature)
                @test Strategies.option_value(strategy2, :experimental_feature) == true
            end
        end
    end
end

end # module

# Export test function to outer scope
test_mode_propagation() = TestModePropagation.test_mode_propagation()
