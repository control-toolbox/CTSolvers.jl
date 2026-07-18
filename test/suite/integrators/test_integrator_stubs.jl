module TestIntegratorExtensionStubs

using Test: Test
import CTBase.Core
import CTBase.Exceptions
import CTBase.Strategies
import CTSolvers.Integrators
using CommonSolve: CommonSolve

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

# Fake tag never implemented by any extension: build_sciml_integrator stub must throw
# even when the SciML extension is loaded (it only implements the concrete SciMLTag).
struct DummyTag <: Core.AbstractTag end

# Fake integrator / result to exercise the generic NotImplemented contract stubs.
struct FakeIntegrator <: Integrators.AbstractIntegrator end
struct FakeResult <: Integrators.AbstractIntegrationResult end

"""
    test_integrator_stubs()

🧪 **Applying Testing Rule**: Error Tests

Tests that core contract stubs throw the right errors when no concrete implementation
matches (extension not loaded, or a foreign integrator/result type).
"""
function test_integrator_stubs()
    Test.@testset "Integrator Extension Stubs" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ====================================================================
        # build_sciml_integrator stub (DummyTag never implemented)
        # ====================================================================

        Test.@testset "build_sciml_integrator stub" begin
            Test.@test_throws Exceptions.ExtensionError Integrators.build_sciml_integrator(
                DummyTag, Strategies.CPU
            )

            err = nothing
            try
                Integrators.build_sciml_integrator(DummyTag, Strategies.CPU)
            catch e
                err = e
            end
            Test.@test err isa Exceptions.ExtensionError
            err_str = string(err)
            Test.@test occursin("OrdinaryDiffEqTsit5", err_str)
            Test.@test occursin("SciML", err_str)
        end

        # ====================================================================
        # __default_sciml_algorithm stub (DummyTag → missing)
        # ====================================================================

        Test.@testset "__default_sciml_algorithm stub" begin
            Test.@test Integrators.__default_sciml_algorithm(DummyTag) === missing
        end

        # ====================================================================
        # CommonSolve.solve generic stub (foreign integrator)
        # ====================================================================

        Test.@testset "solve generic stub" begin
            Test.@test_throws Exceptions.NotImplemented CommonSolve.solve(
                nothing, FakeIntegrator()
            )
        end

        # ====================================================================
        # merge generic stub (foreign result)
        # ====================================================================

        Test.@testset "merge generic stub" begin
            Test.@test_throws Exceptions.NotImplemented Integrators.merge([FakeResult()])
        end

        # ====================================================================
        # AbstractIntegrationResult accessor stubs (foreign result)
        # ====================================================================

        Test.@testset "result accessor stubs" begin
            Test.@test_throws Exceptions.NotImplemented Integrators.final_state(
                FakeResult()
            )
            Test.@test_throws Exceptions.NotImplemented Integrators.times(FakeResult())
            Test.@test_throws Exceptions.NotImplemented Integrators.evaluate_at(
                FakeResult(), 0.0
            )
            Test.@test_throws Exceptions.NotImplemented Integrators.status(FakeResult())
            Test.@test_throws Exceptions.NotImplemented Integrators.successful(FakeResult())
        end
    end
end

end # module

test_integrator_stubs() = TestIntegratorExtensionStubs.test_integrator_stubs()
