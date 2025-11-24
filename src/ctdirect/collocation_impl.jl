function (discretizer::Collocation)(ocp::AbstractOptimalControlProblem)

    function get_docp(initial_guess::Union{AbstractOptimalControlInitialGuess, Nothing}, modeler::Symbol; kwargs...)
        scheme_ctdirect = scheme_symbol(discretizer)
        init_ctdirect = (initial_guess === nothing) ? nothing : (state = state(initial_guess), control = control(initial_guess), variable = variable(initial_guess))

        if modeler == :exa && haskey(kwargs, :backend)
            # Route ExaModeler backend to CTDirect via exa_backend and drop backend from forwarded kwargs.
            exa_backend = kwargs[:backend]
            filtered_kwargs = (; (k => v for (k, v) in pairs(kwargs) if k != :backend)...)
            docp = CTDirect.direct_transcription(
                ocp,
                modeler;
                grid_size=CTSolvers.grid_size(discretizer),
                scheme=scheme_ctdirect,
                init=init_ctdirect,
                lagrange_to_mayer=false,
                exa_backend=exa_backend,
                filtered_kwargs...,
            )
        else
            docp = CTDirect.direct_transcription(
                ocp,
                modeler;
                grid_size=CTSolvers.grid_size(discretizer),
                scheme=scheme_ctdirect,
                init=init_ctdirect,
                lagrange_to_mayer=false,
                kwargs...,
            )
        end

        return docp
    end

    function build_adnlp_model(initial_guess::AbstractOptimalControlInitialGuess; kwargs...)::ADNLPModels.ADNLPModel
        docp = get_docp(initial_guess, :adnlp; kwargs...)
        return CTDirect.nlp_model(docp)
    end

    function build_adnlp_solution(nlp_solution::SolverCore.AbstractExecutionStats)
        docp = get_docp(nothing, :adnlp)
        solu = CTDirect.build_OCP_solution(docp, nlp_solution)
        return solu
    end

    function build_exa_model(::Type{BaseType}, initial_guess::AbstractOptimalControlInitialGuess; kwargs...
    )::ExaModels.ExaModel where {BaseType<:AbstractFloat}
        docp = get_docp(initial_guess, :exa; kwargs...)
        return CTDirect.nlp_model(docp)
    end

    function build_exa_solution(nlp_solution::SolverCore.AbstractExecutionStats)
        docp = get_docp(nothing, :exa)
        solu = CTDirect.build_OCP_solution(docp, nlp_solution)
        return solu
    end

    return DiscretizedOptimalControlProblem(
        ocp,
        CTSolvers.ADNLPModelBuilder(build_adnlp_model),
        CTSolvers.ExaModelBuilder(build_exa_model),
        CTSolvers.ADNLPSolutionBuilder(build_adnlp_solution),
        CTSolvers.ExaSolutionBuilder(build_exa_solution),
    )
end
