# DOCP types
#
# Defines the `DiscretizedModel` type. Builder types live in the
# `CTSolvers.Optimization` module.

"""
$(TYPEDEF)

Discretized optimal control problem ready for NLP solving.

Wraps an optimal control problem together with builders for the supported NLP backends.
This type implements the `Optimization.AbstractOptimizationProblem` contract.

# Fields
- `optimal_control_problem::TO`: The original optimal control problem
- `adnlp_model_builder::TAMB`: Builder for ADNLPModels
- `exa_model_builder::TEMB`: Builder for ExaModels
- `adnlp_solution_builder::TASB`: Builder for ADNLP solutions
- `exa_solution_builder::TESB`: Builder for ExaModel solutions

# Example
```julia
# Conceptual usage pattern
docp = DiscretizedModel(
    ocp,
    adnlp_model_builder,
    exa_model_builder,
    adnlp_solution_builder,
    exa_solution_builder,
)
```

See also: [`ocp_model`](@ref), [`nlp_model`](@ref), [`ocp_solution`](@ref)
"""
struct DiscretizedModel{
    TO<:CTModels.AbstractModel,
    TAMB<:AbstractModelBuilder,
    TEMB<:AbstractModelBuilder,
    TASB<:AbstractSolutionBuilder,
    TESB<:AbstractSolutionBuilder
} <: AbstractOptimizationProblem
    optimal_control_problem::TO
    adnlp_model_builder::TAMB
    exa_model_builder::TEMB
    adnlp_solution_builder::TASB
    exa_solution_builder::TESB
end
