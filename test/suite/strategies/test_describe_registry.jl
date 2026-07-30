module TestDescribeRegistry

using Test: Test
import ADNLPModels: ADNLPModels  # trigger CTSolversADNLPModels extension
import ExaModels: ExaModels  # trigger CTSolversExaModels extension
import CTBase.Exceptions
using CTSolvers: CTSolvers
import CTBase.Strategies
import CTBase.Options
import CTSolvers.Modelers
import CTSolvers.Solvers
import CTSolvers.Integrators

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

# ============================================================================
# Helper: Build a real registry for testing
# ============================================================================

function get_strategy_registry()::Strategies.StrategyRegistry
    return Strategies.create_registry(
        CTSolvers.Modelers.AbstractNLPModeler => (
            (CTSolvers.Modelers.ADNLP, [Strategies.CPU]),
            (CTSolvers.Modelers.Exa, [Strategies.CPU, Strategies.GPU]),
        ),
        CTSolvers.Solvers.AbstractNLPSolver => (
            (CTSolvers.Solvers.Ipopt, [Strategies.CPU]),
            (CTSolvers.Solvers.MadNLP, [Strategies.CPU, Strategies.GPU]),
            (CTSolvers.Solvers.MadNCL, [Strategies.CPU, Strategies.GPU]),
            (CTSolvers.Solvers.Knitro, [Strategies.CPU]),
            (CTSolvers.Solvers.Uno, [Strategies.CPU]),
        ),
        CTSolvers.Integrators.AbstractIntegrator => (
            (CTSolvers.Integrators.SciML, [Strategies.CPU, Strategies.GPU]),
        ),
    )
end

# ============================================================================
# Test function
# ============================================================================

