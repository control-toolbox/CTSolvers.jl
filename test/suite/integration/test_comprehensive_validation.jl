"""
Comprehensive tests for strict/permissive validation across all strategies.

This test suite validates that the mode parameter works correctly for:
- All strategy types (modelers and solvers)
- All construction methods (direct, build_strategy, build_strategy_from_method, orchestration wrapper)
- All validation modes (strict, permissive)
- All option types (known, unknown, defaults)

Author: CTSolvers Development Team
Date: 2026-02-06
"""

module TestComprehensiveValidation

using Test
using CTBase: CTBase
const Exceptions = CTBase.Exceptions
using CTSolvers
using CTSolvers.Strategies
using CTSolvers.Options
using CTSolvers.Modelers
using CTSolvers.Solvers
using CTSolvers.Orchestration

# Load extensions if available for testing
const IPOPT_AVAILABLE = try
    using NLPModelsIpopt
    true
catch
    false
end

const MADNLP_AVAILABLE = try
    using MadNLP
    using MadNLPMumps
    true
catch
    false
end

const MADNCL_AVAILABLE = try
    using MadNLP
    using MadNLPMumps
    using MadNCL
    true
catch
    false
end

# const KNITRO_AVAILABLE = try
#     using NLPModelsKnitro
#     using KNITRO
#     # Test if license is available
#     kc = KNITRO.KN_new()
#     KNITRO.KN_free(kc)
#     true
# catch e
#     if occursin("license", lowercase(string(e))) || occursin("-520", string(e))
#         false
#     else
#         false  # Any error means not available for testing
#     end
# end

# Always false - no license available
const KNITRO_AVAILABLE = false

# Test options for verbose output
const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

# ============================================================================
# Utility Functions
# ============================================================================

