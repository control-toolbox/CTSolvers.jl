module TestExtensionHelpers

import Test
import CTBase.Exceptions
import CTSolvers
import CTSolvers.Solvers
import CTSolvers.Strategies: CPU, GPU
import MadNLP
import MadNCL

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

# Load extensions to access helper functions
using MadNLP: MadNLP
using MadNCL: MadNCL

# Get extension modules
const CTSolversMadNLP = Base.get_extension(Main.CTSolvers, :CTSolversMadNLP)
const CTSolversMadNCL = Base.get_extension(Main.CTSolvers, :CTSolversMadNCL)

"""
    test_helpers()

Tests for extension helper functions.

🧪 **Applying Testing Rule**: Unit Tests for internal helpers

Tests helper functions in extensions that are not directly tested elsewhere:
- base_type extraction
- default linear solver selection (CPU/GPU)
- error paths for missing GPU support
"""
function test_helpers()
    Test.@testset "Extension Helpers" verbose=VERBOSE showtiming=SHOWTIMING begin
        
        # ====================================================================
        # UNIT TESTS - MadNCL base_type helper
        # ====================================================================
        
        Test.@testset "MadNCL base_type" begin
            # Create NCLOptions with Float64
            ncl_opts_f64 = MadNCL.NCLOptions{Float64}()
            base_f64 = CTSolversMadNCL.base_type(ncl_opts_f64)
            Test.@test base_f64 === Float64
            
            # Create NCLOptions with Float32
            ncl_opts_f32 = MadNCL.NCLOptions{Float32}()
            base_f32 = CTSolversMadNCL.base_type(ncl_opts_f32)
            Test.@test base_f32 === Float32
        end
        
        # ====================================================================
        # UNIT TESTS - MadNCL default linear solver (CPU)
        # ====================================================================
        
        Test.@testset "MadNCL default linear solver - CPU" begin
            solver_type = Solvers.__madnlp_suite_default_linear_solver(CPU)
            Test.@test solver_type === MadNLP.MumpsSolver
        end
        
        # ====================================================================
        # UNIT TESTS - MadNCL default linear solver (GPU)
        # ====================================================================
        
        Test.@testset "MadNCL default linear solver - GPU" begin
            # This should throw ExtensionError if MadNLPGPU is not loaded
            if !isdefined(Main, :MadNLPGPU)
                Test.@test_throws Exceptions.ExtensionError Solvers.__madnlp_suite_default_linear_solver(GPU)
            else
                # If MadNLPGPU is loaded, should return CUDSSSolver
                solver_type = Solvers.__madnlp_suite_default_linear_solver(GPU)
                Test.@test solver_type === Main.MadNLPGPU.CUDSSSolver
            end
        end
        
        # ====================================================================
        # UNIT TESTS - MadNLP default linear solver (CPU)
        # ====================================================================
        
        Test.@testset "MadNLP default linear solver - CPU" begin
            solver_type = Solvers.__madnlp_suite_default_linear_solver(CPU)
            Test.@test solver_type === MadNLP.MumpsSolver
        end
        
        # ====================================================================
        # UNIT TESTS - MadNLP default linear solver (GPU)
        # ====================================================================
        
        Test.@testset "MadNLP default linear solver - GPU" begin
            # This should throw ExtensionError if MadNLPGPU is not loaded
            if !isdefined(Main, :MadNLPGPU)
                Test.@test_throws Exceptions.ExtensionError Solvers.__madnlp_suite_default_linear_solver(GPU)
            else
                # If MadNLPGPU is loaded, should return CUDSSSolver
                solver_type = Solvers.__madnlp_suite_default_linear_solver(GPU)
                Test.@test solver_type === Main.MadNLPGPU.CUDSSSolver
            end
        end
        
        # ====================================================================
        # UNIT TESTS - Type stability of helpers
        # ====================================================================
        
        Test.@testset "Type stability" begin
            # base_type should be type-stable
            ncl_opts = MadNCL.NCLOptions{Float64}()
            Test.@test_nowarn CTSolversMadNCL.base_type(ncl_opts)
            
            # default_linear_solver should be type-stable for CPU
            Test.@test_nowarn Solvers.__madnlp_suite_default_linear_solver(CPU)
            Test.@test_nowarn Solvers.__madnlp_suite_default_linear_solver(CPU)
        end
    end
end

end # module

test_helpers() = TestExtensionHelpers.test_helpers()
