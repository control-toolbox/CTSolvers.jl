module TestMadNLPExtension

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
using CUDA
using NLPModels
using ADNLPModels
using MadNLP
using MadNLPMumps
using ExaModels
import MadNLPGPU
using Main.TestProblems: Rosenbrock, Elec, Max1MinusX2, rosenbrock_objective, max1minusx2_objective

# Trigger extension loading
const CTSolversMadNLP = Base.get_extension(CTSolvers, :CTSolversMadNLP)

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

# CUDA availability check
is_cuda_on() = CUDA.functional()
if is_cuda_on()
    println("✓ CUDA functional, GPU tests enabled")
else
    println("⚠️  CUDA not functional, GPU tests will be skipped")
end

"""
    test_madnlp_extension()

Tests for MadNLPSolver extension.

🧪 **Applying Testing Rule**: Unit Tests + Integration Tests

Tests the complete MadNLPSolver functionality including metadata, constructor,
options handling, display flag, and problem solving on CPU (and GPU if available).
"""
function test_madnlp_extension()
    Test.@testset "MadNLP Extension" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ====================================================================
        # UNIT TESTS - Metadata and Options
        # ====================================================================
        
        Test.@testset "Metadata" begin
            meta = Strategies.metadata(Solvers.MadNLPSolver)
            
            Test.@test meta isa Strategies.StrategyMetadata
            Test.@test length(meta) > 0
            
            # Test that key options are defined
            Test.@test :max_iter in keys(meta)
            Test.@test :tol in keys(meta)
            Test.@test :print_level in keys(meta)
            Test.@test :linear_solver in keys(meta)
            
            # Test termination options are defined
            Test.@test :acceptable_tol in keys(meta)
            Test.@test :acceptable_iter in keys(meta)
            Test.@test :max_wall_time in keys(meta)
            Test.@test :diverging_iterates_tol in keys(meta)

            # Test scaling and structure options
            Test.@test :nlp_scaling in keys(meta)
            Test.@test :nlp_scaling_max_gradient in keys(meta)
            Test.@test :jacobian_constant in keys(meta)
            Test.@test :hessian_constant in keys(meta)

            # Test initialization options
            Test.@test :bound_push in keys(meta)
            Test.@test :bound_fac in keys(meta)
            Test.@test :constr_mult_init_max in keys(meta)
            Test.@test :fixed_variable_treatment in keys(meta)
            Test.@test :equality_treatment in keys(meta)

            # Test option types
            Test.@test meta[:max_iter].type == Integer
            Test.@test meta[:tol].type == Real
            Test.@test meta[:print_level].type == MadNLP.LogLevels
            Test.@test meta[:linear_solver].type == Type{<:MadNLP.AbstractLinearSolver}
            
            # Test termination option types
            Test.@test meta[:acceptable_tol].type == Real
            Test.@test meta[:acceptable_iter].type == Integer
            Test.@test meta[:max_wall_time].type == Real
            Test.@test meta[:diverging_iterates_tol].type == Real

            # Test scaling and structure types
            Test.@test meta[:nlp_scaling].type == Bool
            Test.@test meta[:nlp_scaling_max_gradient].type == Real
            Test.@test meta[:jacobian_constant].type == Bool
            Test.@test meta[:hessian_constant].type == Bool

            # Test initialization types
            Test.@test meta[:bound_push].type == Real
            Test.@test meta[:bound_fac].type == Real
            Test.@test meta[:constr_mult_init_max].type == Real
            Test.@test meta[:fixed_variable_treatment].type == Type{<:MadNLP.AbstractFixedVariableTreatment}
            Test.@test meta[:equality_treatment].type == Type{<:MadNLP.AbstractEqualityTreatment}
            Test.@test meta[:kkt_system].type == Union{Type{<:MadNLP.AbstractKKTSystem},UnionAll}
            Test.@test meta[:hessian_approximation].type == Union{Type{<:MadNLP.AbstractHessian},UnionAll}
            Test.@test meta[:inertia_correction_method].type == Type{<:MadNLP.AbstractInertiaCorrector}
            Test.@test meta[:mu_init].type == Real
            Test.@test meta[:mu_min].type == Real
            Test.@test meta[:tau_min].type == Real

            # Test default values
            Test.@test meta[:max_iter].default isa Integer
            Test.@test meta[:tol].default isa Real
            Test.@test meta[:print_level].default isa MadNLP.LogLevels
            Test.@test meta[:linear_solver].default == MadNLPMumps.MumpsSolver

            # Test termination option defaults - all use NotProvided to let MadNLP use its own defaults
            Test.@test meta[:acceptable_iter].default isa Options.NotProvidedType
            Test.@test meta[:acceptable_tol].default isa Options.NotProvidedType
            Test.@test meta[:max_wall_time].default isa Options.NotProvidedType
            Test.@test meta[:diverging_iterates_tol].default isa Options.NotProvidedType

            # Test scaling and structure defaults - all use NotProvided
            Test.@test meta[:nlp_scaling].default isa Options.NotProvidedType
            Test.@test meta[:nlp_scaling_max_gradient].default isa Options.NotProvidedType
            Test.@test meta[:jacobian_constant].default isa Options.NotProvidedType
            Test.@test meta[:hessian_constant].default isa Options.NotProvidedType

            # Test initialization defaults
            Test.@test meta[:bound_push].default isa Options.NotProvidedType
            Test.@test meta[:bound_fac].default isa Options.NotProvidedType
            Test.@test meta[:constr_mult_init_max].default isa Options.NotProvidedType
            Test.@test meta[:fixed_variable_treatment].default isa Options.NotProvidedType
            Test.@test meta[:equality_treatment].default isa Options.NotProvidedType
        end
        
        # ====================================================================
        # UNIT TESTS - Constructor
        # ====================================================================
        
        Test.@testset "Constructor" begin
            # Default constructor
            solver = Solvers.MadNLPSolver(print_level=MadNLP.ERROR)
            Test.@test solver isa Solvers.MadNLPSolver
            Test.@test solver isa Solvers.AbstractOptimizationSolver
            
            # Constructor with options
            solver_custom = Solvers.MadNLPSolver(max_iter=100, tol=1e-6, print_level=MadNLP.ERROR)
            Test.@test solver_custom isa Solvers.MadNLPSolver
            
            # Test Strategies.options() returns StrategyOptions
            opts = Strategies.options(solver)
            Test.@test opts isa Strategies.StrategyOptions
        end
        
        # ====================================================================
        # UNIT TESTS - Options Extraction
        # ====================================================================
        
        Test.@testset "Options Extraction" begin
            solver = Solvers.MadNLPSolver(max_iter=500, tol=1e-8, print_level=MadNLP.ERROR)
            opts = Strategies.options(solver)
            
            # Extract raw options (returns NamedTuple)
            raw_opts = Options.extract_raw_options(opts.options)
            Test.@test raw_opts isa NamedTuple
            Test.@test haskey(raw_opts, :max_iter)
            Test.@test haskey(raw_opts, :tol)
            Test.@test haskey(raw_opts, :print_level)
            
            # Verify values
            Test.@test raw_opts.max_iter == 500
            Test.@test raw_opts.tol == 1e-8
            Test.@test raw_opts.print_level == MadNLP.ERROR
        end
        
        # ====================================================================
        # UNIT TESTS - Display Flag Handling
        # ====================================================================
        
        Test.@testset "Display Flag" begin
            # Create a simple problem
            nlp = ADNLPModels.ADNLPModel(x -> sum(x.^2), [1.0, 2.0])
            
            # Test with display=false sets print_level=MadNLP.ERROR
            solver_verbose = Solvers.MadNLPSolver(
                max_iter=10,
                print_level=MadNLP.INFO
            )
            
            # Verify the solver accepts the display parameter
            Test.@test_nowarn solver_verbose(nlp; display=false)
            redirect_stdout(devnull) do
                Test.@test_nowarn solver_verbose(nlp; display=true)
            end
        end
        
        # ====================================================================
        # INTEGRATION TESTS - Solving Problems (CPU)
        # ====================================================================
        
        Test.@testset "Rosenbrock Problem - CPU" begin
            ros = Rosenbrock()
            
            # Build NLP model
            adnlp_builder = CTSolvers.get_adnlp_model_builder(ros.prob)
            nlp = adnlp_builder(ros.init)
            
            solver = Solvers.MadNLPSolver(
                max_iter=1000,
                tol=1e-6,
                print_level=MadNLP.ERROR,
                linear_solver=MadNLPMumps.MumpsSolver
            )
            
            stats = solver(nlp; display=false)
            
            # Check convergence
            Test.@test stats isa MadNLP.MadNLPExecutionStats
            Test.@test Symbol(stats.status) in (:SOLVE_SUCCEEDED, :SOLVED_TO_ACCEPTABLE_LEVEL)
            Test.@test stats.solution ≈ ros.sol atol=1e-4
        end
        
        Test.@testset "Elec Problem - CPU" begin
            elec = Elec()
            
            # Build NLP model
            adnlp_builder = CTSolvers.get_adnlp_model_builder(elec.prob)
            nlp = adnlp_builder(elec.init)
            
            solver = Solvers.MadNLPSolver(
                max_iter=1000,
                tol=1e-6,
                print_level=MadNLP.ERROR
            )
            
            stats = solver(nlp; display=false)
            
            # Just check it converges
            Test.@test Symbol(stats.status) in (:SOLVE_SUCCEEDED, :SOLVED_TO_ACCEPTABLE_LEVEL)
        end
        
        Test.@testset "Max1MinusX2 Problem - CPU" begin
            max_prob = Max1MinusX2()
            
            # Build NLP model
            adnlp_builder = CTSolvers.get_adnlp_model_builder(max_prob.prob)
            nlp = adnlp_builder(max_prob.init)
            
            solver = Solvers.MadNLPSolver(
                max_iter=1000,
                tol=1e-6,
                print_level=MadNLP.ERROR
            )
            
            stats = solver(nlp; display=false)
            
            # Check convergence
            Test.@test Symbol(stats.status) in (:SOLVE_SUCCEEDED, :SOLVED_TO_ACCEPTABLE_LEVEL)
            Test.@test length(stats.solution) == 1
            Test.@test stats.solution[1] ≈ max_prob.sol[1] atol=1e-6
            # Note: MadNLP 0.8 inverts the sign for maximization problems
            Test.@test -stats.objective ≈ max1minusx2_objective(max_prob.sol) atol=1e-6
        end
        
        # ====================================================================
        # INTEGRATION TESTS - GPU (if CUDA available)
        # ====================================================================
        
        Test.@testset "GPU Tests" begin
            if is_cuda_on()
                gpu_modeler = Modelers.ExaModeler(backend=CUDA.CUDABackend())
                gpu_solver = Solvers.MadNLPSolver(
                    max_iter=1000,
                    tol=1e-6,
                    print_level=MadNLP.ERROR,
                    linear_solver=MadNLPGPU.CUDSSSolver
                )

                Test.@testset "Rosenbrock - GPU" begin
                    ros = Rosenbrock()
                    nlp = Optimization.build_model(ros.prob, ros.init, gpu_modeler)
                    sol = CommonSolve.solve(
                        ros.prob, ros.init, gpu_modeler, gpu_solver;
                        display=false
                    )
                    Test.@test sol.status == MadNLP.SOLVE_SUCCEEDED
                    Test.@test sol.solution ≈ ros.sol atol=1e-6
                    Test.@test sol.objective ≈ rosenbrock_objective(ros.sol) atol=1e-6
                end

                Test.@testset "Elec - GPU" begin
                    elec = Elec()
                    sol = CommonSolve.solve(
                        elec.prob, elec.init, gpu_modeler, gpu_solver;
                        display=false
                    )
                    Test.@test sol.status == MadNLP.SOLVE_SUCCEEDED
                    Test.@test isfinite(sol.objective)
                end

                Test.@testset "Max1MinusX2 - GPU" begin
                    max_prob = Max1MinusX2()
                    sol = CommonSolve.solve(
                        max_prob.prob, max_prob.init, gpu_modeler, gpu_solver;
                        display=false
                    )
                    Test.@test sol.status == MadNLP.SOLVE_SUCCEEDED
                    Test.@test length(sol.solution) == 1
                    Test.@test sol.solution[1] ≈ max_prob.sol[1] atol=1e-6
                end
            else
                @info "CUDA not functional, skipping GPU tests."
            end
        end
        
        # ====================================================================
        # INTEGRATION TESTS - Option Aliases
        # ====================================================================
        
        Test.@testset "Option Aliases" begin
            # Test that aliases work for max_iter
            solver1 = Solvers.MadNLPSolver(max_iter=100, print_level=MadNLP.ERROR)
            solver2 = Solvers.MadNLPSolver(maxiter=100, print_level=MadNLP.ERROR)
            
            opts1 = Strategies.options(solver1)
            opts2 = Strategies.options(solver2)
            
            raw1 = Options.extract_raw_options(opts1.options)
            raw2 = Options.extract_raw_options(opts2.options)
            
            # Both should set max_iter
            Test.@test raw1[:max_iter] == 100
            Test.@test raw2[:max_iter] == 100

            # Test aliases for termination options
            solver_acc = Solvers.MadNLPSolver(acc_tol=1e-5, print_level=MadNLP.ERROR)
            solver_time = Solvers.MadNLPSolver(max_time=100.0, print_level=MadNLP.ERROR)

            raw_acc = Options.extract_raw_options(Strategies.options(solver_acc).options)
            raw_time = Options.extract_raw_options(Strategies.options(solver_time).options)

            Test.@test raw_acc[:acceptable_tol] == 1e-5
            Test.@test raw_time[:max_wall_time] == 100.0
        end

        # ====================================================================
        # UNIT TESTS - Option Validation
        # ====================================================================

        Test.@testset "Termination Options Validation" begin
            # Test invalid values throw IncorrectArgument (suppress error messages)
            redirect_stderr(devnull) do
                Test.@test_throws CTBase.Exceptions.IncorrectArgument Solvers.MadNLPSolver(acceptable_tol=-1.0)
                Test.@test_throws CTBase.Exceptions.IncorrectArgument Solvers.MadNLPSolver(acceptable_tol=0.0)
                Test.@test_throws CTBase.Exceptions.IncorrectArgument Solvers.MadNLPSolver(acceptable_iter=0)
                Test.@test_throws CTBase.Exceptions.IncorrectArgument Solvers.MadNLPSolver(max_wall_time=-1.0)
                Test.@test_throws CTBase.Exceptions.IncorrectArgument Solvers.MadNLPSolver(max_wall_time=0.0)
                Test.@test_throws CTBase.Exceptions.IncorrectArgument Solvers.MadNLPSolver(diverging_iterates_tol=-1.0)
                Test.@test_throws CTBase.Exceptions.IncorrectArgument Solvers.MadNLPSolver(diverging_iterates_tol=0.0)
            end

            # Test valid values work (suppress solver output)
            Test.@test_nowarn Solvers.MadNLPSolver(acceptable_tol=1e-5, acceptable_iter=10, print_level=MadNLP.ERROR)
            Test.@test_nowarn Solvers.MadNLPSolver(max_wall_time=60.0, print_level=MadNLP.ERROR)
            Test.@test_nowarn Solvers.MadNLPSolver(diverging_iterates_tol=1e10, print_level=MadNLP.ERROR)
        end

        Test.@testset "NLP Scaling Options Validation" begin
            # Test valid values
            Test.@test_nowarn Solvers.MadNLPSolver(nlp_scaling=true, print_level=MadNLP.ERROR)
            Test.@test_nowarn Solvers.MadNLPSolver(nlp_scaling_max_gradient=100.0, print_level=MadNLP.ERROR)
            Test.@test_nowarn Solvers.MadNLPSolver(jacobian_constant=true, print_level=MadNLP.ERROR)
            Test.@test_nowarn Solvers.MadNLPSolver(hessian_constant=true, print_level=MadNLP.ERROR)

            # Test aliases
            Test.@test_nowarn Solvers.MadNLPSolver(jacobian_cst=true, print_level=MadNLP.ERROR)
            Test.@test_nowarn Solvers.MadNLPSolver(hessian_cst=true, print_level=MadNLP.ERROR)

            # Test invalid values (suppress error messages)
            redirect_stderr(devnull) do
                Test.@test_throws CTBase.Exceptions.IncorrectArgument Solvers.MadNLPSolver(nlp_scaling_max_gradient=-1.0)
                Test.@test_throws CTBase.Exceptions.IncorrectArgument Solvers.MadNLPSolver(nlp_scaling_max_gradient=0.0)
            end
        end

        Test.@testset "Initialization Options Validation" begin
            # Test valid values
            Test.@test_nowarn Solvers.MadNLPSolver(bound_push=0.01, print_level=MadNLP.ERROR)
            Test.@test_nowarn Solvers.MadNLPSolver(bound_fac=0.01, print_level=MadNLP.ERROR)
            Test.@test_nowarn Solvers.MadNLPSolver(constr_mult_init_max=1000.0, print_level=MadNLP.ERROR)

            # Test Type values
            Test.@test_nowarn Solvers.MadNLPSolver(fixed_variable_treatment=MadNLP.MakeParameter, print_level=MadNLP.ERROR)
            Test.@test_nowarn Solvers.MadNLPSolver(equality_treatment=MadNLP.RelaxEquality, print_level=MadNLP.ERROR)

            # Test invalid values (suppress error messages)
            redirect_stderr(devnull) do
                Test.@test_throws CTBase.Exceptions.IncorrectArgument Solvers.MadNLPSolver(bound_push=-1.0)
                Test.@test_throws CTBase.Exceptions.IncorrectArgument Solvers.MadNLPSolver(bound_push=0.0)

                Test.@test_throws CTBase.Exceptions.IncorrectArgument Solvers.MadNLPSolver(bound_fac=-1.0)
                Test.@test_throws CTBase.Exceptions.IncorrectArgument Solvers.MadNLPSolver(bound_fac=0.0)

                Test.@test_throws CTBase.Exceptions.IncorrectArgument Solvers.MadNLPSolver(constr_mult_init_max=-1.0)
            end
        end
        
        Test.@testset "Advanced Options Validation" begin
            # Test valid type values
            Test.@test_nowarn Solvers.MadNLPSolver(kkt_system=MadNLP.SparseKKTSystem, print_level=MadNLP.ERROR)
            Test.@test_nowarn Solvers.MadNLPSolver(hessian_approximation=MadNLP.BFGS, print_level=MadNLP.ERROR)
            Test.@test_nowarn Solvers.MadNLPSolver(inertia_correction_method=MadNLP.InertiaAuto, print_level=MadNLP.ERROR)

            # Test valid real values
            Test.@test_nowarn Solvers.MadNLPSolver(mu_init=1e-3, print_level=MadNLP.ERROR)
            Test.@test_nowarn Solvers.MadNLPSolver(mu_min=1e-9, print_level=MadNLP.ERROR)
            Test.@test_nowarn Solvers.MadNLPSolver(tau_min=0.99, print_level=MadNLP.ERROR)

            # Test invalid values (expect exceptions for type mismatches)
            redirect_stderr(devnull) do
                Test.@test_throws CTBase.Exceptions.IncorrectArgument Solvers.MadNLPSolver(kkt_system=1)
                Test.@test_throws CTBase.Exceptions.IncorrectArgument Solvers.MadNLPSolver(hessian_approximation=1.0)
                Test.@test_throws CTBase.Exceptions.IncorrectArgument Solvers.MadNLPSolver(inertia_correction_method="invalid")

                Test.@test_throws CTBase.Exceptions.IncorrectArgument Solvers.MadNLPSolver(mu_init=-1.0)
                Test.@test_throws CTBase.Exceptions.IncorrectArgument Solvers.MadNLPSolver(mu_init=0.0)

                Test.@test_throws CTBase.Exceptions.IncorrectArgument Solvers.MadNLPSolver(mu_min=-1.0)
                Test.@test_throws CTBase.Exceptions.IncorrectArgument Solvers.MadNLPSolver(mu_min=0.0)

                Test.@test_throws CTBase.Exceptions.IncorrectArgument Solvers.MadNLPSolver(tau_min=-0.1)
                Test.@test_throws CTBase.Exceptions.IncorrectArgument Solvers.MadNLPSolver(tau_min=1.1)
            end
        end

        # ====================================================================
        # INTEGRATION TESTS - Multiple Solves
        # ====================================================================
        
        Test.@testset "Multiple Solves" begin
            solver = Solvers.MadNLPSolver(
                max_iter=1000,
                tol=1e-6,
                print_level=MadNLP.ERROR
            )
            
            # Solve different problems with same solver
            ros = Rosenbrock()
            max_prob = Max1MinusX2()
            
            # Build NLP models
            adnlp_builder = CTSolvers.get_adnlp_model_builder(ros.prob)
            nlp1 = adnlp_builder(ros.init)
            
            adnlp_builder2 = CTSolvers.get_adnlp_model_builder(max_prob.prob)
            nlp2 = adnlp_builder2(max_prob.init)
            
            stats1 = solver(nlp1; display=false)
            stats2 = solver(nlp2; display=false)
            
            Test.@test Symbol(stats1.status) in (:SOLVE_SUCCEEDED, :SOLVED_TO_ACCEPTABLE_LEVEL)
            Test.@test Symbol(stats2.status) in (:SOLVE_SUCCEEDED, :SOLVED_TO_ACCEPTABLE_LEVEL)
        end
        
        # ====================================================================
        # INTEGRATION TESTS - Initial Guess with Linear Solvers (max_iter=0)
        # ====================================================================
        
        Test.@testset "Initial Guess - Linear Solvers" begin
            BaseType = Float32
            modelers = [Modelers.ADNLPModeler(), Modelers.ExaModeler(; base_type=BaseType)]
            modelers_names = ["ADNLPModeler", "ExaModeler (CPU)"]
            linear_solvers = [MadNLP.UmfpackSolver, MadNLPMumps.MumpsSolver]
            linear_solver_names = ["Umfpack", "Mumps"]
            
            # Rosenbrock: start at the known solution and enforce max_iter=0
            Test.@testset "Rosenbrock" verbose=VERBOSE showtiming=SHOWTIMING begin
                ros = Rosenbrock()
                for (modeler, modeler_name) in zip(modelers, modelers_names)
                    for (linear_solver, linear_solver_name) in zip(linear_solvers, linear_solver_names)
                        Test.@testset "$(modeler_name), $(linear_solver_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                            local opts = Dict(:max_iter => 0, :print_level => MadNLP.ERROR)
                            sol = CommonSolve.solve(
                                ros.prob,
                                ros.sol,
                                modeler,
                                Solvers.MadNLPSolver(; opts..., linear_solver=linear_solver),
                            )
                            Test.@test sol.status == MadNLP.MAXIMUM_ITERATIONS_EXCEEDED
                            Test.@test sol.solution ≈ ros.sol atol=1e-6
                        end
                    end
                end
            end
            
            # Elec
            Test.@testset "Elec" verbose=VERBOSE showtiming=SHOWTIMING begin
                elec = Elec()
                for (modeler, modeler_name) in zip(modelers, modelers_names)
                    for (linear_solver, linear_solver_name) in zip(linear_solvers, linear_solver_names)
                        Test.@testset "$(modeler_name), $(linear_solver_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                            local opts = Dict(:max_iter => 0, :print_level => MadNLP.ERROR)
                            sol = CommonSolve.solve(
                                elec.prob,
                                elec.init,
                                modeler,
                                Solvers.MadNLPSolver(; opts..., linear_solver=linear_solver),
                            )
                            Test.@test sol.status == MadNLP.MAXIMUM_ITERATIONS_EXCEEDED
                            Test.@test sol.solution ≈ vcat(elec.init.x, elec.init.y, elec.init.z) atol=1e-6
                        end
                    end
                end
            end
        end
        
        # ====================================================================
        # INTEGRATION TESTS - solve_with_madnlp (direct function)
        # ====================================================================
        
        Test.@testset "solve_with_madnlp Function" begin
            BaseType = Float32
            modelers = [Modelers.ADNLPModeler(), Modelers.ExaModeler(; base_type=BaseType)]
            modelers_names = ["ADNLPModeler", "ExaModeler (CPU)"]
            madnlp_options = Dict(:max_iter => 1000, :tol => 1e-6, :print_level => MadNLP.ERROR)
            linear_solvers = [MadNLP.UmfpackSolver, MadNLPMumps.MumpsSolver]
            linear_solver_names = ["Umfpack", "Mumps"]
            
            Test.@testset "Rosenbrock" verbose=VERBOSE showtiming=SHOWTIMING begin
                ros = Rosenbrock()
                for (modeler, modeler_name) in zip(modelers, modelers_names)
                    for (linear_solver, linear_solver_name) in zip(linear_solvers, linear_solver_names)
                        Test.@testset "$(modeler_name), $(linear_solver_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                            nlp = Optimization.build_model(ros.prob, ros.init, modeler)
                            sol = CTSolversMadNLP.solve_with_madnlp(nlp; linear_solver=linear_solver, madnlp_options...)
                            Test.@test sol.status == MadNLP.SOLVE_SUCCEEDED
                            Test.@test sol.solution ≈ ros.sol atol=1e-6
                            Test.@test sol.objective ≈ rosenbrock_objective(ros.sol) atol=1e-6
                        end
                    end
                end
            end
            
            Test.@testset "Elec" verbose=VERBOSE showtiming=SHOWTIMING begin
                elec = Elec()
                for (modeler, modeler_name) in zip(modelers, modelers_names)
                    for (linear_solver, linear_solver_name) in zip(linear_solvers, linear_solver_names)
                        Test.@testset "$(modeler_name), $(linear_solver_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                            nlp = Optimization.build_model(elec.prob, elec.init, modeler)
                            sol = CTSolversMadNLP.solve_with_madnlp(nlp; linear_solver=linear_solver, madnlp_options...)
                            Test.@test sol.status == MadNLP.SOLVE_SUCCEEDED
                        end
                    end
                end
            end
            
            Test.@testset "Max1MinusX2" verbose=VERBOSE showtiming=SHOWTIMING begin
                max_prob = Max1MinusX2()
                for (modeler, modeler_name) in zip(modelers, modelers_names)
                    for (linear_solver, linear_solver_name) in zip(linear_solvers, linear_solver_names)
                        Test.@testset "$(modeler_name), $(linear_solver_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                            nlp = Optimization.build_model(max_prob.prob, max_prob.init, modeler)
                            sol = CTSolversMadNLP.solve_with_madnlp(nlp; linear_solver=linear_solver, madnlp_options...)
                            Test.@test sol.status == MadNLP.SOLVE_SUCCEEDED
                            Test.@test length(sol.solution) == 1
                            Test.@test sol.solution[1] ≈ max_prob.sol[1] atol=1e-6
                            # MadNLP inverts sign for maximization
                            Test.@test -sol.objective ≈ max1minusx2_objective(max_prob.sol) atol=1e-6
                        end
                    end
                end
            end
        end
        
        # ====================================================================
        # INTEGRATION TESTS - GPU solve_with_madnlp (direct function)
        # ====================================================================
        
        Test.@testset "GPU - solve_with_madnlp" begin
            if is_cuda_on()
                gpu_modeler = Modelers.ExaModeler(backend=CUDA.CUDABackend())
                madnlp_options = Dict(
                    :max_iter => 1000,
                    :tol => 1e-6,
                    :print_level => MadNLP.ERROR,
                    :linear_solver => MadNLPGPU.CUDSSSolver
                )

                Test.@testset "Rosenbrock - GPU" begin
                    ros = Rosenbrock()
                    nlp = Optimization.build_model(ros.prob, ros.init, gpu_modeler)
                    sol = CTSolversMadNLP.solve_with_madnlp(nlp; madnlp_options...)
                    Test.@test sol.status == MadNLP.SOLVE_SUCCEEDED
                    Test.@test sol.solution ≈ ros.sol atol=1e-6
                    Test.@test sol.objective ≈ rosenbrock_objective(ros.sol) atol=1e-6
                end

                Test.@testset "Elec - GPU" begin
                    elec = Elec()
                    nlp = Optimization.build_model(elec.prob, elec.init, gpu_modeler)
                    sol = CTSolversMadNLP.solve_with_madnlp(nlp; madnlp_options...)
                    Test.@test sol.status == MadNLP.SOLVE_SUCCEEDED
                    Test.@test isfinite(sol.objective)
                end

                Test.@testset "Max1MinusX2 - GPU" begin
                    max_prob = Max1MinusX2()
                    nlp = Optimization.build_model(max_prob.prob, max_prob.init, gpu_modeler)
                    sol = CTSolversMadNLP.solve_with_madnlp(nlp; madnlp_options...)
                    Test.@test sol.status == MadNLP.SOLVE_SUCCEEDED
                    Test.@test length(sol.solution) == 1
                    Test.@test sol.solution[1] ≈ max_prob.sol[1] atol=1e-6
                end
            else
                @info "CUDA not functional, skipping GPU solve_with_madnlp tests."
            end
        end

        # ====================================================================
        # INTEGRATION TESTS - GPU Initial Guess (max_iter=0)
        # ====================================================================

        Test.@testset "GPU - Initial Guess (max_iter=0)" begin
            if is_cuda_on()
                gpu_modeler = Modelers.ExaModeler(backend=CUDA.CUDABackend())
                gpu_solver_0 = Solvers.MadNLPSolver(
                    max_iter=0,
                    print_level=MadNLP.ERROR,
                    linear_solver=MadNLPGPU.CUDSSSolver
                )

                Test.@testset "Rosenbrock - GPU" begin
                    ros = Rosenbrock()
                    sol = CommonSolve.solve(
                        ros.prob, ros.sol, gpu_modeler, gpu_solver_0;
                        display=false
                    )
                    Test.@test sol.status == MadNLP.MAXIMUM_ITERATIONS_EXCEEDED
                    Test.@test sol.solution ≈ ros.sol atol=1e-6
                end

                Test.@testset "Elec - GPU" begin
                    elec = Elec()
                    sol = CommonSolve.solve(
                        elec.prob, elec.init, gpu_modeler, gpu_solver_0;
                        display=false
                    )
                    Test.@test sol.status == MadNLP.MAXIMUM_ITERATIONS_EXCEEDED
                    expected = vcat(elec.init.x, elec.init.y, elec.init.z)
                    Test.@test sol.solution ≈ expected atol=1e-6
                end
            else
                @info "CUDA not functional, skipping GPU initial guess tests."
            end
        end
    end
end

end # module

test_madnlp_extension() = TestMadNLPExtension.test_madnlp_extension()
