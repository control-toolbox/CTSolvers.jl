module TestIntegratorMetadata

using Test: Test
import CTBase.Core
import CTBase.Exceptions
import CTSolvers.Integrators
import CTBase.Strategies
using OrdinaryDiffEqTsit5: OrdinaryDiffEqTsit5, Tsit5
using SciMLBase: SciMLBase
using DiffEqBase: DiffEqBase

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
            # Tsit5 is the default algorithm once OrdinaryDiffEqTsit5 is loaded
            Test.@test Integrators.__default_sciml_algorithm(Integrators.Tsit5Tag) isa Tsit5
        end

        # ====================================================================
        # Construction + accessors
        # ====================================================================

        Test.@testset "construction and accessors" begin
            integ = Integrators.SciML(; alg=Tsit5())
            Test.@test integ isa Integrators.SciML
            Test.@test Strategies.id(typeof(integ)) === :sciml

            # build_integrator convenience delegates to SciML
            integ2 = Integrators.build_integrator(; alg=Tsit5())
            Test.@test integ2 isa Integrators.SciML

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
