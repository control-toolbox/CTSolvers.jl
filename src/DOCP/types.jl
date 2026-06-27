# DOCP types
#
# Defines the `DiscretizedModel` type: a thin pairing of an optimal control
# problem with the discretizer that produced it, plus an optional backend cache.

"""
$(TYPEDEF)

Discretized optimal control problem ready for NLP solving.

A thin pairing of an optimal control problem with the discretizer that produced
it, plus a backend cache. The actual NLP model and OCP solution are produced by
multiple dispatch on `(DiscretizedModel, modeler)` through the `build_model` /
`build_solution` contract, implemented in the package providing the discretizer
(e.g. CTDirect). This mirrors `Flow{system, integrator}` on the ODE side.

# Fields
- `ocp::TO`: The original optimal control problem.
- `discretizer::TD`: The discretization strategy used.
- `cache::TC`: Backend cache (`<: CTBase.Core.AbstractCache`), opaque to CTSolvers,
  populated by the implementing package (e.g. CTDirect's `DOCPCache`).

# Type parameters
- `TO <: CTModels.AbstractModel`
- `TD <: AbstractDiscretizer`
- `TC <: CTBase.Core.AbstractCache`

See also: `ocp_model`, `discretize`, `build_model`, `build_solution`.
"""
struct DiscretizedModel{
    TO<:CTModels.AbstractModel,
    TD<:AbstractDiscretizer,
    TC<:Core.AbstractCache,
} <: AbstractOptimizationProblem
    ocp::TO
    discretizer::TD
    cache::TC
end
