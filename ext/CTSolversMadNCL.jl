module CTSolversMadNCL

using CTSolvers
using MadNCL
using MadNLP
using MadNLPMumps
using NLPModels

# default
__mad_ncl_max_iter() = 1000
__mad_ncl_print_level() = MadNLP.INFO
__mad_ncl_linear_solver() = MadNLPMumps.MumpsSolver
function __mad_ncl_ncl_options()
    MadNCL.NCLOptions{Float64}(
        verbose=true,       # print convergence logs
        # scaling=false,      # specify if we should scale the problem
        opt_tol=1e-8,       # tolerance on dual infeasibility
        feas_tol=1e-8,      # tolerance on primal infeasibility
        # rho_init=1e1,       # initial augmented Lagrangian penalty
        # max_auglag_iter=20, # maximum number of outer iterations
    )
end

base_type(::MadNCL.NCLOptions{BaseType}) where {BaseType<:AbstractFloat} = BaseType

function CTSolvers._option_specs(::Type{CTSolvers.MadNCLSolver})
    return (
        max_iter = CTSolvers.OptionSpec(
            type=Integer,
            default=__mad_ncl_max_iter(),
            description="Maximum number of augmented Lagrangian iterations.",
        ),
        print_level = CTSolvers.OptionSpec(
            type=MadNLP.LogLevels,
            default=__mad_ncl_print_level(),
            description="MadNCL/MadNLP logging level.",
        ),
        linear_solver = CTSolvers.OptionSpec(
            type=Type{<:MadNLP.AbstractLinearSolver},
            default=__mad_ncl_linear_solver(),
            description="Linear solver implementation used inside MadNCL.",
        ),
        ncl_options = CTSolvers.OptionSpec(
            type=MadNCL.NCLOptions,
            default=__mad_ncl_ncl_options(),
            description="Low-level NCLOptions structure controlling the augmented Lagrangian algorithm.",
        ),
    )
end

function CTSolvers.solve_with_madncl(
    nlp::NLPModels.AbstractNLPModel; ncl_options::MadNCL.NCLOptions, kwargs...
)::MadNCL.NCLStats
    solver = MadNCL.NCLSolver(nlp; ncl_options=ncl_options, kwargs...)
    return MadNCL.solve!(solver)
end

# backend constructor
function CTSolvers.MadNCLSolver(; kwargs...)
    values, sources = CTSolvers._build_ocp_tool_options(CTSolvers.MadNCLSolver; kwargs..., strict_keys=true)
    BaseType = base_type(values.ncl_options)
    return CTSolvers.MadNCLSolver{BaseType,typeof(values),typeof(sources)}(values, sources)
end

function (solver::CTSolvers.MadNCLSolver{BaseType})(
    nlp::NLPModels.AbstractNLPModel; display::Bool
)::MadNCL.NCLStats where {BaseType<:AbstractFloat}
    # options control
    options = Dict(pairs(CTSolvers._options_values(solver)))
    if !display
        options[:print_level] = MadNLP.ERROR
        ncl_options_dict = Dict()
        for field in fieldnames(MadNCL.NCLOptions)
            ncl_options_dict[field] = getfield(options[:ncl_options], field)
        end
        ncl_options_dict[:verbose] = false
        options[:ncl_options] = MadNCL.NCLOptions{BaseType}(; ncl_options_dict...)
    end

    # solve the problem
    return CTSolvers.solve_with_madncl(nlp; options...)
end

end
