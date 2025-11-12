# ------------------------------------------------------------------------------
# Solvers utils
# ------------------------------------------------------------------------------

# NLPModelsIpopt
function solve_with_ipopt(
    nlp::NLPModels.AbstractNLPModel;
    kwargs...,
):: SolverCore.GenericExecutionStats
    solver = NLPModelsIpopt.IpoptSolver(nlp)
    return NLPModelsIpopt.solve!(solver, nlp; kwargs...)
end

# MadNLP
function solve_with_madnlp(
    nlp::NLPModels.AbstractNLPModel;
    kwargs...,
):: MadNLP.MadNLPExecutionStats
    solver = MadNLP.MadNLPSolver(nlp; kwargs...)
    return MadNLP.solve!(solver)
end

# MadNCL
function solve_with_madncl(
    nlp::NLPModels.AbstractNLPModel;
    ncl_options::MadNCL.NCLOptions,
    kwargs...,
):: MadNCL.NCLStats
    solver = MadNCL.NCLSolver(nlp; ncl_options=ncl_options, kwargs...)
    return MadNCL.solve!(solver)
end

# ------------------------------------------------------------------------------
# Generic solver method
# ------------------------------------------------------------------------------
abstract type AbstractNLPSolverBackend end

function CommonSolve.solve(
    prob::AbstractCTOptimizationProblem,
    initial_guess,
    modeler::AbstractNLPModelBackend,
    solver::AbstractNLPSolverBackend;
):: SolverCore.AbstractExecutionStats

    # build the model
    nlp = nlp_model(prob, initial_guess, modeler)

    # solve the problem
    return solver(nlp)
end

# ------------------------------------------------------------------------------
# Solver backends
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# NLPModelsIpopt
struct NLPModelsIpoptBackend{KW} <: AbstractNLPSolverBackend
    # attributes
    max_iter::Int
    tol::Float64
    print_level::Int
    mu_strategy::String
    linear_solver::String
    sb::String
    kwargs::KW

    # constructor
    function NLPModelsIpoptBackend(;
        max_iter::Int=__nlp_models_ipopt_max_iter(),
        tol::Float64=__nlp_models_ipopt_tol(),
        print_level::Int=__nlp_models_ipopt_print_level(),
        mu_strategy::String=__nlp_models_ipopt_mu_strategy(),
        linear_solver::String=__nlp_models_ipopt_linear_solver(),
        sb::String=__nlp_models_ipopt_sb(),
        kwargs...,
    )
        return new{typeof(kwargs)}(max_iter, tol, print_level, mu_strategy, linear_solver, sb, kwargs)
    end
end

function (solver::NLPModelsIpoptBackend)(nlp::NLPModels.AbstractNLPModel):: SolverCore.GenericExecutionStats
    return solve_with_ipopt(nlp; 
        max_iter=solver.max_iter, 
        tol=solver.tol, 
        print_level=solver.print_level, 
        mu_strategy=solver.mu_strategy, 
        linear_solver=solver.linear_solver, 
        sb=solver.sb,
        solver.kwargs... 
    )
end

# ------------------------------------------------------------------------------
# MadNLP
struct MadNLPBackend{
    LinearSolverType<:Type{<:MadNLP.AbstractLinearSolver},
    KW
} <: AbstractNLPSolverBackend
    # attributes
    max_iter::Int
    tol::Float64
    print_level::MadNLP.LogLevels
    linear_solver::LinearSolverType
    kwargs::KW

    # constructor
    function MadNLPBackend(;
        max_iter::Int=__mad_nlp_max_iter(),
        tol::Float64=__mad_nlp_tol(),
        print_level::MadNLP.LogLevels=__mad_nlp_print_level(),
        linear_solver::Type{<:MadNLP.AbstractLinearSolver}=__mad_nlp_linear_solver(),
        kwargs...,
    )
        return new{Type{linear_solver}, typeof(kwargs)}(max_iter, tol, print_level, linear_solver, kwargs)
    end
end

function (solver::MadNLPBackend)(nlp::NLPModels.AbstractNLPModel):: MadNLP.MadNLPExecutionStats
    return solve_with_madnlp(nlp; 
        max_iter=solver.max_iter, 
        tol=solver.tol, 
        print_level=solver.print_level, 
        linear_solver=solver.linear_solver,
        solver.kwargs... 
    )
end

# ------------------------------------------------------------------------------
# MadNCL
struct MadNCLBackend{
    BaseType<:AbstractFloat,
    LinearSolverType<:Type{<:MadNLP.AbstractLinearSolver},
    KW
} <: AbstractNLPSolverBackend
    # attributes
    max_iter::Int
    print_level::MadNLP.LogLevels
    linear_solver::LinearSolverType
    ncl_options::MadNCL.NCLOptions{BaseType}
    kwargs::KW

    # constructor
    function MadNCLBackend(;
        max_iter::Int=__mad_ncl_max_iter(),
        print_level::MadNLP.LogLevels=__mad_ncl_print_level(),
        linear_solver::Type{<:MadNLP.AbstractLinearSolver}=__mad_ncl_linear_solver(),
        ncl_options::MadNCL.NCLOptions{BaseType}=__mad_ncl_ncl_options(),
        kwargs...,
    ) where {BaseType<:AbstractFloat}
        return new{BaseType, Type{linear_solver}, typeof(kwargs)}(max_iter, print_level, linear_solver, ncl_options, kwargs)
    end
end

function (solver::MadNCLBackend)(nlp::NLPModels.AbstractNLPModel):: MadNCL.NCLStats
    return solve_with_madncl(nlp;
        max_iter=solver.max_iter, 
        print_level=solver.print_level, 
        linear_solver=solver.linear_solver,
        ncl_options=solver.ncl_options,
        solver.kwargs... 
    )
end