"""
CTSolversMadNLPGPU Extension

Extension providing GPU linear solver functionality for MadNLP and MadNCL solvers.
Implements GPU-specific linear solver defaults and consistency validation.
"""

module CTSolversMadNLPGPU

import CTSolvers.Solvers
import CTSolvers.Strategies
import MadNLPGPU
import DocStringExtensions

"""
$(DocStringExtensions.TYPEDSIGNATURES)

Return the default linear solver for GPU execution.

# Returns
- `MadNLPGPU.CUDSSSolver`: Default GPU linear solver

# Notes
- Overrides the stub implementation in CTSolvers.Solvers
- Used automatically when MadNLP{GPU} or MadNCL{GPU} is created
"""
function Solvers.__madnlp_suite_default_linear_solver(::Type{Strategies.GPU})
    return MadNLPGPU.CUDSSSolver
end

"""
$(DocStringExtensions.TYPEDSIGNATURES)

Check if CUDSSSolver is consistent with CPU parameter.

# Arguments
- `parameter_type::Type{CPU}`: CPU parameter type
- `linear_solver::MadNLPGPU.CUDSSSolver`: GPU linear solver type

# Returns
- `Bool`: false (GPU linear solver inconsistent with CPU parameter)

# Notes
- GPU linear solver should not be used with CPU parameter
- Other linear solvers fall through to default implementation (returns true)
"""
function Solvers.__madnlp_suite_consistent_linear_solver(::Type{Strategies.CPU}, linear_solver::Type{MadNLPGPU.CUDSSSolver})
    return false
end

"""
$(DocStringExtensions.TYPEDSIGNATURES)

Check if CUDSSSolver is consistent with GPU parameter.

# Arguments
- `parameter_type::Type{GPU}`: GPU parameter type
- `linear_solver::MadNLPGPU.CUDSSSolver`: GPU linear solver type

# Returns
- `Bool`: true (CUDSSSolver consistent with GPU parameter)

# Notes
- CUDSSSolver is the recommended linear solver for GPU parameter
- Other linear solvers fall through to default implementation (returns true)
"""
function Solvers.__madnlp_suite_consistent_linear_solver(::Type{Strategies.GPU}, linear_solver::Type{MadNLPGPU.CUDSSSolver})
    return true
end

end # module CTSolversMadNLPGPU
