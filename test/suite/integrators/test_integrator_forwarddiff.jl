module TestIntegratorForwardDiff

using Test: Test
using ForwardDiff: ForwardDiff
import CTSolvers.Integrators
using CommonSolve: CommonSolve
using OrdinaryDiffEqTsit5: OrdinaryDiffEqTsit5, Tsit5
using SciMLBase: SciMLBase, ODEProblem
using DiffEqBase: DiffEqBase

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

function test_integrator_forwarddiff()
    Test.@testset "Integrator ForwardDiff (end-to-end)" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ODE:  u' = -u,  u(0) = u0
        # Analytical solution: u(t) = u0 * exp(-t)
        # Derivative w.r.t. u0: du(t)/du0 = exp(-t)
        #
        # We seed u0 = Dual(1.0, 1.0) so value = exp(-1) and partial = exp(-1) at t=1.
        # This exercises CTSolversForwardDiff (deepvalue + real_norm on Dual) and
        # CTSolversSciMLIntegrator (internalnorm using real_norm) together.

        integ = Integrators.SciML(alg=Tsit5())

        # ====================================================================
        # Scalar dual: internalnorm must not throw on Dual-valued state
        # ====================================================================

        Test.@testset "solve with Dual initial condition" begin
            u0 = [ForwardDiff.Dual{:ADTag}(1.0, 1.0)]
            prob = ODEProblem((u, p, t) -> -u, u0, (0.0, 1.0))

            r = CommonSolve.solve(prob, integ)
            Test.@test r isa Integrators.AbstractIntegrationResult

            fs = Integrators.final_state(r)

            # Value part matches the analytic solution
            Test.@test ForwardDiff.value(fs[1]) ≈ exp(-1) atol=1e-5

            # Partial (sensitivity of final state w.r.t. u0) = exp(-1)
            Test.@test ForwardDiff.partials(fs[1])[1] ≈ exp(-1) atol=1e-5
        end

        # ====================================================================
        # Trajectory evaluation with Dual state
        # ====================================================================

        Test.@testset "evaluate_at with Dual state" begin
            u0 = [ForwardDiff.Dual{:ADTag}(1.0, 1.0)]
            prob = ODEProblem((u, p, t) -> -u, u0, (0.0, 1.0))

            r = CommonSolve.solve(prob, integ)

            mid = Integrators.evaluate_at(r, 0.5)
            Test.@test ForwardDiff.value(mid[1]) ≈ exp(-0.5) atol=1e-4
            Test.@test ForwardDiff.partials(mid[1])[1] ≈ exp(-0.5) atol=1e-4
        end

        # ====================================================================
        # Nested dual (deepvalue must recurse)
        # ====================================================================

        Test.@testset "nested Dual initial condition" begin
            inner = ForwardDiff.Dual{:Inner}(1.0, 1.0)
            u0 = [ForwardDiff.Dual{:Outer}(inner, inner)]
            prob = ODEProblem((u, p, t) -> -u, u0, (0.0, 1.0))

            # Must complete without throwing (internalnorm handles nested duals)
            Test.@test_nowarn CommonSolve.solve(prob, integ)
        end
    end
end

end # module

test_integrator_forwarddiff() = TestIntegratorForwardDiff.test_integrator_forwarddiff()
