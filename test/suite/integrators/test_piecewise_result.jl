module TestPiecewiseResult

using Test: Test
using CTBase: Exceptions
using CTSolvers: Integrators
using CommonSolve: CommonSolve
using OrdinaryDiffEqTsit5: OrdinaryDiffEqTsit5, Tsit5
using SciMLBase: SciMLBase, ODEProblem

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

_integ(; kw...) = Integrators.SciML(; alg=Tsit5(), reltol=1e-12, abstol=1e-12, kw...)

# u' = -u on [t0, t1] from u(t0) = u0
_segment(t0, t1, u0; integ=_integ()) =
    CommonSolve.solve(ODEProblem((u, p, t) -> -u, [u0], (t0, t1)), integ)

"""
    test_piecewise_result()

🧪 **Applying Testing Rule**: Integration Tests (standalone end-to-end)

Multi-phase merge keeps every phase's own interpolant (issue CTFlows#434): evaluation inside a
phase is as accurate as a single-phase integration, and the trajectory is left-continuous at
a switching time.
"""
function test_piecewise_result()
    Test.@testset "Piecewise integration result" verbose=VERBOSE showtiming=SHOWTIMING begin
        ts, Δ = 0.5, 10.0
        left = exp(-ts)
        r1 = _segment(0.0, ts, 1.0)
        r2 = _segment(ts, 1.0, left + Δ)   # jump Δ at ts
        merged = Integrators.merge([r1, r2])
        exact(t) = t <= ts ? exp(-t) : (left + Δ) * exp(-(t - ts))

        Test.@testset "type and grid" begin
            Test.@test merged isa Integrators.PiecewiseIntegrationResult
            Test.@test Integrators.times(merged) ==
                vcat(Integrators.times(r1), Integrators.times(r2))
            Test.@test count(==(ts), Integrators.times(merged)) == 2
            Test.@test Integrators.final_state(merged) == Integrators.final_state(r2)
            Test.@test Integrators.is_dense(merged)
        end

        Test.@testset "dense precision in every phase" begin
            for t in (0.1, 0.25, 0.49, 0.51, 0.75, 0.99)
                Test.@test Integrators.evaluate_at(merged, t)[1] ≈ exact(t) atol = 1e-10
            end
        end

        Test.@testset "left-continuous at the switching time" begin
            Test.@test Integrators.evaluate_at(merged, ts)[1] ≈ left atol = 1e-12
            Test.@test Integrators.evaluate_at(merged, ts + 1e-12)[1] ≈ left + Δ atol = 1e-9
        end

        Test.@testset "three phases" begin
            r3a = _segment(0.0, 0.3, 1.0)
            r3b = _segment(0.3, 0.6, exp(-0.3))
            r3c = _segment(0.6, 1.0, exp(-0.6))
            m3 = Integrators.merge([r3a, r3b, r3c])
            for t in (0.0, 0.15, 0.3, 0.45, 0.6, 0.8, 1.0)
                Test.@test Integrators.evaluate_at(m3, t)[1] ≈ exp(-t) atol = 1e-10
            end
        end

        Test.@testset "backward integration" begin
            b1 = _segment(1.0, 0.5, 1.0)
            b2 = _segment(0.5, 0.0, 2.0 * exp(0.5))   # jump ×2 at 0.5
            mb = Integrators.merge([b1, b2])
            Test.@test Integrators.evaluate_at(mb, 0.75)[1] ≈ exp(0.25) atol = 1e-10
            Test.@test Integrators.evaluate_at(mb, 0.5)[1] ≈ exp(0.5) atol = 1e-10   # left
            Test.@test Integrators.evaluate_at(mb, 0.25)[1] ≈ 2exp(0.75) atol = 1e-9
        end

        Test.@testset "non-dense segments" begin
            integ = _integ(; dense=false)
            m = Integrators.merge([
                _segment(0.0, ts, 1.0; integ=integ), _segment(ts, 1.0, left; integ=integ)
            ])
            Test.@test !Integrators.is_dense(m)
        end

        Test.@testset "status" begin
            Test.@test Integrators.successful(merged)
            Test.@test Integrators.status(merged) == :Success
        end

        Test.@testset "Error: no segment" begin
            Test.@test_throws Exceptions.IncorrectArgument Integrators.PiecewiseIntegrationResult(
                typeof(r1)[]
            )
        end

        Test.@testset "type stability" begin
            Test.@test_nowarn Test.@inferred Integrators.times(merged)
            Test.@test_nowarn Test.@inferred Integrators.evaluate_at(merged, 0.3)
            Test.@test_nowarn Test.@inferred Integrators.final_state(merged)
        end
    end
end

end # module

test_piecewise_result() = TestPiecewiseResult.test_piecewise_result()
