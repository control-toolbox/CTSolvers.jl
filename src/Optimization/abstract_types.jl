# Optimization abstract types
#
# General abstract types for optimization problems.

"""
$(TYPEDEF)

Abstract base type for optimization problems.

This is a general type that represents any optimization problem, not necessarily
tied to optimal control. Subtypes can represent various problem formulations
including discretized optimal control problems, general NLP problems, etc.

Subtypes are typically paired with AbstractModelBuilder and AbstractSolutionBuilder
implementations that know how to construct and interpret NLP back-end models and solutions.

# Example
```julia
struct MyOptimizationProblem <: AbstractOptimizationProblem
    objective::Function
    constraints::Vector{Function}
end
```
"""
abstract type AbstractOptimizationProblem end
