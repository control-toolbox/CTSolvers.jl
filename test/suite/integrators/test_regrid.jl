module TestRegrid

using Test: Test
using CTBase: Exceptions
using CTSolvers: Integrators
using CommonSolve: CommonSolve
using OrdinaryDiffEqTsit5: OrdinaryDiffEqTsit5, Tsit5
using SciMLBase: SciMLBase, ODEProblem

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

# fake result without a regrid method (top level, per the test conventions)
struct FakeResult <: Integrators.AbstractIntegrationResult end
Integrators.times(::FakeResult) = [0.0, 1.0]

_integ(; kw...) = Integrators.SciML(; alg=Tsit5(), reltol=1e-12, abstol=1e-12, kw...)

# u' = -u on tspan from u(t0) = u0
_solve(tspan, u0; integ=_integ()) =
    CommonSolve.solve(ODEProblem((u, p, t) -> -u, [u0], tspan), integ)

"""
    test_regrid()

🧪 **Applying Testing Rule**: Integration Tests (standalone end-to-end)

`Integrators.regrid` replaces the output grid of a result without re-integrating (issue
CTFlows#435): the values on the new grid come from the (dense) interpolant, the original
result is unchanged, and invalid grids are rejected.
"""
function test_regrid()
    Test.@testset "Integrators.regrid" verbose=VERBOSE showtiming=SHOWTIMING begin
        grid = [0.0, 0.1, 0.35, 0.6, 1.0]

        Test.@testset "SciML result" begin
            r = _solve((0.0, 1.0), 1.0)
            T0 = copy(Integrators.times(r))
            g = Integrators.regrid(r, grid)
            Test.@test Integrators.times(g) == grid
            Test.@test eltype(Integrators.times(g)) == Float64
            for t in grid
                Test.@test Integrators.evaluate_at(g, t)[1] ≈ exp(-t) atol = 1e-10
            end
            Test.@test Integrators.evaluate_at(g, 0.77)[1] ≈ exp(-0.77) atol = 1e-10
            Test.@test Integrators.final_state(g) == Integrators.final_state(r)
            Test.@test Integrators.is_dense(g)
            Test.@test Integrators.times(r) == T0   # original unchanged
            # regridding a regridded result, integer and range grids
            Test.@test Integrators.times(Integrators.regrid(g, [0, 1])) == [0.0, 1.0]
            Test.@test Integrators.times(Integrators.regrid(r, range(0, 1, 5))) ==
                collect(range(0, 1, 5))
        end

        Test.@testset "SciML result, backward" begin
            r = _solve((1.0, 0.0), 1.0)
            g = Integrators.regrid(r, [1.0, 0.5, 0.0])
            Test.@test Integrators.times(g) == [1.0, 0.5, 0.0]
            Test.@test Integrators.evaluate_at(g, 0.5)[1] ≈ exp(0.5) atol = 1e-10
        end

        Test.@testset "piecewise result (left-continuous switch)" begin
            ts, Δ = 0.5, 10.0
            r = Integrators.merge([_solve((0.0, ts), 1.0), _solve((ts, 1.0), exp(-ts) + Δ)])
            g = Integrators.regrid(r, grid)
            Test.@test g isa Integrators.PiecewiseIntegrationResult
            Test.@test Integrators.times(g) == grid
            Test.@test Integrators.evaluate_at(g, 0.35)[1] ≈ exp(-0.35) atol = 1e-10
            Test.@test Integrators.evaluate_at(g, 0.6)[1] ≈ (exp(-ts) + Δ) * exp(-0.1) atol =
                1e-10
            gs = Integrators.regrid(r, [0.0, ts, 1.0])
            Test.@test Integrators.evaluate_at(gs, ts)[1] ≈ exp(-ts) atol = 1e-12   # left
            Test.@test count(==(ts), Integrators.times(r)) == 2                    # unchanged
        end

        Test.@testset "non-dense result" begin
            r = _solve((0.0, 1.0), 1.0; integ=_integ(; dense=false))
            g = Integrators.regrid(r, grid)
            Test.@test Integrators.times(g) == grid
            Test.@test !Integrators.is_dense(g)
        end

        Test.@testset "Error: invalid grids" begin
            r = _solve((0.0, 1.0), 1.0)
            for bad in ([0.5], Float64[], [0.0, 0.5, 0.5, 1.0], [0.0, 0.7, 0.5, 1.0],
                        [1.0, 0.5, 0.0], [-0.1, 0.5, 1.0], [0.0, 0.5, 1.1])
                Test.@test_throws Exceptions.IncorrectArgument Integrators.regrid(r, bad)
            end
            rb = _solve((1.0, 0.0), 1.0)
            Test.@test_throws Exceptions.IncorrectArgument Integrators.regrid(rb, [0.0, 1.0])
            pw = Integrators.merge([_solve((0.0, 0.5), 1.0), _solve((0.5, 1.0), 1.0)])
            Test.@test_throws Exceptions.IncorrectArgument Integrators.regrid(pw, [0.0, 1.5])
        end

        Test.@testset "Error: result without regrid" begin
            Test.@test_throws Exceptions.NotImplemented Integrators.regrid(FakeResult(), grid)
        end

        Test.@testset "type stability" begin
            r = _solve((0.0, 1.0), 1.0)
            Test.@test_nowarn Test.@inferred Integrators.regrid(r, grid)
            pw = Integrators.merge([_solve((0.0, 0.5), 1.0), _solve((0.5, 1.0), 1.0)])
            Test.@test_nowarn Test.@inferred Integrators.regrid(pw, grid)
        end
    end
end

end # module

test_regrid() = TestRegrid.test_regrid()
