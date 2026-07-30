"""
    Integrators

ODE integrator strategies for the Control Toolbox.

This module provides concrete integrator strategies that integrate ODE problems through a
unified `CommonSolve.solve(prob, integrator)` interface. It mirrors the `Solvers` module:
the strategy *types* and contract stubs live here, the backend interfaces live in `ext/`.

# Integrator Types
- `Integrators.SciML` - SciML ODE integrator (requires OrdinaryDiffEqTsit5/OrdinaryDiffEq/DifferentialEquations)

# Architecture
- **Types and contract**: Defined in src/Integrators/ (this module).
- **Backend interfaces**: Implemented in ext/ as minimal extensions.
- **Strategy contract**: All integrators implement `AbstractStrategy`.

# Example
```julia
using CTSolvers
using OrdinaryDiffEqTsit5      # Load backend extension
using CommonSolve

integ = Integrators.SciML(alg=Tsit5())

# `prob` is an external SciMLBase.ODEProblem
result = solve(prob, integ)
final = Integrators.final_state(result)
```

See also: `AbstractIntegrator`, `Integrators.SciML`.
"""
module Integrators

# Imports
using DocStringExtensions: TYPEDEF, TYPEDSIGNATURES, TYPEDFIELDS
using CommonSolve: CommonSolve
using CTBase: Exceptions
using CTBase: Core
using CTModels: Solutions

# `Integrators.status`/`Integrators.successful` are aliases onto the CTModels.Solutions
# generics (same Function objects), so extending `Integrators.status` and calling it
# unqualified both act on `Solutions.status` — see BREAKING.md.
const status = Solutions.status
const successful = Solutions.successful

# CTBase generic infrastructure
using CTBase: Strategies
using CTBase: Options

# Include submodules
include(joinpath(@__DIR__, "abstract_integrator.jl"))
include(joinpath(@__DIR__, "integration_result.jl"))
include(joinpath(@__DIR__, "sciml.jl"))
include(joinpath(@__DIR__, "contract.jl"))
include(joinpath(@__DIR__, "internal_norm.jl"))

# Public API - abstract and concrete types
export AbstractIntegrator, AbstractSciMLIntegrator, SciML, SciMLTag, Tsit5Tag

# Public API - integration result
export AbstractIntegrationResult, final_state, times, evaluate_at, status, successful

# Public API - construction and accessors
export options_point, options_trajectory

# Public API - multi-phase
export merge

end # module Integrators
