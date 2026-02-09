"""
Unit tests for strict/permissive mode in option routing.

Tests the behavior of route_all_options() with mode parameter,
ensuring unknown options are handled correctly in both strict and permissive modes.
"""
module TestRoutingValidation

using Test
using CTSolvers
using CTSolvers.Strategies
using CTSolvers.Orchestration
using CTSolvers.Options

# Test options for verbose output
const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

# ============================================================================
# Helper: Create test registry and families
# ============================================================================

# Define mock types for testing
abstract type TestDiscretizerFamily <: Strategies.AbstractStrategy end
struct MyDiscretizer <: TestDiscretizerFamily end
Strategies.id(::Type{MyDiscretizer}) = :test_discretizer
Strategies.metadata(::Type{MyDiscretizer}) = Strategies.StrategyMetadata()

abstract type TestModelerFamily <: Strategies.AbstractStrategy end
struct MyModeler <: TestModelerFamily end
Strategies.id(::Type{MyModeler}) = :test_modeler
Strategies.metadata(::Type{MyModeler}) = Strategies.StrategyMetadata()

abstract type TestSolverFamily <: Strategies.AbstractStrategy end
struct MySolver <: TestSolverFamily end
Strategies.id(::Type{MySolver}) = :test_solver
Strategies.metadata(::Type{MySolver}) = Strategies.StrategyMetadata()

function create_test_setup()
    # Create a simple registry with test strategies
    registry = Strategies.create_registry(
        TestDiscretizerFamily => (MyDiscretizer,),
        TestModelerFamily => (MyModeler,),
        TestSolverFamily => (MySolver,)
    )
    
    # Define families
    families = (
        discretizer = TestDiscretizerFamily,
        modeler = TestModelerFamily,
        solver = TestSolverFamily
    )
    
    # Define action options
    action_defs = [
        OptionDefinition(
            name = :display,
            type = Bool,
            default = true,
            description = "Display progress"
        )
    ]
    
    return registry, families, action_defs
end

function test_routing_validation()
    @testset "Routing Validation Modes" verbose=VERBOSE showtiming=SHOWTIMING begin
        
        # ====================================================================
        # UNIT TESTS - Mode Parameter Validation
        # ====================================================================
        
        @testset "Mode Parameter Validation" begin
            registry, families, action_defs = create_test_setup()
            method = (:test_discretizer, :test_modeler, :test_solver)
            kwargs = (display = true,)
            
            # Valid modes should work
            @test_nowarn Orchestration.route_all_options(
                method, families, action_defs, kwargs, registry;
                mode = :strict
            )
            
            @test_nowarn Orchestration.route_all_options(
                method, families, action_defs, kwargs, registry;
                mode = :permissive
            )
            
            # Invalid mode should throw Exception
            @test_throws Exception Orchestration.route_all_options(
                method, families, action_defs, kwargs, registry;
                mode = :invalid
            )
        end
        
        # ====================================================================
        # UNIT TESTS - Strict Mode (Default)
        # ====================================================================
        
        @testset "Strict Mode - Unknown Option Rejected" begin
            registry, families, action_defs = create_test_setup()
            method = (:test_discretizer, :test_modeler, :test_solver)
            
            # Unknown option without disambiguation should fail in strict mode
            kwargs = (unknown_option = 123,)
            
            @test_throws Exception Orchestration.route_all_options(
                method, families, action_defs, kwargs, registry;
                mode = :strict
            )
        end
        
        @testset "Strict Mode - Unknown Disambiguated Option Rejected" begin
            registry, families, action_defs = create_test_setup()
            method = (:test_discretizer, :test_modeler, :test_solver)
            
            # Unknown option with disambiguation should still fail in strict mode
            kwargs = (unknown_option = Strategies.route_to(test_solver=123),)
            
            @test_throws Exception Orchestration.route_all_options(
                method, families, action_defs, kwargs, registry;
                mode = :strict
            )
        end
        
        # ====================================================================
        # UNIT TESTS - Permissive Mode
        # ====================================================================
        
        @testset "Permissive Mode - Unknown Disambiguated Option Accepted" begin
            registry, families, action_defs = create_test_setup()
            method = (:test_discretizer, :test_modeler, :test_solver)
            
            # Unknown option with disambiguation should be accepted with warning
            kwargs = (custom_option = Strategies.route_to(test_solver=123),)
            
            # Should emit warning but not throw
            result = @test_logs (:warn, r"Unknown option routed in permissive mode") begin
                Orchestration.route_all_options(
                    method, families, action_defs, kwargs, registry;
                    mode = :permissive
                )
            end
            
            # Option should be routed to solver
            @test haskey(result.strategies.solver, :custom_option)
            @test result.strategies.solver.custom_option == 123
        end
        
        @testset "Permissive Mode - Multiple Unknown Options" begin
            registry, families, action_defs = create_test_setup()
            method = (:test_discretizer, :test_modeler, :test_solver)
            
            # Multiple unknown options with disambiguation
            kwargs = (
                custom1 = Strategies.route_to(test_solver=100),
                custom2 = Strategies.route_to(test_modeler=200)
            )
            
            result = @test_logs (:warn,) (:warn,) match_mode=:any begin
                Orchestration.route_all_options(
                    method, families, action_defs, kwargs, registry;
                    mode = :permissive
                )
            end
            
            @test result.strategies.solver.custom1 == 100
            @test result.strategies.modeler.custom2 == 200
        end
        
        @testset "Permissive Mode - Unknown Without Disambiguation Still Fails" begin
            registry, families, action_defs = create_test_setup()
            method = (:test_discretizer, :test_modeler, :test_solver)
            
            # Unknown option without disambiguation should still fail
            # (can't route without knowing which strategy)
            kwargs = (unknown_option = 123,)
            
            @test_throws Exception Orchestration.route_all_options(
                method, families, action_defs, kwargs, registry;
                mode = :permissive
            )
        end
        
        # ====================================================================
        # UNIT TESTS - Invalid Routing Detection
        # ====================================================================
        
        @testset "Invalid Routing - Wrong Strategy in Permissive Mode" begin
            registry, families, action_defs = create_test_setup()
            method = (:test_discretizer, :test_modeler, :test_solver)
            
            # If an option is known but routed to wrong strategy,
            # it should fail even in permissive mode
            # (This would require a real option to test properly)
            # For now, just verify mode doesn't break normal validation
            
            kwargs = (display = true,)
            result = Orchestration.route_all_options(
                method, families, action_defs, kwargs, registry;
                mode = :permissive
            )
            
            @test result.action[:display].value == true
        end
        
        # ====================================================================
        # UNIT TESTS - Default Mode is Strict
        # ====================================================================
        
        @testset "Default Mode is Strict" begin
            registry, families, action_defs = create_test_setup()
            method = (:test_discretizer, :test_modeler, :test_solver)
            
            # Without mode parameter, should behave as strict
            kwargs = (unknown_option = Strategies.route_to(test_solver=123),)
            
            @test_throws Exception Orchestration.route_all_options(
                method, families, action_defs, kwargs, registry
            )
        end
    end
end

end # module

# Export test function to outer scope
test_routing_validation() = TestRoutingValidation.test_routing_validation()
