# Built model
#
# Immutable bundle returned by `build_model` and consumed by `build_solution`.
#
# `build_model` produces two things that are both needed downstream: the backend
# NLP model (for the solver) and an optional build-time auxiliary (e.g. a getter
# produced together with an ExaModel). Both travel by value through `BuiltModel`,
# so no mutable cache is needed and the `build_model` -> `build_solution` coupling
# stays explicit and immutable.

"""
$(TYPEDEF)

Empty cache for backends whose `build_model` produces no auxiliary data.

Used as the `cache` field of a [`BuiltModel`](@ref) when nothing besides the NLP
needs to be carried to `build_solution` (e.g. the ADNLP backend). Reusable by any
backend, including the future ODE side.
"""
struct NoCache <: Core.AbstractCache end

"""
$(TYPEDEF)

Immutable bundle produced by [`build_model`](@ref) and consumed by
[`build_solution`](@ref).

It pairs the optimization problem with the backend NLP model and an optional,
immutable build-time cache. This replaces the previous pattern of mutating a
backend cache attached to the problem: any auxiliary produced while building the
NLP (e.g. an ExaModels getter) is stored here once, never mutated.

# Fields
- `problem::TP`: The optimization problem (e.g. `DiscretizedModel`), giving access
  to the original OCP, the discretizer, and the discretize-time cache (`docp`).
- `nlp::TN`: The backend NLP model. Left untyped because its package (e.g.
  `NLPModels`) is a weak dependency.
- `cache::TC`: Immutable build-time auxiliary (`<: CTBase.Core.AbstractCache`),
  populated by `build_model`. [`NoCache`](@ref) when the backend needs none.

# Type parameters
- `TP <: AbstractOptimizationProblem`
- `TN`
- `TC <: CTBase.Core.AbstractCache`

See also: [`build_model`](@ref), [`build_solution`](@ref), [`NoCache`](@ref).
"""
struct BuiltModel{TP<:AbstractOptimizationProblem,TN,TC<:Core.AbstractCache}
    problem::TP
    nlp::TN
    cache::TC
end
