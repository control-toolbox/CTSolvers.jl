function (discretizer::Collocation)(ocp::AbstractOptimalControlProblem)
    SchemeSymbol = Dict(Midpoint => :midpoint, Trapezoidal => :trapeze, Trapeze => :trapeze)

    function scheme_symbol(discretizer::Collocation)
        scheme = CTSolvers.get_option_value(discretizer, :scheme)
        return SchemeSymbol[typeof(scheme)]
    end

    function get_docp(
        initial_guess::Union{AbstractOptimalControlInitialGuess,Nothing},
        modeler::Symbol;
        kwargs...,
    )
        scheme_ctdirect = scheme_symbol(discretizer)
        init_ctdirect = if (initial_guess === nothing)
            nothing
        else
            (
                state=state(initial_guess),
                control=control(initial_guess),
                variable=variable(initial_guess),
            )
        end

        # Unified grid option: Int => grid_size, Vector => explicit time_grid
        grid = CTSolvers.get_option_value(discretizer, :grid)
        if grid isa Int
            grid_size = grid
            time_grid = nothing
        else
            grid_size = length(grid)
            time_grid = grid
        end

        if modeler == :exa && haskey(kwargs, :backend)
            # Route ExaModeler backend to CTDirect via exa_backend and drop backend from forwarded kwargs.
            exa_backend = kwargs[:backend]
            filtered_kwargs = (; (k => v for (k, v) in pairs(kwargs) if k != :backend)...)
            docp = CTDirect.direct_transcription(
                ocp,
                modeler;
                grid_size=grid_size,
                disc_method=scheme_ctdirect,
                init=init_ctdirect,
                time_grid=time_grid,
                exa_backend=exa_backend,
                filtered_kwargs...,
            )
        else
            docp = CTDirect.direct_transcription(
                ocp,
                modeler;
                grid_size=grid_size,
                disc_method=scheme_ctdirect,
                init=init_ctdirect,
                time_grid=time_grid,
                kwargs...,
            )
        end

        return docp
    end

    function build_adnlp_model(
        initial_guess::AbstractOptimalControlInitialGuess; kwargs...
    )::ADNLPModels.ADNLPModel
        docp = get_docp(initial_guess, :adnlp; kwargs...)
        return CTDirect.nlp_model(docp)
    end

    function build_adnlp_solution(nlp_solution::SolverCore.AbstractExecutionStats)
        docp = get_docp(nothing, :adnlp)
        solu = CTDirect.build_OCP_solution(docp, nlp_solution)
        return solu
    end

    function build_exa_model(
        ::Type{BaseType}, initial_guess::AbstractOptimalControlInitialGuess; kwargs...
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
