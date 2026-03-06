module TestParameterContract

using Test
using CTSolvers
using CTSolvers.Strategies
using CTSolvers.Strategies: _default_parameter
using CTBase.Exceptions

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

# ============================================================================
# Fake strategy type for testing (must be at module top-level)
# ============================================================================

"""
Fake strategy type that does NOT implement the parameter contract.

This type is used to test that the fallback implementations correctly
throw NotImplemented errors.
"""
struct FakeStrategyWithoutContract <: AbstractStrategy
    options::StrategyOptions
end

# Intentionally DO NOT implement _default_parameter to test the fallback behavior

# ============================================================================
# Test function
# ============================================================================

"""
    test_parameter_contract()

Tests for the parameter contract enforcement.

Verifies that:
- Fallback implementations throw NotImplemented
- All real strategies implement the contract
- Non-parameterized strategies are properly rejected
"""
function test_parameter_contract()
    Test.@testset "Parameter Contract Enforcement" verbose=VERBOSE showtiming=SHOWTIMING begin
        
        # ====================================================================
        # UNIT TESTS - Fallback Behavior
        # ====================================================================
        
        Test.@testset "Fallback implementations throw NotImplemented" begin
            Test.@testset "_default_parameter fallback" begin
                err = try
                    _default_parameter(FakeStrategyWithoutContract)
                catch e
                    e
                end
                
                Test.@test err isa NotImplemented
                Test.@test occursin("must implement _default_parameter", err.msg)
                Test.@test occursin("Strategies._default_parameter", err.required_method)
                Test.@test occursin("Strategies._default_parameter", err.suggestion)
                Test.@test occursin("parameter contract", lowercase(err.context))
            end
        end
        
        # ====================================================================
        # UNIT TESTS - Real Strategies Implement Contract
        # ====================================================================
        
        Test.@testset "All real strategies implement the contract" begin
            # List of all parameterized strategies
            strategies = [
                (CTSolvers.Modelers.ADNLP, "ADNLP"),
                (CTSolvers.Modelers.Exa, "Exa"),
                (CTSolvers.Solvers.Ipopt, "Ipopt"),
                (CTSolvers.Solvers.Knitro, "Knitro"),
                (CTSolvers.Solvers.MadNLP, "MadNLP"),
                (CTSolvers.Solvers.MadNCL, "MadNCL")
            ]
            
            for (strategy_type, name) in strategies
                Test.@testset "$name implements contract" begin
                    # Should not throw NotImplemented
                    default = Test.@test_nowarn _default_parameter(strategy_type)
                    Test.@test default == CPU  # All current strategies default to CPU
                    
                    # Type constraints enforce parameter validation at compile-time
                    # No runtime _supported_parameters() needed
                end
            end
        end
        
        # ====================================================================
        # INTEGRATION TESTS - Contract Enforcement in Practice
        # ====================================================================
        
        Test.@testset "Contract enforcement prevents invalid usage" begin
            Test.@testset "Cannot use FakeStrategyWithoutContract in registry" begin
                # Attempting to query default parameter for a strategy without contract
                # should fail with NotImplemented
                Test.@test_throws NotImplemented _default_parameter(FakeStrategyWithoutContract)
            end
        end
    end
end

end # module

# CRITICAL: Redefine in outer scope for TestRunner
test_parameter_contract() = TestParameterContract.test_parameter_contract()
