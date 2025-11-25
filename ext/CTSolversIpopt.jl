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
function CTSolvers.IpoptSolver(; kwargs...)
    defaults = (
        max_iter=__nlp_models_ipopt_max_iter(),
        tol=__nlp_models_ipopt_tol(),
        print_level=__nlp_models_ipopt_print_level(),
        mu_strategy=__nlp_models_ipopt_mu_strategy(),
        linear_solver=__nlp_models_ipopt_linear_solver(),
        sb=__nlp_models_ipopt_sb(),
    )

    user_nt = kwargs
    values = merge(defaults, user_nt)

    src_pairs = Pair{Symbol,Symbol}[]
    for name in keys(values)
        src = haskey(user_nt, name) ? :user : :ct_default
        push!(src_pairs, name => src)
    end
    sources = (; src_pairs...)

    return CTSolvers.IpoptSolver(values, sources)
end

function (solver::CTSolvers.IpoptSolver)(
    nlp::NLPModels.AbstractNLPModel; display::Bool
)::SolverCore.GenericExecutionStats
    options = Dict(CTSolvers._options(solver))
    options[:print_level] = display ? options[:print_level] : 0
    return CTSolvers.solve_with_ipopt(nlp; options...)
end

end
