# DOCP contract implementation
#
# Implements the `Optimization.AbstractOptimizationProblem` contract for
# `DiscretizedModel`.

"""
$(TYPEDSIGNATURES)

Get the ADNLPModels model builder from a DiscretizedModel.

This implements the `Optimization.AbstractOptimizationProblem` contract.

# Arguments
- `prob::DiscretizedModel`: The discretized problem

# Returns
- `AbstractModelBuilder`: The ADNLP model builder

# Example
```julia
builder = Optimization.get_adnlp_model_builder(docp)
nlp = builder(initial_guess)
```

See also: `Optimization.get_exa_model_builder`
"""
function Optimization.get_adnlp_model_builder(prob::DiscretizedModel)
    return prob.adnlp_model_builder
end

"""
$(TYPEDSIGNATURES)

Get the ExaModels model builder from a DiscretizedModel.

This implements the `Optimization.AbstractOptimizationProblem` contract.

# Arguments
- `prob::DiscretizedModel`: The discretized problem

# Returns
- `AbstractModelBuilder`: The ExaModel builder

# Example
```julia
builder = Optimization.get_exa_model_builder(docp)
nlp = builder(Float64, initial_guess)
```

See also: `Optimization.get_adnlp_model_builder`
"""
function Optimization.get_exa_model_builder(prob::DiscretizedModel)
    return prob.exa_model_builder
end

"""
$(TYPEDSIGNATURES)

Get the ADNLPModels solution builder from a DiscretizedModel.

This implements the `Optimization.AbstractOptimizationProblem` contract.

# Arguments
- `prob::DiscretizedModel`: The discretized problem

# Returns
- `AbstractSolutionBuilder`: The ADNLP solution builder

# Example
```julia
builder = Optimization.get_adnlp_solution_builder(docp)
sol = builder(nlp_stats)
```

See also: `Optimization.get_exa_solution_builder`
"""
function Optimization.get_adnlp_solution_builder(prob::DiscretizedModel)
    return prob.adnlp_solution_builder
end

"""
$(TYPEDSIGNATURES)

Get the ExaModels solution builder from a DiscretizedModel.

This implements the `Optimization.AbstractOptimizationProblem` contract.

# Arguments
- `prob::DiscretizedModel`: The discretized problem

# Returns
- `AbstractSolutionBuilder`: The ExaModel solution builder

# Example
```julia
builder = Optimization.get_exa_solution_builder(docp)
sol = builder(nlp_stats)
```

See also: `Optimization.get_adnlp_solution_builder`
"""
function Optimization.get_exa_solution_builder(prob::DiscretizedModel)
    return prob.exa_solution_builder
end
