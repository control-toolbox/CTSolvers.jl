# DOCP contract
#
# Generic entry points implemented (by multiple dispatch) in the package that
# provides the discretizer (e.g. CTDirect). The methods here are stubs that throw
# `NotImplemented` so that a missing implementation fails with a clear message.

"""
$(TYPEDSIGNATURES)

Discretize an optimal control problem into a [`DiscretizedModel`](@ref).

# Contract
Must be implemented in the package providing `discretizer`, dispatching on its
concrete type, e.g. `CTSolvers.discretize(ocp, ::Collocation)` in CTDirect.

# Arguments
- `ocp::CTModels.AbstractModel`: The optimal control problem.
- `discretizer::AbstractDiscretizer`: The discretization strategy.

# Returns
- A [`DiscretizedModel`](@ref) with a populated cache.

See also: `build_model`, `build_solution`.
"""
function discretize(ocp::CTModels.AbstractModel, discretizer::AbstractDiscretizer)
    throw(
        Exceptions.NotImplemented(
            "discretize not implemented";
            required_method="CTSolvers.discretize(ocp, ::$(typeof(discretizer)))",
            suggestion="Implement it in the package providing $(typeof(discretizer))",
            context="DOCP.discretize - required method implementation",
        ),
    )
end
