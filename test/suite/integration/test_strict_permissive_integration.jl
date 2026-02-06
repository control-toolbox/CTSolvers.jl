"""
Integration tests for strict/permissive validation system.

Tests complete workflows combining option validation, routing, and disambiguation
to ensure the system works correctly end-to-end.
"""

module TestStrictPermissiveIntegration

using Test
using CTSolvers
using CTSolvers.Strategies
using CTSolvers.Options
using CTSolvers.Orchestration

# Test options for verbose output
const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

# ============================================================================
# TOP-LEVEL: Fake types for integration testing
# ============================================================================

# Define distinct abstract families for testing
# This allows proper routing and disambiguation tests
"""Abstract family for test solvers."""
abstract type AbstractTestSolver <: Strategies.AbstractStrategy end

"""Abstract family for test modelers."""
abstract type AbstractTestModeler <: Strategies.AbstractStrategy end

"""Abstract family for test discretizers."""
abstract type AbstractTestDiscretizer <: Strategies.AbstractStrategy end

"""Fake solver strategy for testing."""
struct FakeSolver <: AbstractTestSolver
    options::Strategies.StrategyOptions
end

"""Fake modeler strategy for testing."""
struct FakeModeler <: AbstractTestModeler
    options::Strategies.StrategyOptions
end

"""Fake discretizer strategy for testing."""
struct FakeDiscretizer <: AbstractTestDiscretizer
    options::Strategies.StrategyOptions
end

# Strategy IDs
Strategies.id(::Type{FakeSolver}) = :fake_solver
Strategies.id(::Type{FakeModeler}) = :fake_modeler
Strategies.id(::Type{FakeDiscretizer}) = :fake_discretizer

# Metadata for FakeSolver
function Strategies.metadata(::Type{FakeSolver})
    return Strategies.StrategyMetadata(
        Options.OptionDefinition(
            name=:max_iter,
            type=Int,
            default=1000,
            description="Maximum iterations"
        ),
        Options.OptionDefinition(
            name=:tol,
            type=Float64,
            default=1e-6,
            description="Tolerance"
        )
    )
end

# Metadata for FakeModeler
function Strategies.metadata(::Type{FakeModeler})
    return Strategies.StrategyMetadata(
        Options.OptionDefinition(
            name=:backend,
            type=Symbol,
            default=:sparse,
            description="Backend type"
        ),
        Options.OptionDefinition(
            name=:max_iter,
            type=Int,
            default=500,
            description="Maximum iterations"
        )
    )
end

# Metadata for FakeDiscretizer
function Strategies.metadata(::Type{FakeDiscretizer})
    return Strategies.StrategyMetadata(
        Options.OptionDefinition(
            name=:grid_size,
            type=Int,
            default=100,
            description="Grid size"
        )
    )
end

# Constructors
function FakeSolver(; mode::Symbol = :strict, kwargs...)
    opts = Strategies.build_strategy_options(FakeSolver; mode=mode, kwargs...)
    return FakeSolver(opts)
end

function FakeModeler(; mode::Symbol = :strict, kwargs...)
    opts = Strategies.build_strategy_options(FakeModeler; mode=mode, kwargs...)
    return FakeModeler(opts)
end

function FakeDiscretizer(; mode::Symbol = :strict, kwargs...)
    opts = Strategies.build_strategy_options(FakeDiscretizer; mode=mode, kwargs...)
    return FakeDiscretizer(opts)
end

# ============================================================================
# Test Function
# ============================================================================

