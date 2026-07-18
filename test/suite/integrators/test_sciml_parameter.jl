module TestSciMLParameter

using Test: Test
import CTBase.Core
import CTBase.Exceptions
import CTSolvers.Integrators
import CTBase.Strategies

# Extensions: CTSolversSciMLIntegrator (DiffEqBase + SciMLBase), the Tsit5 default alg
# (OrdinaryDiffEqTsit5), and CTSolversCUDA (CUDA) for the device consistency validators.
using OrdinaryDiffEqTsit5: OrdinaryDiffEqTsit5, Tsit5
using SciMLBase: SciMLBase
using DiffEqBase: DiffEqBase
using CUDA: CUDA

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

is_cuda_on() = CUDA.functional()

"""
    test_sciml_parameter()

🧪 **Applying Testing Rule**: Contract tests for the device-parameterized `SciML{P}` integrator.

Covers the `SciML{P<:Union{CPU,GPU}}` parameterization (GPU roadmap phase 1 / D1): the parameter
contract (`parameter`/`default_parameter`/`id`), per-parameter `metadata` and back-compat bare
delegation, per-parameter construction, registry `[CPU, GPU]` registration + global-parameter
extraction, and the `__consistent_initial_condition` device consistency validators. All assertions
run on CPU; only the `CuArray` cases are gated behind `is_cuda_on()`.
"""
function test_sciml_parameter()
    Test.@testset "SciML{P} parameterization" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ====================================================================
        # CONTRACT - parameter / default_parameter / id (no extension needed)
        # ====================================================================

        Test.@testset "parameter contract" begin
            Test.@test Strategies.parameter(Integrators.SciML{Strategies.CPU}) ==
                Strategies.CPU
            Test.@test Strategies.parameter(Integrators.SciML{Strategies.GPU}) ==
                Strategies.GPU
            Test.@test Strategies.default_parameter(Integrators.SciML) == Strategies.CPU

            Test.@test Strategies.id(Integrators.SciML) === :sciml
            Test.@test Strategies.id(Integrators.SciML{Strategies.CPU}) === :sciml
            Test.@test Strategies.id(Integrators.SciML{Strategies.GPU}) === :sciml
        end

        # ====================================================================
        # CONTRACT - per-parameter metadata + back-compat bare delegation
        # ====================================================================

        Test.@testset "per-parameter metadata" begin
            md_bare = Strategies.metadata(Integrators.SciML)
            md_cpu = Strategies.metadata(Integrators.SciML{Strategies.CPU})
            md_gpu = Strategies.metadata(Integrators.SciML{Strategies.GPU})

            Test.@test md_bare isa Strategies.StrategyMetadata
            Test.@test md_cpu isa Strategies.StrategyMetadata
            Test.@test md_gpu isa Strategies.StrategyMetadata

            # Bare `metadata(SciML)` delegates to `metadata(SciML{CPU})` (back-compat).
            Test.@test collect(keys(md_bare)) == collect(keys(md_cpu))

            # Option set is currently identical for both devices (few defaults differ yet).
            Test.@test collect(keys(md_cpu)) == collect(keys(md_gpu))
            for k in (:alg, :reltol, :abstol, :internalnorm)
                Test.@test haskey(md_cpu, k)
                Test.@test haskey(md_gpu, k)
            end
        end

        # ====================================================================
        # CONTRACT - construction per parameter (SciML() ≡ SciML{CPU})
        # ====================================================================

        Test.@testset "construction per parameter" begin
            integ_default = Integrators.SciML(; alg=Tsit5())
            Test.@test integ_default isa Integrators.SciML{Strategies.CPU}
            Test.@test Strategies.parameter(typeof(integ_default)) == Strategies.CPU

            integ_cpu = Integrators.SciML{Strategies.CPU}(; alg=Tsit5())
            Test.@test integ_cpu isa Integrators.SciML{Strategies.CPU}

            # Building a SciML{GPU} needs no functional GPU — only the option bundle is built.
            integ_gpu = Integrators.SciML{Strategies.GPU}(; alg=Tsit5())
            Test.@test integ_gpu isa Integrators.SciML{Strategies.GPU}
            Test.@test Strategies.parameter(typeof(integ_gpu)) == Strategies.GPU
            Test.@test Strategies.id(typeof(integ_gpu)) === :sciml
        end

        # ====================================================================
        # INTEGRATION - registry with [CPU, GPU] + global parameter extraction
        # ====================================================================

        Test.@testset "registry with device parameters" begin
            r = Strategies.create_registry(
                Integrators.AbstractIntegrator =>
                    ((Integrators.SciML, [Strategies.CPU, Strategies.GPU]),),
            )

            Test.@test :sciml in Strategies.strategy_ids(Integrators.AbstractIntegrator, r)

            Test.@test Strategies.extract_global_parameter_from_method((:sciml, :cpu), r) ==
                Strategies.CPU
            Test.@test Strategies.extract_global_parameter_from_method((:sciml, :gpu), r) ==
                Strategies.GPU
        end

        # ====================================================================
        # CONTRACT - __consistent_initial_condition device validator
        # ====================================================================

        Test.@testset "initial-condition consistency" begin
            host = [1.0, 2.0]

            # Core default: a host array is consistent with CPU.
            Test.@test Integrators.__consistent_initial_condition(Strategies.CPU, host) == true

            # CTSolversCUDA (loaded via `using CUDA`): a host array is inconsistent with GPU.
            Test.@test Integrators.__consistent_initial_condition(Strategies.GPU, host) == false

            if is_cuda_on()
                dev = CUDA.cu(host)
                Test.@test Integrators.__consistent_initial_condition(
                    Strategies.GPU, dev
                ) == true
                Test.@test Integrators.__consistent_initial_condition(
                    Strategies.CPU, dev
                ) == false
            end
        end
    end
end

end # module

test_sciml_parameter() = TestSciMLParameter.test_sciml_parameter()
