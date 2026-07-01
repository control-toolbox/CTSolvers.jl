module TestIntegratorTypes

using Test: Test
import CTBase.Core
import CTSolvers.Integrators
import CTBase.Strategies

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

"""
    test_integrator_types()

Tests for the integrator type hierarchy and contracts.

🧪 **Applying Testing Rule**: Contract-First Testing

Tests the basic type hierarchy and `Strategies.id()` contract without requiring
extensions to be loaded.
"""
function test_integrator_types()
    Test.@testset "Integrator Types and Contracts" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ====================================================================
        # UNIT TESTS - Type Hierarchy
        # ====================================================================

        Test.@testset "Type Hierarchy" begin
            Test.@test Integrators.AbstractIntegrator <: Strategies.AbstractStrategy
            Test.@test Integrators.AbstractSciMLIntegrator <: Integrators.AbstractIntegrator
            Test.@test Integrators.SciML <: Integrators.AbstractSciMLIntegrator

            Test.@test isabstracttype(Integrators.AbstractIntegrator)
            Test.@test isabstracttype(Integrators.AbstractSciMLIntegrator)
            Test.@test !isabstracttype(Integrators.SciML)

            Test.@test isabstracttype(Integrators.AbstractIntegrationResult)
        end

        # ====================================================================
        # UNIT TESTS - Strategies.id() Contract
        # ====================================================================

        Test.@testset "Strategies.id() Contract" begin
            Test.@test Strategies.id(Integrators.SciML) === :sciml
            Test.@test Strategies.id(Integrators.SciML) isa Symbol
            Test.@test Strategies.description(Integrators.SciML) isa AbstractString
        end

        # ====================================================================
        # UNIT TESTS - Tag Types
        # ====================================================================

        Test.@testset "Tag Types" begin
            Test.@test Integrators.SciMLTag <: Core.AbstractTag
            Test.@test Integrators.Tsit5Tag <: Core.AbstractTag
            Test.@test !isabstracttype(Integrators.SciMLTag)
            Test.@test !isabstracttype(Integrators.Tsit5Tag)
        end

        # ====================================================================
        # UNIT TESTS - Struct Fields
        # ====================================================================

        Test.@testset "Struct Fields" begin
            Test.@test :options in fieldnames(Integrators.SciML)
            Test.@test :options_point in fieldnames(Integrators.SciML)
            Test.@test :options_trajectory in fieldnames(Integrators.SciML)
            Test.@test length(fieldnames(Integrators.SciML)) == 3
        end
    end
end

end # module

test_integrator_types() = TestIntegratorTypes.test_integrator_types()
