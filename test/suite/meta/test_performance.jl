module TestPerformance

# ==============================================================================
# Performance contract — deterministic allocation guards
# ==============================================================================
#
# This file asserts the *allocation* invariants of CTSolvers' hot path: the
# code called repeatedly while reading back an integration result (trajectory
# evaluation, cached option-dict reads, result accessors). See
# docs/src/guides/performance.md and the Handbook's philosophy/performance.md
# ("hot path vs. setup path") for what is deliberately NOT guarded here —
# strategy construction, `route_to`/`RoutedOption`, option validation/
# extraction, and NLP model/solution building are setup-path, called once per
# problem, and dynamic dispatch there is by design.
#
# Why allocations, and why here:
#   - Type-stability is already guarded by `Test.@inferred`
#     (test/suite/integrators/test_integrator_type_stability.jl) and by the
#     whole-package `JET.test_package` gate (test_jet.jl). This file guards
#     the complementary property: a change can keep a call type-stable yet
#     start allocating (a stray `collect`, a boxed closure, an abstract field
#     access). Neither `@inferred` nor JET would catch that.
#   - Allocation counts are DETERMINISTIC — no run-to-run noise, independent
#     of the machine / CI runner. So `== 0` (or wrapper-vs-raw equality) is a
#     robust assertion, unlike wall-clock time, which must never be asserted
#     in the suite.
#
# Two invariant classes:
#   1. Zero-overhead wrappers — `evaluate_at` must allocate exactly what
#      calling the wrapped `SciMLBase.AbstractODESolution` directly costs
#      (measured at 960 B here; asserted as an equality, not a magic
#      constant, so the guard is independent of Julia version / word size).
#   2. Zero-allocation reads — cached option-dict accessors and result
#      accessors must allocate nothing at all.
# ==============================================================================

using Test: Test
using BenchmarkTools: BenchmarkTools
using CTSolvers: Integrators
using OrdinaryDiffEqTsit5: Tsit5
using SciMLBase: ODEProblem
using CommonSolve: CommonSolve

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

function test_performance()
    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "Performance contract" begin
        integ = Integrators.SciML(alg=Tsit5())
        prob = ODEProblem((u, p, t) -> -u, [1.0], (0.0, 1.0))
        r = CommonSolve.solve(prob, integ)
        t = 0.5

        # ======================================================================
        # 1. Zero-overhead wrappers: wrapper allocations == raw allocations
        # ======================================================================
        Test.@testset "Zero-overhead wrappers" begin
            Test.@test (BenchmarkTools.@ballocated Integrators.evaluate_at($r, $t)) ==
                (BenchmarkTools.@ballocated $(r.ode_sol)($t))
        end

        # ======================================================================
        # 2. Zero-allocation reads: cached option dicts and result accessors
        # ======================================================================
        Test.@testset "Zero-allocation reads" begin
            Test.@test (BenchmarkTools.@ballocated Integrators.options_point($integ)) == 0
            Test.@test (BenchmarkTools.@ballocated Integrators.options_trajectory($integ)) ==
                0
            Test.@test (BenchmarkTools.@ballocated Integrators.final_state($r)) == 0
            Test.@test (BenchmarkTools.@ballocated Integrators.times($r)) == 0
            Test.@test (BenchmarkTools.@ballocated Integrators.status($r)) == 0
            Test.@test (BenchmarkTools.@ballocated Integrators.successful($r)) == 0
        end
    end
    return nothing
end

end # module TestPerformance

# CRITICAL: redefine in outer scope so the test runner can call it
test_performance() = TestPerformance.test_performance()
