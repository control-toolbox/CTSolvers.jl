"""
Integration tests for strict/permissive validation with real strategies.

Tests that the mode parameter works correctly with actual solver and modeler types.
"""

module TestRealStrategiesMode

using Test
using CTSolvers
using CTSolvers.Strategies
using CTSolvers.Options

# Load extensions if available for testing
try
    using NLPModelsIpopt
    using MadNLP
    using MadNLPMumps
catch
    # Extension packages might not be available in standard test environment
end

# Test options for verbose output
const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

# ============================================================================
# Test Function
# ============================================================================

function test_real_strategies_mode()
    @testset "Real Strategies Mode Validation" verbose=VERBOSE showtiming=SHOWTIMING begin
        
        # ====================================================================
        # INTEGRATION TESTS - Real Modelers
        # ====================================================================
        
        @testset "Modelers.ADNLP Mode Validation" begin
            
            @testset "Strict mode rejects unknown options" begin
                # Should throw error for unknown option
                @test_throws Exception CTSolvers.Modelers.ADNLP(
                    backend=:default,
                    unknown_option=123
                )
                
                # Verify it's the right kind of error
                try
                    CTSolvers.Modelers.ADNLP(
                        backend=:default,
                        unknown_option=123
                    )
                    @test false  # Should not reach here
                catch e
                    @test occursin("Unknown", string(e)) || occursin("Unrecognized", string(e))
                end
            end
            
            @testset "Strict mode accepts known options" begin
                # Should work with known options
                modeler = CTSolvers.Modelers.ADNLP(
                    backend=:default,
                    show_time=true
                )
                @test modeler isa CTSolvers.Modelers.ADNLP
                @test Strategies.option_value(modeler, :backend) == :default
                @test Strategies.option_value(modeler, :show_time) == true
                @test Strategies.option_source(modeler, :backend) == :user
                @test Strategies.option_source(modeler, :show_time) == :user
            end
            
            @testset "Permissive mode accepts unknown options" begin
                # Should work with warning
                modeler = CTSolvers.Modelers.ADNLP(
                    backend=:default,
                    unknown_option=123;
                    mode=:permissive
                )
                @test modeler isa CTSolvers.Modelers.ADNLP
                
                # Unknown option should be stored
                @test Strategies.has_option(modeler, :unknown_option)
                @test Strategies.option_value(modeler, :unknown_option) == 123
                @test Strategies.option_source(modeler, :unknown_option) == :user
            end
            
            @testset "Permissive mode validates known options" begin
                # Type validation should still work
                @test_throws Exception CTSolvers.Modelers.ADNLP(
                    backend=:default,
                    show_time="invalid";
                    mode=:permissive
                )
            end
        end
        
        @testset "Modelers.ExaModeler Mode Validation" begin
            
            @testset "Strict mode rejects unknown options" begin
                # Should throw error for unknown option
                @test_throws Exception CTSolvers.Modelers.ExaModeler(
                    backend=nothing,
                    unknown_option=123
                )
            end
            
            @testset "Strict mode accepts known options" begin
                # Should work with known options
                modeler = CTSolvers.Modelers.ExaModeler(
                    backend=nothing
                )
                @test modeler isa CTSolvers.Modelers.ExaModeler
                @test Strategies.option_value(modeler, :backend) === nothing
            end
            
            @testset "Permissive mode accepts unknown options" begin
                # Should work with warning
                modeler = CTSolvers.Modelers.ExaModeler(
                    backend=nothing,
                    unknown_option=123;
                    mode=:permissive
                )
                @test modeler isa CTSolvers.Modelers.ExaModeler
                @test Strategies.has_option(modeler, :unknown_option)
            end
        end
        
        # ====================================================================
        # INTEGRATION TESTS - Real Solvers (if extensions available)
        # ====================================================================
        
        @testset "Solver Mode Validation" begin
            # Test with any available solver extensions
            available_solvers = []
            
            # Check for available solver extensions
            if isdefined(CTSolvers, :Solvers) && isdefined(CTSolvers.Solvers, :IpoptSolver)
                push!(available_solvers, CTSolvers.Solvers.IpoptSolver)
            end
            
            if isdefined(CTSolvers, :Solvers) && isdefined(CTSolvers.Solvers, :MadNLPSolver)
                push!(available_solvers, CTSolvers.Solvers.MadNLPSolver)
            end
            
            if isempty(available_solvers)
                @testset "No solver extensions available" begin
                    @test_skip "No solver extensions available for testing"
                end
                return
            end
            
            for solver_type in available_solvers
                @testset "$(nameof(solver_type)) Mode Validation" begin
                    
                    @testset "Strict mode rejects unknown options" begin
                        # Should throw error for unknown option
                        @test_throws Exception solver_type(
                            max_iter=1000,
                            unknown_option=123
                        )
                    end
                    
                    @testset "Strict mode accepts known options" begin
                        # Should work with known options
                        solver = solver_type(max_iter=1000)
                        @test solver isa solver_type
                        @test Strategies.option_value(solver, :max_iter) == 1000
                        @test Strategies.option_source(solver, :max_iter) == :user
                    end
                    
                    @testset "Permissive mode accepts unknown options" begin
                        # Should work with warning
                        solver = solver_type(
                            max_iter=1000,
                            unknown_option=123;
                            mode=:permissive
                        )
                        @test solver isa solver_type
                        @test Strategies.has_option(solver, :unknown_option)
                    end
                    
                    @testset "Permissive mode validates known options" begin
                        # Type validation should still work
                        @test_throws Exception solver_type(
                            max_iter="invalid";
                            mode=:permissive
                        )
                    end
                end
            end
        end
        
        # ====================================================================
        # INTEGRATION TESTS - Mode Parameter Propagation
        # ====================================================================
        
        @testset "Mode Parameter Propagation" begin
            
            @testset "Default mode is strict" begin
                # Without specifying mode, should be strict
                @test_throws Exception CTSolvers.Modelers.ADNLP(
                    backend=:default,
                    unknown_option=123
                )
            end
            
            @testset "Explicit strict same as default" begin
                # Explicit :strict should behave same as default
                error1 = nothing
                error2 = nothing
                
                try
                    CTSolvers.Modelers.ADNLP(
                        backend=:default,
                        unknown_option=123
                    )
                catch e
                    error1 = e
                end
                
                try
                    CTSolvers.Modelers.ADNLP(
                        backend=:default,
                        unknown_option=123;
                        mode=:strict
                    )
                catch e
                    error2 = e
                end
                
                @test error1 !== nothing
                @test error2 !== nothing
                @test typeof(error1) == typeof(error2)
            end
            
            @testset "Mode parameter validation" begin
                # Invalid mode should throw error
                @test_throws Exception CTSolvers.Modelers.ADNLP(
                    backend=:default;
                    mode=:invalid
                )
            end
        end
        
        # ====================================================================
        # INTEGRATION TESTS - Option Sources
        # ====================================================================
        
        @testset "Option Source Tracking" begin
            
            @testset "Known options have :user source" begin
                modeler = CTSolvers.Modelers.ADNLP(
                    backend=:default,
                    show_time=true
                )
                @test Strategies.option_source(modeler, :backend) == :user
                @test Strategies.option_source(modeler, :show_time) == :user
            end
            
            @testset "Unknown options have :user source in permissive" begin
                modeler = CTSolvers.Modelers.ADNLP(
                    backend=:default,
                    unknown_option=123;
                    mode=:permissive
                )
                @test Strategies.option_source(modeler, :unknown_option) == :user
            end
            
            @testset "Default options have :default source" begin
                modeler = CTSolvers.Modelers.ADNLP()
                @test Strategies.option_source(modeler, :backend) == :default
            end
        end
        
        # ====================================================================
        # INTEGRATION TESTS - Mixed Options
        # ====================================================================
        
        @testset "Mixed Known/Unknown Options" begin
            
            @testset "Strict mode rejects mix" begin
                # Should throw even with known options present
                @test_throws Exception CTSolvers.Modelers.ADNLP(
                    backend=:default,
                    show_time=true,
                    unknown_option=123
                )
            end
            
            @testset "Permissive mode accepts mix" begin
                # Should work with both known and unknown
                modeler = CTSolvers.Modelers.ADNLP(
                    backend=:default,
                    show_time=true,
                    unknown_option=123,
                    another_unknown="test";
                    mode=:permissive
                )
                @test modeler isa CTSolvers.Modelers.ADNLP
                @test Strategies.option_value(modeler, :backend) == :default
                @test Strategies.option_value(modeler, :show_time) == true
                @test Strategies.option_value(modeler, :unknown_option) == 123
                @test Strategies.option_value(modeler, :another_unknown) == "test"
            end
            
            @testset "Known options still validated in permissive" begin
                # Type validation should still work for known options
                @test_throws Exception CTSolvers.Modelers.ADNLP(
                    backend=:default,
                    show_time="invalid",  # Wrong type (Bool expected)
                    unknown_option=123;
                    mode=:permissive
                )
            end
        end
    end
end

end # module

# Export test function to outer scope
test_real_strategies_mode() = TestRealStrategiesMode.test_real_strategies_mode()
