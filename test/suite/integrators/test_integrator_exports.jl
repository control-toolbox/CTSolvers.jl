module TestIntegratorExports

using Test: Test
using CTSolvers: CTSolvers
import CTSolvers.Integrators

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

function test_integrator_exports()
    Test.@testset "Integrators Module Exports" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ====================================================================
        # CTSolvers exposes the Integrators submodule
        # ====================================================================

        Test.@testset "submodule accessible" begin
            Test.@test isdefined(CTSolvers, :Integrators)
            Test.@test CTSolvers.Integrators isa Module
        end

        # ====================================================================
        # Exported abstract types
        # ====================================================================

        Test.@testset "Exported abstract types" begin
            for sym in
                (:AbstractIntegrator, :AbstractSciMLIntegrator, :AbstractIntegrationResult)
                Test.@testset "$sym" begin
                    Test.@test sym in names(Integrators)
                    Test.@test isdefined(Integrators, sym)
                end
            end
        end

        # ====================================================================
        # Exported concrete types and tags
        # ====================================================================

        Test.@testset "Exported concrete types and tags" begin
            for sym in (:SciML, :SciMLTag, :Tsit5Tag)
                Test.@testset "$sym" begin
                    Test.@test sym in names(Integrators)
                    Test.@test isdefined(Integrators, sym)
                end
            end
        end

        # ====================================================================
        # Exported functions
        # ====================================================================

        Test.@testset "Exported functions" begin
            for sym in (
                :final_state,
                :times,
                :evaluate_at,
                :status,
                :successful,
                :options_point,
                :options_trajectory,
                :merge,
            )
                Test.@testset "$sym" begin
                    Test.@test sym in names(Integrators)
                    Test.@test isdefined(Integrators, sym)
                end
            end
        end

        # ====================================================================
        # Internal symbols — defined in the module, NOT exported
        # ====================================================================

        Test.@testset "Internal symbols (not exported)" begin
            for sym in (:__unsafe, :__default_sciml_algorithm, :deepvalue, :real_norm, :_build_sciml_integrator)
                Test.@testset "$sym" begin
                    Test.@test isdefined(Integrators, sym)
                    Test.@test !(sym in names(Integrators))
                end
            end
        end

        # ====================================================================
        # CTSolvers top-level does NOT re-export Integrators symbols
        # ====================================================================

        Test.@testset "No top-level re-exports from CTSolvers" begin
            for sym in (
                :SciML,
                :SciMLTag,
                :Tsit5Tag,
                :AbstractIntegrator,
                :AbstractIntegrationResult,
                :final_state,
                :times,
                :evaluate_at,
                :status,
                :successful,
                :options_point,
                :options_trajectory,
            )
                Test.@test !(sym in names(CTSolvers))
            end
        end
    end
end

end # module

test_integrator_exports() = TestIntegratorExports.test_integrator_exports()
