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
function CTSolvers.MadNLPSolver(;
    max_iter::Int=__mad_nlp_max_iter(),
    tol::Float64=__mad_nlp_tol(),
    print_level::MadNLP.LogLevels=__mad_nlp_print_level(),
    linear_solver::Type{<:MadNLP.AbstractLinearSolver}=__mad_nlp_linear_solver(),
    kwargs...,
)
    return CTSolvers.MadNLPSolver((
        :max_iter => max_iter,
        :tol => tol,
        :print_level => print_level,
        :linear_solver => linear_solver,
        kwargs...,
    ))
end

function (solver::CTSolvers.MadNLPSolver)(
    nlp::NLPModels.AbstractNLPModel; display::Bool
)::MadNLP.MadNLPExecutionStats
    options = Dict(solver.options)
    options[:print_level] = display ? options[:print_level] : MadNLP.ERROR
    return CTSolvers.solve_with_madnlp(nlp; options...)
end

end
