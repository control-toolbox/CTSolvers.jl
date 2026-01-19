module CTSolversKnitro

using CTModels
using CTSolvers
using NLPModelsKnitro
using NLPModels
using SolverCore

# default
__nlp_models_knitro_max_iter() = 1000
__nlp_models_knitro_feastol_abs() = 1e-8
__nlp_models_knitro_opttol_abs() = 1e-8
__nlp_models_knitro_print_level() = 3

function CTModels._option_specs(::Type{<:CTSolvers.KnitroSolver})
    return (
        maxit=CTModels.OptionSpec(;
            type=Integer,
            default=__nlp_models_knitro_max_iter(),
            description="Maximum number of iterations.",
        ),
        feastol_abs=CTModels.OptionSpec(;
            type=Real,
            default=__nlp_models_knitro_feastol_abs(),
            description="Absolute feasibility tolerance.",
        ),
        opttol_abs=CTModels.OptionSpec(;
            type=Real,
            default=__nlp_models_knitro_opttol_abs(),
            description="Absolute optimality tolerance.",
        ),
        print_level=CTModels.OptionSpec(;
            type=Integer,
            default=__nlp_models_knitro_print_level(),
            description="Knitro print level.",
        ),
    )
end

function CTSolvers.solve_with_knitro(
    nlp::NLPModels.AbstractNLPModel; kwargs...
)::SolverCore.GenericExecutionStats
    solver = NLPModelsKnitro.KnitroSolver(nlp; kwargs...)
    return NLPModelsKnitro.solve!(solver, nlp)
end

# backend constructor
function CTSolvers.KnitroSolver(; kwargs...)
    values, sources = CTModels._build_ocp_tool_options(
        CTSolvers.KnitroSolver; kwargs..., strict_keys=false
    )
    return CTSolvers.KnitroSolver(values, sources)
end

function (solver::CTSolvers.KnitroSolver)(
    nlp::NLPModels.AbstractNLPModel; display::Bool
)::SolverCore.GenericExecutionStats
    options = Dict(pairs(CTModels._options_values(solver)))
    options[:print_level] = display ? options[:print_level] : 0
    return CTSolvers.solve_with_knitro(nlp; options...)
end

end
