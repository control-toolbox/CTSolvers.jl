"""
Integration tests for alias resolution with real strategies.

Tests that aliases defined in strategy metadata are properly preserved
and accessible after strategy construction.

Author: CTSolvers Development Team
Date: 2026-03-17
"""

module TestAliasIntegration

using Test: Test
import CTBase.Exceptions
import CTSolvers.Strategies
import CTSolvers.Options
import CTSolvers.Solvers

# Test options for verbose output
const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

# Check if Ipopt extension is available
const IPOPT_AVAILABLE = try
    using NLPModelsIpopt: NLPModelsIpopt
    true
catch
    false
end

# ============================================================================
# Mock Strategy for Unit Tests
# ============================================================================

# TOP-LEVEL: Define mock strategy for testing
struct MockStrategyWithAliases <: Strategies.AbstractStrategy
    options::Strategies.StrategyOptions
end

Strategies.id(::Type{MockStrategyWithAliases}) = :mock_with_aliases

function Strategies.metadata(::Type{MockStrategyWithAliases})
    Strategies.StrategyMetadata(
        Options.OptionDefinition(;
            name=:max_iter,
            type=Int,
            default=1000,
            description="Maximum iterations",
            aliases=(:maxiter, :max_iterations, :maxit),
        ),
        Options.OptionDefinition(;
            name=:max_wall_time,
            type=Float64,
            default=1e8,
            description="Maximum wall time",
            aliases=(:maxtime, :max_time, :time_limit),
        ),
        Options.OptionDefinition(;
            name=:acceptable_tol,
            type=Float64,
            default=1e-6,
            description="Acceptable tolerance",
            aliases=(:acc_tol,),
        ),
        Options.OptionDefinition(;
            name=:tol,
            type=Float64,
            default=1e-6,
            description="Tolerance",
            aliases=(:tolerance, :eps),
        ),
        Options.OptionDefinition(;
            name=:verbose,
            type=Bool,
            default=false,
            description="Verbose output",
            aliases=(:display,),
        ),
    )
end

function MockStrategyWithAliases(; mode=:strict, kwargs...)
    opts = Strategies.build_strategy_options(MockStrategyWithAliases; mode=mode, kwargs...)
    return MockStrategyWithAliases(opts)
end

# ============================================================================
# Test Function
# ============================================================================

