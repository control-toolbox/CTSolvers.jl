# Unit tests for the discretization API (discretize with custom and default discretizers).
struct DummyOCPDiscretize <: CTSolvers.AbstractOptimalControlProblem end

struct DummyDiscretizer <: CTSolvers.AbstractOptimalControlDiscretizer
    calls::Base.RefValue{Int}
    tag::Symbol
end

function (d::DummyDiscretizer)(ocp::CTSolvers.AbstractOptimalControlProblem)
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

    # ========================================================================
    # discretize(ocp; discretizer=__discretizer())
    # ========================================================================

    Test.@testset "ctdirect/discretization_api: default discretizer" verbose=VERBOSE showtiming=SHOWTIMING begin
        ocp = DummyOCPDiscretize()

        docp = CTSolvers.discretize(ocp)

        # The default discretizer should produce a DiscretizedOptimalControlProblem
        Test.@test docp isa CTSolvers.DiscretizedOptimalControlProblem
        Test.@test CTSolvers.ocp_model(docp) === ocp
    end
end
