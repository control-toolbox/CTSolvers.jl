"""
$(TYPEDEF)

Abstract strategy for solving ODE Cauchy problems.

An `AbstractIntegrator` is a strategy that integrates an ODE problem over a time span.
It inherits the `CTBase.Strategies` strategy contract:

# Type-Level Contract (Static Metadata)

Methods defined on the **type** that describe what the integrator can do:
- `Strategies.id(::Type{<:S}) → Symbol`: Unique identifier for routing and introspection.
- `Strategies.metadata(::Type{<:S}) → StrategyMetadata`: Option specifications and validation rules.

# Instance-Level Contract (Configured State)

Methods defined on **instances** that provide the actual configuration:
- `Strategies.options(s::S) → StrategyOptions`: Current option values with provenance tracking.

# Concrete Implementation

Concrete integrators implement, typically in a backend extension:
- `CommonSolve.solve(prob, integrator::S; options, unsafe)`: integrate the (external) ODE
  problem `prob` with the resolved `options`, returning an [`AbstractIntegrationResult`](@ref).
- [`merge`](@ref): concatenate a sequence of integration results (multi-phase trajectories).

The cached per-call option dictionaries are exposed through the
[`options_point`](@ref) / [`options_trajectory`](@ref) accessors.

See also: [`CTSolvers.Integrators.SciML`](@ref), [`CTSolvers.Integrators.AbstractIntegrationResult`](@ref).
"""
abstract type AbstractIntegrator <: Strategies.AbstractStrategy end
