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
