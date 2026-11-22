# DOCP conveniences
#
# Convenience wrappers (`nlp_model`, `ocp_solution`) over the modeler contract,
# specialized for `DiscretizedModel` / its `BuiltModel`, and the accessors
# (`nlp_model`, `ocp_model`) of a built `DiscretizedModel`.

"""
$(TYPEDSIGNATURES)

Build an NLP model from a discretized optimal control problem.

This is a convenience wrapper around `build_model` that returns only the backend
NLP model (the `nlp` field of the [`CTSolvers.Optimization.BuiltModel`](@extref)). Use `build_model`
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

See also: [`CTSolvers.DOCP.ocp_solution`](@extref), [`CTSolvers.Optimization.build_model`](@extref),
[`CTSolvers.Optimization.BuiltModel`](@extref)
"""
function nlp_model(
    prob::DiscretizedModel, initial_guess, modeler::Modelers.AbstractNLPModeler
)
    return build_model(prob, initial_guess, modeler).nlp
end

"""
$(TYPEDSIGNATURES)

Return the NLP model of a built discretized optimal control problem.

Accessor of the [`CTSolvers.Optimization.BuiltModel`](@extref) returned by `build_model`
for a [`CTSolvers.DOCP.DiscretizedModel`](@extref): it returns the NLP that was built,
without building anything. A `BuiltModel` of another problem type has no such method.

# Arguments
- `built::Optimization.BuiltModel{<:DiscretizedModel}`: The built model bundle returned by
  `build_model` for a `DiscretizedModel`

# Returns
- The backend NLP model (e.g. an `ADNLPModel` or an `ExaModel`), the `nlp` field of `built`

# Throws
- `MethodError`: if `built` holds a problem that is not a `DiscretizedModel`

# Example
```julia
built = build_model(docp, initial_guess, modeler)
stats = ipopt(nlp_model(built))
sol = ocp_solution(built, stats, modeler)
```

See also: [`CTSolvers.DOCP.ocp_model`](@extref), [`CTSolvers.DOCP.ocp_solution`](@extref),
[`CTSolvers.Optimization.build_model`](@extref)
"""
nlp_model(built::Optimization.BuiltModel{<:DiscretizedModel}) = built.nlp

"""
$(TYPEDSIGNATURES)

Return the original optimal control problem of a built discretized optimal control problem.

Accessor of the [`CTSolvers.Optimization.BuiltModel`](@extref) returned by `build_model`
for a [`CTSolvers.DOCP.DiscretizedModel`](@extref): same result as `ocp_model` on the
`DiscretizedModel` it was built from. A `BuiltModel` of another problem type has no such
method.

# Arguments
- `built::Optimization.BuiltModel{<:DiscretizedModel}`: The built model bundle returned by
  `build_model` for a `DiscretizedModel`

# Returns
- The original optimal control problem

# Throws
- `MethodError`: if `built` holds a problem that is not a `DiscretizedModel`

# Example
```julia
built = build_model(docp, initial_guess, modeler)
ocp_model(built) === ocp_model(docp)  # true
```

See also: [`CTSolvers.DOCP.nlp_model`](@extref), [`CTSolvers.DOCP.DiscretizedModel`](@extref)
"""
ocp_model(built::Optimization.BuiltModel{<:DiscretizedModel}) = ocp_model(built.problem)

"""
$(TYPEDSIGNATURES)

Build an optimal control solution from NLP execution statistics.

This is a convenience wrapper around `build_solution` that dispatches on the
[`CTSolvers.Optimization.BuiltModel`](@extref) returned by `build_model` and ensures the return type is an
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

See also: [`CTSolvers.DOCP.nlp_model`](@extref), [`CTSolvers.Optimization.build_solution`](@extref),
[`CTSolvers.Optimization.BuiltModel`](@extref)
"""
function ocp_solution(
    built::Optimization.BuiltModel,
    model_solution::SolverCore.AbstractExecutionStats,
    modeler::Modelers.AbstractNLPModeler,
)
    return build_solution(built, model_solution, modeler)
end
