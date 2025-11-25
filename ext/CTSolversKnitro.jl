module CTSolversKnitro

using CTSolvers
using NLPModelsKnitro
using NLPModels
using SolverCore

# default
__nlp_models_knitro_max_iter() = 1000
__nlp_models_knitro_feastol_abs() = 1e-8
__nlp_models_knitro_opttol_abs() = 1e-8
__nlp_models_knitro_print_level() = 3

function CTSolvers.solve_with_knitro(
    nlp::NLPModels.AbstractNLPModel; kwargs...
)::SolverCore.GenericExecutionStats
    solver = NLPModelsKnitro.KnitroSolver(nlp; kwargs...)
    return NLPModelsKnitro.solve!(solver, nlp)
end

# backend constructor
function CTSolvers.KnitroSolver(; kwargs...)
    defaults = (
        maxit=__nlp_models_knitro_max_iter(),
        feastol_abs=__nlp_models_knitro_feastol_abs(),
        opttol_abs=__nlp_models_knitro_opttol_abs(),
        print_level=__nlp_models_knitro_print_level(),
    )

    user_nt = kwargs
    values = merge(defaults, user_nt)

    src_pairs = Pair{Symbol,Symbol}[]
    for name in keys(values)
        src = haskey(user_nt, name) ? :user : :ct_default
        push!(src_pairs, name => src)
    end
    sources = (; src_pairs...)

    return CTSolvers.KnitroSolver(values, sources)
end

function (solver::CTSolvers.KnitroSolver)(
    nlp::NLPModels.AbstractNLPModel; display::Bool
)::SolverCore.GenericExecutionStats
    options = Dict(CTSolvers._options(solver))
    options[:print_level] = display ? options[:print_level] : 0
    return CTSolvers.solve_with_knitro(nlp; options...)
end

end
