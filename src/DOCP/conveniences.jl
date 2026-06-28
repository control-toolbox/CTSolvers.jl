# DOCP conveniences
#
# Convenience wrappers (`nlp_model`, `ocp_solution`) over the modeler contract,
# specialized for `DiscretizedModel` / its `BuiltModel`.

"""
$(TYPEDSIGNATURES)

Build an NLP model from a discretized optimal control problem.

This is a convenience wrapper around `build_model` that returns only the backend
NLP model (the `nlp` field of the [`BuiltModel`](@ref)). Use `build_model`
directly when the build-time cache is needed (e.g. before `build_solution`).

# Arguments
- `prob::DiscretizedModel`: The discretized OCP
- `initial_guess`: Initial guess for the NLP solver
- `modeler`: The modeler to use (e.g., Modelers.ADNLP, Modelers.Exa)

# Returns
- `NLPModels.AbstractNLPModel`: The NLP model

# Example
```julia
nlp = nlp_model(docp, initial_guess, modeler)
```

See also: `ocp_solution`, `Optimization.build_model`, `Optimization.BuiltModel`
"""
function nlp_model(
    prob::DiscretizedModel, initial_guess, modeler::Modelers.AbstractNLPModeler
)
    return build_model(prob, initial_guess, modeler).nlp
end

"""
$(TYPEDSIGNATURES)

Build an optimal control solution from NLP execution statistics.

This is a convenience wrapper around `build_solution` that dispatches on the
[`BuiltModel`](@ref) returned by `build_model` and ensures the return type is an
optimal control solution.

# Arguments
- `built::BuiltModel`: The built model bundle returned by `build_model`
- `model_solution::SolverCore.AbstractExecutionStats`: NLP solver output
- `modeler`: The modeler used for building

# Returns
- `AbstractSolution`: The OCP solution

# Example
```julia
built = build_model(docp, initial_guess, modeler)
sol = ocp_solution(built, nlp_stats, modeler)
```

See also: `nlp_model`, `Optimization.build_solution`, `Optimization.BuiltModel`
"""
function ocp_solution(
    built::Optimization.BuiltModel,
    model_solution::SolverCore.AbstractExecutionStats,
    modeler::Modelers.AbstractNLPModeler,
)
    return build_solution(built, model_solution, modeler)
end
