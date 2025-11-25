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

function CTSolvers.solve_with_madncl(
    nlp::NLPModels.AbstractNLPModel; ncl_options::MadNCL.NCLOptions, kwargs...
)::MadNCL.NCLStats
    solver = MadNCL.NCLSolver(nlp; ncl_options=ncl_options, kwargs...)
    return MadNCL.solve!(solver)
end

# backend constructor
function CTSolvers.MadNCLSolver(; kwargs...)
    defaults = (
        max_iter=__mad_ncl_max_iter(),
        print_level=__mad_ncl_print_level(),
        linear_solver=__mad_ncl_linear_solver(),
        ncl_options=__mad_ncl_ncl_options(),
    )

    user_nt = kwargs
    values = merge(defaults, user_nt)

    src_pairs = Pair{Symbol,Symbol}[]
    for name in keys(values)
        src = haskey(user_nt, name) ? :user : :ct_default
        push!(src_pairs, name => src)
    end
    sources = (; src_pairs...)

    BaseType = base_type(values.ncl_options)
    return CTSolvers.MadNCLSolver{BaseType,typeof(values),typeof(sources)}(values, sources)
end

function (solver::CTSolvers.MadNCLSolver{BaseType})(
    nlp::NLPModels.AbstractNLPModel; display::Bool
)::MadNCL.NCLStats where {BaseType<:AbstractFloat}
    # options control
    options = Dict(CTSolvers._options(solver))
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
