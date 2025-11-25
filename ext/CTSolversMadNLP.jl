module CTSolversMadNLP

using CTSolvers
using MadNLP
using MadNLPMumps
using NLPModels

# default
__mad_nlp_max_iter() = 1000
__mad_nlp_tol() = 1e-8
__mad_nlp_print_level() = MadNLP.INFO
__mad_nlp_linear_solver() = MadNLPMumps.MumpsSolver

# solver interface
function CTSolvers.solve_with_madnlp(
    nlp::NLPModels.AbstractNLPModel; kwargs...
)::MadNLP.MadNLPExecutionStats
    solver = MadNLP.MadNLPSolver(nlp; kwargs...)
    return MadNLP.solve!(solver)
end

# backend constructor
function CTSolvers.MadNLPSolver(; kwargs...)
    defaults = (
        max_iter=__mad_nlp_max_iter(),
        tol=__mad_nlp_tol(),
        print_level=__mad_nlp_print_level(),
        linear_solver=__mad_nlp_linear_solver(),
    )

    user_nt = kwargs
    values = merge(defaults, user_nt)

    src_pairs = Pair{Symbol,Symbol}[]
    for name in keys(values)
        src = haskey(user_nt, name) ? :user : :ct_default
        push!(src_pairs, name => src)
    end
    sources = (; src_pairs...)

    return CTSolvers.MadNLPSolver(values, sources)
end

function (solver::CTSolvers.MadNLPSolver)(
    nlp::NLPModels.AbstractNLPModel; display::Bool
)::MadNLP.MadNLPExecutionStats
    options = Dict(CTSolvers._options(solver))
    options[:print_level] = display ? options[:print_level] : MadNLP.ERROR
    return CTSolvers.solve_with_madnlp(nlp; options...)
end

end
