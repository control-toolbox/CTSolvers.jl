module TestCPUOnlyParametersIntegration

using Test
using CTSolvers
using CTSolvers.Modelers
using CTSolvers.Modelers: AbstractNLPModeler
using CTSolvers.Solvers
using CTSolvers.Solvers: AbstractNLPSolver
using CTSolvers.Strategies
using CTBase.Exceptions
using CUDA

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

# CUDA availability check
is_cuda_on() = CUDA.functional()

# ============================================================================
# Fake parameter type for testing (must be at module top-level)
# ============================================================================

struct FakeParam <: AbstractStrategyParameter end
Strategies.id(::Type{FakeParam}) = :fake

# ============================================================================
# Test function
# ============================================================================

"""
    test_cpu_only_parameters_integration()

Integration tests for CPU-only parameterized strategies (ADNLP, Ipopt).
"""
function test_cpu_only_parameters_integration()
    Test.@testset "CPU-Only Parameters Integration" verbose=VERBOSE showtiming=SHOWTIMING begin
        
        # ====================================================================
        # INTEGRATION TESTS - Registry with CPU-only strategies
        # ====================================================================
        
        Test.@testset "Registry with CPU-only strategies" begin
            # Create registry with parameterized CPU-only strategies
            registry = Strategies.create_registry(
                AbstractNLPModeler => (
                    (Modelers.ADNLP, [Strategies.CPU]),
                    (Modelers.Exa, [Strategies.CPU, Strategies.GPU])
                ),
                AbstractNLPSolver => (
                    (Solvers.Ipopt, [Strategies.CPU]),
                    (Solvers.MadNLP, [Strategies.CPU, Strategies.GPU]),
                    (Solvers.MadNCL, [Strategies.CPU, Strategies.GPU])
                )
            )
            
            # Verify registry structure
            Test.@test registry isa Strategies.StrategyRegistry
            
            # Verify strategy IDs
            modeler_ids = Strategies.strategy_ids(AbstractNLPModeler, registry)
            Test.@test :adnlp in modeler_ids
            Test.@test :exa in modeler_ids
            
            solver_ids = Strategies.strategy_ids(AbstractNLPSolver, registry)
            Test.@test :ipopt in solver_ids
            Test.@test :madnlp in solver_ids
            Test.@test :madncl in solver_ids
        end
        
        # ====================================================================
        # INTEGRATION TESTS - Building strategies with CPU parameter
        # ====================================================================
        
        Test.@testset "Build CPU-only strategies from registry" begin
            registry = Strategies.create_registry(
                AbstractNLPModeler => ((Modelers.ADNLP, [Strategies.CPU]),),
                AbstractNLPSolver => ((Solvers.Ipopt, [Strategies.CPU]),)
            )
            
            # Build ADNLP with CPU (should work)
            Test.@test_nowarn Strategies.build_strategy(
                :adnlp, Strategies.CPU, AbstractNLPModeler, registry
            )
            
            # Verify type
            modeler = Strategies.build_strategy(
                :adnlp, Strategies.CPU, AbstractNLPModeler, registry
            )
            Test.@test modeler isa Modelers.ADNLP{Strategies.CPU}
        end
        
        # ====================================================================
        # INTEGRATION TESTS - Attempting to build with GPU parameter
        # ====================================================================
        
        Test.@testset "Reject GPU parameter for CPU-only strategies" begin
            registry = Strategies.create_registry(
                AbstractNLPModeler => ((Modelers.ADNLP, [Strategies.CPU]),)
            )
            
            # Attempting to build ADNLP with GPU should fail
            Test.@test_throws Exceptions.IncorrectArgument begin
                Strategies.build_strategy(
                    :adnlp, Strategies.GPU, AbstractNLPModeler, registry
                )
            end
        end
        
        # ====================================================================
        # INTEGRATION TESTS - Mixed CPU and GPU strategies
        # ====================================================================
        
        Test.@testset "Mixed CPU-only and GPU-capable strategies" begin
            registry = Strategies.create_registry(
                AbstractNLPModeler => (
                    (Modelers.ADNLP, [Strategies.CPU]),
                    (Modelers.Exa, [Strategies.CPU, Strategies.GPU])
                )
            )
            
            # CPU parameter works for both
            Test.@test_nowarn Strategies.build_strategy(
                :adnlp, Strategies.CPU, AbstractNLPModeler, registry
            )
            Test.@test_nowarn Strategies.build_strategy(
                :exa, Strategies.CPU, AbstractNLPModeler, registry
            )
            
            # GPU tests only if CUDA is functional
            if is_cuda_on()
                # GPU parameter works only for Exa
                Test.@test_nowarn Strategies.build_strategy(
                    :exa, Strategies.GPU, AbstractNLPModeler, registry
                )
            else
                # CUDA not functional — skip GPU test silently
            end
            
            # GPU parameter fails for ADNLP (doesn't require CUDA to be functional)
            Test.@test_throws Exceptions.IncorrectArgument begin
                Strategies.build_strategy(
                    :adnlp, Strategies.GPU, AbstractNLPModeler, registry
                )
            end
        end
        
        # ====================================================================
        # INTEGRATION TESTS - Parameter extraction from method tuple
        # ====================================================================
        
        Test.@testset "Parameter extraction with CPU-only strategies" begin
            registry = Strategies.create_registry(
                AbstractNLPModeler => ((Modelers.ADNLP, [Strategies.CPU]),),
                AbstractNLPSolver => ((Solvers.Ipopt, [Strategies.CPU]),)
            )
            
            # Method with CPU parameter should work
            method_cpu = (:adnlp, :ipopt, :cpu)
            param = Strategies.extract_global_parameter_from_method(method_cpu, registry)
            Test.@test param == Strategies.CPU
            
            # Method with GPU parameter should fail (no strategy supports it)
            method_gpu = (:adnlp, :ipopt, :gpu)
            Test.@test_throws Exceptions.IncorrectArgument begin
                Strategies.extract_global_parameter_from_method(method_gpu, registry)
            end
        end
        
        # ====================================================================
        # INTEGRATION TESTS - Default parameters
        # ====================================================================
        
        Test.@testset "Default parameters for CPU-only strategies" begin
            # Verify default parameters
            Test.@test Strategies._default_parameter(Modelers.ADNLP) == Strategies.CPU
            Test.@test Strategies._default_parameter(Solvers.Ipopt) == Strategies.CPU
            
        end
        
        # ====================================================================
        # INTEGRATION TESTS - Error messages quality
        # ====================================================================
        
        Test.@testset "Error messages for unsupported parameters" begin
            registry = Strategies.create_registry(
                AbstractNLPModeler => ((Modelers.ADNLP, [Strategies.CPU]),)
            )
            
            # Test error message when trying to build with GPU
            err = try
                Strategies.build_strategy(
                    :adnlp, Strategies.GPU, AbstractNLPModeler, registry
                )
            catch e
                e
            end
            
            Test.@test err isa Exceptions.IncorrectArgument
            Test.@test occursin("CPU", err.expected)
            Test.@test occursin("available parameters", lowercase(err.msg))
            Test.@test err.suggestion !== nothing
        end
        
        # ====================================================================
        # INTEGRATION TESTS - Consistency across strategies
        # ====================================================================
        
        Test.@testset "Consistent behavior across CPU-only strategies" begin
            # All CPU-only strategies should behave consistently
            strategies_to_test = [
                (Modelers.ADNLP, "ADNLP"),
                (Solvers.Ipopt, "Ipopt")
            ]
            
            for (strategy_type, name) in strategies_to_test
                # Default parameter should be CPU
                Test.@test Strategies._default_parameter(strategy_type) == Strategies.CPU
                
                # Type constraints enforce parameter validation at compile-time
                # GPU and custom parameters will throw TypeError when attempting to construct
            end
        end
    end
end

end # module

test_cpu_only_parameters_integration() = TestCPUOnlyParametersIntegration.test_cpu_only_parameters_integration()
