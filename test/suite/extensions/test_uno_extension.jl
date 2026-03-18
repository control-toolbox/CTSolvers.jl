module TestUnoExtension

using Test: Test
import CTBase.Exceptions
using CTSolvers: CTSolvers
import CTSolvers.Solvers
import CTSolvers.Strategies
import CTSolvers.Options
import CTSolvers.Modelers
import CTSolvers.Optimization
using CommonSolve: CommonSolve
using NLPModels: NLPModels
using ADNLPModels: ADNLPModels

include(joinpath(@__DIR__, "..", "..", "problems", "TestProblems.jl"))
import .TestProblems

# Get extension to access solve_with_uno
using UnoSolver
const CTSolversUno = Base.get_extension(CTSolvers, :CTSolversUno)

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

"""
    test_uno_extension()

Tests for Solvers.Uno extension.

🧪 **Applying Testing Rule**: Unit Tests + Integration Tests

Tests the complete Solvers.Uno functionality including metadata, constructor,
options handling, display flag, and problem solving with ADNLP modeler only.
"""
function test_uno_extension()
    Test.@testset "Uno Extension" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ====================================================================
        # UNIT TESTS - Metadata and Options
        # ====================================================================

        Test.@testset "Metadata" begin
            meta = Strategies.metadata(Solvers.Uno)

            Test.@test meta isa Strategies.StrategyMetadata
            Test.@test length(meta) > 0

            # Test that key options are defined
            Test.@test :preset in keys(meta)
            Test.@test :max_iterations in keys(meta)
            Test.@test :primal_tolerance in keys(meta)
            Test.@test :dual_tolerance in keys(meta)
            Test.@test :logger in keys(meta)
            Test.@test :print_solution in keys(meta)

            # Test option types
            Test.@test Options.type(meta[:preset]) == String
            Test.@test Options.type(meta[:max_iterations]) == Integer
            Test.@test Options.type(meta[:primal_tolerance]) == Real
            Test.@test Options.type(meta[:dual_tolerance]) == Real
            Test.@test Options.type(meta[:logger]) == String

            # Test default values exist
            Test.@test Options.default(meta[:preset]) == "ipopt"
            Test.@test Options.default(meta[:max_iterations]) == 1000
            Test.@test Options.default(meta[:primal_tolerance]) == 1e-8
            Test.@test Options.default(meta[:dual_tolerance]) == 1e-8
            Test.@test Options.default(meta[:logger]) == "INFO"
        end

        # ====================================================================
        # UNIT TESTS - Status Conversion
        # ====================================================================

        Test.@testset "Status Conversion" begin
            # Test UNO_SUCCESS cases
            Test.@test CTSolversUno._uno_status_to_solvercore(
                UnoSolver.UNO_SUCCESS, UnoSolver.UNO_FEASIBLE_KKT_POINT
            ) == :first_order

            Test.@test CTSolversUno._uno_status_to_solvercore(
                UnoSolver.UNO_SUCCESS, UnoSolver.UNO_FEASIBLE_FJ_POINT
            ) == :acceptable

            Test.@test CTSolversUno._uno_status_to_solvercore(
                UnoSolver.UNO_SUCCESS, UnoSolver.UNO_INFEASIBLE_STATIONARY_POINT
            ) == :infeasible

            Test.@test CTSolversUno._uno_status_to_solvercore(
                UnoSolver.UNO_SUCCESS, UnoSolver.UNO_FEASIBLE_SMALL_STEP
            ) == :small_step

            Test.@test CTSolversUno._uno_status_to_solvercore(
                UnoSolver.UNO_SUCCESS, UnoSolver.UNO_INFEASIBLE_SMALL_STEP
            ) == :small_step

            Test.@test CTSolversUno._uno_status_to_solvercore(
                UnoSolver.UNO_SUCCESS, UnoSolver.UNO_UNBOUNDED
            ) == :unbounded

            # Test termination status cases
            Test.@test CTSolversUno._uno_status_to_solvercore(
                UnoSolver.UNO_ITERATION_LIMIT, UnoSolver.UNO_FEASIBLE_KKT_POINT
            ) == :max_iter

            Test.@test CTSolversUno._uno_status_to_solvercore(
                UnoSolver.UNO_TIME_LIMIT, UnoSolver.UNO_FEASIBLE_KKT_POINT
            ) == :max_time

            Test.@test CTSolversUno._uno_status_to_solvercore(
                UnoSolver.UNO_EVALUATION_ERROR, UnoSolver.UNO_FEASIBLE_KKT_POINT
            ) == :exception

            Test.@test CTSolversUno._uno_status_to_solvercore(
                UnoSolver.UNO_ALGORITHMIC_ERROR, UnoSolver.UNO_FEASIBLE_KKT_POINT
            ) == :exception
        end

        # ====================================================================
        # UNIT TESTS - Constructor
        # ====================================================================

        Test.@testset "Constructor" begin
            # Default constructor
            solver = Solvers.Uno()
            Test.@test solver isa Solvers.Uno
            Test.@test solver isa Solvers.AbstractNLPSolver

            # Constructor with options
            solver_custom = Solvers.Uno(max_iterations=100, primal_tolerance=1e-6)
            Test.@test solver_custom isa Solvers.Uno

            # Test Strategies.options() returns StrategyOptions
            opts = Strategies.options(solver)
            Test.@test opts isa Strategies.StrategyOptions

            opts_custom = Strategies.options(solver_custom)
            Test.@test opts_custom isa Strategies.StrategyOptions
        end

        # ====================================================================
        # UNIT TESTS - Options Extraction
        # ====================================================================

        Test.@testset "Options Extraction" begin
            solver = Solvers.Uno(max_iterations=500, primal_tolerance=1e-8, logger="INFO")
            opts = Strategies.options(solver)

            # Extract raw options (returns NamedTuple)
            raw_opts = Options.extract_raw_options(Strategies._raw_options(opts))
            Test.@test raw_opts isa NamedTuple
            Test.@test haskey(raw_opts, :max_iterations)
            Test.@test haskey(raw_opts, :primal_tolerance)
            Test.@test haskey(raw_opts, :logger)

            # Verify values
            Test.@test raw_opts[:max_iterations] == 500
            Test.@test raw_opts[:primal_tolerance] == 1e-8
            Test.@test raw_opts[:logger] == "INFO"
        end

        # ====================================================================
        # UNIT TESTS - Display Flag Handling
        # ====================================================================

        Test.@testset "Display Flag" begin
            # Create a simple problem
            nlp = ADNLPModels.ADNLPModel(x -> sum(x .^ 2), [1.0, 2.0])

            # Test with display=false sets logger=SILENT
            solver_verbose = Solvers.Uno(max_iterations=10, logger="INFO")

            # Note: We can't easily test the internal behavior without actually solving,
            # but we can verify the solver accepts the display parameter
            Test.@test_nowarn solver_verbose(nlp; display=false)
            Test.@test_nowarn solver_verbose(nlp; display=true)
        end

        # ====================================================================
        # INTEGRATION TESTS - Solving Problems with ADNLPModels
        # ====================================================================

        Test.@testset "Rosenbrock Problem - ADNLPModels" begin
            ros = TestProblems.Rosenbrock()

            # Build NLP model from problem
            adnlp_builder = CTSolvers.get_adnlp_model_builder(ros.prob)
            nlp = adnlp_builder(ros.init)

            # Create solver with appropriate options
            solver = Solvers.Uno(
                max_iterations=1000,
                primal_tolerance=1e-6,
                dual_tolerance=1e-6,
                logger="SILENT",
                preset="ipopt",
            )

            # Solve the problem
            stats = solver(nlp; display=false)

            # Check convergence (stats is now GenericExecutionStats)
            Test.@test stats.status in (:first_order, :acceptable)
            Test.@test stats.solution ≈ ros.sol atol=1e-4
            Test.@test stats.objective ≈ TestProblems.rosenbrock_objective(ros.sol) atol=1e-4
        end

        Test.@testset "Elec Problem - ADNLPModels" begin
            elec = TestProblems.Elec()

            # Build NLP model
            adnlp_builder = CTSolvers.get_adnlp_model_builder(elec.prob)
            nlp = adnlp_builder(elec.init)

            solver = Solvers.Uno(
                max_iterations=1000, primal_tolerance=1e-6, logger="SILENT"
            )

            stats = solver(nlp; display=false)

            # Just check it converges (stats is now GenericExecutionStats)
            Test.@test stats.status in (:first_order, :acceptable)
        end

        Test.@testset "Max1MinusX2 Problem - ADNLPModels" begin
            max_prob = TestProblems.Max1MinusX2()

            # Build NLP model
            adnlp_builder = CTSolvers.get_adnlp_model_builder(max_prob.prob)
            nlp = adnlp_builder(max_prob.init)

            solver = Solvers.Uno(
                max_iterations=1000, primal_tolerance=1e-6, logger="SILENT"
            )

            stats = solver(nlp; display=false)

            # Check convergence (stats is now GenericExecutionStats)
            Test.@test stats.status in (:first_order, :acceptable)
            Test.@test length(stats.solution) == 1
            Test.@test stats.solution[1] ≈ max_prob.sol[1] atol=1e-4
            Test.@test stats.objective ≈ TestProblems.max1minusx2_objective(max_prob.sol) atol=1e-4
        end

        # ====================================================================
        # INTEGRATION TESTS - Option Aliases
        # ====================================================================

        Test.@testset "Option Aliases" begin
            # Test that aliases work
            solver1 = Solvers.Uno(max_iterations=100)
            solver2 = Solvers.Uno(max_iter=100)

            opts1 = Strategies.options(solver1)
            opts2 = Strategies.options(solver2)

            raw1 = Options.extract_raw_options(Strategies._raw_options(opts1))
            raw2 = Options.extract_raw_options(Strategies._raw_options(opts2))

            # Both should set max_iterations
            Test.@test raw1[:max_iterations] == 100
            Test.@test raw2[:max_iterations] == 100
        end

        # ====================================================================
        # INTEGRATION TESTS - Multiple Solves
        # ====================================================================

        Test.@testset "Multiple Solves" begin
            solver = Solvers.Uno(
                max_iterations=1000, primal_tolerance=1e-6, logger="SILENT"
            )

            # Solve different problems with same solver
            ros = TestProblems.Rosenbrock()
            max_prob = TestProblems.Max1MinusX2()

            # Build NLP models
            nlp1 = CTSolvers.get_adnlp_model_builder(ros.prob)(ros.init)
            nlp2 = CTSolvers.get_adnlp_model_builder(max_prob.prob)(max_prob.init)

            stats1 = solver(nlp1; display=false)
            stats2 = solver(nlp2; display=false)

            # Stats are now GenericExecutionStats
            Test.@test stats1.status in (:first_order, :acceptable)
            Test.@test stats2.status in (:first_order, :acceptable)
        end

        # ====================================================================
        # INTEGRATION TESTS - Initial Guess (max_iterations=0)
        # ====================================================================
        # NOTE: Skipped because Uno performs 1 iteration even with max_iterations=0,
        # so the solution is not exactly the initial guess. This is Uno-specific behavior.

        Test.@testset "Initial Guess - max_iterations=0" begin
            Test.@testset "Rosenbrock" verbose=VERBOSE showtiming=SHOWTIMING begin
                Test.@testset "Modelers.ADNLP" verbose=VERBOSE showtiming=SHOWTIMING begin
                    Test.@test_skip "Uno performs 1 iteration even with max_iterations=0"
                end
            end

            Test.@testset "Elec" verbose=VERBOSE showtiming=SHOWTIMING begin
                Test.@testset "Modelers.ADNLP" verbose=VERBOSE showtiming=SHOWTIMING begin
                    Test.@test_skip "Uno performs 1 iteration even with max_iterations=0"
                end
            end
        end

        # ====================================================================
        # INTEGRATION TESTS - solve_with_uno (direct function)
        # ====================================================================

        Test.@testset "solve_with_uno Function" begin
            modelers = [Modelers.ADNLP()]
            modelers_names = ["Modelers.ADNLP"]

            uno_options = Dict(
                :max_iterations => 1000,
                :primal_tolerance => 1e-6,
                :dual_tolerance => 1e-6,
                :logger => "SILENT",
                :preset => "ipopt",
            )

            Test.@testset "Rosenbrock" verbose=VERBOSE showtiming=SHOWTIMING begin
                ros = TestProblems.Rosenbrock()
                for (modeler, modeler_name) in zip(modelers, modelers_names)
                    Test.@testset "$(modeler_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                        nlp = Optimization.build_model(ros.prob, ros.init, modeler)
                        sol = CTSolversUno.solve_with_uno(nlp; uno_options...)
                        # solve_with_uno now returns GenericExecutionStats
                        Test.@test sol.status in (:first_order, :acceptable)
                        Test.@test sol.solution ≈ ros.sol atol=1e-4
                        Test.@test sol.objective ≈
                            TestProblems.rosenbrock_objective(ros.sol) atol=1e-4
                    end
                end
            end

            Test.@testset "Elec" verbose=VERBOSE showtiming=SHOWTIMING begin
                elec = TestProblems.Elec()
                for (modeler, modeler_name) in zip(modelers, modelers_names)
                    Test.@testset "$(modeler_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                        nlp = Optimization.build_model(elec.prob, elec.init, modeler)
                        sol = CTSolversUno.solve_with_uno(nlp; uno_options...)
                        # solve_with_uno now returns GenericExecutionStats
                        Test.@test sol.status in (:first_order, :acceptable)
                    end
                end
            end

            Test.@testset "Max1MinusX2" verbose=VERBOSE showtiming=SHOWTIMING begin
                max_prob = TestProblems.Max1MinusX2()
                for (modeler, modeler_name) in zip(modelers, modelers_names)
                    Test.@testset "$(modeler_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                        nlp = Optimization.build_model(
                            max_prob.prob, max_prob.init, modeler
                        )
                        sol = CTSolversUno.solve_with_uno(nlp; uno_options...)
                        # solve_with_uno now returns GenericExecutionStats
                        Test.@test sol.status in (:first_order, :acceptable)
                        Test.@test length(sol.solution) == 1
                        Test.@test sol.solution[1] ≈ max_prob.sol[1] atol=1e-4
                        Test.@test sol.objective ≈
                            TestProblems.max1minusx2_objective(max_prob.sol) atol=1e-4
                    end
                end
            end
        end

        # ====================================================================
        # INTEGRATION TESTS - CommonSolve.solve with Uno
        # ====================================================================

        Test.@testset "CommonSolve.solve with Uno" begin
            modelers = [Modelers.ADNLP()]
            modelers_names = ["Modelers.ADNLP"]

            uno_options = Dict(
                :max_iterations => 1000,
                :primal_tolerance => 1e-6,
                :dual_tolerance => 1e-6,
                :logger => "SILENT",
                :preset => "ipopt",
            )

            Test.@testset "Rosenbrock" verbose=VERBOSE showtiming=SHOWTIMING begin
                ros = TestProblems.Rosenbrock()
                for (modeler, modeler_name) in zip(modelers, modelers_names)
                    Test.@testset "$(modeler_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                        sol = CommonSolve.solve(
                            ros.prob, ros.init, modeler, Solvers.Uno(; uno_options...)
                        )
                        Test.@test sol.status in (:first_order, :acceptable)
                        Test.@test sol.solution ≈ ros.sol atol=1e-4
                        Test.@test sol.objective ≈
                            TestProblems.rosenbrock_objective(ros.sol) atol=1e-4
                    end
                end
            end

            Test.@testset "Elec" verbose=VERBOSE showtiming=SHOWTIMING begin
                elec = TestProblems.Elec()
                for (modeler, modeler_name) in zip(modelers, modelers_names)
                    Test.@testset "$(modeler_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                        sol = CommonSolve.solve(
                            elec.prob, elec.init, modeler, Solvers.Uno(; uno_options...)
                        )
                        Test.@test sol.status in (:first_order, :acceptable)
                    end
                end
            end

            Test.@testset "Max1MinusX2" verbose=VERBOSE showtiming=SHOWTIMING begin
                max_prob = TestProblems.Max1MinusX2()
                for (modeler, modeler_name) in zip(modelers, modelers_names)
                    Test.@testset "$(modeler_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                        sol = CommonSolve.solve(
                            max_prob.prob,
                            max_prob.init,
                            modeler,
                            Solvers.Uno(; uno_options...),
                        )
                        Test.@test sol.status in (:first_order, :acceptable)
                        Test.@test length(sol.solution) == 1
                        Test.@test sol.solution[1] ≈ max_prob.sol[1] atol=1e-4
                        Test.@test sol.objective ≈
                            TestProblems.max1minusx2_objective(max_prob.sol) atol=1e-4
                    end
                end
            end
        end

        # ====================================================================
        # UNIT TESTS - Additional Options Metadata
        # ====================================================================

        Test.@testset "Additional Options Metadata" begin
            meta = Strategies.metadata(Solvers.Uno)

            # Termination options
            Test.@test :loose_primal_tolerance in keys(meta)
            Test.@test :loose_dual_tolerance in keys(meta)
            Test.@test :time_limit in keys(meta)

            # Main options
            Test.@test :progress_norm in keys(meta)
            Test.@test :residual_norm in keys(meta)
            Test.@test :residual_scaling_threshold in keys(meta)
            Test.@test :protect_actual_reduction_against_roundoff in keys(meta)
        end

        # ====================================================================
        # UNIT TESTS - Option Validation
        # ====================================================================

        Test.@testset "Additional Options Validation" begin
            redirect_stderr(devnull) do
                # Invalid preset
                Test.@test_throws Exceptions.IncorrectArgument Solvers.Uno(preset="invalid")

                # Invalid logger
                Test.@test_throws Exceptions.IncorrectArgument Solvers.Uno(
                    logger="INVALID_LEVEL"
                )

                # Negative tolerance
                Test.@test_throws Exceptions.IncorrectArgument Solvers.Uno(
                    primal_tolerance=-1e-6
                )

                # Invalid progress_norm
                Test.@test_throws Exceptions.IncorrectArgument Solvers.Uno(
                    progress_norm="INVALID"
                )
            end

            # Valid cases
            Test.@test_nowarn Solvers.Uno(preset="filtersqp")
            Test.@test_nowarn Solvers.Uno(logger="DEBUG")
            Test.@test_nowarn Solvers.Uno(progress_norm="L1")
        end

        # ====================================================================
        # INTEGRATION TESTS - Exhaustive Options Validation
        # ====================================================================

        Test.@testset "Exhaustive Options Validation" begin
            ros = TestProblems.Rosenbrock()
            adnlp_builder = CTSolvers.get_adnlp_model_builder(ros.prob)
            nlp = adnlp_builder(ros.init)

            # Define all options with valid values to check for typos in names
            exhaustive_options = Dict(
                :preset => "ipopt",
                :primal_tolerance => 1e-6,
                :dual_tolerance => 1e-6,
                :max_iterations => 10,
                :logger => "SILENT",
                :print_solution => false,
            )

            solver = Solvers.Uno(; exhaustive_options...)

            # This should NOT throw any ErrorException about unknown options
            Test.@test_nowarn solver(nlp; display=false)
        end
    end
end

end # module

test_uno_extension() = TestUnoExtension.test_uno_extension()
