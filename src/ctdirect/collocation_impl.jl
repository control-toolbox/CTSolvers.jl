function (discretizer::Collocation)(ocp::AbstractOptimalControlProblem)

    scheme_ctdirect = scheme_symbol(discretizer)

    function build_adnlp_model(initial_guess::AbstractOptimalControlInitialGuess; kwargs...)::ADNLPModels.ADNLPModel
        init_ctdirect = (state = state(initial_guess), control = control(initial_guess), variable = variable(initial_guess))
        docp = CTDirect.direct_transcription(
            ocp,
            :adnlp;
            grid_size=CTSolvers.grid_size(discretizer),
            scheme=scheme_ctdirect,
            init=init_ctdirect,
            lagrange_to_mayer=false,
            kwargs...,
        )
        return CTDirect.nlp_model(docp)
    end

    function adnlp_solution_helper(nlp_solution::SolverCore.AbstractExecutionStats, val::Symbol)
        return nothing
    end

    function build_exa_model(::Type{BaseType}, initial_guess::AbstractOptimalControlInitialGuess; kwargs...
    )::ExaModels.ExaModel where {BaseType<:AbstractFloat}
        init_ctdirect = (state = state(initial_guess), control = control(initial_guess), variable = variable(initial_guess))
        docp = CTDirect.direct_transcription(
            ocp,
            :exa;
            grid_size=CTSolvers.grid_size(discretizer),
            scheme=scheme_ctdirect,
            init=init_ctdirect,
            lagrange_to_mayer=false,
            kwargs...,
        )
        return CTDirect.nlp_model(docp)
    end

    function exa_solution_helper(nlp_solution::SolverCore.AbstractExecutionStats, val::Symbol)
        return nothing
    end

    return DiscretizedOptimalControlProblem(
        ocp,
        CTSolvers.ADNLPModelBuilder(build_adnlp_model),
        CTSolvers.ExaModelBuilder(build_exa_model),
        CTSolvers.ADNLPModelerOCPHelper(adnlp_solution_helper),
        CTSolvers.ExaModelerOCPHelper(exa_solution_helper),
    )
end
