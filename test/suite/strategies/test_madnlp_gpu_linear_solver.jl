module TestMadNLPGPULinearSolver

import Test
import CTSolvers.Strategies
import CTSolvers.Solvers

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

function test_madnlp_gpu_linear_solver()
    Test.@testset "MadNLP/MadNCL GPU Linear Solver Defaults" verbose=VERBOSE showtiming=SHOWTIMING begin
        
        # ====================================================================
        # UNIT TESTS - MadNLP CPU defaults
        # ====================================================================
        
        Test.@testset "MadNLP{CPU} defaults" begin
            # Note: We can't instantiate without MadNLP extension loaded
            # But we can test the type exists and parameter extraction works
            Test.@test Solvers.MadNLP{CPU} isa Type{Solvers.MadNLP{CPU}}
            Test.@test Strategies.get_parameter_type(Solvers.MadNLP{CPU}) == CPU
            Test.@test Strategies.id(Solvers.MadNLP{CPU}) == :madnlp
        end
        
        # ====================================================================
        # UNIT TESTS - MadNLP GPU type
        # ====================================================================
        
        Test.@testset "MadNLP{GPU} type" begin
            Test.@test Solvers.MadNLP{GPU} isa Type{Solvers.MadNLP{GPU}}
            Test.@test Strategies.get_parameter_type(Solvers.MadNLP{GPU}) == GPU
            Test.@test Strategies.id(Solvers.MadNLP{GPU}) == :madnlp
        end
        
        # ====================================================================
        # UNIT TESTS - MadNCL CPU defaults
        # ====================================================================
        
        Test.@testset "MadNCL{CPU} defaults" begin
            Test.@test Solvers.MadNCL{CPU} isa Type{Solvers.MadNCL{CPU}}
            Test.@test Strategies.get_parameter_type(Solvers.MadNCL{CPU}) == CPU
            Test.@test Strategies.id(Solvers.MadNCL{CPU}) == :madncl
        end
        
        # ====================================================================
        # UNIT TESTS - MadNCL GPU type
        # ====================================================================
        
        Test.@testset "MadNCL{GPU} type" begin
            Test.@test Solvers.MadNCL{GPU} isa Type{Solvers.MadNCL{GPU}}
            Test.@test Strategies.get_parameter_type(Solvers.MadNCL{GPU}) == GPU
            Test.@test Strategies.id(Solvers.MadNCL{GPU}) == :madncl
        end
        
        # ====================================================================
        # INTEGRATION TESTS - Registry with parameterized solvers
        # ====================================================================
        
        Test.@testset "Registry with GPU solvers" begin
            r = Strategies.create_registry(
                CTSolvers.Solvers.AbstractNLPSolver => (
                    (Solvers.MadNLP, [CPU, GPU]),
                    (Solvers.MadNCL, [CPU, GPU])
                )
            )
            
            # Test that all strategies are registered
            solver_ids = Strategies.strategy_ids(CTSolvers.Solvers.AbstractNLPSolver, r)
            Test.@test :madnlp in solver_ids
            Test.@test :madncl in solver_ids
            
            # Test parameter extraction
            Test.@test Strategies.extract_parameter_from_method((:madnlp, :cpu), r) == CPU
            Test.@test Strategies.extract_parameter_from_method((:madnlp, :gpu), r) == GPU
            Test.@test Strategies.extract_parameter_from_method((:madncl, :cpu), r) == CPU
            Test.@test Strategies.extract_parameter_from_method((:madncl, :gpu), r) == GPU
        end
        
        # ====================================================================
        # INTEGRATION TESTS - Type stability
        # ====================================================================
        
        Test.@testset "Type stability" begin
            # Test that parameter extraction is type stable
            Test.@test_nowarn Test.@inferred Strategies.get_parameter_type(Solvers.MadNLP{CPU})
            Test.@test_nowarn Test.@inferred Strategies.get_parameter_type(Solvers.MadNLP{GPU})
            Test.@test_nowarn Test.@inferred Strategies.get_parameter_type(Solvers.MadNCL{CPU})
            Test.@test_nowarn Test.@inferred Strategies.get_parameter_type(Solvers.MadNCL{GPU})
        end
        
        # ====================================================================
        # NOTE: Tests for actual linear_solver defaults
        # ====================================================================
        
        # We cannot test the actual linear_solver defaults without loading
        # the MadNLP and MadNLPGPU extensions. These tests would need to be
        # in a separate test file that conditionally runs when extensions
        # are loaded.
        #
        # Expected behavior (to be tested when extensions are loaded):
        # - MadNLP{CPU}() should have linear_solver = MadNLP.MumpsSolver
        # - MadNLP{GPU}() should have linear_solver = MadNLPGPU.CUDSSSolver
        # - MadNCL{CPU}() should have linear_solver = MadNLP.MumpsSolver
        # - MadNCL{GPU}() should have linear_solver = MadNLPGPU.CUDSSSolver
        #
        # - MadNLP{GPU}() without MadNLPGPU loaded should throw ExtensionError
        # - MadNCL{GPU}() without MadNLPGPU loaded should throw ExtensionError
    end
end

end # module

# Redefine in outer scope for TestRunner
test_madnlp_gpu_linear_solver() = TestMadNLPGPULinearSolver.test_madnlp_gpu_linear_solver()
