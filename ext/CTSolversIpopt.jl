module CTSolversIpopt

using CTSolvers
using NLPModelsIpopt
using NLPModels
using SolverCore

# default
__nlp_models_ipopt_max_iter() = 1000
__nlp_models_ipopt_tol() = 1e-8
__nlp_models_ipopt_print_level() = 5
__nlp_models_ipopt_mu_strategy() = "adaptive"
__nlp_models_ipopt_linear_solver() = "Mumps"
__nlp_models_ipopt_sb() = "yes"

# solver interface
function CTSolvers.solve_with_ipopt(
    nlp::NLPModels.AbstractNLPModel; kwargs...
)::SolverCore.GenericExecutionStats
    solver = NLPModelsIpopt.IpoptSolver(nlp)
    return NLPModelsIpopt.solve!(solver, nlp; kwargs...)
end

# backend constructor
function CTSolvers.NLPModelsIpoptBackend(;
    max_iter::Int=__nlp_models_ipopt_max_iter(),
    tol::Float64=__nlp_models_ipopt_tol(),
    print_level::Int=__nlp_models_ipopt_print_level(),
    mu_strategy::String=__nlp_models_ipopt_mu_strategy(),
    linear_solver::String=__nlp_models_ipopt_linear_solver(),
    sb::String=__nlp_models_ipopt_sb(),
    kwargs...,
)
    return CTSolvers.NLPModelsIpoptBackend((
        :max_iter => max_iter,
        :tol => tol,
        :print_level => print_level,
        :mu_strategy => mu_strategy,
        :linear_solver => linear_solver,
        :sb => sb,
        kwargs...,
    ))
end

function (solver::CTSolvers.NLPModelsIpoptBackend)(
    nlp::NLPModels.AbstractNLPModel; display::Bool
)::SolverCore.GenericExecutionStats
    options = Dict(solver.options)
    options[:print_level] = display ? options[:print_level] : 0
    return CTSolvers.solve_with_ipopt(nlp; options...)
end

end
