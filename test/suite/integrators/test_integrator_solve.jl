module TestIntegratorSolve

using Test: Test
import CTBase.Exceptions
import CTSolvers.Integrators
using CommonSolve: CommonSolve
using OrdinaryDiffEqTsit5: OrdinaryDiffEqTsit5, Tsit5
using SciMLBase: SciMLBase, ODEProblem
using DiffEqBase: DiffEqBase

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

"""
    test_integrator_solve()

🧪 **Applying Testing Rule**: Integration Tests (standalone end-to-end)

Integrates a raw `ODEProblem` with a `SciML` integrator and checks the result interface
against the known analytic solution u' = -u, u(0) = 1 ⇒ u(1) = exp(-1).
"""
function test_integrator_solve()
    Test.@testset "Integrator Solve (end-to-end)" verbose=VERBOSE showtiming=SHOWTIMING begin
        integ = Integrators.SciML(; alg=Tsit5())
        prob = ODEProblem((u, p, t) -> -u, [1.0], (0.0, 1.0))

        # ====================================================================
        # Default options (trajectory) + result interface
        # ====================================================================

        Test.@testset "solve + result interface" begin
            r = CommonSolve.solve(prob, integ)
            Test.@test r isa Integrators.AbstractIntegrationResult

            fs = Integrators.final_state(r)
            Test.@test fs[1] ≈ exp(-1) atol=1e-6

            ts = Integrators.times(r)
            Test.@test first(ts) == 0.0
            Test.@test last(ts) == 1.0

            # Continuous evaluation via interpolation (dense trajectory options)
            Test.@test Integrators.evaluate_at(r, 0.5)[1] ≈ exp(-0.5) atol=1e-5

            Test.@test Integrators.successful(r) == true
            Test.@test Integrators.status(r) == :Success
        end

        # ====================================================================
        # Explicit options dict
        # ====================================================================

        Test.@testset "solve with explicit options" begin
            r = CommonSolve.solve(prob, integ; options=Integrators.options_point(integ))
            Test.@test Integrators.final_state(r)[1] ≈ exp(-1) atol=1e-6
        end

        # ====================================================================
        # merge concatenates segments
        # ====================================================================

        Test.@testset "merge segments" begin
            prob1 = ODEProblem((u, p, t) -> -u, [1.0], (0.0, 0.5))
            prob2 = ODEProblem((u, p, t) -> -u, [1.0], (0.5, 1.0))
            r1 = CommonSolve.solve(prob1, integ)
            r2 = CommonSolve.solve(prob2, integ)
            merged = Integrators.merge([r1, r2])
            Test.@test merged isa Integrators.AbstractIntegrationResult
            Test.@test last(Integrators.times(merged)) == 1.0
            Test.@test Integrators.successful(merged) == true
            Test.@test Integrators.status(merged) == :Success

            # single-element merge returns the segment unchanged
            Test.@test Integrators.merge([r1]) === r1
        end

        # ====================================================================
        # merge propagates a failing segment's status instead of overwriting it
        # ====================================================================

        Test.@testset "merge aggregates a failing segment's retcode" begin
            bad_prob = ODEProblem((u, p, t) -> -u, [1.0], (0.0, 0.5))
            r_bad = CommonSolve.solve(
                bad_prob,
                integ;
                options=Dict{Symbol,Any}(:alg => Tsit5(), :maxiters => 1),
                unsafe=true,
            )
            r_ok = CommonSolve.solve(
                ODEProblem((u, p, t) -> -u, [1.0], (0.5, 1.0)), integ
            )
            Test.@test Integrators.successful(r_bad) == false

            merged = Integrators.merge([r_bad, r_ok])
            Test.@test Integrators.successful(merged) == false
            Test.@test Integrators.status(merged) == Integrators.status(r_bad)
        end

        # ====================================================================
        # evaluate_at at boundary points
        # ====================================================================

        Test.@testset "evaluate_at boundary points" begin
            r = CommonSolve.solve(prob, integ)
            Test.@test Integrators.evaluate_at(r, 0.0)[1] ≈ 1.0 atol=1e-10
            Test.@test Integrators.evaluate_at(r, 1.0)[1] ≈ exp(-1) atol=1e-6
        end

        # ====================================================================
        # unsafe flag on a failing integration
        # ====================================================================

        Test.@testset "retcode checking" begin
            # maxiters=1 forces an unsuccessful retcode
            bad = ODEProblem((u, p, t) -> -u, [1.0], (0.0, 1.0))
            Test.@test_throws Exceptions.SolverFailure CommonSolve.solve(
                bad, integ; options=Dict{Symbol,Any}(:alg => Tsit5(), :maxiters => 1)
            )
            # unsafe=true bypasses the check
            r = CommonSolve.solve(
                bad,
                integ;
                options=Dict{Symbol,Any}(:alg => Tsit5(), :maxiters => 1),
                unsafe=true,
            )
            Test.@test r isa Integrators.AbstractIntegrationResult
            Test.@test Integrators.successful(r) == false
            Test.@test Integrators.status(r) != :Success
        end
    end
end

end # module

test_integrator_solve() = TestIntegratorSolve.test_integrator_solve()
