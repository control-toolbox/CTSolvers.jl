module TestDescribeRegistry

using Test: Test
import ADNLPModels: ADNLPModels  # trigger CTSolversADNLPModels extension
import ExaModels: ExaModels  # trigger CTSolversExaModels extension
import CTBase.Exceptions
using CTSolvers: CTSolvers
import CTBase.Strategies
import CTBase.Options
import CTSolvers.Modelers

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
        # OUTPUT VERIFICATION - Print all strategies for visual check
        # ====================================================================

        Test.@testset "Print all strategies" begin
            for strat_id in (:adnlp, :exa, :ipopt, :madnlp, :madncl, :knitro)
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
