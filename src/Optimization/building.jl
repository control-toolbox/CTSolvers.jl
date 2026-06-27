# Optimization building API
#
# General API for building NLP models and solutions from optimization problems.

"""
$(TYPEDSIGNATURES)

Build a [`BuiltModel`](@ref) from an optimization problem using the specified modeler.

This is a general function that works with any `AbstractOptimizationProblem`.
The modeler handles the conversion to the specific NLP backend. The returned
[`BuiltModel`](@ref) carries the backend NLP model together with any immutable
build-time auxiliary needed later by [`build_solution`](@ref).

# Arguments
- `prob::AbstractOptimizationProblem`: The optimization problem
- `initial_guess`: Initial guess for the NLP solver
- `modeler`: The modeler strategy (e.g., Modelers.ADNLP, Modelers.Exa)

# Returns
- A [`BuiltModel`](@ref) bundling the backend NLP model and its build-time cache

# Example
```julia
modeler = Modelers.ADNLP(show_time=false)
built = build_model(prob, initial_guess, modeler)
```

See also: `build_solution`, `BuiltModel`
"""
function build_model(prob::AbstractOptimizationProblem, initial_guess, modeler)
    throw(
        Exceptions.NotImplemented(
            "Model building not implemented";
            required_method="build_model(prob::$(typeof(prob)), initial_guess, modeler::$(typeof(modeler)))",
            suggestion="Implement build_model for this (problem, modeler) pair in the package providing the problem",
            context="Optimization.build_model - required method implementation",
        ),
    )
end

"""
$(TYPEDSIGNATURES)

Build a solution from NLP execution statistics using the specified modeler.

Dispatches on the [`BuiltModel`](@ref) returned by [`build_model`](@ref): it
carries both the problem (for problem-level data) and the immutable build-time
cache (e.g. an ExaModels getter) needed to reconstruct the solution.

# Arguments
- `built::BuiltModel`: The built model bundle returned by `build_model`
- `model_solution`: NLP solver output (execution statistics)
- `modeler`: The modeler strategy used for building

# Returns
- A solution object appropriate for the problem type

# Example
```julia
built = build_model(prob, initial_guess, modeler)
nlp_stats = solve(built.nlp, solver)
sol = build_solution(built, nlp_stats, modeler)
```

See also: `build_model`, `BuiltModel`
"""
function build_solution(built::BuiltModel, model_solution, modeler)
    throw(
        Exceptions.NotImplemented(
            "Solution building not implemented";
            required_method="build_solution(built::BuiltModel{$(typeof(built.problem))}, model_solution, modeler::$(typeof(modeler)))",
            suggestion="Implement build_solution for this (problem, modeler) pair in the package providing the problem",
            context="Optimization.build_solution - required method implementation",
        ),
    )
end
