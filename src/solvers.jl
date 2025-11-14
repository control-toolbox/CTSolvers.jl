# ------------------------------------------------------------------------------
# Solvers utils
# ------------------------------------------------------------------------------

# NLPModelsIpopt
function solve_with_ipopt(nlp; kwargs...)
    return throw(CTBase.ExtensionError(:NLPModelsIpopt))
end

# MadNLP
function solve_with_madnlp(nlp; kwargs...)
    return throw(CTBase.ExtensionError(:MadNLP))
end

# MadNCL
function solve_with_madncl(nlp; kwargs...)
    return throw(CTBase.ExtensionError(:MadNCL))
end

# Knitro
function solve_with_knitro(nlp; kwargs...)
    return throw(CTBase.ExtensionError(:NLPModelsKnitro))
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
    display::Bool=__display(),
)::SolverCore.AbstractExecutionStats
    nlp = nlp_model(prob, initial_guess, modeler)
    return solver(nlp; display=display)
end

# ------------------------------------------------------------------------------
# Solver backends
# ------------------------------------------------------------------------------

# NLPModelsIpopt
struct NLPModelsIpoptBackend{T<:Tuple} <: AbstractNLPSolverBackend
    options::T
end

# MadNLP
struct MadNLPBackend{T<:Tuple} <: AbstractNLPSolverBackend
    options::T
end

# MadNCL
struct MadNCLBackend{BaseType<:AbstractFloat,T<:Tuple} <: AbstractNLPSolverBackend
    options::T
end

# Knitro
struct KnitroBackend{T<:Tuple} <: AbstractNLPSolverBackend
    options::T
end
