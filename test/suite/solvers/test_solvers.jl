module TestSolvers

import Test
import CTBase.Exceptions
import CTSolvers
import CTSolvers.Solvers
import CTSolvers.Strategies
using CTSolvers.Solvers  # For testing exported symbols

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true
const CurrentModule = TestSolvers

"""
    test_solvers()

Tests for Solvers module exports.

This function tests the complete Solvers module exports including:
- Abstract types (AbstractNLPSolver)
- Concrete solver types (Ipopt, MadNLP, MadNCL, Knitro)
- Strategy interface compliance
"""
function test_solvers()
    Test.@testset "Solvers Module" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ====================================================================
        # META TESTS - Exports / Public API surface
        # ====================================================================

        Test.@testset "Exports verification" begin
            # Test that Solvers module is available
            Test.@testset "Solvers Module" begin
                Test.@test isdefined(CTSolvers, :Solvers)
                Test.@test CTSolvers.Solvers isa Module
            end
            
            # Test exported abstract types
            Test.@testset "Exported Abstract Types" begin
                for T in (
                    AbstractNLPSolver,
                )
                    Test.@testset "$(nameof(T))" begin
                        Test.@test isdefined(Solvers, nameof(T))
                        Test.@test isdefined(CurrentModule, nameof(T))
                        Test.@test T isa DataType || T isa UnionAll
                    end
                end
            end
            
            # Test exported concrete types
            Test.@testset "Exported Concrete Types" begin
                for T in (
                    Ipopt,
                    MadNLP,
                    MadNCL,
                    Knitro,
                )
                    Test.@testset "$(nameof(T))" begin
                        Test.@test isdefined(Solvers, nameof(T))
                        Test.@test isdefined(CurrentModule, nameof(T))
                        Test.@test T isa DataType || T isa UnionAll
                    end
                end
            end
            
            # Test that internal symbols are NOT exported
            Test.@testset "Internal Functions (not exported)" begin
                for f in (
                    :__madnlp_suite_default_linear_solver,     # Internal helper functions
                    :__madnlp_suite_consistent_linear_solver,
                )
                    Test.@testset "$f" begin
                        Test.@test isdefined(Solvers, f)
                        Test.@test !isdefined(CurrentModule, f)
                    end
                end
            end
        end

        # ====================================================================
        # UNIT TESTS - Type hierarchy and interface compliance
        # ====================================================================

        Test.@testset "Type hierarchy" begin
            Test.@testset "Abstract types" begin
                Test.@test Solvers.AbstractNLPSolver <: Any
                Test.@test Solvers.AbstractNLPSolver <: Strategies.AbstractStrategy
            end
        end

        Test.@testset "Interface compliance" begin
            Test.@testset "All solvers implement AbstractStrategy" begin
                # Test that all exported concrete solvers are subtypes of AbstractNLPSolver
                Test.@test Solvers.Ipopt <: Solvers.AbstractNLPSolver
                Test.@test Solvers.MadNLP <: Solvers.AbstractNLPSolver
                Test.@test Solvers.MadNCL <: Solvers.AbstractNLPSolver
                Test.@test Solvers.Knitro <: Solvers.AbstractNLPSolver
                
                # Test that they all implement AbstractStrategy through inheritance
                Test.@test Solvers.Ipopt <: Strategies.AbstractStrategy
                Test.@test Solvers.MadNLP <: Strategies.AbstractStrategy
                Test.@test Solvers.MadNCL <: Strategies.AbstractStrategy
                Test.@test Solvers.Knitro <: Strategies.AbstractStrategy
            end
        end
    end
end

end # module

test_solvers() = TestSolvers.test_solvers()
