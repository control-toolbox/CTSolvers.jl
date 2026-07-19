"""
CTSolversCUDA Extension

Extension providing CUDA functionality for CTSolvers:
- `Modelers.Exa` GPU backend defaults and backend consistency validation;
- `Integrators.SciML{P}` initial-condition/device consistency validation.
"""

module CTSolversCUDA

import CTSolvers.Modelers
import CTSolvers.Integrators
import CTBase.Strategies
using CUDA: CUDA
using DocStringExtensions: DocStringExtensions

"""
$(DocStringExtensions.TYPEDSIGNATURES)

Return the CUDA backend for GPU execution.

# Returns
- `CUDA.CUDABackend()`: CUDA backend object

# Notes
- Issues a warning if CUDA is loaded but not functional
- Overrides the stub implementation in CTSolvers.Modelers
"""
function Modelers.__get_cuda_backend(::Type{Strategies.GPU})
    if !CUDA.functional()
        @warn "CUDA is loaded but not functional. GPU backend may not work properly." maxlog=1
    end
    return CUDA.CUDABackend()
end

"""
$(DocStringExtensions.TYPEDSIGNATURES)

Check if CUDA backend is consistent with CPU parameter.

# Arguments
- `parameter_type::Type{CPU}`: CPU parameter type
- `backend::CUDA.CUDABackend`: CUDA backend to check

# Returns
- `Bool`: false (CUDA backend inconsistent with CPU parameter)

# Notes
- CUDA backend should not be used with CPU parameter
- Other backends fall through to default implementation (returns true)
"""
function Modelers.__consistent_backend(::Type{Strategies.CPU}, backend::CUDA.CUDABackend)
    return false
end

"""
$(DocStringExtensions.TYPEDSIGNATURES)

Check if no backend is consistent with GPU parameter.

# Arguments
- `parameter_type::Type{GPU}`: GPU parameter type
- `backend::Nothing`: No backend

# Returns
- `Bool`: false (no backend inconsistent with GPU parameter)

# Notes
- GPU parameter requires a backend
- CUDA backend case handled by separate method
"""
function Modelers.__consistent_backend(::Type{Strategies.GPU}, backend::Nothing)
    return false
end

"""
$(DocStringExtensions.TYPEDSIGNATURES)

Check if CUDA backend is consistent with GPU parameter.

# Arguments
- `parameter_type::Type{GPU}`: GPU parameter type
- `backend::CUDA.CUDABackend`: CUDA backend to check

# Returns
- `Bool`: true (CUDA backend consistent with GPU parameter)

# Notes
- CUDA backend is the recommended backend for GPU parameter
- Other backends fall through to default implementation (returns true)
"""
function Modelers.__consistent_backend(::Type{Strategies.GPU}, backend::CUDA.CUDABackend)
    return true
end

# ============================================================================
# SciML integrator — initial-condition / device consistency
# ============================================================================

"""
$(DocStringExtensions.TYPEDSIGNATURES)

A device `CuArray` initial condition is inconsistent with a `SciML{CPU}` integrator.

Overrides the `true`-returning stub in `CTSolvers.Integrators`. Other host-array cases fall
through to the default (returns `true`).
"""
function Integrators.__consistent_initial_condition(
    ::Type{Strategies.CPU}, u0::CUDA.AnyCuArray
)
    return false
end

"""
$(DocStringExtensions.TYPEDSIGNATURES)

A host `Array` initial condition is inconsistent with a `SciML{GPU}` integrator (the state
must live on the device).

Overrides the `true`-returning stub in `CTSolvers.Integrators`.
"""
function Integrators.__consistent_initial_condition(::Type{Strategies.GPU}, u0::Array)
    return false
end

"""
$(DocStringExtensions.TYPEDSIGNATURES)

A device `CuArray` initial condition is consistent with a `SciML{GPU}` integrator.
"""
function Integrators.__consistent_initial_condition(
    ::Type{Strategies.GPU}, u0::CUDA.AnyCuArray
)
    return true
end

end # module CTSolversCUDA