function test_strict_permissive_integration()
    @testset "Strict/Permissive Integration" verbose=VERBOSE showtiming=SHOWTIMING begin
        
        # ====================================================================
        # INTEGRATION TESTS - Single Strategy Workflows
        # ====================================================================
        
        @testset "Single Strategy Workflows" begin
            
            @testset "Strict workflow with valid options" begin
                # Create solver with valid options
                solver = FakeSolver(max_iter=2000, tol=1e-8)
                
                @test solver isa FakeSolver
                @test Strategies.option_value(solver, :max_iter) == 2000
                @test Strategies.option_value(solver, :tol) == 1e-8
                @test Strategies.option_source(solver, :max_iter) == :user
                @test Strategies.option_source(solver, :tol) == :user
            end
            
            @testset "Strict workflow rejects invalid options" begin
                # Should reject unknown option
                @test_throws Exception FakeSolver(max_iter=2000, unknown=123)
                
                # Should reject invalid type
                @test_throws Exception FakeSolver(max_iter="invalid")
            end
            
            @testset "Permissive workflow with mixed options" begin
                # Create solver with mix of known and unknown options
                solver = FakeSolver(
                    max_iter=2000,
                    tol=1e-8,
                    custom_linear_solver="ma57",
                    mu_strategy="adaptive";
                    mode=:permissive
                )
                
                @test solver isa FakeSolver
                @test Strategies.option_value(solver, :max_iter) == 2000
                @test Strategies.option_value(solver, :tol) == 1e-8
                @test Strategies.has_option(solver, :custom_linear_solver)
                @test Strategies.option_value(solver, :custom_linear_solver) == "ma57"
                @test Strategies.has_option(solver, :mu_strategy)
            end
            
            @testset "Permissive still validates known options" begin
                # Type validation should still work
                @test_throws Exception FakeSolver(
                    max_iter="invalid",
                    custom_option=123;
                    mode=:permissive
                )
            end
        end
        
        # ====================================================================
        # INTEGRATION TESTS - Multiple Strategy Workflows
        # ====================================================================
        
        @testset "Multiple Strategy Workflows" begin
            
            @testset "Multiple strategies with different modes" begin
                # Solver in strict mode
                solver = FakeSolver(max_iter=2000)
                @test solver isa FakeSolver
                
                # Modeler in permissive mode
                modeler = FakeModeler(
                    backend=:dense,
                    custom_option="test";
                    mode=:permissive
                )
                @test modeler isa FakeModeler
                @test Strategies.has_option(modeler, :custom_option)
                
                # Discretizer in strict mode
                discretizer = FakeDiscretizer(grid_size=200)
                @test discretizer isa FakeDiscretizer
            end
            
            @testset "Ambiguous option with disambiguation" begin
                # Both solver and modeler have max_iter option
                # Test with route_to() for disambiguation
                
                routed_solver = Strategies.route_to(solver=3000)
                routed_modeler = Strategies.route_to(modeler=1500)
                
                @test routed_solver isa Strategies.RoutedOption
                @test routed_modeler isa Strategies.RoutedOption
                @test length(routed_solver.routes) == 1
                @test length(routed_modeler.routes) == 1
            end
            
            @testset "Multiple strategies with route_to()" begin
                # Create routed option for multiple strategies
                routed = Strategies.route_to(
                    solver=3000,
                    modeler=1500,
                    discretizer=250
                )
                
                @test routed isa Strategies.RoutedOption
                @test length(routed.routes) == 3
                @test routed.routes.solver == 3000
                @test routed.routes.modeler == 1500
                @test routed.routes.discretizer == 250
            end
        end
        
        # ====================================================================
        # INTEGRATION TESTS - Registry-Based Workflows
        # ====================================================================
        
        @testset "Registry-Based Workflows" begin
            # Create registry with distinct families
            registry = Strategies.create_registry(
                AbstractTestSolver => (FakeSolver,),
                AbstractTestModeler => (FakeModeler,),
                AbstractTestDiscretizer => (FakeDiscretizer,)
            )
            
            @testset "Build from ID in strict mode" begin
                solver = Strategies.build_strategy(
                    :fake_solver,
                    AbstractTestSolver,
                    registry;
                    max_iter=2000
                )
                @test solver isa FakeSolver
                @test Strategies.option_value(solver, :max_iter) == 2000
            end
            
            @testset "Build from ID in permissive mode" begin
                solver = Strategies.build_strategy(
                    :fake_solver,
                    AbstractTestSolver,
                    registry;
                    max_iter=2000,
                    custom_option=123,
                    mode=:permissive
                )
                @test solver isa FakeSolver
                @test Strategies.has_option(solver, :custom_option)
            end
            
            @testset "Build from method tuple" begin
                method = (:fake_solver, :fake_modeler, :fake_discretizer)
                
                # Build solver from method (first family in tuple)
                solver = Strategies.build_strategy_from_method(
                    method,
                    AbstractTestSolver,
                    registry;
                    max_iter=2000
                )
                @test solver isa FakeSolver
            end
        end
        
        # ====================================================================
        # INTEGRATION TESTS - Option Routing Workflows
        # ====================================================================
        
        @testset "Option Routing Workflows" begin
            registry = Strategies.create_registry(
                AbstractTestSolver => (FakeSolver,),
                AbstractTestModeler => (FakeModeler,)
            )
            
            method = (:fake_solver, :fake_modeler)
            
            @testset "Routing with strict mode" begin
                # Create families map (must be NamedTuple, not Dict)
                families = (
                    solver=AbstractTestSolver,
                    modeler=AbstractTestModeler
                )
                
                # Action definitions (empty for this test)
                action_defs = Options.OptionDefinition[]
                
                # Options with disambiguation (use strategy IDs, not family names)
                kwargs = (
                    max_iter=Strategies.route_to(fake_solver=3000, fake_modeler=1500),
                    tol = 0.5e-6,
                    backend = :dense
                )
                
                # Route options in strict mode
                routed = Orchestration.route_all_options(
                    method,
                    families,
                    action_defs,
                    kwargs,
                    registry;
                    mode=:strict
                )
                
                @test haskey(routed.strategies, :solver)
                @test haskey(routed.strategies, :modeler)
            end
            
            @testset "Routing with permissive mode" begin
                # Create families map (must be NamedTuple, not Dict)
                families = (
                    solver=AbstractTestSolver,
                    modeler=AbstractTestModeler
                )
                
                action_defs = Options.OptionDefinition[]
                
                # Options with unknown option disambiguated (use strategy IDs, not family names)
                kwargs = (
                    max_iter=Strategies.route_to(fake_solver=3000),
                    custom_solver_option=Strategies.route_to(fake_solver="advanced"),
                )
                
                # Route options in permissive mode
                routed = Orchestration.route_all_options(
                    method,
                    families,
                    action_defs,
                    kwargs,
                    registry;
                    mode=:permissive
                )
                
                @test haskey(routed.strategies, :solver)
            end
        end
        
        # ====================================================================
        # INTEGRATION TESTS - Error Recovery Workflows
        # ====================================================================
        
        @testset "Error Recovery Workflows" begin
            
            @testset "Graceful degradation to permissive" begin
                # Try strict first, fall back to permissive
                function create_solver_safe(; kwargs...)
                    try
                        return FakeSolver(; kwargs...)
                    catch e
                        if occursin("Unknown", string(e)) || occursin("Unrecognized", string(e))
                            return FakeSolver(; kwargs..., mode=:permissive)
                        else
                            rethrow(e)
                        end
                    end
                end
                
                # Should work with unknown option via fallback
                solver = create_solver_safe(max_iter=2000, unknown=123)
                @test solver isa FakeSolver
                @test Strategies.has_option(solver, :unknown)
            end
            
            @testset "Validation errors not masked" begin
                # Type errors should not be caught by permissive mode
                @test_throws Exception FakeSolver(
                    max_iter="invalid";
                    mode=:permissive
                )
            end
        end
        
        # ====================================================================
        # INTEGRATION TESTS - Real-World Scenarios
        # ====================================================================
        
        @testset "Real-World Scenarios" begin
            
            @testset "Development workflow (strict)" begin
                # Developer wants early error detection
                @test_throws Exception FakeSolver(
                    max_itter=2000  # Typo
                )
                
                # Error message should suggest correct option
                try
                    FakeSolver(max_itter=2000)
                    @test false
                catch e
                    msg = string(e)
                    # Should suggest max_iter
                    @test occursin("max_iter", msg) || occursin("Unrecognized", msg)
                end
            end
            
            @testset "Production workflow (permissive)" begin
                # Production needs backend-specific options
                solver = FakeSolver(
                    max_iter=2000,
                    tol=1e-8,
                    # Backend-specific options
                    linear_solver="ma57",
                    mu_strategy="adaptive",
                    warm_start_init_point="yes";
                    mode=:permissive
                )
                
                @test solver isa FakeSolver
                @test Strategies.option_value(solver, :max_iter) == 2000
                @test Strategies.has_option(solver, :linear_solver)
                @test Strategies.has_option(solver, :mu_strategy)
                @test Strategies.has_option(solver, :warm_start_init_point)
            end
            
            @testset "Migration workflow" begin
                # Old code with deprecated options
                function create_legacy_solver()
                    # Use permissive mode for gradual migration
                    return FakeSolver(
                        max_iter=2000,
                        old_option="legacy",
                        deprecated_flag=true;
                        mode=:permissive
                    )
                end
                
                solver = create_legacy_solver()
                @test solver isa FakeSolver
                @test Strategies.has_option(solver, :old_option)
                @test Strategies.has_option(solver, :deprecated_flag)
            end
        end
        
        # ====================================================================
        # INTEGRATION TESTS - Performance Scenarios
        # ====================================================================
        
        @testset "Performance Scenarios" begin
            
            @testset "Many options in strict mode" begin
                # Should handle many known options efficiently
                solver = FakeSolver(
                    max_iter=2000,
                    tol=1e-8
                )
                @test solver isa FakeSolver
            end
            
            @testset "Many options in permissive mode" begin
                # Should handle many unknown options efficiently
                solver = FakeSolver(
                    max_iter=2000,
                    tol=1e-8,
                    opt1="a", opt2="b", opt3="c", opt4="d", opt5="e",
                    opt6="f", opt7="g", opt8="h", opt9="i", opt10="j";
                    mode=:permissive
                )
                @test solver isa FakeSolver
                @test Strategies.has_option(solver, :opt1)
                @test Strategies.has_option(solver, :opt10)
            end
        end
        
        # ====================================================================
        # INTEGRATION TESTS - Edge Cases
        # ====================================================================
        
        @testset "Edge Cases" begin
            
            @testset "Empty options" begin
                # Should work with no options
                solver = FakeSolver()
                @test solver isa FakeSolver
                @test Strategies.option_source(solver, :max_iter) == :default
            end
            
            @testset "Only unknown options in permissive" begin
                # Should work with only unknown options
                solver = FakeSolver(
                    unknown1=1,
                    unknown2=2,
                    unknown3=3;
                    mode=:permissive
                )
                @test solver isa FakeSolver
                @test Strategies.has_option(solver, :unknown1)
                @test Strategies.has_option(solver, :unknown2)
                @test Strategies.has_option(solver, :unknown3)
            end
            
            @testset "Complex value types" begin
                # Should handle various value types
                solver = FakeSolver(
                    max_iter=2000,
                    array_option=[1, 2, 3],
                    dict_option=Dict(:a => 1),
                    tuple_option=(1, 2, 3),
                    function_option=x -> x^2;
                    mode=:permissive
                )
                @test solver isa FakeSolver
                @test Strategies.has_option(solver, :array_option)
                @test Strategies.has_option(solver, :dict_option)
                @test Strategies.has_option(solver, :tuple_option)
                @test Strategies.has_option(solver, :function_option)
            end
        end
    end
end

end # module

# Export test function to outer scope
test_strict_permissive_integration() = TestStrictPermissiveIntegration.test_strict_permissive_integration()
