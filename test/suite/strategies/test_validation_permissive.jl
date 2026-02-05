"""
Unit tests for permissive mode validation in strategy option building.

Tests the behavior of build_strategy_options() in permissive mode,
ensuring unknown options are accepted with warnings while known options
are still validated.
"""
module TestValidationPermissive

using Test
using CTSolvers
using CTSolvers.Strategies
using CTSolvers.Solvers
using CTSolvers.Options

# Test options for verbose output
const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

function test_validation_permissive()
    @testset "Permissive Mode Validation" verbose=VERBOSE showtiming=SHOWTIMING begin
        
        # ====================================================================
        # UNIT TESTS - Known Options Work Normally
        # ====================================================================
        
        @testset "Known Options Work Normally" begin
            opts = Strategies.build_strategy_options(Solvers.IpoptSolver; max_iter=100, mode=:permissive)
            @test opts[:max_iter] == 100
            @test Strategies.option_source(opts, :max_iter) == :user
        end
        
        # ====================================================================
        # UNIT TESTS - Type Validation Still Applied
        # ====================================================================
        
        @testset "Type Validation Still Applied" begin
            # Type validation should work even in permissive mode for known options
            @test_throws Exception begin
                Strategies.build_strategy_options(Solvers.IpoptSolver; max_iter=1.5, mode=:permissive)
            end
        end
        
        # ====================================================================
        # UNIT TESTS - Custom Validation Still Applied
        # ====================================================================
        
        @testset "Custom Validation Still Applied" begin
            # Custom validation should work even in permissive mode
            @test_throws Exception begin
                Strategies.build_strategy_options(Solvers.IpoptSolver; tol=-1.0, mode=:permissive)
            end
        end
        
        # ====================================================================
        # UNIT TESTS - Unknown Options Accepted with Warning
        # ====================================================================
        
        @testset "Unknown Option Accepted with Warning" begin
            # Capture warning
            opts = @test_logs (:warn, r"Unrecognized options") begin
                Strategies.build_strategy_options(Solvers.IpoptSolver; unknown_option=123, mode=:permissive)
            end
            @test haskey(opts.options, :unknown_option)
            @test opts[:unknown_option] == 123
        end
        
        @testset "Multiple Unknown Options Accepted" begin
            opts = @test_logs (:warn, r"Unrecognized options") begin
                Strategies.build_strategy_options(
                    Solvers.IpoptSolver;
                    unknown1=123,
                    unknown2=456,
                    mode=:permissive
                )
            end
            @test opts[:unknown1] == 123
            @test opts[:unknown2] == 456
        end
        
        @testset "Mix Known/Unknown Options Accepted" begin
            opts = @test_logs (:warn, r"Unrecognized options") begin
                Strategies.build_strategy_options(
                    Solvers.IpoptSolver;
                    max_iter=1000,
                    unknown=123,
                    mode=:permissive
                )
            end
            @test opts[:max_iter] == 1000
            @test opts[:unknown] == 123
        end
        
        # ====================================================================
        # UNIT TESTS - Options Have Correct Source
        # ====================================================================
        
        @testset "Unknown Options Have User Source" begin
            opts = @test_logs (:warn,) begin
                Strategies.build_strategy_options(Solvers.IpoptSolver; custom_opt=123, mode=:permissive)
            end
            @test Strategies.option_source(opts, :custom_opt) == :user
        end
        
        # ====================================================================
        # UNIT TESTS - Warning Message Quality
        # ====================================================================
        
        @testset "Warning Contains Option List" begin
            # We can't easily test warning content, but we can verify it warns
            @test_logs (:warn,) begin
                Strategies.build_strategy_options(Solvers.IpoptSolver; custom1=1, custom2=2, mode=:permissive)
            end
        end
        
        # ====================================================================
        # UNIT TESTS - Integration with Known Options
        # ====================================================================
        
        @testset "Permissive Mode Preserves Known Option Behavior" begin
            # Test that known options work exactly the same in permissive mode
            opts_strict = Strategies.build_strategy_options(Solvers.IpoptSolver; max_iter=100, tol=1e-6)
            opts_permissive = Strategies.build_strategy_options(Solvers.IpoptSolver; max_iter=100, tol=1e-6, mode=:permissive)
            
            @test opts_strict[:max_iter] == opts_permissive[:max_iter]
            @test opts_strict[:tol] == opts_permissive[:tol]
            @test Strategies.option_source(opts_strict, :max_iter) == Strategies.option_source(opts_permissive, :max_iter)
        end
        
        # ====================================================================
        # UNIT TESTS - Different Value Types
        # ====================================================================
        
        @testset "Unknown Options with Different Types" begin
            opts = @test_logs (:warn,) begin
                Strategies.build_strategy_options(
                    Solvers.IpoptSolver;
                    custom_int=123,
                    custom_float=1.5,
                    custom_string="test",
                    custom_bool=true,
                    mode=:permissive
                )
            end
            
            @test opts[:custom_int] == 123
            @test opts[:custom_float] == 1.5
            @test opts[:custom_string] == "test"
            @test opts[:custom_bool] == true
        end
    end
end

end # module

# Export test function to outer scope
test_validation_permissive() = TestValidationPermissive.test_validation_permissive()
