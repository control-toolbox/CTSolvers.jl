module TestExaGPU

import Test
import CTBase.Exceptions
import CTSolvers.Modelers
import CTSolvers.Strategies
import CTSolvers.Options
import CUDA

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

is_cuda_on() = CUDA.functional()

"""
    test_exa_gpu()

🧪 **Applying Testing Rule**: Unit Tests for Exa GPU backend handling

Tests uncovered lines in exa.jl:
- Lines 41-75: __get_cuda_backend() and GPU parameter handling
- Line 205: Strategies.id()
- Lines 342-351: Parameterized constructor with deprecated aliases
"""
function test_exa_gpu()
    Test.@testset "Exa GPU Backend" verbose=VERBOSE showtiming=SHOWTIMING begin
        
        # ====================================================================
        # UNIT TESTS - Strategies.id()
        # ====================================================================
        
        Test.@testset "Strategies.id()" begin
            # Test id() for Exa type (covers exa.jl:205)
            Test.@test Strategies.id(Modelers.Exa) === :exa
            Test.@test Strategies.id(Modelers.Exa{Strategies.CPU}) === :exa
            Test.@test Strategies.id(Modelers.Exa{Strategies.GPU}) === :exa
        end
        
        # ====================================================================
        # UNIT TESTS - Parameterized Constructor with Deprecated Aliases
        # ====================================================================
        
        Test.@testset "Parameterized Constructor - Deprecated Aliases" begin
            # Test parameterized constructor with deprecated exa_backend alias
            # This covers exa.jl:342-351
            
            # Suppress deprecation warning
            redirect_stderr(devnull) do
                # CPU parameter with deprecated alias
                Test.@test_logs (:warn, r"exa_backend is deprecated") Modelers.Exa{Strategies.CPU}(exa_backend=nothing)
                
                modeler = Modelers.Exa{Strategies.CPU}(exa_backend=nothing)
                Test.@test modeler isa Modelers.Exa{Strategies.CPU}
            end
            
            # Test without deprecated alias (should not warn)
            Test.@test_nowarn Modelers.Exa{Strategies.CPU}(backend=nothing)
        end
        
        # ====================================================================
        # UNIT TESTS - Default Parameter
        # ====================================================================
        
        Test.@testset "Default Parameter" begin
            # Test that default constructor uses CPU parameter
            modeler = Modelers.Exa()
            Test.@test modeler isa Modelers.Exa{Strategies.CPU}
        end
        
        # ====================================================================
        # UNIT TESTS - Consistency Validation
        # ====================================================================
        
        Test.@testset "Consistency validation warnings" begin
            # Test that metadata contains validators for backend consistency
            
            # Test Exa metadata structure
            exa_cpu_meta = Strategies.metadata(Modelers.Exa{Strategies.CPU})
            exa_gpu_meta = Strategies.metadata(Modelers.Exa{Strategies.GPU})
            
            Test.@test haskey(exa_cpu_meta, :backend)
            Test.@test haskey(exa_gpu_meta, :backend)
            
            # Verify that the backend options have validators
            Test.@test exa_cpu_meta[:backend].validator !== nothing
            Test.@test exa_gpu_meta[:backend].validator !== nothing
            
            # Test that validators are functions (callable)
            Test.@test isa(exa_cpu_meta[:backend].validator, Function)
            Test.@test isa(exa_gpu_meta[:backend].validator, Function)
            
            # Test actual validation with different backends
            cpu_validator = exa_cpu_meta[:backend].validator
            gpu_validator = exa_gpu_meta[:backend].validator
            
            # Test validators accept different inputs (no warnings expected)
            Test.@test cpu_validator(nothing) === nothing
            Test.@test gpu_validator(nothing) === nothing  # This will warn but still return nothing
            
            # Test GPU parameter with nothing backend (should warn)
            Test.@test_logs (:warn, r"Inconsistent backend") gpu_validator(nothing)
            
            # If CUDA is available, test with CUDA backend
            if is_cuda_on()
                cuda_backend = CUDA.CUDABackend()
                Test.@test cpu_validator(cuda_backend) === cuda_backend  # This will warn but still return cuda_backend
                Test.@test gpu_validator(cuda_backend) === cuda_backend
                
                # Test CPU parameter with CUDA backend (should warn)
                Test.@test_logs (:warn, r"Inconsistent backend") cpu_validator(cuda_backend)
            end
        end
    end
end

end # module

test_exa_gpu() = TestExaGPU.test_exa_gpu()
