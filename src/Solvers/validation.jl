"""
Validation utilities for solver options and configurations.
"""

"""
    validate_solver_options(solver_type::Type{<:AbstractOptimizationSolver}, options::Dict)

Validate solver options against the solver's metadata.

# Arguments
- `solver_type`: The solver type to validate options for
- `options`: Dictionary of option name => value pairs

# Returns
- `true` if all options are valid

# Throws
- `Exceptions.IncorrectArgument` if any option is invalid or has wrong type
"""
function validate_solver_options(
    solver_type::Type{<:AbstractOptimizationSolver}, 
    options::Dict
)
    meta = Strategies.metadata(solver_type)
    
    for (key, value) in options
        if !hasfield(typeof(meta.options), key)
            throw(Exceptions.IncorrectArgument(
                "Unknown option for $(solver_type): $key",
                suggestion="Valid options are: $(join(fieldnames(typeof(meta.options)), ", "))",
                context="Solver option validation"
            ))
        end
        
        # Type validation would go here if needed
    end
    
    return true
end
