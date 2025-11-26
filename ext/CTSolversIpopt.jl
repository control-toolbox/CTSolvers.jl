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

function CTSolvers._option_specs(::Type{CTSolvers.IpoptSolver})
    return (
        max_iter = CTSolvers.OptionSpec(
            type=Integer,
            default=__nlp_models_ipopt_max_iter(),
            description="Maximum number of iterations.",
        ),
        tol = CTSolvers.OptionSpec(
            type=Real,
            default=__nlp_models_ipopt_tol(),
            description="Optimality tolerance.",
        ),
        print_level = CTSolvers.OptionSpec(
            type=Integer,
            default=__nlp_models_ipopt_print_level(),
            description="Ipopt print level.",
        ),
        mu_strategy = CTSolvers.OptionSpec(
            type=String,
            default=__nlp_models_ipopt_mu_strategy(),
            description="Strategy used to update the barrier parameter.",
        ),
        linear_solver = CTSolvers.OptionSpec(
            type=String,
            default=__nlp_models_ipopt_linear_solver(),
            description="Linear solver used by Ipopt.",
        ),
        sb = CTSolvers.OptionSpec(
            type=String,
            default=__nlp_models_ipopt_sb(),
            description="Ipopt 'sb' (screen output) option, typically 'yes' or 'no'.",
        ),
    )
end

# solver interface
function CTSolvers.solve_with_ipopt(
    nlp::NLPModels.AbstractNLPModel; kwargs...
)::SolverCore.GenericExecutionStats
    solver = NLPModelsIpopt.IpoptSolver(nlp)
    return NLPModelsIpopt.solve!(solver, nlp; kwargs...)
end

# backend constructor
function CTSolvers.IpoptSolver(; kwargs...)
    values, sources = CTSolvers._build_ocp_tool_options(CTSolvers.IpoptSolver; kwargs..., strict_keys=true)
    return CTSolvers.IpoptSolver(values, sources)
end

function (solver::CTSolvers.IpoptSolver)(
    nlp::NLPModels.AbstractNLPModel; display::Bool
)::SolverCore.GenericExecutionStats
    options = Dict(CTSolvers._options_values(solver))
    options[:print_level] = display ? options[:print_level] : 0
    return CTSolvers.solve_with_ipopt(nlp; options...)
end

end
