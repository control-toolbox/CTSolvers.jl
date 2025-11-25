# ------------------------------------------------------------------------------
# Solver backends
# ------------------------------------------------------------------------------

# NLPModelsIpopt
struct IpoptSolver{Vals,Srcs} <: AbstractOptimizationSolver
    options_values::Vals
    options_sources::Srcs
end

function _options(solver::IpoptSolver)
    return solver.options_values
end

function _option_sources(solver::IpoptSolver)
    return solver.options_sources
end

# MadNLP
struct MadNLPSolver{Vals,Srcs} <: AbstractOptimizationSolver
    options_values::Vals
    options_sources::Srcs
end

function _options(solver::MadNLPSolver)
    return solver.options_values
end

function _option_sources(solver::MadNLPSolver)
    return solver.options_sources
end

# MadNCL
struct MadNCLSolver{BaseType<:AbstractFloat,Vals,Srcs} <: AbstractOptimizationSolver
    options_values::Vals
    options_sources::Srcs
end

function _options(solver::MadNCLSolver)
    return solver.options_values
end

function _option_sources(solver::MadNCLSolver)
    return solver.options_sources
end

# Knitro
struct KnitroSolver{Vals,Srcs} <: AbstractOptimizationSolver
    options_values::Vals
    options_sources::Srcs
end

function _options(solver::KnitroSolver)
    return solver.options_values
end

function _option_sources(solver::KnitroSolver)
    return solver.options_sources
end
