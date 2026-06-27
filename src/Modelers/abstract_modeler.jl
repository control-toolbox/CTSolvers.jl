# Abstract modeler
#
# Defines the `AbstractNLPModeler` strategy contract.

"""
$(TYPEDEF)

Abstract base type for all modeler strategies.

Modeler strategies are responsible for converting discretized optimization
problems (`Optimization.AbstractOptimizationProblem`) into NLP backend models.
They implement the `Strategies.AbstractStrategy` contract together with named
model- and solution-building methods.

# Implementation Requirements
All concrete modeler strategies must:
- Implement the `Strategies.AbstractStrategy` contract
- Have the package providing the problem implement, by multiple dispatch:
  - `Optimization.build_model(prob, initial_guess, modeler)` returning a
    `Optimization.BuiltModel`
  - `Optimization.build_solution(built::Optimization.BuiltModel, nlp_solution, modeler)`

# Example
```julia
struct MyModeler <: AbstractNLPModeler
    options::Strategies.StrategyOptions
end

Strategies.id(::Type{<:MyModeler}) = :my_modeler

# In the package providing the concrete problem type:
function Optimization.build_model(prob::MyProblem, initial_guess, modeler::MyModeler)
    # Build NLP model from problem and initial guess
    nlp = ...
    return Optimization.BuiltModel(prob, nlp, Optimization.NoCache())
end

function Optimization.build_solution(built::Optimization.BuiltModel{<:MyProblem}, nlp_solution, ::MyModeler)
    # Reconstruct the problem-level solution from built and nlp_solution
    return solution
end
```

See also: `Strategies.AbstractStrategy`, `Optimization.build_model`, `Optimization.build_solution`
"""
abstract type AbstractNLPModeler <: Strategies.AbstractStrategy end
