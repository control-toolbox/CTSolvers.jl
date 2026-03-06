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
- Implement `(modeler)(prob::Optimization.AbstractOptimizationProblem, initial_guess)`
- Implement `(modeler)(prob::Optimization.AbstractOptimizationProblem, stats::SolverCore.AbstractExecutionStats)`

# Example
```julia
struct MyModeler <: AbstractNLPModeler
    options::Strategies.StrategyOptions
end

Strategies.id(::Type{<:MyModeler}) = :my_modeler

function (modeler::MyModeler)(
    prob::Optimization.AbstractOptimizationProblem,
    initial_guess
)
    # Build NLP model from problem and initial guess
    return nlp_model
end
```

See also: [`Strategies.AbstractStrategy`](@ref), [`Optimization.build_model`](@ref), [`Optimization.build_solution`](@ref)
"""
abstract type AbstractNLPModeler <: Strategies.AbstractStrategy end

"""
$(TYPEDSIGNATURES)

Build an NLP model from a discretized optimal control problem and initial guess.

# Arguments
- `modeler::AbstractNLPModeler`: The modeler strategy instance
- `prob::Optimization.AbstractOptimizationProblem`: The discretized optimal control problem
- `initial_guess`: Initial guess for optimization variables

# Returns
- An NLP model compatible with the target backend (e.g., ADNLPModel, ExaModel)

# Throws
- `CTBase.Exceptions.NotImplemented`: If not implemented by concrete type
"""
function (modeler::AbstractNLPModeler)(
    ::Optimization.AbstractOptimizationProblem, 
    initial_guess
)
    throw(Exceptions.NotImplemented(
        "Model building not implemented",
        required_method="(modeler::$(typeof(modeler)))(prob::Optimization.AbstractOptimizationProblem, initial_guess)",
        suggestion="Implement the callable method for $(typeof(modeler)) to build NLP models",
        context="AbstractNLPModeler - required method implementation"
    ))
end

"""
$(TYPEDSIGNATURES)

Build a solution object from a discretized optimal control problem and NLP solution.

# Arguments
- `modeler::AbstractNLPModeler`: The modeler strategy instance
- `prob::Optimization.AbstractOptimizationProblem`: The discretized optimal control problem
- `nlp_solution::SolverCore.AbstractExecutionStats`: Solution from NLP solver

# Returns
- A solution object appropriate for the problem type

# Throws
- `CTBase.Exceptions.NotImplemented`: If not implemented by concrete type
"""
function (modeler::AbstractNLPModeler)(
    ::Optimization.AbstractOptimizationProblem,
    ::SolverCore.AbstractExecutionStats
)
    throw(Exceptions.NotImplemented(
        "Solution building not implemented",
        required_method="(modeler::$(typeof(modeler)))(prob::Optimization.AbstractOptimizationProblem, nlp_solution::SolverCore.AbstractExecutionStats)",
        suggestion="Implement the callable method for $(typeof(modeler)) to build solution objects",
        context="AbstractNLPModeler - required method implementation"
    ))
end