"""
Test strategy construction with all methods for a given strategy type.

# Arguments
- `strategy_type`: The concrete strategy type to test
- `strategy_id`: The strategy ID symbol
- `family`: The abstract family type
- `known_options`: NamedTuple of known valid options
- `unknown_options`: NamedTuple of unknown options
- `registry`: Strategy registry to use
"""
function test_strategy_construction(
    strategy_type::Type,
    strategy_id::Symbol,
    family::Type{<:AbstractStrategy},
    known_options::NamedTuple,
    unknown_options::NamedTuple,
    registry::CTSolvers.Strategies.StrategyRegistry
)
    @testset "Strategy Construction - $(strategy_type)" begin
        
        # ====================================================================
        # 1. Direct Constructor Tests
        # ====================================================================
        
        @testset "Direct Constructor" begin
            @testset "Strict Mode" begin
                # Known options only - should work
                @test_nowarn strategy_type(; known_options...)
                strategy = strategy_type(; known_options...)
                @test strategy isa strategy_type
                
                # Unknown option - should throw
                @test_throws Exceptions.IncorrectArgument strategy_type(; known_options..., unknown_options...)
                
                # Verify error quality
                try
                    strategy_type(; known_options..., unknown_options...)
                    @test false  # Should not reach here
                catch e
                    @test e isa Exceptions.IncorrectArgument
                    @test occursin("unknown", string(e)) || occursin("unrecognized", string(e)) || occursin("Invalid", string(e)) || occursin("not defined", string(e))
                end
            end
            
            @testset "Permissive Mode" begin
                # Known + unknown options - should work with warning
                @test_warn "Unrecognized options" strategy_type(; known_options..., unknown_options..., mode=:permissive)
                strategy = strategy_type(; known_options..., unknown_options..., mode=:permissive)
                @test strategy isa strategy_type
                
                # Verify mode is NOT stored in options (correct behavior)
                @test_throws FieldError strategy.options.mode
            end
        end
        
        # ====================================================================
        # 2. build_strategy() Tests
        # ====================================================================
        
        @testset "build_strategy()" begin
            @testset "Strict Mode" begin
                # Known options only - should work
                @test_nowarn build_strategy(strategy_id, family, registry; known_options...)
                strategy = build_strategy(strategy_id, family, registry; known_options...)
                @test strategy isa strategy_type
                
                # Unknown option - should throw
                @test_throws Exceptions.IncorrectArgument build_strategy(strategy_id, family, registry; known_options..., unknown_options...)
            end
            
            @testset "Permissive Mode" begin
                # Known + unknown options - should work
                @test_warn "Unrecognized options" build_strategy(strategy_id, family, registry; known_options..., unknown_options..., mode=:permissive)
                strategy = build_strategy(strategy_id, family, registry; known_options..., unknown_options..., mode=:permissive)
                @test strategy isa strategy_type
                                # Verify mode is NOT stored in options (correct behavior)
                @test_throws FieldError strategy.options.mode
            end
        end
        
        # ====================================================================
        # 3. build_strategy_from_method() Tests
        # ====================================================================
        
        @testset "build_strategy_from_method()" begin
            # Create method tuple with strategy ID
            method = if family == AbstractOptimizationModeler
                (:collocation, strategy_id, :ipopt)
            else
                (:collocation, :adnlp, strategy_id)
            end
            
            @testset "Strict Mode" begin
                # Known options only - should work
                @test_nowarn CTSolvers.Strategies.build_strategy_from_method(method, family, registry; known_options...)
                strategy = CTSolvers.Strategies.build_strategy_from_method(method, family, registry; known_options...)
                @test strategy isa strategy_type
                
                # Unknown option - should throw
                @test_throws Exceptions.IncorrectArgument CTSolvers.Strategies.build_strategy_from_method(method, family, registry; known_options..., unknown_options...)
            end
            
            @testset "Permissive Mode" begin
                # Known + unknown options - should work
                @test_warn "Unrecognized options" CTSolvers.Strategies.build_strategy_from_method(method, family, registry; known_options..., unknown_options..., mode=:permissive)
                strategy = CTSolvers.Strategies.build_strategy_from_method(method, family, registry; known_options..., unknown_options..., mode=:permissive)
                @test strategy isa strategy_type
                                # Verify mode is NOT stored in options (correct behavior)
                @test_throws FieldError strategy.options.mode
            end
        end
        
        # ====================================================================
        # 4. Orchestration Wrapper Tests
        # ====================================================================
        
        @testset "Orchestration Wrapper" begin
            method = if family == AbstractOptimizationModeler
                (:collocation, strategy_id, :ipopt)
            else
                (:collocation, :adnlp, strategy_id)
            end
            
            @testset "Strict Mode" begin
                # Known options only - should work
                @test_nowarn Orchestration.build_strategy_from_method(method, family, registry; known_options...)
                strategy = Orchestration.build_strategy_from_method(method, family, registry; known_options...)
                @test strategy isa strategy_type
                
                # Unknown option - should throw
                @test_throws Exceptions.IncorrectArgument Orchestration.build_strategy_from_method(method, family, registry; known_options..., unknown_options...)
            end
            
            @testset "Permissive Mode" begin
                # Known + unknown options - should work
                @test_warn "Unrecognized options" Orchestration.build_strategy_from_method(method, family, registry; known_options..., unknown_options..., mode=:permissive)
                strategy = Orchestration.build_strategy_from_method(method, family, registry; known_options..., unknown_options..., mode=:permissive)
                @test strategy isa strategy_type
                                # Verify mode is NOT stored in options (correct behavior)
                @test_throws FieldError strategy.options.mode
            end
        end
    end
end

