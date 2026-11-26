module TestReversedResult

using Test: Test
using CTBase: Exceptions
using CTSolvers: Integrators
using CommonSolve: CommonSolve
using OrdinaryDiffEqTsit5: OrdinaryDiffEqTsit5, Tsit5
using SciMLBase: SciMLBase, ODEProblem

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

_integ(; kw...) = Integrators.SciML(; alg=Tsit5(), reltol=1e-12, abstol=1e-12, kw...)

# u' = -u on the span (t0, t1) from u(t0) = u0: u(t) = u0 e^{-(t - t0)}
function _segment(t0, t1, u0; integ=_integ())
    return CommonSolve.solve(ODEProblem((u, p, t) -> -u, [u0], (t0, t1)), integ)
end

"""
    test_reversed_result()

🧪 **Applying Testing Rule**: Unit + Integration Tests

`reverse(r)` reads an integration result in the other direction of time without integrating
again (issue #355): a backward integration read in increasing time, as a forward one would
be, for a single result and for a piecewise one (left-continuous at a switching time).
"""
function test_reversed_result()
    Test.@testset "Reversed integration result" verbose = VERBOSE showtiming = SHOWTIMING begin

        # ====================================================================
        # UNIT TESTS - a single result
        # ====================================================================

        Test.@testset "a backward integration read forward" begin
            # u(1) = 1, integrated down to 0: u(t) = e^{1 - t}
            r = _segment(1.0, 0.0, 1.0)
            rv = reverse(r)
            Test.@test rv isa Integrators.ReversedIntegrationResult
            Test.@test issorted(Integrators.times(rv); lt=(<=))
            Test.@test Integrators.times(rv) == reverse(Integrators.times(r))
            Test.@test first(Integrators.times(rv)) == 0.0
            Test.@test last(Integrators.times(rv)) == 1.0
            # the final state is the state at the largest time: the initial condition
            Test.@test Integrators.final_state(rv)[1] ≈ 1.0 atol = 1e-14
            for t in (0.0, 0.3, 0.5, 0.9, 1.0)
                Test.@test Integrators.evaluate_at(rv, t)[1] ≈ exp(1 - t) atol = 1e-10
                Test.@test Integrators.evaluate_at(rv, t) == Integrators.evaluate_at(r, t)
            end
            Test.@test Integrators.is_dense(rv) == Integrators.is_dense(r)
            Test.@test Integrators.status(rv) == Integrators.status(r)
            Test.@test Integrators.successful(rv)
            Test.@test Integrators._tspan(rv) == (0.0, 1.0)
            Test.@test isempty(Integrators.switching_times(rv))
        end

        Test.@testset "involution" begin
            r = _segment(1.0, 0.0, 1.0)
            Test.@test reverse(reverse(r)) === r
            f = _segment(0.0, 1.0, 1.0)
            Test.@test Integrators.times(reverse(reverse(f))) == Integrators.times(f)
        end

        Test.@testset "regrid in the new direction" begin
            r = _segment(1.0, 0.0, 1.0)
            grid = collect(range(0.0, 1.0; length=11))
            g = Integrators.regrid(reverse(r), grid)
            Test.@test g isa Integrators.ReversedIntegrationResult
            Test.@test Integrators.times(g) == grid
            for t in grid
                Test.@test Integrators.evaluate_at(g, t)[1] ≈ exp(1 - t) atol = 1e-10
            end
            Test.@test Integrators.final_state(g)[1] ≈ 1.0 atol = 1e-12
            # a grid in the integration order of the inner result is not valid here
            Test.@test_throws Exceptions.IncorrectArgument Integrators.regrid(
                reverse(r), reverse(grid)
            )
        end

        Test.@testset "a regridded result reversed" begin
            r = Integrators.regrid(_segment(1.0, 0.0, 1.0), [1.0, 0.75, 0.5, 0.25, 0.0])
            rv = reverse(r)
            Test.@test Integrators.times(rv) == [0.0, 0.25, 0.5, 0.75, 1.0]
            Test.@test Integrators.final_state(rv)[1] ≈ 1.0 atol = 1e-12
        end

        # ====================================================================
        # INTEGRATION TESTS - piecewise results
        # ====================================================================

        Test.@testset "a backward piecewise integration, with a jump" begin
            # Forward in time: u' = -u on [0, ts], jump +Δ at ts, u' = -u on [ts, 1].
            # Integrated backward from u(1), with the inverse jump -Δ at ts.
            ts, Δ = 0.5, 10.0
            u_left = 1.0                             # u(ts) before the jump
            u_right = u_left + Δ                     # u(ts) after the jump
            u1 = u_right * exp(-(1 - ts))            # u(1)
            r2 = _segment(1.0, ts, u1)               # phase 2, backward: ends at u_right
            r1 = _segment(ts, 0.0, u_left)           # phase 1, backward, after the inverse jump
            merged = Integrators.merge([r2, r1])     # integration order
            Test.@test Integrators.switching_times(merged) == [ts]
            rv = reverse(merged)
            Test.@test rv isa Integrators.PiecewiseIntegrationResult
            Test.@test issorted(Integrators.times(rv); lt=(<=))
            Test.@test count(==(ts), Integrators.times(rv)) == 1
            Test.@test Integrators.switching_times(rv) == [ts]
            Test.@test Integrators.final_state(rv)[1] ≈ u1 atol = 1e-12
            # left-continuous in increasing time: the value before the jump, then after
            Test.@test Integrators.evaluate_at(rv, ts)[1] ≈ u_left atol = 1e-12
            Test.@test Integrators.right_limit(rv, 1)[1] ≈ u_right atol = 1e-12
            exact(t) = t <= ts ? u_left * exp(-(t - ts)) : u_right * exp(-(t - ts))
            for t in (0.0, 0.2, 0.49, 0.51, 0.8, 1.0)
                Test.@test Integrators.evaluate_at(rv, t)[1] ≈ exact(t) atol = 1e-9
            end
        end

        Test.@testset "three backward phases" begin
            r3 = _segment(3.0, 2.0, 1.0)
            r2 = _segment(2.0, 1.0, 2.0)
            r1 = _segment(1.0, 0.0, 3.0)
            rv = reverse(Integrators.merge([r3, r2, r1]))
            Test.@test Integrators.switching_times(rv) == [1.0, 2.0]
            Test.@test first(Integrators.times(rv)) == 0.0
            Test.@test last(Integrators.times(rv)) == 3.0
            Test.@test Integrators.evaluate_at(rv, 1.0)[1] ≈ 3.0 atol = 1e-12
            Test.@test Integrators.right_limit(rv, 1)[1] ≈ 2.0 * exp(1.0) atol = 1e-9
            Test.@test Integrators.evaluate_at(rv, 2.0)[1] ≈ 2.0 atol = 1e-12
            Test.@test Integrators.right_limit(rv, 2)[1] ≈ exp(1.0) atol = 1e-9
            Test.@test Integrators.final_state(rv)[1] ≈ 1.0 atol = 1e-12
            # reversing twice gives the integration order back
            rr = reverse(rv)
            Test.@test Integrators.times(rr) ==
                Integrators.times(Integrators.merge([r3, r2, r1]))
            Test.@test Integrators.switching_times(rr) == [2.0, 1.0]
        end

        Test.@testset "a forward piecewise result reversed" begin
            m = Integrators.merge([_segment(0.0, 0.5, 1.0), _segment(0.5, 1.0, 5.0)])
            rv = reverse(m)
            Test.@test !issorted(Integrators.times(rv))
            Test.@test Integrators.switching_times(rv) == [0.5]
            # in decreasing time, the value at ts is the one of the phase that ends there
            Test.@test Integrators.evaluate_at(rv, 0.5)[1] ≈ 5.0 atol = 1e-12
            Test.@test Integrators.right_limit(rv, 1)[1] ≈ exp(-0.5) atol = 1e-10
        end

        # ====================================================================
        # Type stability
        # ====================================================================

        Test.@testset "type stability" begin
            rv = reverse(_segment(1.0, 0.0, 1.0))
            Test.@inferred Integrators.evaluate_at(rv, 0.5)
            Test.@inferred Integrators.times(rv)
            Test.@inferred Integrators.final_state(rv)
        end
    end
end

end # module

test_reversed_result() = TestReversedResult.test_reversed_result()
