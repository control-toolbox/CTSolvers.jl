"""
    Solvers

Optimization solvers module for the Control Toolbox.

This module provides concrete solver strategies that wrap NLP backends (Ipopt, MadNLP,
MadNCL, Knitro, Uno). All solvers implement the `AbstractStrategy` contract and are
called through `CommonSolve.solve`.

# Solver Types
- `Solvers.Ipopt` - Interior point optimizer, CPU (requires NLPModelsIpopt)
- `Solvers.MadNLP` - Pure-Julia interior point optimizer, CPU/GPU (requires MadNLP)
- `Solvers.MadNCL` - Augmented Lagrangian (NCL) solver built on MadNLP, CPU/GPU
  (requires MadNCL, MadNLP)
- `Solvers.Knitro` - Commercial solver, CPU (requires NLPModelsKnitro)
- `Solvers.Uno` - Unified Lagrange-Newton solver, CPU (requires UnoSolver)

# Architecture
- **Types and logic**: Defined in src/Solvers/ (this module)
- **Backend interfaces**: Implemented in ext/ as minimal extensions
- **Strategy contract**: All solvers implement AbstractStrategy

# Example
```julia
using CTSolvers
using NLPModelsIpopt  # Load backend extension
using ADNLPModels
using CommonSolve

solver = Solvers.Ipopt(max_iter=1000, tol=1e-6)
nlp = ADNLPModel(x -> sum(x.^2), zeros(10))
stats = solve(nlp, solver; display=false)
```

See also: `AbstractNLPSolver`, `Solvers.Ipopt`
"""
module Solvers

# Imports
using DocStringExtensions: TYPEDEF, TYPEDSIGNATURES, TYPEDFIELDS
using SolverCore: SolverCore
using CommonSolve: CommonSolve
using CTBase: Exceptions
using CTBase: Core

# CTBase generic infrastructure
using CTBase: Strategies
using CTBase: Options

# Internal CTSolvers modules
using ..Optimization
using ..Modelers

# Include submodules
include(joinpath(@__DIR__, "abstract_solver.jl"))
include(joinpath(@__DIR__, "ipopt.jl"))
include(joinpath(@__DIR__, "madnlp.jl"))
include(joinpath(@__DIR__, "madncl.jl"))
include(joinpath(@__DIR__, "madnlpsuite.jl"))
include(joinpath(@__DIR__, "knitro.jl"))
include(joinpath(@__DIR__, "uno.jl"))
include(joinpath(@__DIR__, "contract.jl"))
include(joinpath(@__DIR__, "orchestration.jl"))
include(joinpath(@__DIR__, "solver_info.jl"))

# Public API - abstract and concrete types
export AbstractNLPSolver
export Ipopt, MadNLP, MadNCL, Knitro, Uno

# Public API - solver utilities
export extract_solver_infos

end # module Solvers
