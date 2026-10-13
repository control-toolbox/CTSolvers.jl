"""
    CTSolvers

Control Toolbox Solvers (CTSolvers) - the resolution layer of the control-toolbox ecosystem.

CTSolvers provides the strategies (NLP modelers, NLP solvers, ODE integrators) and the
abstract problem types used by CTDirect (direct methods) and CTFlows (flows for indirect
methods). Backends are optional: each one is activated by loading its package, which
triggers the corresponding extension in `ext/`.

# Modules

Loaded in dependency order:

- **Optimization**: abstract problem type, `BuiltModel`/`NoCache`, `build_model`/`build_solution`
- **Modelers**: NLP backend selection (`Modelers.ADNLP`, `Modelers.Exa`)
- **DOCP**: `AbstractDiscretizer`, `DiscretizedModel`, `discretize`
- **Solvers**: NLP solvers (`Solvers.Ipopt`, `Solvers.MadNLP`, `Solvers.MadNCL`,
  `Solvers.Knitro`, `Solvers.Uno`) and the high-level `CommonSolve.solve` pipeline
- **Integrators**: ODE integrators (`Integrators.SciML`) and integration results

The generic strategy, option and routing infrastructure (`CTBase.Strategies`,
`CTBase.Options`, `CTBase.Orchestration`) is provided by CTBase.

# Public API

CTSolvers exports nothing at the top level: use qualified paths, e.g.
`CTSolvers.Solvers.Ipopt(max_iter=100)` or `CTSolvers.Integrators.final_state(result)`.
"""
module CTSolvers

# Optimization module - general optimization abstractions and builders
include(joinpath(@__DIR__, "Optimization", "Optimization.jl"))
using .Optimization

# Modelers module - backend modeler implementations (Modelers.ADNLP, Modelers.Exa)
include(joinpath(@__DIR__, "Modelers", "Modelers.jl"))
using .Modelers

# DOCP module - Discretized Optimal Control Problem types and operations
include(joinpath(@__DIR__, "DOCP", "DOCP.jl"))
using .DOCP

# Solvers module - optimization solver implementations and CommonSolve API
include(joinpath(@__DIR__, "Solvers", "Solvers.jl"))
using .Solvers

# Integrators module - ODE integrator strategies and CommonSolve API
include(joinpath(@__DIR__, "Integrators", "Integrators.jl"))
using .Integrators

end
