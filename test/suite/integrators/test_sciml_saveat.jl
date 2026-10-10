module TestSciMLSaveat

using Test: Test
using CTSolvers: Integrators
using CommonSolve: CommonSolve
using OrdinaryDiffEqTsit5: OrdinaryDiffEqTsit5, Tsit5
using SciMLBase: SciMLBase, ODEProblem

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

# Harmonic oscillator x'' = -x, x(0) = (1, 0) ⇒ x(t) = (cos t, -sin t). The right-hand side
# counts its calls, to compare integration costs.
const NCALLS = Ref(0)
_rhs(u, p, t) = (NCALLS[] += 1; [u[2], -u[1]])
_exact(t) = [cos(t), -sin(t)]
_prob(tspan=(0.0, 1.0); kw...) = ODEProblem(_rhs, [1.0, 0.0], tspan; kw...)
_tol() = (; alg=Tsit5(), reltol=1e-10, abstol=1e-10)

# maximal error of the result against the exact solution on a fine grid of [0, 1]
function _offgrid_error(r)
    return maximum(
        maximum(abs.(Integrators.evaluate_at(r, t) .- _exact(t))) for t in 0:0.001:1
    )
end

# solve with the integrator's trajectory options, counting right-hand side calls
function _counted_solve(prob, integ; kw...)
    NCALLS[] = 0
    r = CommonSolve.solve(prob, integ; kw...)
    return r, NCALLS[]
end

# SciML's native saving with the same options (the reference grid and values)
function _native(prob, integ)
    opts = Dict{Symbol,Any}(pairs(Integrators.options_trajectory(integ)))
    opts[:dense] = false
    return SciMLBase.solve(prob; opts...)
end

