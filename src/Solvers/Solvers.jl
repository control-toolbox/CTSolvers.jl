"""
    Solvers

Optimization solvers module for the Control Toolbox.

This module provides concrete solver implementations that integrate with various
optimization backends (Ipopt, MadNLP, MadNCL, Knitro). All solvers implement
the `AbstractStrategy` contract and provide a unified callable interface.

# Solver Types
- `Solvers.Ipopt` - Interior point optimizer (requires NLPModelsIpopt)
- `Solvers.MadNLP` - Matrix-free augmented Lagrangian (requires MadNLP)
- `Solvers.MadNCL` - NCL variant of MadNLP (requires MadNCL, MadNLP)
- `Solvers.Knitro` - Commercial solver (requires NLPModelsKnitro)

# Architecture
- **Types and logic**: Defined in src/Solvers/ (this module)
- **Backend interfaces**: Implemented in ext/ as minimal extensions
- **Strategy contract**: All solvers implement AbstractStrategy

# Example
```julia
using CTSolvers
using NLPModelsIpopt  # Load backend extension

# Create solver with options
solver = Solvers.Ipopt(max_iter=1000, tol=1e-6)

# Solve NLP problem
using ADNLPModels
nlp = ADNLPModel(x -> sum(x.^2), zeros(10))
stats = solver(nlp, display=true)

# Or use CommonSolve API
using CommonSolve
stats = solve(nlp, solver, display=false)
```

See also: [`AbstractNLPSolver`](@ref), [`Solvers.Ipopt`](@ref)
"""
module Solvers

# Imports
import DocStringExtensions: TYPEDEF, TYPEDSIGNATURES, TYPEDFIELDS
import NLPModels
import SolverCore
import CommonSolve
import CTBase.Exceptions

# CTSolvers modules
using ..Strategies
using ..Options
using ..Optimization
using ..Modelers

# Import from CTSolvers
import CTSolvers: AbstractTag

# Include submodules
include(joinpath(@__DIR__, "abstract_solver.jl"))
include(joinpath(@__DIR__, "ipopt.jl"))
include(joinpath(@__DIR__, "madnlp.jl"))
include(joinpath(@__DIR__, "madncl.jl"))
include(joinpath(@__DIR__, "madnlpsuite.jl"))
include(joinpath(@__DIR__, "knitro.jl"))
include(joinpath(@__DIR__, "common_solve_api.jl"))

# Public API - abstract and concrete types
export AbstractNLPSolver
export Ipopt, MadNLP, MadNCL, Knitro

end # module Solvers
