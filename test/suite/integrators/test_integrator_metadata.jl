module TestIntegratorMetadata

using Test: Test
using CTBase: Core
using CTBase: Exceptions
using CTBase: Options
using CTSolvers: Integrators
using CTBase: Strategies
using OrdinaryDiffEqTsit5: OrdinaryDiffEqTsit5, Tsit5
using SciMLBase: SciMLBase
using DiffEqBase: DiffEqBase
using CTSolvers: CTSolvers

const CTSolversSciMLIntegrator = Base.get_extension(CTSolvers, :CTSolversSciMLIntegrator)

struct FakeDEAlgorithm <: SciMLBase.AbstractDEAlgorithm end

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

"""
    test_integrator_metadata()

🧪 **Applying Testing Rule**: Contract Tests (extension loaded)

Tests `Strategies.metadata`, construction, and the cached option-dict accessors with the
SciML extension active.
"""
function test_integrator_metadata()
    Test.@testset "Integrator Metadata" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ====================================================================
        # Metadata is available once the extension is loaded
        # ====================================================================

        Test.@testset "metadata" begin
            md = Strategies.metadata(Integrators.SciML)
            Test.@test md isa Strategies.StrategyMetadata
            alg_without_default = CTSolversSciMLIntegrator._sciml_alg_option(missing)
            Test.@test Options.type(alg_without_default) ==
                Union{Missing, SciMLBase.AbstractDEAlgorithm}
            Test.@test Options.default(alg_without_default) === missing
            Test.@test Options.type(md[:alg]) ==
                Union{Missing, SciMLBase.AbstractDEAlgorithm}
            # Tsit5 is the default algorithm once OrdinaryDiffEqTsit5 is loaded
            Test.@test Integrators.__default_sciml_algorithm(Integrators.Tsit5Tag) isa Tsit5
        end

        Test.@testset "missing algorithm diagnostic" begin
            err = CTSolversSciMLIntegrator._missing_sciml_algorithm_error()
            Test.@test err isa Exceptions.PreconditionError
            err_str = string(err)
            Test.@test occursin("SciML(alg=Vern6())", err_str)
            Test.@test occursin("Flow(ocp, law; alg=Vern6())", err_str)
            Test.@test occursin("OrdinaryDiffEqVerner", err_str)
        end

        # ====================================================================
        # Construction + accessors
        # ====================================================================

        Test.@testset "construction and accessors" begin
            integ = Integrators.SciML(; alg=Tsit5())
            Test.@test integ isa Integrators.SciML
            Test.@test Strategies.id(typeof(integ)) === :sciml

            # Accessors return the cached point/trajectory option dicts
            op = Integrators.options_point(integ)
            ot = Integrators.options_trajectory(integ)
            Test.@test op isa Dict{Symbol,Any}
            Test.@test ot isa Dict{Symbol,Any}

            # :auto sentinel resolution: point=false, trajectory=true
            for k in (:dense, :save_everystep, :save_start)
                Test.@test op[k] === false
                Test.@test ot[k] === true
            end

            fake_integ = Integrators.SciML(; alg=FakeDEAlgorithm())
            Test.@test Integrators.options_point(fake_integ)[:alg] isa FakeDEAlgorithm
            Test.@test Integrators.options_trajectory(fake_integ)[:alg] isa FakeDEAlgorithm
        end

        # ====================================================================
        # Option validation
        # ====================================================================

        Test.@testset "option validation" begin
            # strict mode (default): invalid value rejected at construction
            Test.@test_throws Exceptions.IncorrectArgument Integrators.SciML(;
                alg=Tsit5(), reltol=-1.0
            )

            # strict mode: unknown option also rejected
            Test.@test_throws Exceptions.IncorrectArgument Integrators.SciML(;
                alg=Tsit5(), unknown_option=42
            )

            # permissive mode: unknown options accepted (with warning), value validation still applies
            Test.@test_logs (:warn, r"") match_mode=:any Integrators.SciML(;
                alg=Tsit5(), unknown_option=42, mode=:permissive
            )
        end
    end
end

end # module

test_integrator_metadata() = TestIntegratorMetadata.test_integrator_metadata()