function test_describe_registry()
    Test.@testset "describe(id, registry)" verbose=VERBOSE showtiming=SHOWTIMING begin
        registry = get_strategy_registry()

        # ====================================================================
        # UNIT TESTS - Parameterized, single parameter (ADNLP - CPU only)
        # ====================================================================

        Test.@testset "ADNLP (CPU only, metadata available)" begin
            buf = IOBuffer()
            Strategies.describe(buf, :adnlp, registry)
            output = String(take!(buf))

            # Test individual components without relying on exact color formatting
            Test.@test occursin("ADNLP", output)
            Test.@test occursin("strategy", output)
            Test.@test occursin("id", output)
            Test.@test occursin("adnlp", output)
            Test.@test occursin("family", output)
            Test.@test occursin("AbstractNLPModeler", output)
            Test.@test occursin("parameters", output)
            Test.@test occursin("CPU", output)

            # Check options section exists
            Test.@test occursin("options", output)
        end

        # ====================================================================
        # UNIT TESTS - Parameterized, multi-parameter (Exa - CPU + GPU)
        # ====================================================================

        Test.@testset "Exa (CPU + GPU, common + computed options)" begin
            buf = IOBuffer()
            Strategies.describe(buf, :exa, registry)
            output = String(take!(buf))

            # Test individual components without relying on exact color formatting
            Test.@test occursin("Exa", output)
            Test.@test occursin("id", output)
            Test.@test occursin("exa", output)
            Test.@test occursin("family", output)
            Test.@test occursin("AbstractNLPModeler", output)
            Test.@test occursin("default", output)
            Test.@test occursin("parameter", output)
            Test.@test occursin("CPU", output)
            Test.@test occursin("parameters", output)
            Test.@test occursin("GPU", output)

            # Check common options section
            Test.@test occursin("common", output)
            Test.@test occursin("options", output)
            Test.@test occursin("base_type", output)

            # Check computed options sections
            Test.@test occursin("computed", output)
            Test.@test occursin("options", output)
            Test.@test occursin("CPU", output)
            Test.@test occursin("GPU", output)
            Test.@test occursin("backend", output)
        end

        # ====================================================================
        # UNIT TESTS - Extension-dependent strategies (Ipopt, MadNLP, etc.)
        # ====================================================================

        Test.@testset "Ipopt (extension not loaded)" begin
            buf = IOBuffer()
            Strategies.describe(buf, :ipopt, registry)
            output = String(take!(buf))

            # Test individual components without relying on exact color formatting
            Test.@test occursin("Ipopt", output)
            Test.@test occursin("id", output)
            Test.@test occursin("ipopt", output)
            Test.@test occursin("family", output)
            Test.@test occursin("AbstractNLPSolver", output)
            Test.@test occursin("parameters", output)
            Test.@test occursin("CPU", output)

            # Check graceful ExtensionError handling
            Test.@test occursin("requires", output) || occursin("options", output)
        end

        Test.@testset "MadNLP (extension not loaded, multi-param)" begin
            buf = IOBuffer()
            Strategies.describe(buf, :madnlp, registry)
            output = String(take!(buf))

            # Test individual components without relying on exact color formatting
            Test.@test occursin("MadNLP", output)
            Test.@test occursin("id", output)
            Test.@test occursin("madnlp", output)
            Test.@test occursin("family", output)
            Test.@test occursin("AbstractNLPSolver", output)
            Test.@test occursin("parameters", output)
            Test.@test occursin("CPU", output)
            Test.@test occursin("GPU", output)

            # Check graceful fallback for metadata
            Test.@test occursin("requires", output) || occursin("options", output)
        end

        Test.@testset "MadNCL (extension not loaded, multi-param)" begin
            buf = IOBuffer()
            Strategies.describe(buf, :madncl, registry)
            output = String(take!(buf))

            # Test individual components without relying on exact color formatting
            Test.@test occursin("MadNCL", output)
            Test.@test occursin("id", output)
            Test.@test occursin("madncl", output)
            Test.@test occursin("parameters", output)
            Test.@test occursin("CPU", output)
            Test.@test occursin("GPU", output)
        end

        Test.@testset "Knitro (extension not loaded)" begin
            buf = IOBuffer()
            Strategies.describe(buf, :knitro, registry)
            output = String(take!(buf))

            # Test individual components without relying on exact color formatting
            Test.@test occursin("Knitro", output)
            Test.@test occursin("id", output)
            Test.@test occursin("knitro", output)
            Test.@test occursin("parameters", output)
            Test.@test occursin("CPU", output)
        end

        Test.@testset "Uno (extension not loaded)" begin
            buf = IOBuffer()
            Strategies.describe(buf, :uno, registry)
            output = String(take!(buf))

            # Test individual components without relying on exact color formatting
            Test.@test occursin("Uno", output)
            Test.@test occursin("id", output)
            Test.@test occursin("uno", output)
            Test.@test occursin("family", output)
            Test.@test occursin("AbstractNLPSolver", output)
            Test.@test occursin("parameters", output)
            Test.@test occursin("CPU", output)

            # Check graceful ExtensionError handling
            Test.@test occursin("requires", output) || occursin("options", output)
        end

        # ====================================================================
        # UNIT TESTS - Integrators family
        # ====================================================================

        Test.@testset "SciML (extension not loaded, 4 type params — CTBase#516 regression)" begin
            # SciML has four type parameters (P, O, OP, OT), the only strategy in the
            # ecosystem with 3+. Before CTBase#516 (fixed in CTBase 0.28.8-beta),
            # `_strategy_base_name`/`_strategy_type_name` only peeled one `UnionAll`
            # layer and threw `FieldError` here. This is the regression coverage.
            buf = IOBuffer()
            Strategies.describe(buf, :sciml, registry)
            output = String(take!(buf))

            Test.@test occursin("SciML", output)
            Test.@test occursin("id", output)
            Test.@test occursin("sciml", output)
            Test.@test occursin("family", output)
            Test.@test occursin("AbstractIntegrator", output)
            Test.@test occursin("parameters", output)
            Test.@test occursin("CPU", output)
            Test.@test occursin("GPU", output)

            # Check graceful ExtensionError handling
            Test.@test occursin("requires", output) || occursin("options", output)
        end

        # ====================================================================
        # ERROR TESTS - Unknown ID
        # ====================================================================

        Test.@testset "Unknown strategy ID" begin
            buf = IOBuffer()
            Test.@test_throws Exceptions.IncorrectArgument Strategies.describe(
                buf, :nonexistent, registry
            )
        end

        # ====================================================================
        # UNIT TESTS - Parameter path on the full registry (incl. SciML)
        # ====================================================================

        # `describe(:cpu/:gpu, registry)` walks every registered strategy to list which
        # ones support the parameter (`_find_strategies_using_parameter`), so a single
        # undescribable strategy took the parameter introspection down with it too —
        # this is the CTBase#516 regression coverage for that path.
        Test.@testset "describe(:cpu, registry) - full registry incl. SciML" begin
            buf = IOBuffer()
            Strategies.describe(buf, :cpu, registry)
            output = String(take!(buf))

            Test.@test occursin("CPU", output)
            Test.@test occursin("parameter", output)
            Test.@test occursin("used", output)
            Test.@test occursin("strategies", output)
            Test.@test occursin(":sciml", output)
            Test.@test occursin("SciML", output)
        end

        Test.@testset "describe(:gpu, registry) - full registry incl. SciML" begin
            buf = IOBuffer()
            Strategies.describe(buf, :gpu, registry)
            output = String(take!(buf))

            Test.@test occursin("GPU", output)
            Test.@test occursin("parameter", output)
            Test.@test occursin("used", output)
            Test.@test occursin("strategies", output)
            Test.@test occursin(":sciml", output)
            Test.@test occursin("SciML", output)
        end

        # ====================================================================
        # OUTPUT VERIFICATION - Print all strategies for visual check
        # ====================================================================

        Test.@testset "Print all strategies" begin
            # Table-driven over strategy_ids across all three families so a newly
            # registered strategy is covered by construction. `strategy_ids` returns a
            # `Tuple{Symbol,...}`, so splat (not vcat, which would nest the tuples) to
            # get a flat collection of ids.
            ids = (
                Strategies.strategy_ids(CTSolvers.Modelers.AbstractNLPModeler, registry)...,
                Strategies.strategy_ids(CTSolvers.Solvers.AbstractNLPSolver, registry)...,
                Strategies.strategy_ids(CTSolvers.Integrators.AbstractIntegrator, registry)...,
            )
            for strat_id in ids
                buf = IOBuffer()
                Test.@test_nowarn Strategies.describe(buf, strat_id, registry)
                output = String(take!(buf))
                Test.@test !isempty(output)
                Test.@test occursin(string(strat_id), output)
            end
        end

        # ====================================================================
        # STDOUT convenience method
        # ====================================================================

        Test.@testset "describe(id, registry) to stdout" begin
            redirect_stdout(devnull) do
                Test.@test_nowarn Strategies.describe(:adnlp, registry)
                Test.@test_nowarn Strategies.describe(:exa, registry)
            end
        end
    end
end

end # module

# CRITICAL: Redefine in outer scope for TestRunner
test_describe_registry() = TestDescribeRegistry.test_describe_registry()