function test_alias_integration()
    Test.@testset "Alias Integration Tests" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ====================================================================
        # UNIT TESTS - Mock Strategy
        # ====================================================================

        Test.@testset "Mock Strategy - Alias Resolution" begin
            Test.@testset "Construction with canonical names" begin
                strategy = MockStrategyWithAliases(max_iter=500, tol=1e-8, verbose=true)

                # Test access via canonical names
                Test.@test Strategies.has_option(strategy, :max_iter)
                Test.@test Strategies.option_value(strategy, :max_iter) == 500
                Test.@test Strategies.option_source(strategy, :max_iter) == :user

                Test.@test Strategies.has_option(strategy, :tol)
                Test.@test Strategies.option_value(strategy, :tol) == 1e-8

                Test.@test Strategies.has_option(strategy, :verbose)
                Test.@test Strategies.option_value(strategy, :verbose) == true
            end

            Test.@testset "Construction with aliases" begin
                # Use aliases in construction
                strategy = MockStrategyWithAliases(
                    maxiter=500, tolerance=1e-8, display=true
                )

                # Access via canonical names should work
                Test.@test Strategies.has_option(strategy, :max_iter)
                Test.@test Strategies.option_value(strategy, :max_iter) == 500
                Test.@test Strategies.option_source(strategy, :max_iter) == :user

                Test.@test Strategies.has_option(strategy, :tol)
                Test.@test Strategies.option_value(strategy, :tol) == 1e-8

                Test.@test Strategies.has_option(strategy, :verbose)
                Test.@test Strategies.option_value(strategy, :verbose) == true
            end

            Test.@testset "Cross-solver alias resolution" begin
                # Test max_iter cross-solver aliases
                strategy = MockStrategyWithAliases(maxit=300)
                Test.@test Strategies.option_value(strategy, :max_iter) == 300
                Test.@test Strategies.has_option(strategy, :maxit)  # Alias access
                Test.@test Strategies.has_option(strategy, :maxiter)  # Original alias
                Test.@test Strategies.has_option(strategy, :max_iterations)  # Original alias

                # Test max_wall_time cross-solver aliases
                strategy = MockStrategyWithAliases(maxtime=3600.0)
                Test.@test Strategies.option_value(strategy, :max_wall_time) == 3600.0
                Test.@test Strategies.has_option(strategy, :max_wall_time)  # Canonical
                Test.@test Strategies.has_option(strategy, :maxtime)  # Alias used
                Test.@test Strategies.has_option(strategy, :max_time)  # Cross alias
                Test.@test Strategies.has_option(strategy, :time_limit)  # Cross alias

                # Test acceptable_tol cross-solver aliases
                strategy = MockStrategyWithAliases(acc_tol=1e-4)
                Test.@test Strategies.option_value(strategy, :acceptable_tol) == 1e-4
                Test.@test Strategies.has_option(strategy, :acceptable_tol)  # Canonical
                Test.@test Strategies.has_option(strategy, :acc_tol)  # Cross alias
            end

            Test.@testset "Access via aliases after construction" begin
                strategy = MockStrategyWithAliases(max_iter=500, tol=1e-8)

                # Test haskey with aliases
                Test.@test Strategies.has_option(strategy, :maxiter)
                Test.@test Strategies.has_option(strategy, :max_iterations)
                Test.@test Strategies.has_option(strategy, :maxit)  # Cross-solver alias
                Test.@test Strategies.has_option(strategy, :tolerance)
                Test.@test Strategies.has_option(strategy, :eps)
                Test.@test Strategies.has_option(strategy, :max_wall_time)  # Time aliases
                Test.@test Strategies.has_option(strategy, :maxtime)
                Test.@test Strategies.has_option(strategy, :max_time)
                Test.@test Strategies.has_option(strategy, :time_limit)
                Test.@test Strategies.has_option(strategy, :acceptable_tol)  # Acceptable tol aliases
                Test.@test Strategies.has_option(strategy, :acc_tol)

                # Test value access via aliases
                opts = Strategies.options(strategy)
                Test.@test opts[:maxiter] == 500
                Test.@test opts[:max_iterations] == 500
                Test.@test opts[:maxit] == 500  # Cross-solver alias
                Test.@test opts[:tolerance] == 1e-8
                Test.@test opts[:eps] == 1e-8

                # Test source access via aliases
                Test.@test Options.source(opts, :maxiter) == :user
                Test.@test Options.source(opts, :maxit) == :user  # Cross-solver alias
                Test.@test Options.source(opts, :maxtime) == :default  # Time alias (default value)
                Test.@test Options.source(opts, :acc_tol) == :default  # Acceptable tol alias (default value)
                Test.@test Options.source(opts, :max_iterations) == :user
                Test.@test Options.source(opts, :tolerance) == :user
                Test.@test Options.source(opts, :eps) == :user
            end

            Test.@testset "Mixed canonical and alias usage" begin
                # Construct with mix of canonical and aliases
                strategy = MockStrategyWithAliases(
                    max_iter=500, tolerance=1e-8, display=true
                )

                # All should be accessible via both canonical and aliases
                Test.@test Strategies.option_value(strategy, :max_iter) == 500
                Test.@test Strategies.option_value(strategy, :tol) == 1e-8
                Test.@test Strategies.option_value(strategy, :verbose) == true

                opts = Strategies.options(strategy)
                Test.@test opts[:maxiter] == 500
                Test.@test opts[:eps] == 1e-8
                Test.@test opts[:display] == true
            end

            Test.@testset "Default values with alias access" begin
                # Construct without providing options (use defaults)
                strategy = MockStrategyWithAliases()

                # Access defaults via aliases
                opts = Strategies.options(strategy)
                Test.@test opts[:maxiter] == 1000  # Default value
                Test.@test opts[:max_iterations] == 1000
                Test.@test opts[:tolerance] == 1e-6
                Test.@test opts[:eps] == 1e-6
                Test.@test opts[:display] == false

                # Check sources are :default
                Test.@test Options.source(opts, :maxiter) == :default
                Test.@test Options.source(opts, :tolerance) == :default
            end
        end

        # ====================================================================
        # INTEGRATION TESTS - Real Ipopt Strategy (if available)
        # ====================================================================

        if IPOPT_AVAILABLE
            Test.@testset "Real Ipopt Strategy - Alias Resolution" begin
                Test.@testset "Construction with canonical names" begin
                    solver = Solvers.Ipopt(max_iter=500, tol=1e-8)

                    # Test access via canonical names
                    Test.@test Strategies.has_option(solver, :max_iter)
                    Test.@test Strategies.option_value(solver, :max_iter) == 500
                    Test.@test Strategies.option_source(solver, :max_iter) == :user

                    Test.@test Strategies.has_option(solver, :tol)
                    Test.@test Strategies.option_value(solver, :tol) == 1e-8
                end

                Test.@testset "Construction with aliases" begin
                    # Ipopt has aliases: :maxiter and :max_iterations for :max_iter
                    solver = Solvers.Ipopt(maxiter=500, tol=1e-8)

                    # Access via canonical name should work
                    Test.@test Strategies.has_option(solver, :max_iter)
                    Test.@test Strategies.option_value(solver, :max_iter) == 500
                    Test.@test Strategies.option_source(solver, :max_iter) == :user
                end

                Test.@testset "Access via aliases after construction" begin
                    solver = Solvers.Ipopt(max_iter=500, tol=1e-8)

                    # Test haskey with aliases
                    Test.@test Strategies.has_option(solver, :maxiter)
                    Test.@test Strategies.has_option(solver, :max_iterations)

                    # Test value access via aliases
                    opts = Strategies.options(solver)
                    Test.@test opts[:maxiter] == 500
                    Test.@test opts[:max_iterations] == 500

                    # Test source access via aliases
                    Test.@test Options.source(opts, :maxiter) == :user
                    Test.@test Options.source(opts, :max_iterations) == :user
                end

                Test.@testset "options_dict preserves values" begin
                    # This is the original issue: options_dict should work with aliases
                    solver = Solvers.Ipopt(maxiter=500, tol=1e-8)

                    # Get options as Dict
                    opts_dict = Strategies.options_dict(solver)

                    # Dict should have canonical names (not aliases)
                    Test.@test haskey(opts_dict, :max_iter)
                    Test.@test opts_dict[:max_iter] == 500
                    Test.@test opts_dict[:tol] == 1e-8

                    # But we can still access via aliases in StrategyOptions
                    opts = Strategies.options(solver)
                    Test.@test opts[:maxiter] == 500
                    Test.@test opts[:max_iterations] == 500
                end

                Test.@testset "Multiple aliases for same option" begin
                    # Test that all aliases work
                    solver1 = Solvers.Ipopt(max_iter=500)
                    solver2 = Solvers.Ipopt(maxiter=500)
                    solver3 = Solvers.Ipopt(max_iterations=500)

                    # All should have the same value accessible via canonical name
                    Test.@test Strategies.option_value(solver1, :max_iter) == 500
                    Test.@test Strategies.option_value(solver2, :max_iter) == 500
                    Test.@test Strategies.option_value(solver3, :max_iter) == 500

                    # All should be accessible via all aliases
                    opts1 = Strategies.options(solver1)
                    opts2 = Strategies.options(solver2)
                    opts3 = Strategies.options(solver3)

                    Test.@test opts1[:maxiter] == 500
                    Test.@test opts2[:max_iterations] == 500
                    Test.@test opts3[:max_iter] == 500
                end
            end
        else
            Test.@testset "Real Ipopt Strategy (Not Available)" begin
                Test.@test_skip "NLPModelsIpopt not available"
            end
        end
    end
end

end # module

# Redefine in outer scope for TestRunner
test_alias_integration() = TestAliasIntegration.test_alias_integration()
