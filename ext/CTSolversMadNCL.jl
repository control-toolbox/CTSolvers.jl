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

# solver interface
function CTSolvers.solve_with_madncl(
    nlp::NLPModels.AbstractNLPModel; ncl_options::MadNCL.NCLOptions, kwargs...
)::MadNCL.NCLStats
    solver = MadNCL.NCLSolver(nlp; ncl_options=ncl_options, kwargs...)
    return MadNCL.solve!(solver)
end

# backend constructor
function CTSolvers.MadNCLBackend(;
    max_iter::Int=__mad_ncl_max_iter(),
    print_level::MadNLP.LogLevels=__mad_ncl_print_level(),
    linear_solver::Type{<:MadNLP.AbstractLinearSolver}=__mad_ncl_linear_solver(),
    ncl_options::MadNCL.NCLOptions{BaseType}=__mad_ncl_ncl_options(),
    kwargs...,
) where {BaseType<:AbstractFloat}
    options = (
        :max_iter => max_iter,
        :print_level => print_level,
        :linear_solver => linear_solver,
        :ncl_options => ncl_options,
        kwargs...,
    )
    return CTSolvers.MadNCLBackend{BaseType,typeof(options)}(options)
end

function (solver::CTSolvers.MadNCLBackend{BaseType})(
    nlp::NLPModels.AbstractNLPModel; display::Bool
)::MadNCL.NCLStats where {BaseType<:AbstractFloat}
    # options control
    options = Dict(solver.options)
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
