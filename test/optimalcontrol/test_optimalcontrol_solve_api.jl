# Optimal control-level tests for CommonSolve.solve on OCPs.

struct OCDummyOCP <: CTSolvers.AbstractOptimalControlProblem end

struct OCDummyDiscretizedOCP <: CTSolvers.AbstractOptimizationProblem end

struct OCDummyInit <: CTSolvers.AbstractOptimalControlInitialGuess
    x0::Vector{Float64}
end

struct OCDummyStats <: SolverCore.AbstractExecutionStats
    tag::Symbol
end

struct OCDummySolution <: CTSolvers.AbstractOptimalControlSolution end

struct OCFakeDiscretizer <: CTSolvers.AbstractOptimalControlDiscretizer
    calls::Base.RefValue{Int}
end

function (d::OCFakeDiscretizer)(
    ocp::CTSolvers.AbstractOptimalControlProblem,
)
    d.calls[] += 1
    return OCDummyDiscretizedOCP()
end

struct OCFakeModeler <: CTSolvers.AbstractOptimizationModeler
    model_calls::Base.RefValue{Int}
    solution_calls::Base.RefValue{Int}
end

function (m::OCFakeModeler)(
    prob::CTSolvers.AbstractOptimizationProblem,
    init::OCDummyInit,
)::NLPModels.AbstractNLPModel
    m.model_calls[] += 1
    f(z) = sum(z .^ 2)
    return ADNLPModels.ADNLPModel(f, init.x0)
end

function (m::OCFakeModeler)(
    prob::CTSolvers.AbstractOptimizationProblem,
    nlp_solution::SolverCore.AbstractExecutionStats,
)
    m.solution_calls[] += 1
    return OCDummySolution()
end

struct OCFakeSolverNLP <: CTSolvers.AbstractOptimizationSolver
    calls::Base.RefValue{Int}
end

function (s::OCFakeSolverNLP)(
    nlp::NLPModels.AbstractNLPModel;
    display::Bool,
)::SolverCore.AbstractExecutionStats
    s.calls[] += 1
    return OCDummyStats(:solver_called)
end

