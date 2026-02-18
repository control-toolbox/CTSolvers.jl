module TestExtMadNCL

import Test
import CTSolvers
import CTSolvers.Optimization
import MadNCL
import MadNLP
import MadNLPMumps
import NLPModels
import ADNLPModels
import SolverCore

include(joinpath(@__DIR__, "..", "..", "problems", "TestProblems.jl"))
import .TestProblems

# Default test options (can be overridden by Main.TestOptions if available)
const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

"""
    test_madncl_extract_solver_infos()

Test the MadNCL extension for CTSolvers.

This tests the `extract_solver_infos` function which extracts solver information
from MadNCL execution statistics, including proper handling of objective sign
correction and status codes.

🧪 **Applying Testing Rule**: Unit Tests + Integration Tests
"""
function test_madncl_extract_solver_infos()
    Test.@testset "MadNCL Extension - extract_solver_infos" verbose=VERBOSE showtiming=SHOWTIMING begin
        
        Test.@testset "extract_solver_infos with minimization (Rosenbrock)" begin
            # Use Rosenbrock problem which is known to work
            ros = TestProblems.Rosenbrock()
            
            # Build NLP model
            adnlp_builder = CTSolvers.get_adnlp_model_builder(ros.prob)
            nlp = adnlp_builder(ros.init)

            # Configure MadNCL options
            ncl_options = MadNCL.NCLOptions{Float64}(verbose=false)
            
            # Solve with MadNCL
            solver = MadNCL.NCLSolver(nlp; ncl_options=ncl_options, print_level=MadNLP.ERROR)
            stats = MadNCL.solve!(solver)
            
            # Extract solver infos using CTSolvers extension
            objective, iterations, constraints_violation, message, status, successful = 
                Optimization.extract_solver_infos(stats, NLPModels.get_minimize(nlp))
            
            # Verify results
            Test.@test objective ≈ 0.0 atol=1e-4  # Optimal objective for Rosenbrock
            Test.@test iterations > 0  # Should have done some iterations
            Test.@test message == "MadNCL"
            Test.@test status isa Symbol
            Test.@test status in (:SOLVE_SUCCEEDED, :SOLVED_TO_ACCEPTABLE_LEVEL)
            Test.@test successful == true
            
            # For minimization, objective should equal stats.objective
            Test.@test objective ≈ stats.objective atol=1e-10
        end
        
        Test.@testset "maximization problem - objective sign consistency (Max1MinusX2)" begin
            # Use Max1MinusX2 problem: max 1 - x^2
            # Solution: x = 0, objective = 1
            max_prob = TestProblems.Max1MinusX2()
            
            # Build NLP model
            adnlp_builder = CTSolvers.get_adnlp_model_builder(max_prob.prob)
            nlp = adnlp_builder(max_prob.init)
            
            # Verify it's a maximization problem
            Test.@test NLPModels.get_minimize(nlp) == false
            
            # Configure MadNCL options
            ncl_options = MadNCL.NCLOptions{Float64}(verbose=false)

            # Solve with MadNCL
            solver = MadNCL.NCLSolver(nlp; ncl_options=ncl_options, print_level=MadNLP.ERROR)
            stats = MadNCL.solve!(solver)
            
            # Extract solver infos
            objective_extracted, _, _, _, _, _ = Optimization.extract_solver_infos(stats, NLPModels.get_minimize(nlp))
            
            # The extracted objective should be the true maximization objective (≈ 1.0)
            expected_objective = TestProblems.max1minusx2_objective(max_prob.sol)
            Test.@test objective_extracted ≈ expected_objective atol=1e-6
            
            # Test the consistency logic: (flip_madncl && flip_extract) || (!flip_madncl && !flip_extract)
            # We need to determine if MadNCL flips the sign internally
            raw_madncl_objective = stats.objective
            
            # If MadNCL returns the negative (like MadNLP bug), then raw should be ≈ -1.0
            # If MadNCL returns the positive (correct behavior), then raw should be ≈ 1.0
            flip_madncl = abs(raw_madncl_objective + expected_objective) < 1e-6  # MadNCL returns negative
            flip_extract = abs(objective_extracted - raw_madncl_objective) > 1e-6  # Our function flips it
            
            # The consistency condition should always be true
            # Either both flip (MadNCL has bug, we correct it) or neither flips (MadNCL correct, we don't touch)
            consistency_condition = (flip_madncl && flip_extract) || (!flip_madncl && !flip_extract)
            Test.@test consistency_condition == true
            
            # Additional debugging info (if test fails)
            if !consistency_condition
                println("DEBUG INFO:")
                println("Raw MadNCL objective: $raw_madncl_objective")
                println("Extracted objective: $objective_extracted")
                println("Expected objective: $expected_objective")
                println("flip_madncl: $flip_madncl")
                println("flip_extract: $flip_extract")
                println("Consistency condition failed!")
            end
        end
        
        Test.@testset "unit test - maximization objective flip logic" begin
            # Unit test to verify that MadNCL does NOT flip the sign
            # (unlike MadNLP which has this bug)
            ros = TestProblems.Rosenbrock()
            adnlp_builder = CTSolvers.get_adnlp_model_builder(ros.prob)
            nlp = adnlp_builder(ros.init)
            
            # Configure MadNCL options
            ncl_options = MadNCL.NCLOptions{Float64}(verbose=false)

            # Solve to get real stats
            solver = MadNCL.NCLSolver(nlp; ncl_options=ncl_options, print_level=MadNLP.ERROR)
            stats = MadNCL.solve!(solver)
            
            original_objective = stats.objective
            
            # Test case 1: minimization (should not flip)
            obj_min, _, _, _, _, _ = Optimization.extract_solver_infos(stats, true)
            Test.@test obj_min ≈ original_objective atol=1e-10
            
            # Test case 2: maximization (MadNCL returns correct sign, so we should NOT flip)
            # This is different from MadNLP!
            obj_max, _, _, _, _, _ = Optimization.extract_solver_infos(stats, false)
            Test.@test obj_max ≈ original_objective atol=1e-10  # Same value, no flip
            
            # Verify: for MadNCL, both should be equal (no flip)
            Test.@test obj_max == obj_min
        end
    end
end

end # module

test_madncl_extract_solver_infos() = TestExtMadNCL.test_madncl_extract_solver_infos()
