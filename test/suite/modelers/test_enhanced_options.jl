# Tests for Enhanced Modelers Options
#
# This file tests the enhanced Modelers.ADNLPModeler and ExaModeler options
# to ensure they work correctly with validation and provide expected behavior.
#
# Author: CTSolvers Development Team
# Date: 2026-01-31

module TestEnhancedOptions

import Test
import CTBase.Exceptions
const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

# Import the specific types we need
import CTSolvers.Modelers
import CTSolvers.Modelers: ExaModeler
import KernelAbstractions
import CTSolvers.Strategies

# Define structs at top-level (crucial!)
struct TestDummyModel end

function test_enhanced_options()
    Test.@testset "Enhanced Modelers Options" verbose = VERBOSE showtiming = SHOWTIMING begin

        Test.@testset "Modelers.ADNLPModeler Enhanced Options" begin
            
            Test.@testset "New Options Validation" begin
                # Test matrix_free option
                modeler = Modelers.ADNLPModeler(matrix_free=true)
                Test.@test Strategies.options(modeler)[:matrix_free] == true
                
                modeler = Modelers.ADNLPModeler(matrix_free=false)
                Test.@test Strategies.options(modeler)[:matrix_free] == false
                
                # Test name option
                modeler = Modelers.ADNLPModeler(name="TestProblem")
                Test.@test Strategies.options(modeler)[:name] == "TestProblem"
            end
            
            Test.@testset "Backend Validation" begin
                # Valid backends should work (some may generate warnings if packages not loaded)
                Test.@test_nowarn Modelers.ADNLPModeler(backend=:default)
                Test.@test_nowarn Modelers.ADNLPModeler(backend=:optimized)
                Test.@test_nowarn Modelers.ADNLPModeler(backend=:generic)
                # Enzyme and Zygote may generate warnings if packages not loaded - that's expected
                redirect_stderr(devnull) do
                    Modelers.ADNLPModeler(backend=:enzyme)  # May warn if Enzyme not loaded
                    Modelers.ADNLPModeler(backend=:zygote)  # May warn if Zygote not loaded
                end
                
                # Invalid backend should throw error (redirect stderr to hide error logs)
                redirect_stderr(devnull) do
                    Test.@test_throws Exceptions.IncorrectArgument Modelers.ADNLPModeler(backend=:invalid)
                end
            end
            
            Test.@testset "Name Validation" begin
                # Valid names should work
                Test.@test_nowarn Modelers.ADNLPModeler(name="ValidName")
                Test.@test_nowarn Modelers.ADNLPModeler(name="name_with_123")
                
                # Empty name should throw error (redirect stderr to hide error logs)
                redirect_stderr(devnull) do
                    Test.@test_throws Exceptions.IncorrectArgument Modelers.ADNLPModeler(name="")
                end
            end
            
            Test.@testset "Combined Options" begin
                # Test multiple options together
                modeler = Modelers.ADNLPModeler(
                    backend=:optimized,
                    matrix_free=true,
                    name="CombinedTest",
                    show_time=true
                )
                
                opts = Strategies.options(modeler)
                Test.@test opts[:backend] == :optimized
                Test.@test opts[:matrix_free] == true
                Test.@test opts[:name] == "CombinedTest"
                Test.@test opts[:show_time] == true
            end
        end
        
        Test.@testset "ExaModeler Enhanced Options" begin
            
            Test.@testset "Base Type Validation" begin
                # Test valid base types
                modeler = ExaModeler(base_type=Float32)
                Test.@test Strategies.options(modeler)[:base_type] == Float32
                
                modeler = ExaModeler(base_type=Float64)
                Test.@test Strategies.options(modeler)[:base_type] == Float64
            end
            
            Test.@testset "Backend Validation" begin
                # Test backend option
                modeler = ExaModeler(backend=nothing)
                Test.@test Strategies.options(modeler)[:backend] === nothing
                
                # Test with a backend type
                modeler = ExaModeler(backend=KernelAbstractions.CPU())
                Test.@test Strategies.options(modeler)[:backend] == KernelAbstractions.CPU()
            end
            
            Test.@testset "Base Type Extraction in Build" begin
                # Test that BaseType is correctly extracted and used in build process
                modeler = ExaModeler(base_type=Float32)
                
                # Verify base_type is stored in options
                Test.@test Strategies.options(modeler)[:base_type] == Float32
                
                # Test with Float64 as well
                modeler64 = ExaModeler(base_type=Float64)
                Test.@test Strategies.options(modeler64)[:base_type] == Float64
                
                # Test that default base_type is preserved
                default_modeler = ExaModeler()
                Test.@test Strategies.options(default_modeler)[:base_type] == Float64
            end
            
            Test.@testset "Combined Options" begin
                # Test multiple options together
                modeler = ExaModeler(
                    base_type=Float32,
                    backend=nothing
                )
                
                opts = Strategies.options(modeler)
                Test.@test opts[:backend] === nothing
                Test.@test opts[:base_type] == Float32
                
                # Check that modeler is not parameterized anymore
                Test.@test modeler isa ExaModeler
            end
        end
        
        Test.@testset "Backward Compatibility" begin
            
            Test.@testset "Modelers.ADNLPModeler Backward Compatibility" begin
                # Original constructor should still work
                modeler1 = Modelers.ADNLPModeler()
                Test.@test modeler1 isa Modelers.ADNLPModeler
                
                # Original options should still work
                modeler2 = Modelers.ADNLPModeler(show_time=true, backend=:default)
                Test.@test modeler2 isa Modelers.ADNLPModeler
                Test.@test Strategies.options(modeler2)[:show_time] == true
                Test.@test Strategies.options(modeler2)[:backend] == :default
                
                # Default values should be preserved
                modeler3 = Modelers.ADNLPModeler()
                opts = Strategies.options(modeler3)
                Test.@test opts[:backend] == :optimized
                # show_time, matrix_free, name have NotProvided defaults — not stored when not provided
                Test.@test !haskey(opts.options, :show_time)
                Test.@test !haskey(opts.options, :matrix_free)
                Test.@test !haskey(opts.options, :name)
            end
            
            Test.@testset "ExaModeler Backward Compatibility" begin
                # Original constructor should still work
                modeler1 = ExaModeler()
                Test.@test modeler1 isa ExaModeler
                
                # Original options should still work
                modeler2 = ExaModeler(base_type=Float32)
                Test.@test modeler2 isa ExaModeler
                Test.@test Strategies.options(modeler2)[:base_type] == Float32
                
                # Default values should be preserved
                modeler3 = ExaModeler()
                opts = Strategies.options(modeler3)
                Test.@test opts[:backend] === nothing
                Test.@test opts[:base_type] == Float64
            end
        end

        Test.@testset "Advanced Backend Overrides" begin
            Test.@testset "Backend Override Validation" begin
                # Valid backend overrides should work
                Test.@test_nowarn Modelers.ADNLPModeler(gradient_backend=nothing)
                Test.@test_nowarn Modelers.ADNLPModeler(hprod_backend=nothing)
                Test.@test_nowarn Modelers.ADNLPModeler(jprod_backend=nothing)
                Test.@test_nowarn Modelers.ADNLPModeler(jtprod_backend=nothing)
                Test.@test_nowarn Modelers.ADNLPModeler(jacobian_backend=nothing)
                Test.@test_nowarn Modelers.ADNLPModeler(hessian_backend=nothing)

                # NLS backend overrides should work
                Test.@test_nowarn Modelers.ADNLPModeler(ghjvprod_backend=nothing)
                Test.@test_nowarn Modelers.ADNLPModeler(hprod_residual_backend=nothing)
                Test.@test_nowarn Modelers.ADNLPModeler(jprod_residual_backend=nothing)
                Test.@test_nowarn Modelers.ADNLPModeler(jtprod_residual_backend=nothing)
                Test.@test_nowarn Modelers.ADNLPModeler(jacobian_residual_backend=nothing)
                Test.@test_nowarn Modelers.ADNLPModeler(hessian_residual_backend=nothing)

                # Test that options are accessible
                modeler = Modelers.ADNLPModeler(
                    gradient_backend=nothing,
                    hprod_backend=nothing,
                    ghjvprod_backend=nothing
                )
                opts = Strategies.options(modeler)
                Test.@test opts[:gradient_backend] === nothing
                Test.@test opts[:hprod_backend] === nothing
                Test.@test opts[:ghjvprod_backend] === nothing
            end

            Test.@testset "Backend Override Type Validation" begin
                # Invalid types should throw enriched exceptions (redirect stderr to hide error logs)
                redirect_stderr(devnull) do
                    Test.@test_throws Exceptions.IncorrectArgument Modelers.ADNLPModeler(gradient_backend="invalid")
                    Test.@test_throws Exceptions.IncorrectArgument Modelers.ADNLPModeler(hprod_backend=123)
                    Test.@test_throws Exceptions.IncorrectArgument Modelers.ADNLPModeler(jprod_backend=:invalid)
                    Test.@test_throws Exceptions.IncorrectArgument Modelers.ADNLPModeler(ghjvprod_backend="invalid")
                end
            end

            Test.@testset "Combined Advanced Options" begin
                # Test advanced options with basic options
                modeler = Modelers.ADNLPModeler(
                    backend=:optimized,
                    matrix_free=true,
                    name="AdvancedTest",
                    gradient_backend=nothing,
                    hprod_backend=nothing,
                    jacobian_backend=nothing,
                    ghjvprod_backend=nothing
                )

                opts = Strategies.options(modeler)
                Test.@test opts[:backend] == :optimized
                Test.@test opts[:matrix_free] == true
                Test.@test opts[:name] == "AdvancedTest"
                # Options with NotProvided default are only stored when explicitly set
                Test.@test opts[:gradient_backend] === nothing
                Test.@test opts[:hprod_backend] === nothing
                Test.@test opts[:jacobian_backend] === nothing
                Test.@test opts[:ghjvprod_backend] === nothing
            end
        end
        
        Test.@testset "Backend Aliases with Deprecation Warnings" begin
            # Test Modelers.ADNLPModeler with adnlp_backend alias
            # Use :generic (not the default :optimized) to verify the alias actually passes the value
            Test.@testset "Modelers.ADNLPModeler adnlp_backend alias" begin
                modeler = Modelers.ADNLPModeler(adnlp_backend=:generic)
                opts = Strategies.options(modeler)
                Test.@test haskey(opts.options, :backend)
                Test.@test opts[:backend] == :generic
            end
            
            # Test ExaModeler with exa_backend alias
            # Default is nothing, so pass a CPU backend to verify alias works
            Test.@testset "ExaModeler exa_backend alias" begin
                modeler = ExaModeler(exa_backend=nothing)
                opts = Strategies.options(modeler)
                Test.@test haskey(opts.options, :backend)
                Test.@test opts[:backend] === nothing
            end
            
            # Test deprecation warnings are emitted
            Test.@testset "Deprecation warnings" begin
                Test.@test_logs (:warn, "adnlp_backend is deprecated, use backend instead") Modelers.ADNLPModeler(adnlp_backend=:default)
                Test.@test_logs (:warn, "exa_backend is deprecated, use backend instead") ExaModeler(exa_backend=nothing)
            end
            
            # Test standard backend does not emit warning
            Test.@testset "No warning with standard backend" begin
                Test.@test_logs Modelers.ADNLPModeler(backend=:generic)
                Test.@test_logs ExaModeler(backend=nothing)
            end
        end
    end

end # function test_enhanced_options

end # module TestEnhancedOptions

# CRITICAL: Redefine the function in the outer scope so TestRunner can find it
test_enhanced_options() = TestEnhancedOptions.test_enhanced_options()
