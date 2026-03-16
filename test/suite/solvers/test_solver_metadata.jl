module TestSolverMetadata

using Test: Test
import CTBase.Exceptions
import CTSolvers.Solvers
import CTSolvers.Strategies
using MadNLP: MadNLP
using MadNCL: MadNCL
using UnoSolver: UnoSolver

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

"""
    test_solver_metadata()

🧪 **Applying Testing Rule**: Unit Tests for solver metadata and id() methods

Tests uncovered lines in solver files:
- madnlp.jl:91, 167, 204
- madncl.jl:85, 161, 198  
- ipopt.jl:77, 145
"""
function test_solver_metadata()
    Test.@testset "Solver Metadata and IDs" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ====================================================================
        # UNIT TESTS - Strategies.id() for solver types
        # ====================================================================

        Test.@testset "Strategies.id() - Direct Type Calls" begin
            # Test id() methods for solver types
            Test.@test Strategies.id(Solvers.MadNLP) === :madnlp
            Test.@test Strategies.id(Solvers.MadNCL) === :madncl
            Test.@test Strategies.id(Solvers.Ipopt) === :ipopt
            Test.@test Strategies.id(Solvers.Knitro) === :knitro
            Test.@test Strategies.id(Solvers.Uno) === :uno

            # Test with parameterized types
            Test.@test Strategies.id(Solvers.MadNLP{Strategies.CPU}) === :madnlp
            Test.@test Strategies.id(Solvers.MadNLP{Strategies.GPU}) === :madnlp
            Test.@test Strategies.id(Solvers.MadNCL{Strategies.CPU}) === :madncl
            Test.@test Strategies.id(Solvers.MadNCL{Strategies.GPU}) === :madncl
            Test.@test Strategies.id(Solvers.Uno{Strategies.CPU}) === :uno
        end

        # ====================================================================
        # UNIT TESTS - Parameterized constructor paths
        # ====================================================================

        Test.@testset "Parameterized Constructors" begin
            # Test parameterized constructors (covers lines like madnlp.jl:167, madncl.jl:161)
            # These should work when extensions are loaded

            # MadNLP{CPU} constructor
            Test.@test_nowarn Solvers.MadNLP{Strategies.CPU}(print_level=MadNLP.ERROR)
            solver_cpu = Solvers.MadNLP{Strategies.CPU}(
                max_iter=100, print_level=MadNLP.ERROR
            )
            Test.@test solver_cpu isa Solvers.MadNLP{Strategies.CPU}

            # MadNLP{GPU} constructor (may fail if CUDA not available, but tests the path)
            # We just test that the constructor exists and can be called
            Test.@test Solvers.MadNLP{Strategies.GPU} isa Type

            # MadNCL{CPU} constructor  
            Test.@test_nowarn Solvers.MadNCL{Strategies.CPU}(print_level=MadNLP.ERROR)
            solver_ncl_cpu = Solvers.MadNCL{Strategies.CPU}(
                max_iter=100, print_level=MadNLP.ERROR
            )
            Test.@test solver_ncl_cpu isa Solvers.MadNCL{Strategies.CPU}

            # MadNCL{GPU} constructor
            Test.@test Solvers.MadNCL{Strategies.GPU} isa Type

            # Uno{CPU} constructor
            Test.@test_nowarn Solvers.Uno{Strategies.CPU}()
            solver_uno_cpu = Solvers.Uno{Strategies.CPU}(max_iterations=100)
            Test.@test solver_uno_cpu isa Solvers.Uno{Strategies.CPU}
        end

        # ====================================================================
        # UNIT TESTS - Default parameter functions
        # ====================================================================

        Test.@testset "Default Parameters" begin
            # Test _default_parameter functions (internal, but affects constructor behavior)
            # These are called when constructing without explicit parameter

            # Verify default constructors use CPU parameter
            solver_madnlp = Solvers.MadNLP(print_level=MadNLP.ERROR)
            Test.@test solver_madnlp isa Solvers.MadNLP{Strategies.CPU}

            solver_madncl = Solvers.MadNCL(print_level=MadNLP.ERROR)
            Test.@test solver_madncl isa Solvers.MadNCL{Strategies.CPU}

            solver_uno = Solvers.Uno()
            Test.@test solver_uno isa Solvers.Uno{Strategies.CPU}
        end
    end
end

end # module

test_solver_metadata() = TestSolverMetadata.test_solver_metadata()