function test_optimalcontrol_solve_api()

    # ========================================================================
    # Unit test: CommonSolve.solve(ocp, init, discretizer, modeler, solver)
    # ========================================================================

    Test.@testset "optimalcontrol/solve_api: solve(ocp, init, discretizer, modeler, solver)" verbose=VERBOSE showtiming=SHOWTIMING begin
        prob = OCDummyOCP()
        init = OCDummyInit([1.0, 2.0])

        discretizer_calls = Ref(0)
        model_calls = Ref(0)
        solution_calls = Ref(0)
        solver_calls = Ref(0)

        discretizer = OCFakeDiscretizer(discretizer_calls)
        modeler = OCFakeModeler(model_calls, solution_calls)
        solver = OCFakeSolverNLP(solver_calls)

        sol = CommonSolve.solve(prob, init, discretizer, modeler, solver; display=false)

        Test.@test sol isa OCDummySolution
        Test.@test discretizer_calls[] == 1
        Test.@test model_calls[] == 1
        Test.@test solver_calls[] == 1
        Test.@test solution_calls[] == 1
    end

    Test.@testset "optimalcontrol/solve_api: solve(ocp; kwargs)" verbose=VERBOSE showtiming=SHOWTIMING begin
        prob = OCDummyOCP()
        init = OCDummyInit([1.0, 2.0])

        discretizer_calls = Ref(0)
        model_calls = Ref(0)
        solution_calls = Ref(0)
        solver_calls = Ref(0)

        discretizer = OCFakeDiscretizer(discretizer_calls)
        modeler = OCFakeModeler(model_calls, solution_calls)
        solver = OCFakeSolverNLP(solver_calls)

        sol = CommonSolve.solve(
            prob;
            initial_guess=init,
            discretizer=discretizer,
            modeler=modeler,
            solver=solver,
            display=false,
        )

        Test.@test sol isa OCDummySolution
        Test.@test discretizer_calls[] == 1
        Test.@test model_calls[] == 1
        Test.@test solver_calls[] == 1
        Test.@test solution_calls[] == 1
    end

    # ========================================================================
    # Integration tests: Beam OCP level with Ipopt and MadNLP
    # ========================================================================

    Test.@testset "optimalcontrol/solve_api: Beam OCP level" verbose=VERBOSE showtiming=SHOWTIMING begin

        ipopt_options = Dict(
            :max_iter => 1000,
            :tol => 1e-6,
            :print_level => 0,
            :mu_strategy => "adaptive",
            :linear_solver => "Mumps",
            :sb => "yes",
        )

        madnlp_options = Dict(
            :max_iter => 1000,
            :tol => 1e-6,
            :print_level => MadNLP.ERROR,
        )

        ocp, init = beam()
        discretizer = CTSolvers.Collocation()

        modelers = [
            CTSolvers.ADNLPModeler(; backend=:manual),
            CTSolvers.ExaModeler(),
        ]
        modelers_names = ["ADNLPModeler (manual)", "ExaModeler (CPU)"]

        # ------------------------------------------------------------------
        # OCP level: CommonSolve.solve(ocp, init, discretizer, modeler, solver)
        # ------------------------------------------------------------------

        Test.@testset "OCP level (Ipopt)" verbose=VERBOSE showtiming=SHOWTIMING begin
            for (modeler, modeler_name) in zip(modelers, modelers_names)
                Test.@testset "$(modeler_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                    solver = CTSolvers.IpoptSolver(; ipopt_options...)
                    sol = CommonSolve.solve(ocp, init, discretizer, modeler, solver; display=false)
                    Test.@test sol isa CTModels.Solution
                    Test.@test CTModels.successful(sol)
                    Test.@test isfinite(CTModels.objective(sol))
                    Test.@test CTModels.iterations(sol) <= ipopt_options[:max_iter]
                    Test.@test CTModels.constraints_violation(sol) <= 1e-6
                end
            end
        end

        Test.@testset "OCP level (MadNLP)" verbose=VERBOSE showtiming=SHOWTIMING begin
            for (modeler, modeler_name) in zip(modelers, modelers_names)
                Test.@testset "$(modeler_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                    solver = CTSolvers.MadNLPSolver(; madnlp_options...)
                    sol = CommonSolve.solve(ocp, init, discretizer, modeler, solver; display=false)
                    Test.@test sol isa CTModels.Solution
                    Test.@test CTModels.successful(sol)
                    Test.@test isfinite(CTModels.objective(sol))
                    Test.@test CTModels.iterations(sol) <= madnlp_options[:max_iter]
                    Test.@test CTModels.constraints_violation(sol) <= 1e-6
                end
            end
        end

        # ------------------------------------------------------------------
        # OCP level with @init (Ipopt, ADNLPModeler)
        # ------------------------------------------------------------------

        Test.@testset "OCP level with @init (Ipopt, ADNLPModeler)" verbose=VERBOSE showtiming=SHOWTIMING begin
            init_macro = CTSolvers.@init ocp begin
                x := [0.05, 0.1]
                u := 0.1
            end
            modeler = CTSolvers.ADNLPModeler(; backend=:manual)
            solver = CTSolvers.IpoptSolver(; ipopt_options...)
            sol = CommonSolve.solve(ocp, init_macro, discretizer, modeler, solver; display=false)
            Test.@test sol isa CTModels.Solution
            Test.@test CTModels.successful(sol)
            Test.@test isfinite(CTModels.objective(sol))
        end

        # ------------------------------------------------------------------
        # OCP level: keyword-based API CommonSolve.solve(ocp; ...)
        # ------------------------------------------------------------------

        Test.@testset "OCP level keyword API (Ipopt, ADNLPModeler)" verbose=VERBOSE showtiming=SHOWTIMING begin
            modeler = CTSolvers.ADNLPModeler(; backend=:manual)
            solver = CTSolvers.IpoptSolver(; ipopt_options...)
            sol = CommonSolve.solve(
                ocp;
                initial_guess=init,
                discretizer=discretizer,
                modeler=modeler,
                solver=solver,
                display=false,
            )
            Test.@test sol isa CTModels.Solution
            Test.@test CTModels.successful(sol)
            Test.@test isfinite(CTModels.objective(sol))
            Test.@test CTModels.iterations(sol) <= ipopt_options[:max_iter]
            Test.@test CTModels.constraints_violation(sol) <= 1e-6
        end

    end

end
