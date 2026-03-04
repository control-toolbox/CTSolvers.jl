module TestMadNLPGPULinearSolver

import Test
import CTSolvers.Strategies
import CTSolvers.Solvers

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

function test_madnlp_gpu_linear_solver()
    Test.@testset "MadNLP/MadNCL Strategies.GPU Linear Solver Defaults" verbose=VERBOSE showtiming=SHOWTIMING begin
        
        # ====================================================================
        # UNIT TESTS - MadNLP Strategies.CPU defaults
        # ====================================================================
        
        Test.@testset "MadNLP{Strategies.CPU} defaults" begin
            # Note: We can't instantiate without MadNLP extension loaded
            # But we can test the type exists and parameter extraction works
            Test.@test Solvers.MadNLP{Strategies.CPU} isa Type{Solvers.MadNLP{Strategies.CPU}}
            Test.@test Strategies.get_parameter_type(Solvers.MadNLP{Strategies.CPU}) == Strategies.CPU
            Test.@test Strategies.id(Solvers.MadNLP{Strategies.CPU}) == :madnlp
        end
        
        # ====================================================================
        # UNIT TESTS - MadNLP Strategies.GPU type
        # ====================================================================
        
        Test.@testset "MadNLP{Strategies.GPU} type" begin
            Test.@test Solvers.MadNLP{Strategies.GPU} isa Type{Solvers.MadNLP{Strategies.GPU}}
            Test.@test Strategies.get_parameter_type(Solvers.MadNLP{Strategies.GPU}) == Strategies.GPU
            Test.@test Strategies.id(Solvers.MadNLP{Strategies.GPU}) == :madnlp
        end
        
        # ====================================================================
        # UNIT TESTS - MadNCL Strategies.CPU defaults
        # ====================================================================
        
        Test.@testset "MadNCL{Strategies.CPU} defaults" begin
            Test.@test Solvers.MadNCL{Strategies.CPU} isa Type{Solvers.MadNCL{Strategies.CPU}}
            Test.@test Strategies.get_parameter_type(Solvers.MadNCL{Strategies.CPU}) == Strategies.CPU
            Test.@test Strategies.id(Solvers.MadNCL{Strategies.CPU}) == :madncl
        end
        
        # ====================================================================
        # UNIT TESTS - MadNCL Strategies.GPU type
        # ====================================================================
        
        Test.@testset "MadNCL{Strategies.GPU} type" begin
            Test.@test Solvers.MadNCL{Strategies.GPU} isa Type{Solvers.MadNCL{Strategies.GPU}}
            Test.@test Strategies.get_parameter_type(Solvers.MadNCL{Strategies.GPU}) == Strategies.GPU
            Test.@test Strategies.id(Solvers.MadNCL{Strategies.GPU}) == :madncl
        end
        
        # ====================================================================
        # INTEGRATION TESTS - Registry with parameterized solvers
        # ====================================================================
        
        Test.@testset "Registry with Strategies.GPU solvers" begin
            r = Strategies.create_registry(
                Solvers.AbstractNLPSolver => (
                    (Solvers.MadNLP, [Strategies.CPU, Strategies.GPU]),
                    (Solvers.MadNCL, [Strategies.CPU, Strategies.GPU])
                )
            )
            
            # Test that all strategies are registered
            solver_ids = Strategies.strategy_ids(Solvers.AbstractNLPSolver, r)
            Test.@test :madnlp in solver_ids
            Test.@test :madncl in solver_ids
            
            # Test parameter extraction
            Test.@test Strategies.extract_global_parameter_from_method((:madnlp, :cpu), r) == Strategies.CPU
            Test.@test Strategies.extract_global_parameter_from_method((:madnlp, :gpu), r) == Strategies.GPU
            Test.@test Strategies.extract_global_parameter_from_method((:madncl, :cpu), r) == Strategies.CPU
            Test.@test Strategies.extract_global_parameter_from_method((:madncl, :gpu), r) == Strategies.GPU
        end
        
        # ====================================================================
        # INTEGRATION TESTS - Type stability
        # ====================================================================
        
        Test.@testset "Type stability" begin
            # Test that parameter extraction is type stable
            Test.@test_nowarn Test.@inferred Strategies.get_parameter_type(Solvers.MadNLP{Strategies.CPU})
            Test.@test_nowarn Test.@inferred Strategies.get_parameter_type(Solvers.MadNLP{Strategies.GPU})
            Test.@test_nowarn Test.@inferred Strategies.get_parameter_type(Solvers.MadNCL{Strategies.CPU})
            Test.@test_nowarn Test.@inferred Strategies.get_parameter_type(Solvers.MadNCL{Strategies.GPU})
        end
        
        # ====================================================================
        # NOTE: Tests for actual linear_solver defaults
        # ====================================================================
        
        # We cannot test the actual linear_solver defaults without loading
        # the MadNLP and MadNLPStrategies.GPU extensions. These tests would need to be
        # in a separate test file that conditionally runs when extensions
        # are loaded.
        #
        # Expected behavior (to be tested when extensions are loaded):
        # - MadNLP{Strategies.CPU}() should have linear_solver = MadNLP.MumpsSolver
        # - MadNLP{Strategies.GPU}() should have linear_solver = MadNLPStrategies.GPU.CUDSSSolver
        # - MadNCL{Strategies.CPU}() should have linear_solver = MadNLP.MumpsSolver
        # - MadNCL{Strategies.GPU}() should have linear_solver = MadNLPStrategies.GPU.CUDSSSolver
        #
        # - MadNLP{Strategies.GPU}() without MadNLPStrategies.GPU loaded should throw ExtensionError
        # - MadNCL{Strategies.GPU}() without MadNLPStrategies.GPU loaded should throw ExtensionError
    end
end

end # module

# Redefine in outer scope for TestRunner
test_madnlp_gpu_linear_solver() = TestMadNLPGPULinearSolver.test_madnlp_gpu_linear_solver()
