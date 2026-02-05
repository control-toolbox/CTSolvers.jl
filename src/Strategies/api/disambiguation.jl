# ============================================================================
# Option disambiguation helpers
# ============================================================================

using DocStringExtensions

"""
$(TYPEDSIGNATURES)

Create a disambiguated option value by tagging it with a target strategy identifier.

This helper function is used to resolve ambiguity when the same option name exists
in multiple strategies (e.g., modeler and solver both have `max_iter`). By wrapping
the value with its target strategy, the orchestration layer can route the option
to the correct strategy.

# Arguments
- `strategy::Symbol`: Target strategy identifier (e.g., `:modeler`, `:solver`)
- `value`: The option value to route to the specified strategy

# Returns
- `Tuple{Any, Symbol}`: A tuple `(value, strategy)` that can be passed as an option value

# Example
```julia-repl
julia> using CTSolvers.Strategies

julia> Strategies.route_to(:solver, 100)
(100, :solver)

julia> Strategies.route_to(:modeler, 1e-6)
(1.0e-6, :modeler)
```

# Notes
- This is a convenience function equivalent to manually creating a tuple `(value, strategy)`
- The tuple format is recognized by the orchestration layer for option routing
- Use this when you need to pass the same option name to different strategies with different values
- The strategy identifier must match a registered strategy ID in the system

# Example with Multiple Strategies
```julia
# Without disambiguation - ambiguous which strategy gets max_iter
solve(ocp; max_iter=100)

# With disambiguation - explicit routing
solve(ocp; 
    max_iter=route_to(:solver, 100),    # Solver gets 100 iterations
    max_iter=route_to(:modeler, 50)     # Modeler gets 50 iterations
)
```

See also: [`build_strategy_options`](@ref), [`StrategyOptions`](@ref)
"""
function route_to(strategy::Symbol, value)
    return (value, strategy)
end
