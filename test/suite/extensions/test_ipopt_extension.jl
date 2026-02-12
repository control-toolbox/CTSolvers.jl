module TestIpoptExtension

using Test
using CTBase: CTBase
const Exceptions = CTBase.Exceptions
using CTSolvers
using CTSolvers.Solvers
using CTSolvers.Strategies
using CTSolvers.Options
using CTSolvers.Modelers
using CTSolvers.Optimization
using CommonSolve
using NLPModels
using ADNLPModels
using Main.TestProblems: Rosenbrock, Elec, Max1MinusX2, rosenbrock_objective, max1minusx2_objective

# Get extension to access solve_with_ipopt
using NLPModelsIpopt
const CTSolversIpopt = Base.get_extension(CTSolvers, :CTSolversIpopt)

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

"""
    test_ipopt_extension()

Tests for IpoptSolver extension.

🧪 **Applying Testing Rule**: Unit Tests + Integration Tests

Tests the complete IpoptSolver functionality including metadata, constructor,
options handling, display flag, and problem solving.
"""
function test_ipopt_extension()
    Test.@testset "Ipopt Extension" verbose=VERBOSE showtiming=SHOWTIMING begin
        
        # ====================================================================
        # UNIT TESTS - Metadata and Options
        # ====================================================================
        
        Test.@testset "Metadata" begin
            meta = Strategies.metadata(Solvers.IpoptSolver)
            
            Test.@test meta isa Strategies.StrategyMetadata
            Test.@test length(meta) > 0
            
            # Test that key options are defined
            Test.@test :max_iter in keys(meta)
            Test.@test :tol in keys(meta)
            Test.@test :print_level in keys(meta)
            Test.@test :mu_strategy in keys(meta)
            Test.@test :linear_solver in keys(meta)
            Test.@test :sb in keys(meta)
            
            # Test option types
            Test.@test meta[:max_iter].type == Integer
            Test.@test meta[:tol].type == Real
            Test.@test meta[:print_level].type == Integer
            
            # Test default values exist
            Test.@test meta[:max_iter].default isa Integer
            Test.@test meta[:tol].default isa Real
            Test.@test meta[:print_level].default isa Integer
        end
        
        # ====================================================================
        # UNIT TESTS - Constructor
        # ====================================================================
        
        Test.@testset "Constructor" begin
            # Default constructor
            solver = Solvers.IpoptSolver()
            Test.@test solver isa Solvers.IpoptSolver
            Test.@test solver isa Solvers.AbstractOptimizationSolver
            
            # Constructor with options
            solver_custom = Solvers.IpoptSolver(max_iter=100, tol=1e-6)
            Test.@test solver_custom isa Solvers.IpoptSolver
            
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
            solver = Solvers.IpoptSolver(max_iter=500, tol=1e-8, print_level=0)
            opts = Strategies.options(solver)
            
            # Extract raw options (returns NamedTuple)
            raw_opts = Options.extract_raw_options(opts.options)
            Test.@test raw_opts isa NamedTuple
            Test.@test haskey(raw_opts, :max_iter)
            Test.@test haskey(raw_opts, :tol)
            Test.@test haskey(raw_opts, :print_level)
            
            # Verify values
            Test.@test raw_opts[:max_iter] == 500
            Test.@test raw_opts[:tol] == 1e-8
            Test.@test raw_opts[:print_level] == 0
        end
        
        # ====================================================================
        # UNIT TESTS - Display Flag Handling
        # ====================================================================
        
        Test.@testset "Display Flag" begin
            # Create a simple problem
            nlp = ADNLPModels.ADNLPModel(x -> sum(x.^2), [1.0, 2.0])
            
            # Test with display=false sets print_level=0
            solver_verbose = Solvers.IpoptSolver(max_iter=10, print_level=0)
            
            # Note: We can't easily test the internal behavior without actually solving,
            # but we can verify the solver accepts the display parameter
            Test.@test_nowarn solver_verbose(nlp; display=false)
            Test.@test_nowarn solver_verbose(nlp; display=true)
        end
        
        # ====================================================================
        # INTEGRATION TESTS - Solving Problems with ADNLPModels
        # ====================================================================
        
        Test.@testset "Rosenbrock Problem - ADNLPModels" begin
            ros = Rosenbrock()
            
            # Build NLP model from problem
            adnlp_builder = CTSolvers.get_adnlp_model_builder(ros.prob)
            nlp = adnlp_builder(ros.init)
            
            # Create solver with appropriate options
            solver = Solvers.IpoptSolver(
                max_iter=1000,
                tol=1e-6,
                print_level=0,
                mu_strategy="adaptive",
                linear_solver="mumps",
                sb="yes"
            )
            
            # Solve the problem
            stats = solver(nlp; display=false)
            
            # Check convergence
            Test.@test stats.status == :first_order
            Test.@test stats.solution ≈ ros.sol atol=1e-6
            Test.@test stats.objective ≈ rosenbrock_objective(ros.sol) atol=1e-6
        end
        
        Test.@testset "Elec Problem - ADNLPModels" begin
            elec = Elec()
            
            # Build NLP model
            adnlp_builder = CTSolvers.get_adnlp_model_builder(elec.prob)
            nlp = adnlp_builder(elec.init)
            
            solver = Solvers.IpoptSolver(
                max_iter=1000,
                tol=1e-6,
                print_level=0
            )
            
            stats = solver(nlp; display=false)
            
            # Just check it converges
            Test.@test stats.status == :first_order
        end
        
        Test.@testset "Max1MinusX2 Problem - ADNLPModels" begin
            max_prob = Max1MinusX2()
            
            # Build NLP model
            adnlp_builder = CTSolvers.get_adnlp_model_builder(max_prob.prob)
            nlp = adnlp_builder(max_prob.init)
            
            solver = Solvers.IpoptSolver(
                max_iter=1000,
                tol=1e-6,
                print_level=0
            )
            
            stats = solver(nlp; display=false)
            
            # Check convergence
            Test.@test stats.status == :first_order
            Test.@test length(stats.solution) == 1
            Test.@test stats.solution[1] ≈ max_prob.sol[1] atol=1e-6
            Test.@test stats.objective ≈ max1minusx2_objective(max_prob.sol) atol=1e-6
        end
        
        # ====================================================================
        # INTEGRATION TESTS - Option Aliases
        # ====================================================================
        
        Test.@testset "Option Aliases" begin
            # Test that aliases work
            solver1 = Solvers.IpoptSolver(max_iter=100)
            solver2 = Solvers.IpoptSolver(maxiter=100)
            
            opts1 = Strategies.options(solver1)
            opts2 = Strategies.options(solver2)
            
            raw1 = Options.extract_raw_options(opts1.options)
            raw2 = Options.extract_raw_options(opts2.options)
            
            # Both should set max_iter
            Test.@test raw1[:max_iter] == 100
            Test.@test raw2[:max_iter] == 100
        end
        
        # ====================================================================
        # INTEGRATION TESTS - Multiple Solves
        # ====================================================================
        
        Test.@testset "Multiple Solves" begin
            solver = Solvers.IpoptSolver(max_iter=1000, tol=1e-6, print_level=0)
            
            # Solve different problems with same solver
            ros = Rosenbrock()
            max_prob = Max1MinusX2()
            
            # Build NLP models
            nlp1 = CTSolvers.get_adnlp_model_builder(ros.prob)(ros.init)
            nlp2 = CTSolvers.get_adnlp_model_builder(max_prob.prob)(max_prob.init)
            
            stats1 = solver(nlp1; display=false)
            stats2 = solver(nlp2; display=false)
            
            Test.@test stats1.status == :first_order
            Test.@test stats2.status == :first_order
        end
        
        # ====================================================================
        # INTEGRATION TESTS - Initial Guess (max_iter=0)
        # ====================================================================
        
        Test.@testset "Initial Guess - max_iter=0" begin
            modelers = [Modelers.ADNLP(), Modelers.ExaModeler()]
            modelers_names = ["Modelers.ADNLP", "Modelers.ExaModeler (CPU)"]
            
            # Rosenbrock: start at the known solution and enforce max_iter=0
            Test.@testset "Rosenbrock" verbose=VERBOSE showtiming=SHOWTIMING begin
                ros = Rosenbrock()
                for (modeler, modeler_name) in zip(modelers, modelers_names)
                    Test.@testset "$(modeler_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                        local opts = Dict(
                            :max_iter => 0,
                            :print_level => 0,
                            :sb => "yes"
                        )
                        sol = CommonSolve.solve(
                            ros.prob, ros.sol, modeler, Solvers.IpoptSolver(; opts...)
                        )
                        Test.@test sol.status == :max_iter
                        Test.@test sol.solution ≈ ros.sol atol=1e-6
                    end
                end
            end
            
            # Elec: expect solution to remain equal to the initial guess vector
            Test.@testset "Elec" verbose=VERBOSE showtiming=SHOWTIMING begin
                elec = Elec()
                for (modeler, modeler_name) in zip(modelers, modelers_names)
                    Test.@testset "$(modeler_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                        local opts = Dict(
                            :max_iter => 0,
                            :print_level => 0,
                            :sb => "yes"
                        )
                        sol = CommonSolve.solve(
                            elec.prob, elec.init, modeler, Solvers.IpoptSolver(; opts...)
                        )
                        Test.@test sol.status == :max_iter
                        Test.@test sol.solution ≈ vcat(elec.init.x, elec.init.y, elec.init.z) atol=1e-6
                    end
                end
            end
        end
        
        # ====================================================================
        # INTEGRATION TESTS - solve_with_ipopt (direct function)
        # ====================================================================
        
        Test.@testset "solve_with_ipopt Function" begin
            modelers = [Modelers.ADNLP()]
            modelers_names = ["Modelers.ADNLP"]
            
            ipopt_options = Dict(
                :max_iter => 1000,
                :tol => 1e-6,
                :print_level => 0,
                :mu_strategy => "adaptive",
                :linear_solver => "mumps",
                :sb => "yes",
            )
            
            Test.@testset "Rosenbrock" verbose=VERBOSE showtiming=SHOWTIMING begin
                ros = Rosenbrock()
                for (modeler, modeler_name) in zip(modelers, modelers_names)
                    Test.@testset "$(modeler_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                        nlp = Optimization.build_model(ros.prob, ros.init, modeler)
                        sol = CTSolversIpopt.solve_with_ipopt(nlp; ipopt_options...)
                        Test.@test sol.status == :first_order
                        Test.@test sol.solution ≈ ros.sol atol=1e-6
                        Test.@test sol.objective ≈ rosenbrock_objective(ros.sol) atol=1e-6
                    end
                end
            end
            
            Test.@testset "Elec" verbose=VERBOSE showtiming=SHOWTIMING begin
                elec = Elec()
                for (modeler, modeler_name) in zip(modelers, modelers_names)
                    Test.@testset "$(modeler_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                        nlp = Optimization.build_model(elec.prob, elec.init, modeler)
                        sol = CTSolversIpopt.solve_with_ipopt(nlp; ipopt_options...)
                        Test.@test sol.status == :first_order
                    end
                end
            end
            
            Test.@testset "Max1MinusX2" verbose=VERBOSE showtiming=SHOWTIMING begin
                max_prob = Max1MinusX2()
                for (modeler, modeler_name) in zip(modelers, modelers_names)
                    Test.@testset "$(modeler_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                        nlp = Optimization.build_model(max_prob.prob, max_prob.init, modeler)
                        sol = CTSolversIpopt.solve_with_ipopt(nlp; ipopt_options...)
                        Test.@test sol.status == :first_order
                        Test.@test length(sol.solution) == 1
                        Test.@test sol.solution[1] ≈ max_prob.sol[1] atol=1e-6
                        Test.@test sol.objective ≈ max1minusx2_objective(max_prob.sol) atol=1e-6
                    end
                end
            end
        end
        
        # ====================================================================
        # INTEGRATION TESTS - CommonSolve.solve with Ipopt
        # ====================================================================
        
        Test.@testset "CommonSolve.solve with Ipopt" begin
            modelers = [Modelers.ADNLP(), Modelers.ExaModeler()]
            modelers_names = ["Modelers.ADNLP", "Modelers.ExaModeler (CPU)"]
            
            ipopt_options = Dict(
                :max_iter => 1000,
                :tol => 1e-6,
                :print_level => 0,
                :mu_strategy => "adaptive",
                :linear_solver => "mumps",
                :sb => "yes",
            )
            
            Test.@testset "Rosenbrock" verbose=VERBOSE showtiming=SHOWTIMING begin
                ros = Rosenbrock()
                for (modeler, modeler_name) in zip(modelers, modelers_names)
                    Test.@testset "$(modeler_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                        sol = CommonSolve.solve(
                            ros.prob,
                            ros.init,
                            modeler,
                            Solvers.IpoptSolver(; ipopt_options...),
                        )
                        Test.@test sol.status == :first_order
                        Test.@test sol.solution ≈ ros.sol atol=1e-6
                        Test.@test sol.objective ≈ rosenbrock_objective(ros.sol) atol=1e-6
                    end
                end
            end
            
            Test.@testset "Elec" verbose=VERBOSE showtiming=SHOWTIMING begin
                elec = Elec()
                for (modeler, modeler_name) in zip(modelers, modelers_names)
                    Test.@testset "$(modeler_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                        sol = CommonSolve.solve(
                            elec.prob,
                            elec.init,
                            modeler,
                            Solvers.IpoptSolver(; ipopt_options...),
                        )
                        Test.@test sol.status == :first_order
                    end
                end
            end
            
            Test.@testset "Max1MinusX2" verbose=VERBOSE showtiming=SHOWTIMING begin
                max_prob = Max1MinusX2()
                for (modeler, modeler_name) in zip(modelers, modelers_names)
                    Test.@testset "$(modeler_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                        sol = CommonSolve.solve(
                            max_prob.prob,
                            max_prob.init,
                            modeler,
                            Solvers.IpoptSolver(; ipopt_options...),
                        )
                        Test.@test sol.status == :first_order
                        Test.@test length(sol.solution) == 1
                        Test.@test sol.solution[1] ≈ max_prob.sol[1] atol=1e-6
                        Test.@test sol.objective ≈ max1minusx2_objective(max_prob.sol) atol=1e-6
                    end
                end
            end
        end

        # ====================================================================
        # UNIT TESTS - Additional Options Metadata
        # ====================================================================

        Test.@testset "Additional Options Metadata" begin
            meta = Strategies.metadata(Solvers.IpoptSolver)

            # Debugging
            Test.@test :derivative_test in keys(meta)
            Test.@test :derivative_test_tol in keys(meta)
            Test.@test :derivative_test_print_all in keys(meta)

            # Hessian
            Test.@test :hessian_approximation in keys(meta)
            Test.@test :limited_memory_update_type in keys(meta)

            # Warm Start
            Test.@test :warm_start_init_point in keys(meta)
            Test.@test :warm_start_bound_push in keys(meta)
            Test.@test :warm_start_mult_bound_push in keys(meta)

            # Advanced Termination
            Test.@test :acceptable_tol in keys(meta)
            Test.@test :acceptable_iter in keys(meta)
            Test.@test :diverging_iterates_tol in keys(meta)

            # Barrier
            Test.@test :mu_init in keys(meta)
            Test.@test :mu_max_fact in keys(meta)
            Test.@test :mu_max in keys(meta)
            Test.@test :mu_min in keys(meta)

            # Timing
            Test.@test :timing_statistics in keys(meta)
            Test.@test :print_timing_statistics in keys(meta)
            Test.@test :print_frequency_iter in keys(meta)
            Test.@test :print_frequency_time in keys(meta)
        end

        # ====================================================================
        # UNIT TESTS - Option Validation
        # ====================================================================

        Test.@testset "Additional Options Validation" begin
            redirect_stderr(devnull) do
                # Derivative Test
                Test.@test_throws Exceptions.IncorrectArgument Solvers.IpoptSolver(derivative_test="invalid")

                # Hessian
                Test.@test_throws Exceptions.IncorrectArgument Solvers.IpoptSolver(hessian_approximation="invalid")

                # Warm Start
                Test.@test_throws Exceptions.IncorrectArgument Solvers.IpoptSolver(warm_start_init_point="invalid")

                # Barrier
                Test.@test_throws Exceptions.IncorrectArgument Solvers.IpoptSolver(mu_strategy="invalid")
            end

            # Valid cases
            Test.@test_nowarn Solvers.IpoptSolver(derivative_test="first-order")
            Test.@test_nowarn Solvers.IpoptSolver(hessian_approximation="limited-memory")
            Test.@test_nowarn Solvers.IpoptSolver(warm_start_init_point="yes")
            Test.@test_nowarn Solvers.IpoptSolver(mu_strategy="monotone")
        end

        # ====================================================================
        # INTEGRATION TESTS - Pass-through verify
        # ====================================================================

        Test.@testset "Pass-through Verification" begin
            ros = Rosenbrock()
            adnlp_builder = CTSolvers.get_adnlp_model_builder(ros.prob)
            nlp = adnlp_builder(ros.init)

            # Test derivative_test="first-order"
            # It should run without error (might print output, suppression handled if needed)
            solver = Solvers.IpoptSolver(
                max_iter=1,
                derivative_test="first-order",
                print_level=0,
                sb="yes"
            )

            # We use redirect_stderr/stdout to suppress potential verbose output from derivative checker if it bypasses print_level
            redirect_stdout(devnull) do
                redirect_stderr(devnull) do
                    # Just check it runs
                    Test.@test_nowarn solver(nlp; display=false)
                end
            end

            # Test hessian_approximation="limited-memory"
            solver_lbfgs = Solvers.IpoptSolver(
                max_iter=10,
                hessian_approximation="limited-memory",
                print_level=0,
                sb="yes"
            )
            Test.@test_nowarn solver_lbfgs(nlp; display=false)
        end

        # ====================================================================
        # INTEGRATION TESTS - Exhaustive Options Validation
        # ====================================================================

        Test.@testset "Exhaustive Options Validation" begin
            ros = Rosenbrock()
            adnlp_builder = CTSolvers.get_adnlp_model_builder(ros.prob)
            nlp = adnlp_builder(ros.init)

            # Define all options with valid values to check for typos in names
            exhaustive_options = Dict(
                :tol => 1e-8,
                :dual_inf_tol => 1e-5,
                :constr_viol_tol => 1e-4,
                :acceptable_tol => 1e-2,
                :diverging_iterates_tol => 1e20,
                :max_iter => 1,
                :max_wall_time => 100.0,
                :max_cpu_time => 100.0,
                :acceptable_iter => 15,
                :derivative_test => "none",
                :derivative_test_tol => 1e-4,
                :derivative_test_print_all => "no",
                :hessian_approximation => "exact",
                :limited_memory_update_type => "bfgs",
                :warm_start_init_point => "no",
                :warm_start_bound_push => 1e-9,
                :warm_start_mult_bound_push => 1e-9,
                :mu_strategy => "adaptive",
                :mu_init => 0.1,
                :mu_max_fact => 1000.0,
                :mu_max => 1e5,
                :mu_min => 1e-11,
                :print_level => 0,
                :sb => "yes",
                :timing_statistics => "no",
                :print_timing_statistics => "no",
                :print_frequency_iter => 1,
                :print_frequency_time => 0.0,
                :linear_solver => "mumps"
            )

            solver = Solvers.IpoptSolver(; exhaustive_options...)

            # This should NOT throw any ErrorException about unknown options
            Test.@test_nowarn solver(nlp; display=false)
        end
    end
end

end # module

test_ipopt_extension() = TestIpoptExtension.test_ipopt_extension()
