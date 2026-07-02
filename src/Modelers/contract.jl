# Modeler contract
#
# Canonical contract for modeler strategies: the generic `Optimization.build_model`
# / `Optimization.build_solution` methods, dispatched on `AbstractNLPModeler`. These
# are `NotImplemented` stubs; the package providing the concrete problem implements
# them by multiple dispatch on the concrete `(problem, modeler)` pair (e.g. CTDirect
# for `(DiscretizedModel, ADNLP/Exa)`). Defining these methods here also creates the
# `Optimization.build_model` / `Optimization.build_solution` generic functions.

"""
$(TYPEDSIGNATURES)

Build a [`Optimization.BuiltModel`](@ref) from an optimization problem using the
specified modeler.

This is the modeler contract: the modeler converts the problem into a backend NLP
model. The returned [`Optimization.BuiltModel`](@ref) carries the backend NLP model
together with any immutable build-time auxiliary needed later by
[`Optimization.build_solution`](@ref).

# Contract
Must be implemented in the package providing the concrete problem, dispatching on the
concrete `(problem, modeler)` pair, e.g.
`Optimization.build_model(prob::DiscretizedModel, init, ::ADNLP)` in CTDirect. This
generic stub throws [`CTBase.Exceptions.NotImplemented`](@extref).

# Arguments
- `prob::Optimization.AbstractOptimizationProblem`: The optimization problem.
- `initial_guess`: Initial guess for the NLP solver.
- `modeler::AbstractNLPModeler`: The modeler strategy (e.g. `ADNLP`, `Exa`).

# Returns
- A [`Optimization.BuiltModel`](@ref) bundling the backend NLP model and its build-time cache.

# Throws
- [`CTBase.Exceptions.NotImplemented`](@extref): when no method exists for this
  `(problem, modeler)` pair.

See also: `Optimization.build_solution`, `Optimization.BuiltModel`.
"""
function Optimization.build_model(
    prob::Optimization.AbstractOptimizationProblem,
    initial_guess,
    modeler::AbstractNLPModeler,
)
    return throw(
        Exceptions.NotImplemented(
            "Model building not implemented";
            required_method="Optimization.build_model(prob::$(typeof(prob)), initial_guess, modeler::$(typeof(modeler)))",
            suggestion="Implement build_model for this (problem, modeler) pair in the package providing the problem",
            context="Modelers.build_model - required method implementation",
        ),
    )
end

"""
$(TYPEDSIGNATURES)

Build a problem-level solution from NLP execution statistics using the specified
modeler.

This is the modeler contract: it reconstructs the solution from the
[`Optimization.BuiltModel`](@ref) returned by [`Optimization.build_model`](@ref)
(which carries the problem and the immutable build-time cache) and the solver output.

# Contract
Must be implemented in the package providing the concrete problem, dispatching on the
concrete `(built, modeler)` pair, e.g.
`Optimization.build_solution(built::BuiltModel{<:DiscretizedModel}, stats, ::ADNLP)`
in CTDirect. This generic stub throws [`CTBase.Exceptions.NotImplemented`](@extref).

# Arguments
- `built::Optimization.BuiltModel`: The bundle returned by `build_model`.
- `model_solution`: NLP solver output (execution statistics).
- `modeler::AbstractNLPModeler`: The modeler strategy used for building.

# Returns
- A solution object appropriate for the problem type.

# Throws
- [`CTBase.Exceptions.NotImplemented`](@extref): when no method exists for this
  `(problem, modeler)` pair.

See also: `Optimization.build_model`, `Optimization.BuiltModel`.
"""
function Optimization.build_solution(
    built::Optimization.BuiltModel, model_solution, modeler::AbstractNLPModeler
)
    return throw(
        Exceptions.NotImplemented(
            "Solution building not implemented";
            required_method="Optimization.build_solution(built::BuiltModel{$(typeof(built.problem))}, model_solution, modeler::$(typeof(modeler)))",
            suggestion="Implement build_solution for this (problem, modeler) pair in the package providing the problem",
            context="Modelers.build_solution - required method implementation",
        ),
    )
end
