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

function CTSolvers._option_specs(::Type{<:CTSolvers.MadNLPSolver})
    return (
        max_iter=CTSolvers.OptionSpec(;
            type=Integer,
            default=__mad_nlp_max_iter(),
            description="Maximum number of iterations.",
        ),
        tol=CTSolvers.OptionSpec(;
            type=Real, default=__mad_nlp_tol(), description="Optimality tolerance."
        ),
        print_level=CTSolvers.OptionSpec(;
            type=MadNLP.LogLevels,
            default=__mad_nlp_print_level(),
            description="MadNLP logging level.",
        ),
        linear_solver=CTSolvers.OptionSpec(;
            type=Type{<:MadNLP.AbstractLinearSolver},
            default=__mad_nlp_linear_solver(),
            description="Linear solver implementation used by MadNLP.",
        ),
    )
end

# solver interface
function CTSolvers.solve_with_madnlp(
    nlp::NLPModels.AbstractNLPModel; kwargs...
)::MadNLP.MadNLPExecutionStats
    solver = MadNLP.MadNLPSolver(nlp; kwargs...)
    return MadNLP.solve!(solver)
end

# backend constructor
function CTSolvers.MadNLPSolver(; kwargs...)
    values, sources = CTSolvers._build_ocp_tool_options(
        CTSolvers.MadNLPSolver; kwargs..., strict_keys=false
    )
    return CTSolvers.MadNLPSolver(values, sources)
end

function (solver::CTSolvers.MadNLPSolver)(
    nlp::NLPModels.AbstractNLPModel; display::Bool
)::MadNLP.MadNLPExecutionStats
    options = Dict(pairs(CTSolvers._options_values(solver)))
    options[:print_level] = display ? options[:print_level] : MadNLP.ERROR
    return CTSolvers.solve_with_madnlp(nlp; options...)
end

end
