"""
Unit tests for mode parameter validation and behavior.

Tests the mode parameter itself: validation, default behavior, and error handling.
"""
module TestValidationMode

using Test
using CTSolvers
using CTSolvers.Strategies
using CTSolvers.Solvers
using NLPModelsIpopt

# Test options for verbose output
const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

function test_validation_mode()
    @testset "Mode Parameter Validation" verbose=VERBOSE showtiming=SHOWTIMING begin
        
        # ====================================================================
        # UNIT TESTS - Mode Parameter Validation
        # ====================================================================
        
        @testset "Valid Modes Accepted" begin
            # :strict should work
            opts = Strategies.build_strategy_options(Solvers.IpoptSolver; max_iter=100, mode=:strict)
            @test opts[:max_iter] == 100
            
            # :permissive should work
            opts = @test_logs (:warn,) match_mode=:any begin
                Strategies.build_strategy_options(Solvers.IpoptSolver; max_iter=100, custom=1, mode=:permissive)
            end
            @test opts[:max_iter] == 100
        end
        
        @testset "Invalid Mode Rejected" begin
            @test_throws Exception begin
                Strategies.build_strategy_options(Solvers.IpoptSolver; max_iter=100, mode=:invalid)
            end
            
            @test_throws Exception begin
                Strategies.build_strategy_options(Solvers.IpoptSolver; mode=:wrong)
            end
        end
        
        @testset "Invalid Mode Error Message" begin
            try
                Strategies.build_strategy_options(Solvers.IpoptSolver; mode=:invalid)
                @test false
            catch e
                msg = string(e)
                @test occursin("Invalid", msg) || occursin("mode", msg)
                @test occursin(":strict", msg)
                @test occursin(":permissive", msg)
            end
        end
        
        # ====================================================================
        # UNIT TESTS - Default Mode Behavior
        # ====================================================================
        
        @testset "Default Mode is Strict" begin
            # Without mode parameter, should behave as strict
            @test_throws Exception begin
                Strategies.build_strategy_options(Solvers.IpoptSolver; unknown_option=123)
            end
        end
        
        @testset "Explicit Strict Same as Default" begin
            # Explicit mode=:strict should be identical to default
            try
                Strategies.build_strategy_options(Solvers.IpoptSolver; unknown=123)
                @test false
            catch e1
                try
                    Strategies.build_strategy_options(Solvers.IpoptSolver; unknown=123, mode=:strict)
                    @test false
                catch e2
                    # Both should throw the same type of error
                    @test typeof(e1) == typeof(e2)
                end
            end
        end
        
        # ====================================================================
        # UNIT TESTS - Mode Parameter Type
        # ====================================================================
        
        @testset "Mode Must Be Symbol" begin
            # String should not work
            @test_throws Exception begin
                Strategies.build_strategy_options(Solvers.IpoptSolver; mode="strict")
            end
        end
    end
end

end # module

# Export test function to outer scope
test_validation_mode() = TestValidationMode.test_validation_mode()
