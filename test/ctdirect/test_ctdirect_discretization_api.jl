# Unit tests for the discretization API (discretize with custom and default discretizers).
struct DummyOCPDiscretize <: CTSolvers.AbstractOptimalControlProblem end

struct DummyDiscretizer <: CTSolvers.AbstractOptimalControlDiscretizer
    calls::Base.RefValue{Int}
    tag::Symbol
end

function (d::DummyDiscretizer)(
    ocp::CTSolvers.AbstractOptimalControlProblem,
)
    d.calls[] += 1
    return (ocp, d.tag)
end

function test_ctdirect_discretization_api()

    # ========================================================================
    # discretize(ocp, discretizer)
    # ========================================================================

    Test.@testset "ctdirect/discretization_api: discretize(ocp, discretizer)" verbose=VERBOSE showtiming=SHOWTIMING begin
        ocp = DummyOCPDiscretize()
        calls = Ref(0)
        discretizer = DummyDiscretizer(calls, :dummy)

        result = CTSolvers.discretize(ocp, discretizer)

        Test.@test result == (ocp, :dummy)
        Test.@test calls[] == 1
    end

end

