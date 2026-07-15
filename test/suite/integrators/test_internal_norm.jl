module TestInternalNorm

using Test: Test
import CTSolvers.Integrators
using ForwardDiff: ForwardDiff
using DiffEqBase: DiffEqBase   # activates the array real_norm overload

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

"""
    test_internal_norm()

🧪 **Applying Testing Rule**: Unit Tests

Tests the `deepvalue` / `real_norm` grid-invariance helpers: scalar fallbacks (core),
the array overload (`CTSolversSciMLIntegrator`), and the ForwardDiff dual overloads
(`CTSolversForwardDiff`).
"""
function test_internal_norm()
    Test.@testset "Internal Norm (grid invariance)" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ====================================================================
        # Scalar fallbacks (core)
        # ====================================================================

        Test.@testset "scalar fallbacks" begin
            Test.@test Integrators.deepvalue(3.14) == 3.14
            Test.@test Integrators.deepvalue(1.0 + 2.0im) == 1.0 + 2.0im
            Test.@test Integrators.real_norm(3.0, 0.0) == 3.0
            Test.@test Integrators.real_norm(3.0 + 4.0im, 0.0) == 5.0
        end

        # ====================================================================
        # ForwardDiff dual overloads (CTSolversForwardDiff)
        # ====================================================================

        Test.@testset "ForwardDiff duals" begin
            d1 = ForwardDiff.Dual{:Tag}(3.0, 1.0)
            Test.@test Integrators.deepvalue(d1) == 3.0
            d2 = ForwardDiff.Dual{:Tag2}(d1, d1)   # nested dual
            Test.@test Integrators.deepvalue(d2) == 3.0
            Test.@test Integrators.real_norm(d1, 0.0) == 3.0
        end

        # ====================================================================
        # Array overload (CTSolversSciMLIntegrator) — grid invariance
        # ====================================================================

        Test.@testset "array grid invariance" begin
            u_real = [1.0, 2.0, 3.0]
            u_dual = ForwardDiff.Dual{:T}.(u_real, ones(3))
            Test.@test Integrators.real_norm(u_real, 0.0) ≈
                Integrators.real_norm(u_dual, 0.0)
        end
    end
end

end # module

test_internal_norm() = TestInternalNorm.test_internal_norm()
