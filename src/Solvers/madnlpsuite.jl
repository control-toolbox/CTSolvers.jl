"""
MadNLP/MadNCL Suite Common Functions

This module contains common functions shared between MadNLP and MadNCL solvers
for GPU/CPU linear solver defaults and consistency validation.
"""

"""
$(TYPEDSIGNATURES)

Return the default linear solver for the given parameter type.

# Arguments
- `parameter_type::Type{<:AbstractStrategyParameter}`: CPU or GPU parameter

# Returns
- `Type{<:MadNLP.AbstractLinearSolver}`: Default linear solver type

# Throws
- `Exceptions.ExtensionError`: If GPU parameter used but MadNLPGPU not loaded

# Notes
- Default implementation throws ExtensionError for GPU
- CPU implementation provided by CTSolversMadNLP extension
- GPU implementation provided by CTSolversMadNLPGPU extension
"""
function __madnlp_suite_default_linear_solver(::Type{<:GPU})
    throw(
        Exceptions.ExtensionError(
            :MadNLPGPU;
            message="to use GPU linear solver with MadNLP/MadNCL",
            feature="GPU computation with MadNLP/MadNCL",
            context="Load MadNLPGPU extension first: using MadNLPGPU",
        ),
    )
end

"""
$(TYPEDSIGNATURES)

Check if linear solver is consistent with parameter type.

# Arguments
- `parameter_type::Type{<:AbstractStrategyParameter}`: CPU or GPU parameter
- `linear_solver::Type`: Linear solver type

# Returns
- `Bool`: true if consistent, false otherwise

# Notes
- Default implementation returns true (all combinations allowed)
- Specific implementations in extensions provide actual consistency checks
"""
function __madnlp_suite_consistent_linear_solver(
    ::Type{<:AbstractStrategyParameter}, linear_solver::Type
)
    return true
end
