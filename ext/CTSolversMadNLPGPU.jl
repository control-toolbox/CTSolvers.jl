"""
CTSolversMadNLPGPU Extension

Extension providing GPU linear solver functionality for MadNLP and MadNCL solvers.
Implements GPU-specific linear solver defaults and consistency validation.
"""

module CTSolversMadNLPGPU

using CTSolvers: Solvers
using CTBase: Strategies
using MadNLPGPU: MadNLPGPU
using DocStringExtensions: DocStringExtensions

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

Check if `linear_solver` is consistent with CPU parameter.

# Arguments
- `parameter_type::Type{Strategies.CPU}`: CPU parameter type
- `linear_solver::Type`: Linear solver type

# Returns
- `Bool`: false when `linear_solver` is `MadNLPGPU.CUDSSSolver` (GPU-only solver on CPU
  parameter is inconsistent), true otherwise

# Notes
- `MadNLPGPU.CUDSSSolver` is read here, inside the method body, rather than baked into the
  dispatch signature as `Type{MadNLPGPU.CUDSSSolver}`. That global can be `nothing` or a
  concrete type depending on whether `MadNLPGPUCUDAExt` has armed by the time *this*
  extension gets loaded/precompiled — an ordering Julia does not guarantee even when both
  extensions share overlapping triggers. Dispatching on `linear_solver::Type` and comparing
  with `===` at call time reads the current value instead of whatever was frozen into the
  precompile cache, so this stays correct regardless of extension load order.
"""
function Solvers.__madnlp_suite_consistent_linear_solver(
    ::Type{Strategies.CPU}, linear_solver::Type
)
    return linear_solver !== MadNLPGPU.CUDSSSolver
end

"""
$(DocStringExtensions.TYPEDSIGNATURES)

Check if `linear_solver` is consistent with GPU parameter.

# Arguments
- `parameter_type::Type{Strategies.GPU}`: GPU parameter type
- `linear_solver::Type`: Linear solver type

# Returns
- `Bool`: true — `MadNLPGPU.CUDSSSolver` is the recommended linear solver for GPU
  parameter, and any other type reaching this method (not intercepted by a more specific
  override, e.g. the CPU-only solvers flagged in `CTSolversMadNLP`) falls back to the same
  "consistent" default as `Solvers.__madnlp_suite_consistent_linear_solver`'s generic stub.

# Notes
- See the CPU method above for why this reads `MadNLPGPU.CUDSSSolver` dynamically rather
  than dispatching on `Type{MadNLPGPU.CUDSSSolver}`.
"""
function Solvers.__madnlp_suite_consistent_linear_solver(::Type{Strategies.GPU}, ::Type)
    return true
end

end # module CTSolversMadNLPGPU
