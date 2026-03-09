module TestMadNLPGPULinearSolver

using Test: Test
import CTSolvers.Strategies
import CTSolvers.Solvers

# Import extensions to enable metadata testing
using MadNLP: MadNLP
using MadNCL: MadNCL
using MadNLPGPU: MadNLPGPU

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

function test_madnlp_gpu_linear_solver()
    Test.@testset "MadNLP/MadNCL Strategies.GPU Linear Solver Defaults" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ====================================================================
        # UNIT TESTS - MadNLP Strategies.CPU defaults
        # ====================================================================

        Test.@testset "MadNLP{Strategies.CPU} defaults" begin
            # Note: We can't instantiate without MadNLP extension loaded
            # But we can test the type exists and parameter extraction works
            Test.@test Solvers.MadNLP{Strategies.CPU} isa
                Type{Solvers.MadNLP{Strategies.CPU}}
            Test.@test Strategies.get_parameter_type(Solvers.MadNLP{Strategies.CPU}) ==
                Strategies.CPU
            Test.@test Strategies.id(Solvers.MadNLP{Strategies.CPU}) == :madnlp
        end

        # ====================================================================
        # UNIT TESTS - MadNLP Strategies.GPU type
        # ====================================================================

        Test.@testset "MadNLP{Strategies.GPU} type" begin
            Test.@test Solvers.MadNLP{Strategies.GPU} isa
                Type{Solvers.MadNLP{Strategies.GPU}}
            Test.@test Strategies.get_parameter_type(Solvers.MadNLP{Strategies.GPU}) ==
                Strategies.GPU
            Test.@test Strategies.id(Solvers.MadNLP{Strategies.GPU}) == :madnlp
        end

        # ====================================================================
        # UNIT TESTS - MadNCL Strategies.CPU defaults
        # ====================================================================

        Test.@testset "MadNCL{Strategies.CPU} defaults" begin
            Test.@test Solvers.MadNCL{Strategies.CPU} isa
                Type{Solvers.MadNCL{Strategies.CPU}}
            Test.@test Strategies.get_parameter_type(Solvers.MadNCL{Strategies.CPU}) ==
                Strategies.CPU
            Test.@test Strategies.id(Solvers.MadNCL{Strategies.CPU}) == :madncl
        end

        # ====================================================================
        # UNIT TESTS - MadNCL Strategies.GPU type
        # ====================================================================

        Test.@testset "MadNCL{Strategies.GPU} type" begin
            Test.@test Solvers.MadNCL{Strategies.GPU} isa
                Type{Solvers.MadNCL{Strategies.GPU}}
            Test.@test Strategies.get_parameter_type(Solvers.MadNCL{Strategies.GPU}) ==
                Strategies.GPU
            Test.@test Strategies.id(Solvers.MadNCL{Strategies.GPU}) == :madncl
        end

        # ====================================================================
        # INTEGRATION TESTS - Registry with parameterized solvers
        # ====================================================================

        Test.@testset "Registry with Strategies.GPU solvers" begin
            r = Strategies.create_registry(
                Solvers.AbstractNLPSolver => (
                    (Solvers.MadNLP, [Strategies.CPU, Strategies.GPU]),
                    (Solvers.MadNCL, [Strategies.CPU, Strategies.GPU]),
                ),
            )

            # Test that all strategies are registered
            solver_ids = Strategies.strategy_ids(Solvers.AbstractNLPSolver, r)
            Test.@test :madnlp in solver_ids
            Test.@test :madncl in solver_ids

            # Test parameter extraction
            Test.@test Strategies.extract_global_parameter_from_method(
                (:madnlp, :cpu), r
            ) == Strategies.CPU
            Test.@test Strategies.extract_global_parameter_from_method(
                (:madnlp, :gpu), r
            ) == Strategies.GPU
            Test.@test Strategies.extract_global_parameter_from_method(
                (:madncl, :cpu), r
            ) == Strategies.CPU
            Test.@test Strategies.extract_global_parameter_from_method(
                (:madncl, :gpu), r
            ) == Strategies.GPU
        end

        # ====================================================================
        # UNIT TESTS - Consistency Validation
        # ====================================================================

        Test.@testset "Consistency validation warnings" begin
            # Test that metadata contains validators (now we can test with extensions loaded)

            # Test MadNLP metadata structure (CPU only to avoid MadNLPGPU dependency)
            madnlp_cpu_meta = Strategies.metadata(Solvers.MadNLP{Strategies.CPU})
            Test.@test haskey(madnlp_cpu_meta, :linear_solver)
            Test.@test madnlp_cpu_meta[:linear_solver].validator !== nothing
            Test.@test isa(madnlp_cpu_meta[:linear_solver].validator, Function)

            # Test MadNCL metadata structure (CPU only to avoid MadNLPGPU dependency)
            madncl_cpu_meta = Strategies.metadata(Solvers.MadNCL{Strategies.CPU})
            Test.@test haskey(madncl_cpu_meta, :linear_solver)
            Test.@test madncl_cpu_meta[:linear_solver].validator !== nothing
            Test.@test isa(madncl_cpu_meta[:linear_solver].validator, Function)

            # Test actual validation with different linear solvers
            cpu_madnlp_validator = madnlp_cpu_meta[:linear_solver].validator
            cpu_madncl_validator = madncl_cpu_meta[:linear_solver].validator

            # Test CPU validator with different solvers (no warnings expected)
            Test.@test cpu_madnlp_validator(MadNLP.MumpsSolver) === MadNLP.MumpsSolver
            Test.@test cpu_madncl_validator(MadNLP.MumpsSolver) === MadNLP.MumpsSolver

            # Test GPU solver validation with CPU parameter (should warn but work)
            Test.@test_logs (:warn, r"Inconsistent linear solver") cpu_madnlp_validator(
                MadNLPGPU.CUDSSSolver
            )
            Test.@test_logs (:warn, r"Inconsistent linear solver") cpu_madncl_validator(
                MadNLPGPU.CUDSSSolver
            )

            # Test GPU metadata if MadNLPGPU is available
            if isdefined(Main, :MadNLPGPU)
                # Test MadNLP GPU metadata
                madnlp_gpu_meta = Strategies.metadata(Solvers.MadNLP{Strategies.GPU})
                Test.@test haskey(madnlp_gpu_meta, :linear_solver)
                gpu_madnlp_validator = madnlp_gpu_meta[:linear_solver].validator

                # Test CPU solver with GPU parameter (should warn)
                Test.@test_logs (:warn, r"Inconsistent linear solver") gpu_madnlp_validator(
                    MadNLP.MumpsSolver
                )

                # Test GPU solver with GPU parameter (no warning)
                Test.@test gpu_madnlp_validator(MadNLPGPU.CUDSSSolver) ===
                    MadNLPGPU.CUDSSSolver

                # Test MadNCL GPU metadata
                madncl_gpu_meta = Strategies.metadata(Solvers.MadNCL{Strategies.GPU})
                Test.@test haskey(madncl_gpu_meta, :linear_solver)
                gpu_madncl_validator = madncl_gpu_meta[:linear_solver].validator

                # Test CPU solver with GPU parameter (should warn)
                Test.@test_logs (:warn, r"Inconsistent linear solver") gpu_madncl_validator(
                    MadNLP.MumpsSolver
                )

                # Test GPU solver with GPU parameter (no warning)
                Test.@test gpu_madnlp_validator(MadNLPGPU.CUDSSSolver) ===
                    MadNLPGPU.CUDSSSolver
                Test.@test gpu_madncl_validator(MadNLPGPU.CUDSSSolver) ===
                    MadNLPGPU.CUDSSSolver
            end
        end

        # ====================================================================
        # INTEGRATION TESTS - Type stability
        # ====================================================================

        # Test.@testset "Type stability" begin
        #     # Test that parameter extraction is type stable
        #     Test.@test_nowarn Test.@inferred Strategies.get_parameter_type(Solvers.MadNLP{Strategies.CPU})
        #     Test.@test_nowarn Test.@inferred Strategies.get_parameter_type(Solvers.MadNLP{Strategies.GPU})
        #     Test.@test_nowarn Test.@inferred Strategies.get_parameter_type(Solvers.MadNCL{Strategies.CPU})
        #     Test.@test_nowarn Test.@inferred Strategies.get_parameter_type(Solvers.MadNCL{Strategies.GPU})
        # end

        # ====================================================================
        # INTEGRATION TESTS - Actual linear_solver defaults and warnings
        # ====================================================================

        Test.@testset "Linear solver defaults and warnings" begin
            # Test actual linear_solver defaults with extensions loaded

            # Test MadNLP CPU defaults
            madnlp_cpu_meta = Strategies.metadata(Solvers.MadNLP{Strategies.CPU})
            Test.@test madnlp_cpu_meta[:linear_solver].default == MadNLP.MumpsSolver

            # Test MadNCL CPU defaults
            madncl_cpu_meta = Strategies.metadata(Solvers.MadNCL{Strategies.CPU})
            Test.@test madncl_cpu_meta[:linear_solver].default == MadNLP.MumpsSolver

            # Test GPU defaults (should work with MadNLPGPU loaded)
            if isdefined(Main, :MadNLPGPU)
                # Test MadNLP GPU defaults
                madnlp_gpu_meta = Strategies.metadata(Solvers.MadNLP{Strategies.GPU})
                Test.@test madnlp_gpu_meta[:linear_solver].default == MadNLPGPU.CUDSSSolver

                # Test MadNCL GPU defaults
                madncl_gpu_meta = Strategies.metadata(Solvers.MadNCL{Strategies.GPU})
                Test.@test madncl_gpu_meta[:linear_solver].default == MadNLPGPU.CUDSSSolver

                # Test warnings for inconsistent combinations
                Test.@test_logs (:warn, r"Inconsistent linear solver") madnlp_cpu_meta[:linear_solver].validator(
                    MadNLPGPU.CUDSSSolver
                )
                Test.@test_logs (:warn, r"Inconsistent linear solver") madncl_cpu_meta[:linear_solver].validator(
                    MadNLPGPU.CUDSSSolver
                )
                Test.@test_logs (:warn, r"Inconsistent linear solver") madnlp_gpu_meta[:linear_solver].validator(
                    MadNLP.MumpsSolver
                )
                Test.@test_logs (:warn, r"Inconsistent linear solver") madncl_gpu_meta[:linear_solver].validator(
                    MadNLP.MumpsSolver
                )

                # Test consistent combinations (no warnings)
                Test.@test madnlp_cpu_meta[:linear_solver].validator(MadNLP.MumpsSolver) ===
                    MadNLP.MumpsSolver
                Test.@test madncl_cpu_meta[:linear_solver].validator(MadNLP.MumpsSolver) ===
                    MadNLP.MumpsSolver
                Test.@test madnlp_gpu_meta[:linear_solver].validator(
                    MadNLPGPU.CUDSSSolver
                ) === MadNLPGPU.CUDSSSolver
                Test.@test madncl_gpu_meta[:linear_solver].validator(
                    MadNLPGPU.CUDSSSolver
                ) === MadNLPGPU.CUDSSSolver
            end
        end
    end
end

end # module

# Redefine in outer scope for TestRunner
test_madnlp_gpu_linear_solver() = TestMadNLPGPULinearSolver.test_madnlp_gpu_linear_solver()
