# Unit tests for Collocation discretizer wiring from OCP to discretized OCP and builders.
struct DummyOCPCollocation <: CTSolvers.AbstractOptimalControlProblem end

struct DummyOCPExaRouting <: CTSolvers.AbstractOptimalControlProblem end

struct DummyDOCPCollocationRouting end

function test_ctdirect_collocation_impl()

    Test.@testset "Collocation as discretizer" verbose=VERBOSE showtiming=SHOWTIMING begin
        ocp = DummyOCPCollocation()

        # Use the default Collocation discretizer to avoid relying on CTDirect
        discretizer = CTSolvers.__discretizer()
        Test.@test discretizer isa CTSolvers.Collocation

        docp = discretizer(ocp)

        # The call operator on Collocation should return a DiscretizedOptimalControlProblem
        Test.@test docp isa CTSolvers.DiscretizedOptimalControlProblem
        Test.@test CTSolvers.ocp_model(docp) === ocp

        # The model and solution builders should be correctly wired with both
        # ADNLP and Exa backends present.
        adnlp_builder = CTSolvers.get_adnlp_model_builder(docp)
        exa_builder   = CTSolvers.get_exa_model_builder(docp)
        adnlp_sol     = CTSolvers.get_adnlp_solution_builder(docp)
        exa_sol       = CTSolvers.get_exa_solution_builder(docp)

        Test.@test adnlp_builder isa CTSolvers.ADNLPModelBuilder
        Test.@test exa_builder   isa CTSolvers.ExaModelBuilder
        Test.@test adnlp_sol     isa CTSolvers.ADNLPSolutionBuilder
        Test.@test exa_sol       isa CTSolvers.ExaSolutionBuilder
    end

    Test.@testset "Exa backend routing" verbose=VERBOSE showtiming=SHOWTIMING begin
        ocp = DummyOCPExaRouting()

        # Stub CTDirect.direct_transcription for DummyOCPExaRouting to record kwargs
        recorded = Ref{Any}(nothing)

        function CTDirect.direct_transcription(
            ocp::DummyOCPExaRouting,
            modeler::Symbol;
            grid_size,
            disc_method,
            init,
            lagrange_to_mayer,
            kwargs...,
        )
            recorded[] = (
                ocp=ocp,
                modeler=modeler,
                grid_size=grid_size,
                disc_method=disc_method,
                init=init,
                lagrange_to_mayer=lagrange_to_mayer,
                kwargs=NamedTuple(kwargs),
            )
            return DummyDOCPCollocationRouting()
        end

        function CTDirect.nlp_model(::DummyDOCPCollocationRouting)
            return :dummy_nlp
        end

        discretizer = CTSolvers.Collocation()
        docp = discretizer(ocp)

        exa_builder = CTSolvers.get_exa_model_builder(docp)

        # Minimal initial guess: functions for state/control and empty variable
        init_guess = CTSolvers.OptimalControlInitialGuess(t -> 0.0, t -> 0.0, Float64[])

        BaseType = Float32
        _ = exa_builder(BaseType, init_guess; backend=:gpu, foo=1)

        rec = recorded[]
        Test.@test rec !== nothing
        Test.@test rec[:modeler] === :exa

        kw = rec[:kwargs]
        # backend should have been rerouted to exa_backend
        Test.@test haskey(kw, :exa_backend)
        Test.@test kw[:exa_backend] === :gpu
        # original backend key should not be forwarded
        Test.@test !haskey(kw, :backend)
        # other kwargs are preserved
        Test.@test haskey(kw, :foo)
        Test.@test kw[:foo] == 1
    end

end

