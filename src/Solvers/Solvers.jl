"""
    Solvers

Optimization solvers module for the Control Toolbox.

This module provides concrete solver implementations that integrate with various
optimization backends (Ipopt, MadNLP, MadNCL, Knitro). All solvers implement
the `AbstractStrategy` contract and provide a unified callable interface.

# Solver Types
- `IpoptSolver` - Interior point optimizer (requires NLPModelsIpopt)
- `MadNLPSolver` - Matrix-free augmented Lagrangian (requires MadNLP, MadNLPMumps)
- `MadNCLSolver` - NCL variant of MadNLP (requires MadNCL, MadNLP, MadNLPMumps)
- `KnitroSolver` - Commercial solver (requires NLPModelsKnitro)

# Architecture
- **Types and logic**: Defined in src/Solvers/ (this module)
- **Backend interfaces**: Implemented in ext/ as minimal extensions
- **Strategy contract**: All solvers implement AbstractStrategy

# Example
```julia
using CTSolvers
using NLPModelsIpopt  # Load backend extension

# Create solver with options
solver = IpoptSolver(max_iter=1000, tol=1e-6)

# Solve NLP problem
using ADNLPModels
nlp = ADNLPModel(x -> sum(x.^2), zeros(10))
stats = solver(nlp, display=true)

# Or use CommonSolve API
using CommonSolve
stats = solve(nlp, solver, display=false)
```

See also: [`AbstractOptimizationSolver`](@ref), [`IpoptSolver`](@ref)
"""
module Solvers

using DocStringExtensions
using NLPModels
using SolverCore
using CommonSolve
using CTBase: CTBase, Exceptions

# Import parent module components
using ..CTSolvers.Strategies
using ..CTSolvers.Options
using ..CTSolvers.Optimization
using ..CTSolvers.Modelers

# Tag Dispatch Infrastructure
"""
    AbstractTag

Abstract type for tag dispatch pattern used to handle extension-dependent implementations.
"""
abstract type AbstractTag end

# Include submodules
include(joinpath(@__DIR__, "abstract_solver.jl"))
include(joinpath(@__DIR__, "validation.jl"))
include(joinpath(@__DIR__, "ipopt_solver.jl"))
include(joinpath(@__DIR__, "madnlp_solver.jl"))
include(joinpath(@__DIR__, "madncl_solver.jl"))
include(joinpath(@__DIR__, "knitro_solver.jl"))
include(joinpath(@__DIR__, "common_solve_api.jl"))

# Public API - types abstraits et concrets
export AbstractOptimizationSolver
export IpoptSolver, MadNLPSolver, MadNCLSolver, KnitroSolver

end # module Solvers
