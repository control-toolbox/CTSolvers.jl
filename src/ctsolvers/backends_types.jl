# ------------------------------------------------------------------------------
# Solver backends
# ------------------------------------------------------------------------------

# NLPModelsIpopt
struct IpoptSolver{T<:Tuple} <: AbstractOptimizationSolver
    options::T
end

# MadNLP
struct MadNLPSolver{T<:Tuple} <: AbstractOptimizationSolver
    options::T
end

# MadNCL
struct MadNCLSolver{BaseType<:AbstractFloat,T<:Tuple} <: AbstractOptimizationSolver
    options::T
end

# Knitro
struct KnitroSolver{T<:Tuple} <: AbstractOptimizationSolver
    options::T
end
