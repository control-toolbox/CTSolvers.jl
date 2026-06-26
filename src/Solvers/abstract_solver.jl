"""
$(TYPEDEF)

Abstract base type for optimization solvers in the Control Toolbox.

All concrete solver types must:
1. Be a subtype of `AbstractNLPSolver`
2. Implement the `AbstractStrategy` contract:
   - `Strategies.id(::Type{<:MySolver})` - Return unique Symbol identifier
   - `Strategies.metadata(::Type{<:MySolver})` - Return StrategyMetadata with options
   - Have an `options::Strategies.StrategyOptions` field
3. Implement the solve method (typically in a backend extension):
   - `CommonSolve.solve(nlp::NLPModels.AbstractNLPModel, solver::MySolver; display=Bool)`

# Solver Types
- `Solvers.Ipopt` - Interior point optimizer (Ipopt backend)
- `Solvers.MadNLP` - Matrix-free augmented Lagrangian (MadNLP backend)
- `Solvers.MadNCL` - NCL variant of MadNLP
- `Solvers.Knitro` - Commercial solver (Knitro backend)

# Example
```julia
using CommonSolve

# Create solver with options
solver = Solvers.Ipopt(max_iter=1000, tol=1e-8)

# Solve an NLP problem
nlp = ADNLPModel(x -> sum(x.^2), zeros(10))
stats = solve(nlp, solver; display=true)
```

See also: `Solvers.Ipopt`, `Solvers.MadNLP`, `Solvers.MadNCL`, `Solvers.Knitro`, `CommonSolve.solve`
"""
abstract type AbstractNLPSolver <: Strategies.AbstractStrategy end