"""
Test option recovery for a constructed strategy.

# Arguments
- `strategy`: The constructed strategy instance
- `known_options`: NamedTuple of known options that were passed
- `unknown_options`: NamedTuple of unknown options that were passed (empty for strict mode)
- `mode`: The validation mode used
"""
function test_option_recovery(
    strategy::AbstractStrategy,
    known_options::NamedTuple,
    unknown_options::NamedTuple,
    mode::Symbol
)
    @testset "Option Recovery - $(typeof(strategy))" begin
        # Test known options
        for (name, value) in pairs(known_options)
            @test has_option(strategy, name)
            @test option_value(strategy, name) == value
            @test option_source(strategy, name) == :user
        end
        
        # Test unknown options (only in permissive mode)
        if mode == :permissive
            for (name, value) in pairs(unknown_options)
                @test has_option(strategy, name)
                @test option_value(strategy, name) == value
                @test option_source(strategy, name) == :user
            end
        else
            # In strict mode, unknown options should not be present
            for (name, _) in pairs(unknown_options)
                @test !has_option(strategy, name)
            end
        end
        
        # Test mode is NOT stored in options (correct behavior)
        @test_throws FieldError strategy.options.mode
        
        # Test some default options (should be present with :default source)
        metadata_def = Strategies.metadata(typeof(strategy))
        for (name, definition) in pairs(metadata_def)
            if !(definition.default isa Options.NotProvidedType) && !haskey(known_options, name)
                @test has_option(strategy, name)
                @test option_source(strategy, name) == :default
            end
        end
    end
end

"""
Test error quality for invalid mode parameter.
"""
function test_invalid_mode(strategy_type::Type)
    @testset "Invalid Mode Tests - $(strategy_type)" begin
        @test_throws Exceptions.IncorrectArgument strategy_type(; mode=:invalid)
        @test_throws Exceptions.IncorrectArgument build_strategy(:test, AbstractStrategy, CTSolvers.Strategies.create_registry(); mode=:invalid)
    end
end

# ============================================================================
# Main Test Function
# ============================================================================

