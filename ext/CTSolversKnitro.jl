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

# solver interface
function CTSolvers.solve_with_knitro(
    nlp::NLPModels.AbstractNLPModel; kwargs...
)::SolverCore.GenericExecutionStats
    solver = NLPModelsKnitro.KnitroSolver(nlp; kwargs...)
    return NLPModelsKnitro.solve!(solver, nlp)
end

# backend constructor
function CTSolvers.KnitroSolver(;
    maxit::Int=__nlp_models_knitro_max_iter(),
    feastol_abs::Float64=__nlp_models_knitro_feastol_abs(),
    opttol_abs::Float64=__nlp_models_knitro_opttol_abs(),
    print_level::Int=__nlp_models_knitro_print_level(),
    kwargs...,
)
    return CTSolvers.KnitroSolver((
        :maxit => maxit,
        :feastol_abs => feastol_abs,
        :opttol_abs => opttol_abs,
        :print_level => print_level,
        kwargs...,
    ))
end

function (solver::CTSolvers.KnitroSolver)(
    nlp::NLPModels.AbstractNLPModel; display::Bool
)::SolverCore.GenericExecutionStats
    options = Dict(solver.options)
    options[:print_level] = display ? options[:print_level] : 0
    return CTSolvers.solve_with_knitro(nlp; options...)
end

end
