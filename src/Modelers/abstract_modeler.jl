# Abstract modeler
#
# Defines the `AbstractNLPModeler` strategy contract.

"""
$(TYPEDEF)

Abstract base type for all modeler strategies.

Modeler strategies are responsible for converting discretized optimization
problems (`Optimization.AbstractOptimizationProblem`) into NLP backend models.
They implement the `Strategies.AbstractStrategy` contract and provide callable
interfaces for model and solution building.

# Implementation Requirements
All concrete modeler strategies must:
- Implement the `Strategies.AbstractStrategy` contract
- Have the package providing the problem implement, by multiple dispatch on
  `(prob, modeler)`:
  - `Optimization.build_model(prob, initial_guess, modeler)`
  - `Optimization.build_solution(prob, nlp_solution, modeler)`

# Example
```julia
struct MyModeler <: AbstractNLPModeler
    options::Strategies.StrategyOptions
end

Strategies.id(::Type{<:MyModeler}) = :my_modeler

# In the package providing the concrete problem type:
function Optimization.build_model(prob::MyProblem, initial_guess, ::MyModeler)
    # Build NLP model from problem and initial guess
    return nlp_model
end
```

See also: `Strategies.AbstractStrategy`, `Optimization.build_model`, `Optimization.build_solution`
"""
abstract type AbstractNLPModeler <: Strategies.AbstractStrategy end
