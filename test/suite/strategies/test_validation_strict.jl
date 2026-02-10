"""
Unit tests for strict mode validation in strategy option building.

Tests the behavior of build_strategy_options() in strict mode (default),
ensuring unknown options are rejected with helpful error messages.
"""
module TestValidationStrict

using Test
using CTSolvers
using CTSolvers.Strategies
using CTSolvers.Solvers
using CTSolvers.Options
using NLPModelsIpopt
using CTBase: CTBase
const Exceptions = CTBase.Exceptions

# Test options for verbose output
const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

function test_validation_strict()
    @testset "Strict Mode Validation" verbose=VERBOSE showtiming=SHOWTIMING begin
        
        # ====================================================================
        # UNIT TESTS - Known Options Accepted
        # ====================================================================
        
        @testset "Known Options Accepted" begin
            # Test with single known option
            opts = Strategies.build_strategy_options(Solvers.IpoptSolver; max_iter=100)
            @test opts[:max_iter] == 100
            @test Strategies.source(opts, :max_iter) == :user
            
            # Test with multiple known options
            opts = Strategies.build_strategy_options(Solvers.IpoptSolver; max_iter=200, tol=1e-6)
            @test opts[:max_iter] == 200
            @test opts[:tol] == 1e-6
            
            # Test with alias
            opts = Strategies.build_strategy_options(Solvers.IpoptSolver; maxiter=300)
            @test opts[:max_iter] == 300  # Alias resolved to primary name
        end
        
        # ====================================================================
        # UNIT TESTS - Default Options Used
        # ====================================================================
        
        @testset "Default Options Used" begin
            opts = Strategies.build_strategy_options(Solvers.IpoptSolver)
            @test Strategies.source(opts, :max_iter) == :default
            @test Strategies.source(opts, :tol) == :default
        end
        
        # ====================================================================
        # UNIT TESTS - Unknown Options Rejected
        # ====================================================================
        
        @testset "Unknown Option Rejected" begin
            @test_throws Exception begin
                Strategies.build_strategy_options(Solvers.IpoptSolver; unknown_option=123)
            end
        end
        
        @testset "Multiple Unknown Options Rejected" begin
            @test_throws Exception begin
                Strategies.build_strategy_options(Solvers.IpoptSolver; unknown1=123, unknown2=456)
            end
        end
        
        @testset "Mix Known/Unknown Options Rejected" begin
            @test_throws Exception begin
                Strategies.build_strategy_options(Solvers.IpoptSolver; max_iter=1000, unknown=123)
            end
        end
        
        # ====================================================================
        # UNIT TESTS - Error Message Quality
        # ====================================================================
        
        @testset "Error Message Contains Unknown Option" begin
            try
                Strategies.build_strategy_options(Solvers.IpoptSolver; unknown_option=123)
                @test false  # Should not reach here
            catch e
                msg = string(e)
                @test occursin("unknown_option", msg)
                @test occursin("Unknown options", msg) || occursin("Unrecognized options", msg)
            end
        end
        
        @testset "Error Message Contains Suggestions (Typo)" begin
            try
                Strategies.build_strategy_options(Solvers.IpoptSolver; max_it=1000)  # Typo
                @test false
            catch e
                msg = string(e)
                @test occursin("max_it", msg)
                @test occursin("max_iter", msg)  # Should suggest correct name
            end
        end
        
        @testset "Error Message Contains Available Options" begin
            try
                Strategies.build_strategy_options(Solvers.IpoptSolver; unknown=123)
                @test false
            catch e
                msg = string(e)
                @test occursin("Available options", msg) || occursin("options:", msg)
                @test occursin("max_iter", msg)
                @test occursin("tol", msg)
            end
        end
        
        @testset "Error Message Suggests Permissive Mode" begin
            try
                Strategies.build_strategy_options(Solvers.IpoptSolver; custom_opt=123)
                @test false
            catch e
                msg = string(e)
                @test occursin("permissive", msg)
                @test occursin("mode", msg)
            end
        end
        
        # ====================================================================
        # UNIT TESTS - Type Validation
        # ====================================================================
        
        @testset "Type Validation Enforced" begin
            # This should fail type validation (max_iter expects Integer)
            @test_throws Exceptions.IncorrectArgument begin
                Strategies.build_strategy_options(Solvers.IpoptSolver; max_iter=1.5)
            end
        end
        
        # ====================================================================
        # UNIT TESTS - Custom Validation
        # ====================================================================
        
        @testset "Custom Validation Enforced" begin
            # tol must be positive
            @test_throws Exceptions.IncorrectArgument begin
                Strategies.build_strategy_options(Solvers.IpoptSolver; tol=-1.0)
            end
        end
        
        # ====================================================================
        # UNIT TESTS - Explicit Strict Mode
        # ====================================================================
        
        @testset "Explicit Strict Mode" begin
            # mode=:strict should behave identically to default
            @test_throws Exceptions.IncorrectArgument begin
                Strategies.build_strategy_options(Solvers.IpoptSolver; unknown=123, mode=:strict)
            end
            
            # Known options should work
            opts = Strategies.build_strategy_options(Solvers.IpoptSolver; max_iter=100, mode=:strict)
            @test opts[:max_iter] == 100
        end
    end
end

end # module

# Export test function to outer scope
test_validation_strict() = TestValidationStrict.test_validation_strict()
