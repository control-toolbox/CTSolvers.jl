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

    Test.@testset "optimalcontrol/solve_api: raw defaults" verbose=VERBOSE showtiming=SHOWTIMING begin
        Test.@test CTSolvers.__initial_guess() === nothing
    end

    Test.@testset "optimalcontrol/solve_api: description helpers" verbose=VERBOSE showtiming=SHOWTIMING begin
        methods = CTSolvers.available_methods()
        Test.@test !isempty(methods)

        first_method = methods[1]
        Test.@test first_method[1] === :collocation
        Test.@test any(m -> m[1] === :collocation && (:adnlp in m) && (:ipopt in m), methods)

        # Partial descriptions are completed using CTBase.complete with priority order.
        method_from_disc = CTBase.complete(:collocation; descriptions=methods)
        Test.@test :collocation in method_from_disc

        method_from_solver = CTBase.complete(:ipopt; descriptions=methods)
        Test.@test :ipopt in method_from_solver

        # Discretizer options registry: keys inferred from the Collocation tool
        method = (:collocation, :adnlp, :ipopt)
        keys_from_method = CTSolvers._discretizer_options_keys(method)
        keys_from_type   = CTSolvers.options_keys(CTSolvers.Collocation)
        Test.@test keys_from_method == keys_from_type

        # Discretizer symbol helper
        for m in methods
            Test.@test CTSolvers._get_discretizer_symbol(m) === :collocation
        end

        # Error when no discretizer symbol is present in the method
        Test.@test_throws CTBase.IncorrectArgument CTSolvers._get_discretizer_symbol((:adnlp, :ipopt))

        # Modeler and solver symbol helpers using registries
        for m in methods
            msym = CTSolvers._get_modeler_symbol(m)
            Test.@test msym in CTSolvers.modeler_symbols()
            ssym = CTSolvers._get_solver_symbol(m)
            Test.@test ssym in CTSolvers.solver_symbols()
        end

        # _modeler_options_keys / _solver_options_keys should match options_keys
        method_ad_ip = (:collocation, :adnlp, :ipopt)
        Test.@test Set(CTSolvers._modeler_options_keys(method_ad_ip)) ==
                   Set(CTSolvers.options_keys(CTSolvers.ADNLPModeler))
        Test.@test Set(CTSolvers._solver_options_keys(method_ad_ip)) ==
                   Set(CTSolvers.options_keys(CTSolvers.IpoptSolver))

        method_exa_mad = (:collocation, :exa, :madnlp)
        Test.@test Set(CTSolvers._modeler_options_keys(method_exa_mad)) ==
                   Set(CTSolvers.options_keys(CTSolvers.ExaModeler))
        Test.@test Set(CTSolvers._solver_options_keys(method_exa_mad)) ==
                   Set(CTSolvers.options_keys(CTSolvers.MadNLPSolver))

        # Multiple symbols of the same family in a method should raise an error
        Test.@test_throws CTBase.IncorrectArgument CTSolvers._get_modeler_symbol((:collocation, :adnlp, :exa, :ipopt))
        Test.@test_throws CTBase.IncorrectArgument CTSolvers._get_solver_symbol((:collocation, :adnlp, :ipopt, :madnlp))

        # _build_modeler_from_method should construct the appropriate modeler
        m_ad = CTSolvers._build_modeler_from_method((:collocation, :adnlp, :ipopt), (; backend=:manual))
        Test.@test m_ad isa CTSolvers.ADNLPModeler

        m_exa = CTSolvers._build_modeler_from_method((:collocation, :exa, :ipopt), NamedTuple())
        Test.@test m_exa isa CTSolvers.ExaModeler

        # _build_solver_from_method should construct the appropriate solver
        s_ip = CTSolvers._build_solver_from_method((:collocation, :adnlp, :ipopt), NamedTuple())
        Test.@test s_ip isa CTSolvers.IpoptSolver

        s_mad = CTSolvers._build_solver_from_method((:collocation, :adnlp, :madnlp), NamedTuple())
        Test.@test s_mad isa CTSolvers.MadNLPSolver

        # Modeler options normalization helper
        Test.@test CTSolvers._normalize_modeler_options(nothing) === NamedTuple()
        Test.@test CTSolvers._normalize_modeler_options((backend=:manual,)) == (backend=:manual,)
        Test.@test CTSolvers._normalize_modeler_options((; backend=:manual)) == (backend=:manual,)
    end

    Test.@testset "optimalcontrol/solve_api: option routing helpers" verbose=VERBOSE showtiming=SHOWTIMING begin
        # _extract_option_tool without explicit tool tag
        v, tool = CTSolvers._extract_option_tool(1.0)
        Test.@test v == 1.0
        Test.@test tool === nothing

        # _extract_option_tool with explicit tool tag
        v2, tool2 = CTSolvers._extract_option_tool((42, :solver))
        Test.@test v2 == 42
        Test.@test tool2 === :solver

        # Non-ambiguous routing: single owner
        v3, owner3 = CTSolvers._route_option_for_description(:tol, 1e-6, Symbol[:solver], :description)
        Test.@test v3 == 1e-6
        Test.@test owner3 === :solver

        # Unknown ownership: empty owner list
        owners_empty = Symbol[]
        Test.@test_throws CTBase.IncorrectArgument CTSolvers._route_option_for_description(:foo, 1, owners_empty, :description)

        # Ambiguous ownership in description mode
        owners_amb = Symbol[:discretizer, :solver]
        err = nothing
        try
            CTSolvers._route_option_for_description(:foo, 1.0, owners_amb, :description)
        catch e
            err = e
        end
        Test.@test err isa CTBase.IncorrectArgument

        # Disambiguation via (value, tool)
        v4, owner4 = CTSolvers._route_option_for_description(:foo, (2.0, :solver), owners_amb, :description)
        Test.@test v4 == 2.0
        Test.@test owner4 === :solver

        # Ambiguous when coming from explicit mode should also throw
        Test.@test_throws CTBase.IncorrectArgument CTSolvers._route_option_for_description(:foo, 1.0, owners_amb, :explicit)
    end

    Test.@testset "optimalcontrol/solve_api: display helpers" verbose=VERBOSE showtiming=SHOWTIMING begin
        method = (:collocation, :adnlp, :ipopt)
        discretizer = CTSolvers.Collocation()
        modeler = CTSolvers.ADNLPModeler()
        solver = CTSolvers.IpoptSolver()

        buf = sprint() do io
            redirect_stdout(io) do
                CTSolvers._display_ocp_method(
                    method,
                    discretizer,
                    modeler,
                    solver;
                    display=true,
                )
            end
        end
        Test.@test occursin("ADNLPModels", buf)
        Test.@test occursin("NLPModelsIpopt", buf)
    end

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

        sol = CTSolvers._solve(prob, init, discretizer, modeler, solver; display=false)

        Test.@test sol isa OCDummySolution
        Test.@test discretizer_calls[] == 1
        Test.@test model_calls[] == 1
        Test.@test solver_calls[] == 1
        Test.@test solution_calls[] == 1
    end

    Test.@testset "optimalcontrol/solve_api: explicit-mode kwarg validation" verbose=VERBOSE showtiming=SHOWTIMING begin
        prob = OCDummyOCP()
        init = OCDummyInit([1.0, 2.0])

        discretizer_calls = Ref(0)
        model_calls = Ref(0)
        solution_calls = Ref(0)
        solver_calls = Ref(0)

        discretizer = OCFakeDiscretizer(discretizer_calls)
        modeler = OCFakeModeler(model_calls, solution_calls)
        solver = OCFakeSolverNLP(solver_calls)

        # modeler_options is forbidden in explicit mode
        Test.@test_throws CTBase.IncorrectArgument begin
            CommonSolve.solve(
                prob;
                initial_guess=init,
                discretizer=discretizer,
                modeler=modeler,
                solver=solver,
                display=false,
                modeler_options=(backend=:manual,),
            )
        end

        # Unknown kwargs are rejected in explicit mode
        Test.@test_throws CTBase.IncorrectArgument begin
            CommonSolve.solve(
                prob;
                initial_guess=init,
                discretizer=discretizer,
                modeler=modeler,
                solver=solver,
                display=false,
                unknown_kwarg=1,
            )
        end

        # Mixing description with explicit components is rejected
        Test.@test_throws CTBase.IncorrectArgument begin
            CommonSolve.solve(
                prob,
                :collocation;
                initial_guess=init,
                discretizer=discretizer,
                display=false,
            )
        end
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
                    sol = CTSolvers._solve(ocp, init, discretizer, modeler, solver; display=false)
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
                    sol = CTSolvers._solve(ocp, init, discretizer, modeler, solver; display=false)
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
            sol = CTSolvers._solve(ocp, init_macro, discretizer, modeler, solver; display=false)
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

        # ------------------------------------------------------------------
        # OCP level: description-based API CommonSolve.solve(ocp, description; ...)
        # ------------------------------------------------------------------

        Test.@testset "OCP level description API" verbose=VERBOSE showtiming=SHOWTIMING begin

            desc_cases = [
                ((:collocation, :adnlp, :ipopt), ipopt_options),
                ((:collocation, :adnlp, :madnlp), madnlp_options),
                ((:collocation, :exa,   :ipopt), ipopt_options),
                ((:collocation, :exa,   :madnlp), madnlp_options),
            ]

            for (method_syms, options) in desc_cases
                Test.@testset "description = $(method_syms)" verbose=VERBOSE showtiming=SHOWTIMING begin
                    sol = CommonSolve.solve(
                        ocp,
                        method_syms...;
                        initial_guess=init,
                        display=false,
                        options...,
                    )
                    Test.@test sol isa CTModels.Solution
                    Test.@test CTModels.successful(sol)
                    Test.@test isfinite(CTModels.objective(sol))

                    if :ipopt in method_syms
                        Test.@test CTModels.iterations(sol) <= ipopt_options[:max_iter]
                        Test.@test CTModels.constraints_violation(sol) <= 1e-6
                    elseif :madnlp in method_syms
                        Test.@test CTModels.iterations(sol) <= madnlp_options[:max_iter]
                        Test.@test CTModels.constraints_violation(sol) <= 1e-6
                    end
                end
            end

            # modeler_options is allowed in description mode and forwarded to the
            # modeler constructor.
            Test.@testset "description API with modeler_options" verbose=VERBOSE showtiming=SHOWTIMING begin
                sol = CommonSolve.solve(
                    ocp,
                    :collocation,
                    :adnlp,
                    :ipopt;
                    initial_guess=init,
                    modeler_options=(backend=:manual,),
                    display=false,
                    ipopt_options...,
                )
                Test.@test sol isa CTModels.Solution
                Test.@test CTModels.successful(sol)
            end

            # Tagged options using the (value, tool) convention: discretizer options
            # are explicitly routed to the discretizer, and Ipopt options to the solver.
            Test.@testset "description API with explicit tool tags" verbose=VERBOSE showtiming=SHOWTIMING begin
                sol = CommonSolve.solve(
                    ocp,
                    :collocation,
                    :adnlp,
                    :ipopt;
                    initial_guess=init,
                    display=false,
                    # Discretizer options
                    grid_size=(CTSolvers.get_option_value(discretizer, :grid_size), :discretizer),
                    scheme=(CTSolvers.get_option_value(discretizer, :scheme), :discretizer),
                    # Ipopt solver options
                    max_iter=(ipopt_options[:max_iter], :solver),
                    tol=(ipopt_options[:tol], :solver),
                    print_level=(ipopt_options[:print_level], :solver),
                    mu_strategy=(ipopt_options[:mu_strategy], :solver),
                    linear_solver=(ipopt_options[:linear_solver], :solver),
                    sb=(ipopt_options[:sb], :solver),
                )
                Test.@test sol isa CTModels.Solution
                Test.@test CTModels.successful(sol)
                Test.@test isfinite(CTModels.objective(sol))
                Test.@test CTModels.iterations(sol) <= ipopt_options[:max_iter]
                Test.@test CTModels.constraints_violation(sol) <= 1e-6
            end
        end

    end

end
