
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# Solvers on CPU: NLPModelsIpopt, MadNLP, MadNCL

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

# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# Generic solvers
abstract type AbstractNLPSolverBackend end

# ------------------------------------------------------------------------------
# NLPModelsIpopt
struct NLPModelsIpoptBackend <: AbstractNLPSolverBackend
    # attributes
    max_iter::Int
    tol::Float64
    print_level::Int
    mu_strategy::String
    linear_solver::String
    sb::String
    kwargs

    # constructor
    function NLPModelsIpoptBackend(;
        max_iter::Int=100,
        tol::Float64=1e-6,
        print_level::Int=5,
        mu_strategy::String="adaptive",
        linear_solver::String="Mumps",
        sb::String="yes",
        kwargs...,
    )
        return new(max_iter, tol, print_level, mu_strategy, linear_solver, sb, kwargs)
    end
end

function CommonSolve.solve(
    prob::AbstractOptimizationProblem,
    initial_guess,
    modeler::AbstractNLPModelBackend,
    solver::NLPModelsIpoptBackend;
):: SolverCore.GenericExecutionStats

    # build the model
    nlp = build_model(prob, initial_guess, modeler)

    # solve the problem
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
struct MadNLPBackend <: AbstractNLPSolverBackend
    # attributes
    max_iter::Int
    tol::Float64
    print_level::MadNLP.LogLevels
    linear_solver::Type{<:MadNLP.AbstractLinearSolver}
    kwargs

    # constructor
    function MadNLPBackend(;
        max_iter::Int=100,
        tol::Float64=1e-6,
        print_level::MadNLP.LogLevels=MadNLP.INFO,
        linear_solver::Type{<:MadNLP.AbstractLinearSolver}=MadNLPMumps.MumpsSolver,
        kwargs...,
    )
        return new(max_iter, tol, print_level, linear_solver, kwargs)
    end
end

function CommonSolve.solve(
    prob::AbstractOptimizationProblem,
    initial_guess,
    modeler::AbstractNLPModelBackend,
    solver::MadNLPBackend;
):: MadNLP.MadNLPExecutionStats
    
    # build the model
    nlp = build_model(prob, initial_guess, modeler)

    # solve the problem
    return solve_with_madnlp(nlp; 
        max_iter=solver.max_iter, 
        tol=solver.tol, 
        print_level=solver.print_level, 
        linear_solver=solver.linear_solver,
        solver.kwargs... 
    )
end