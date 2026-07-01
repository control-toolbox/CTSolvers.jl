module TestIntegratorTypeStability

using Test: Test
import CTSolvers.Integrators
import CTBase.Strategies
using OrdinaryDiffEqTsit5: OrdinaryDiffEqTsit5, Tsit5
using SciMLBase: SciMLBase, ODEProblem
using DiffEqBase: DiffEqBase
import CommonSolve

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

function test_type_stability()
    Test.@testset "Integrator Type Stability" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ====================================================================
        # Strategies contract
        # ====================================================================

        Test.@testset "Strategies.id" begin
            Test.@test_nowarn Test.@inferred Strategies.id(Integrators.SciML)
            Test.@test Test.@inferred(Strategies.id(Integrators.SciML)) === :sciml
        end

        # ====================================================================
        # Construction
        # ====================================================================

        Test.@testset "SciML construction" begin
            # @inferred is too strict for parametric StrategyOptions{NT} — Julia infers
            # NT<:NamedTuple rather than the concrete NamedTuple. Check concrete type instead.
            Test.@test Integrators.SciML(alg=Tsit5()) isa Integrators.SciML
            Test.@test Integrators.SciML(alg=Tsit5(), reltol=1e-8) isa Integrators.SciML
            Test.@test Integrators.build_integrator(alg=Tsit5()) isa Integrators.SciML
        end

        # ====================================================================
        # Cached option-dict accessors (co-located with the SciML type)
        # ====================================================================

        Test.@testset "options_point / options_trajectory" begin
            integ = Integrators.SciML(alg=Tsit5())
            Test.@test_nowarn Test.@inferred Integrators.options_point(integ)
            Test.@test_nowarn Test.@inferred Integrators.options_trajectory(integ)
            Test.@test Test.@inferred(Integrators.options_point(integ)) isa Dict{Symbol,Any}
            Test.@test Test.@inferred(Integrators.options_trajectory(integ)) isa Dict{Symbol,Any}
        end

        # ====================================================================
        # Result accessors (after a real solve)
        # ====================================================================

        Test.@testset "result accessors" begin
            integ = Integrators.SciML(alg=Tsit5())
            prob = ODEProblem((u, p, t) -> -u, [1.0], (0.0, 1.0))
            r = CommonSolve.solve(prob, integ)

            Test.@test_nowarn Test.@inferred Integrators.final_state(r)
            Test.@test_nowarn Test.@inferred Integrators.times(r)
            Test.@test_nowarn Test.@inferred Integrators.evaluate_at(r, 0.5)
        end
    end
end

end # module

test_integrator_type_stability() = TestIntegratorTypeStability.test_type_stability()
