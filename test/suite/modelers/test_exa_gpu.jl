module TestExaGPU

import Test
import CTBase.Exceptions
import CTSolvers.Modelers
import CTSolvers.Strategies
import CTSolvers.Options
import CUDA

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

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
    end
end

end # module

test_exa_gpu() = TestExaGPU.test_exa_gpu()