function test_comprehensive_validation()
    @testset "Comprehensive Strict/Permissive Validation" verbose=VERBOSE showtiming=SHOWTIMING begin
        
        # Create registries for testing
        modeler_registry = CTSolvers.Strategies.create_registry(
            AbstractOptimizationModeler => (ADNLPModeler, ExaModeler)
        )
        
        # Create solver registry based on available extensions
        solver_types = []
        IPOPT_AVAILABLE && push!(solver_types, CTSolvers.Solvers.IpoptSolver)
        MADNLP_AVAILABLE && push!(solver_types, CTSolvers.Solvers.MadNLPSolver)
        MADNCL_AVAILABLE && push!(solver_types, CTSolvers.Solvers.MadNCLSolver)
        # KNITRO_AVAILABLE && push!(solver_types, CTSolvers.Solvers.KnitroSolver)  # Never available - no license
        
        solver_registry = if isempty(solver_types)
            CTSolvers.Strategies.create_registry(AbstractOptimizationSolver => ())
        else
            CTSolvers.Strategies.create_registry(AbstractOptimizationSolver => tuple(solver_types...))
        end
        
        # ====================================================================
        # TESTS FOR MODELERS
        # ====================================================================
        
        @testset "Modelers" begin
            
            # ----------------------------------------------------------------
            # ADNLPModeler Tests
            # ----------------------------------------------------------------
            
            @testset "ADNLPModeler" begin
                known_options = (backend=:default, show_time=true)
                unknown_options = (fake_option=123, custom_param="test")
                
                # Test all construction methods
                test_strategy_construction(
                    ADNLPModeler, :adnlp, AbstractOptimizationModeler,
                    known_options, unknown_options, modeler_registry
                )
                
                # Test option recovery for successful constructions
                @testset "Option Recovery" begin
                    # Strict mode - known options only
                    strategy_strict = ADNLPModeler(; known_options...)
                    test_option_recovery(strategy_strict, known_options, NamedTuple(), :strict)
                    
                    # Permissive mode - known + unknown options
                    strategy_permissive = ADNLPModeler(; known_options..., unknown_options..., mode=:permissive)
                    test_option_recovery(strategy_permissive, known_options, unknown_options, :permissive)
                    
                    # Test build_strategy option recovery
                    strategy_build = build_strategy(:adnlp, AbstractOptimizationModeler, modeler_registry; known_options..., unknown_options..., mode=:permissive)
                    test_option_recovery(strategy_build, known_options, unknown_options, :permissive)
                end
                
                # Test invalid mode
                test_invalid_mode(ADNLPModeler)
            end
            
            # ----------------------------------------------------------------
            # ExaModeler Tests
            # ----------------------------------------------------------------
            
            @testset "ExaModeler" begin
                known_options = (base_type=Float64, backend=:dense)
                unknown_options = (exa_fake=456, unknown_setting=true)
                
                # Test all construction methods
                test_strategy_construction(
                    ExaModeler, :exa, AbstractOptimizationModeler,
                    known_options, unknown_options, modeler_registry
                )
                
                # Test option recovery
                @testset "Option Recovery" begin
                    strategy_strict = ExaModeler(; known_options...)
                    test_option_recovery(strategy_strict, known_options, NamedTuple(), :strict)
                    
                    strategy_permissive = ExaModeler(; known_options..., unknown_options..., mode=:permissive)
                    test_option_recovery(strategy_permissive, known_options, unknown_options, :permissive)
                end
                
                # Test invalid mode
                test_invalid_mode(ExaModeler)
            end
        end
        
        # ====================================================================
        # TESTS FOR SOLVERS (conditional based on available extensions)
        # ====================================================================
        
        @testset "Solvers" begin
            
            # ----------------------------------------------------------------
            # IpoptSolver Tests (if available)
            # ----------------------------------------------------------------
            
            if IPOPT_AVAILABLE
                @testset "IpoptSolver" begin
                    # Note: IpoptSolver options are defined in the extension
                    # We'll use some common options that are typically available
                    known_options = (max_iter=1000, tol=1e-6)
                    unknown_options = (ipopt_fake=789, custom_ipopt_opt="value")
                    
                    # Test all construction methods
                    test_strategy_construction(
                        CTSolvers.Solvers.IpoptSolver, :ipopt, AbstractOptimizationSolver,
                        known_options, unknown_options, solver_registry
                    )
                    
                    # Test option recovery
                    @testset "Option Recovery" begin
                        strategy_strict = CTSolvers.Solvers.IpoptSolver(; known_options...)
                        test_option_recovery(strategy_strict, known_options, NamedTuple(), :strict)
                        
                        strategy_permissive = CTSolvers.Solvers.IpoptSolver(; known_options..., unknown_options..., mode=:permissive)
                        test_option_recovery(strategy_permissive, known_options, unknown_options, :permissive)
                    end
                    
                    # Test invalid mode
                    test_invalid_mode(CTSolvers.Solvers.IpoptSolver)
                end
            else
                @testset "IpoptSolver (Not Available)" begin
                    @test_skip "NLPModelsIpopt not available"
                end
            end
            
            # ----------------------------------------------------------------
            # MadNLPSolver Tests (if available)
            # ----------------------------------------------------------------
            
            if MADNLP_AVAILABLE
                @testset "MadNLPSolver" begin
                    known_options = (max_iter=500, tol=1e-8)
                    unknown_options = (madnlp_fake=111, custom_madnlp=true)
                    
                    test_strategy_construction(
                        CTSolvers.Solvers.MadNLPSolver, :madnlp, AbstractOptimizationSolver,
                        known_options, unknown_options, solver_registry
                    )
                    
                    @testset "Option Recovery" begin
                        strategy_strict = CTSolvers.Solvers.MadNLPSolver(; known_options...)
                        test_option_recovery(strategy_strict, known_options, NamedTuple(), :strict)
                        
                        strategy_permissive = CTSolvers.Solvers.MadNLPSolver(; known_options..., unknown_options..., mode=:permissive)
                        test_option_recovery(strategy_permissive, known_options, unknown_options, :permissive)
                    end
                    
                    test_invalid_mode(CTSolvers.Solvers.MadNLPSolver)
                end
            else
                @testset "MadNLPSolver (Not Available)" begin
                    @test_skip "MadNLP not available"
                end
            end
            
            # ----------------------------------------------------------------
            # MadNCLSolver Tests (if available)
            # ----------------------------------------------------------------
            
            if MADNCL_AVAILABLE
                @testset "MadNCLSolver" begin
                    known_options = (max_iter=300, tol=1e-10)
                    unknown_options = (madncl_fake=222, custom_ncl_opt=3.14)
                    
                    test_strategy_construction(
                        CTSolvers.Solvers.MadNCLSolver, :madncl, AbstractOptimizationSolver,
                        known_options, unknown_options, solver_registry
                    )
                    
                    @testset "Option Recovery" begin
                        strategy_strict = CTSolvers.Solvers.MadNCLSolver(; known_options...)
                        test_option_recovery(strategy_strict, known_options, NamedTuple(), :strict)
                        
                        strategy_permissive = CTSolvers.Solvers.MadNCLSolver(; known_options..., unknown_options..., mode=:permissive)
                        test_option_recovery(strategy_permissive, known_options, unknown_options, :permissive)
                    end
                    
                    test_invalid_mode(CTSolvers.Solvers.MadNCLSolver)
                end
            else
                @testset "MadNCLSolver (Not Available)" begin
                    @test_skip "MadNCL not available"
                end
            end
            
            # ----------------------------------------------------------------
            # KnitroSolver Tests (if available)
            # ----------------------------------------------------------------
            
            # Commented out - no license available
            # if KNITRO_AVAILABLE
            #     @testset "KnitroSolver" begin
            #         known_options = (maxit=200, feastol_abs=1e-12)
            #         unknown_options = (knitro_fake=333, custom_knitro="test")
                    
            #         test_strategy_construction(
            #             CTSolvers.Solvers.KnitroSolver, :knitro, AbstractOptimizationSolver,
            #             known_options, unknown_options, solver_registry
            #         )
                    
            #         @testset "Option Recovery" begin
            #             strategy_strict = CTSolvers.Solvers.KnitroSolver(; known_options...)
            #             test_option_recovery(strategy_strict, known_options, NamedTuple(), :strict)
                        
            #             strategy_permissive = CTSolvers.Solvers.KnitroSolver(; known_options..., unknown_options..., mode=:permissive)
            #             test_option_recovery(strategy_permissive, known_options, unknown_options, :permissive)
            #         end
                    
            #         test_invalid_mode(CTSolvers.Solvers.KnitroSolver)
            #     end
            # else
            #     @testset "KnitroSolver (Not Available)" begin
            #         @test_skip "NLPModelsKnitro not available or no license"
            #     end
            # end
        end
        
        # ====================================================================
        # INTEGRATION TESTS
        # ====================================================================
        
        @testset "Integration Tests" begin
            @testset "Mode Propagation" begin
                # Test that mode is correctly propagated through different construction methods
                registry = modeler_registry
                
                # Direct constructor - mode should NOT be stored in options
                modeler1 = ADNLPModeler(backend=:default; mode=:permissive)
                # @test modeler1.options.mode == :permissive  # WRONG - mode should NOT be stored
                
                # build_strategy - mode should NOT be stored in options  
                modeler2 = build_strategy(:adnlp, AbstractOptimizationModeler, registry; backend=:default, mode=:permissive)
                # @test modeler2.options.mode == :permissive  # WRONG - mode should NOT be stored
                
                # build_strategy_from_method - mode should NOT be stored in options
                method = (:collocation, :adnlp, :ipopt)
                modeler3 = CTSolvers.Strategies.build_strategy_from_method(method, AbstractOptimizationModeler, registry; backend=:default, mode=:permissive)
                # @test modeler3.options.mode == :permissive  # WRONG - mode should NOT be stored
                
                # Orchestration wrapper - mode should NOT be stored in options
                modeler4 = Orchestration.build_strategy_from_method(method, AbstractOptimizationModeler, registry; backend=:default, mode=:permissive)
                # @test modeler4.options.mode == :permissive  # WRONG - mode should NOT be stored
                
                # CORRECT: Verify mode is NOT stored in options
                @test_throws FieldError modeler1.options.mode
                @test_throws FieldError modeler2.options.mode
                @test_throws FieldError modeler3.options.mode
                @test_throws FieldError modeler4.options.mode
            end
            
            @testset "Error Quality" begin
                # Test that error messages are helpful
                try
                    ADNLPModeler(backend=:default, completely_unknown_option=999)
                    @test false  # Should not reach here
                catch e
                    @test e isa Exceptions.IncorrectArgument
                    @test occursin("completely_unknown_option", string(e))
                    @test occursin("unknown", string(e)) || occursin("unrecognized", string(e))
                end
                
                # Test invalid mode error
                try
                    ADNLPModeler(backend=:default; mode=:totally_invalid)
                    @test false  # Should not reach here
                catch e
                    @test e isa Exceptions.IncorrectArgument
                    @test occursin("mode", string(e))
                    @test occursin("strict", string(e)) || occursin("permissive", string(e))
                end
            end
            
            @testset "Option Consistency" begin
                # Test that options are consistent across construction methods
                local known_options = (backend=:default, show_time=false)
                local unknown_options = (test_consistency=42)
                
                local registry = CTSolvers.Strategies.create_registry(
                    AbstractOptimizationModeler => (ADNLPModeler, ExaModeler)
                )
                
                # Create strategies with different methods
                modeler1 = ADNLPModeler(; backend=:default, show_time=false, test_consistency=42, mode=:permissive)
                modeler2 = build_strategy(:adnlp, AbstractOptimizationModeler, registry; backend=:default, show_time=false, test_consistency=42, mode=:permissive)
                
                method = (:collocation, :adnlp, :ipopt)
                modeler3 = CTSolvers.Strategies.build_strategy_from_method(method, AbstractOptimizationModeler, registry; backend=:default, show_time=false, test_consistency=42, mode=:permissive)
                modeler4 = Orchestration.build_strategy_from_method(method, AbstractOptimizationModeler, registry; backend=:default, show_time=false, test_consistency=42, mode=:permissive)
                
                # Test that all have the same options
                strategies = [modeler1, modeler2, modeler3, modeler4]
                
                for strategy in strategies
                    @test option_value(strategy, :backend) == :default
                    @test option_value(strategy, :show_time) == false
                    @test option_value(strategy, :test_consistency) == 42
                    @test option_source(strategy, :backend) == :user
                    @test option_source(strategy, :show_time) == :user
                    @test option_source(strategy, :test_consistency) == :user
                    # Verify mode is NOT stored in options (correct behavior)
                    @test_throws FieldError strategy.options.mode
                end
            end
        end
        
        # ====================================================================
        # REGRESSION TESTS
        # ====================================================================
        
        @testset "Regression Tests" begin
            @testset "Empty Options" begin
                # Test that strategies can be created with no options
                @test_nowarn ADNLPModeler()
                @test_nowarn ADNLPModeler(; mode=:permissive)
                
                # Test mode is NOT stored in options (correct behavior)
                modeler = ADNLPModeler()
                @test_throws FieldError modeler.options.mode  # Default
                
                modeler_permissive = ADNLPModeler(; mode=:permissive)
                @test_throws FieldError modeler_permissive.options.mode
            end
            
            @testset "Mixed Valid/Invalid Options" begin
                # Test with a mix of valid and invalid options
                @test_throws Exceptions.IncorrectArgument ADNLPModeler(
                    backend=:default,  # valid
                    show_time=true,    # valid  
                    fake_option=123,   # invalid
                    another_fake=456   # invalid
                )
                
                # In permissive mode, should work with warnings
                @test_warn "Unrecognized options" ADNLPModeler(
                    backend=:default,  # valid
                    show_time=true,    # valid
                    fake_option=123,   # invalid but accepted
                    another_fake=456;   # invalid but accepted
                    mode=:permissive
                )
            end
        end
    end
end

end # module

# Redefine in outer scope for TestRunner
test_comprehensive_validation() = TestComprehensiveValidation.test_comprehensive_validation()