"""
    test_sciml_saveat()

🧪 **Applying Testing Rule**: Integration Tests (standalone end-to-end)

`saveat` is an output grid only (issue CTFlows#434): with dense output wanted, the
integration ignores it and keeps the dense interpolant; the result's time grid and values
match SciML's native `saveat` saving, at the same integration cost.
"""
function test_sciml_saveat()
    Test.@testset "SciML saveat as output grid" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ====================================================================
        # Option resolution
        # ====================================================================

        Test.@testset "option resolution" begin
            integ = Integrators.SciML(; _tol()..., saveat=0.1)
            Test.@test !haskey(Integrators.options_point(integ), :saveat)
            Test.@test Integrators.options_point(integ)[:dense] === false
            traj = Integrators.options_trajectory(integ)
            Test.@test traj[:saveat] == 0.1
            Test.@test traj[:dense] === true
            Test.@test traj[:save_everystep] === false
            Test.@test traj[:save_start] === true

            plain = Integrators.SciML(; _tol()...)
            Test.@test Integrators.options_trajectory(plain)[:save_everystep] === true

            explicit = Integrators.SciML(; _tol()..., saveat=0.1, save_everystep=true)
            Test.@test Integrators.options_trajectory(explicit)[:save_everystep] === true
        end

        # ====================================================================
        # Grid and values match SciML's native saving
        # ====================================================================

        Test.@testset "grid and values [$label]" for (label, tspan, kw) in (
            ("vector", (0.0, 1.0), (; saveat=collect(0:0.1:1))),
            ("range", (0.0, 1.0), (; saveat=range(0, 1, 11))),
            ("interior times", (0.0, 1.0), (; saveat=[0.25, 0.5, 0.75])),
            ("scalar step", (0.0, 1.0), (; saveat=0.1)),
            ("scalar step, not a divisor", (0.0, 1.0), (; saveat=0.3)),
            ("times outside the span", (0.0, 1.0), (; saveat=[-1.0, 0.5, 2.0])),
            ("backward, vector", (1.0, 0.0), (; saveat=[0.2, 0.5, 0.8])),
            ("backward, scalar step", (1.0, 0.0), (; saveat=0.25)),
            ("save_start=false", (0.0, 1.0), (; saveat=0.25, save_start=false)),
            ("save_end=false", (0.0, 1.0), (; saveat=[0.5, 1.0], save_end=false)),
            (
                "save_everystep=true",
                (0.0, 1.0),
                (; saveat=[0.33, 0.66], save_everystep=true),
            ),
        )
            prob = _prob(tspan)
            integ = Integrators.SciML(; _tol()..., kw...)
            r, ncalls = _counted_solve(prob, integ)
            NCALLS[] = 0
            native = _native(prob, integ)
            ncalls_native = NCALLS[]

            Test.@test Integrators.is_dense(r)
            Test.@test Integrators.times(r) == native.t
            for (t, u) in zip(native.t, native.u)
                Test.@test Integrators.evaluate_at(r, t) ≈ u atol = 1e-14
            end
            Test.@test ncalls == ncalls_native   # no extra integration cost
        end

        # ====================================================================
        # Precision between the grid points
        # ====================================================================

        Test.@testset "dense precision between grid points" begin
            prob = _prob()
            r = CommonSolve.solve(prob, Integrators.SciML(; _tol()..., saveat=0.1))
            Test.@test _offgrid_error(r) < 1e-9
            Test.@test Integrators.final_state(r) ≈ _exact(1.0) atol = 1e-9

            # same integration, same accuracy as without saveat
            plain = CommonSolve.solve(prob, Integrators.SciML(; _tol()...))
            Test.@test Integrators.evaluate_at(r, 0.33) ≈
                Integrators.evaluate_at(plain, 0.33) atol = 1e-14
        end

        # ====================================================================
        # Explicit dense=true with saveat (formerly a segfault in SciML)
        # ====================================================================

        Test.@testset "explicit dense=true with saveat" begin
            integ = Integrators.SciML(; _tol()..., saveat=0.1, dense=true)
            r = CommonSolve.solve(_prob(), integ)
            Test.@test Integrators.is_dense(r)
            Test.@test length(Integrators.times(r)) == 11
            Test.@test _offgrid_error(r) < 1e-9
        end

        # ====================================================================
        # dense=false: SciML's native saving, linear between grid points
        # ====================================================================

        Test.@testset "dense=false keeps native saving" begin
            integ = Integrators.SciML(; _tol()..., saveat=0.1, dense=false)
            r = CommonSolve.solve(_prob(), integ)
            Test.@test !Integrators.is_dense(r)
            Test.@test Integrators.times(r) ≈ collect(0:0.1:1)
            Test.@test Integrators.evaluate_at(r, 0.5) ≈ _exact(0.5) atol = 1e-9
            Test.@test _offgrid_error(r) > 1e-4   # linear interpolation between points
        end

        # ====================================================================
        # saveat stored in the problem's keyword arguments
        # ====================================================================

        Test.@testset "saveat in the problem" begin
            prob = _prob(; saveat=0.1)
            r = CommonSolve.solve(prob, Integrators.SciML(; _tol()...))
            Test.@test Integrators.is_dense(r)
            Test.@test Integrators.times(r) ≈ collect(0:0.1:1)
            Test.@test _offgrid_error(r) < 1e-9
        end

        # ====================================================================
        # Point options ignore saveat
        # ====================================================================

        Test.@testset "point integration ignores saveat" begin
            integ = Integrators.SciML(; _tol()..., saveat=0.1)
            r = CommonSolve.solve(_prob(), integ; options=Integrators.options_point(integ))
            Test.@test Integrators.final_state(r) ≈ _exact(1.0) atol = 1e-9
            Test.@test length(Integrators.times(r)) == 1
        end

        # ====================================================================
        # Type stability of the accessors
        # ====================================================================

        Test.@testset "type stability" begin
            r = CommonSolve.solve(_prob(), Integrators.SciML(; _tol()..., saveat=0.1))
            Test.@test_nowarn Test.@inferred Integrators.times(r)
            Test.@test_nowarn Test.@inferred Integrators.evaluate_at(r, 0.5)
            Test.@test_nowarn Test.@inferred Integrators.is_dense(r)
        end
    end
end

end # module

test_sciml_saveat() = TestSciMLSaveat.test_sciml_saveat()
