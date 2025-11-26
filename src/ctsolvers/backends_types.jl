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

get_symbol(::Type{IpoptSolver})   = :ipopt
get_symbol(::Type{MadNLPSolver})  = :madnlp
get_symbol(::Type{MadNCLSolver})  = :madncl
get_symbol(::Type{KnitroSolver})  = :knitro

tool_package_name(::Type{IpoptSolver})   = "NLPModelsIpopt"
tool_package_name(::Type{MadNLPSolver})  = "MadNLP suite"
tool_package_name(::Type{MadNCLSolver})  = "MadNCL"
tool_package_name(::Type{KnitroSolver})  = "NLPModelsKnitro"

const REGISTERED_SOLVERS = (IpoptSolver, MadNLPSolver, MadNCLSolver, KnitroSolver)

registered_solver_types() = REGISTERED_SOLVERS

solver_symbols() = Tuple(get_symbol(T) for T in REGISTERED_SOLVERS)

function build_solver_from_symbol(sym::Symbol; kwargs...)
    for T in REGISTERED_SOLVERS
        if get_symbol(T) === sym
            return T(; kwargs...)
        end
    end
    msg = "Unknown solver symbol $(sym). Supported symbols: $(solver_symbols())."
    throw(CTBase.IncorrectArgument(msg))
end
