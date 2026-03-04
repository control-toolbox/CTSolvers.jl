# DOCP accessors
#
# Accessor functions for `DiscretizedModel`.

"""
$(TYPEDSIGNATURES)

Extract the original optimal control problem from a discretized problem.

# Arguments
- `docp::DiscretizedModel`: The discretized optimal control problem

# Returns
- The original optimal control problem

# Example
```julia
ocp = ocp_model(docp)
```

See also: [`DiscretizedModel`](@ref)
"""
ocp_model(docp::DiscretizedModel) = docp.optimal_control_problem
