# Exa modeler
#
# Implementation of `Modelers.Exa` using the `Strategies.AbstractStrategy`
# contract.

# ============================================================================
# Tag dispatch infrastructure
# ============================================================================

"""
$(TYPEDEF)

Tag type for Exa-specific implementation dispatch.
"""
struct ExaTag <: Core.AbstractTag end

# Default option values
"""
$(TYPEDSIGNATURES)

Return the default floating-point type for `Modelers.Exa`.

Default is `Float64`.
"""
__exa_model_base_type() = Float64

"""
$(TYPEDSIGNATURES)

Return the default execution backend for `Modelers.Exa`.

Default is `nothing` (CPU).
"""
__exa_model_backend() = nothing

"""
$(TYPEDSIGNATURES)

Return the default execution backend for CPU parameter.

Always returns `nothing` for CPU execution.
"""
__exa_model_backend(::Type{CPU}) = nothing

"""
$(TYPEDSIGNATURES)

Return the default execution backend for GPU parameter.

Returns CUDA backend if available, throws ExtensionError otherwise.
"""
function __exa_model_backend(P::Type{GPU})
    return __get_cuda_backend(P)
end

"""
$(TYPEDSIGNATURES)

Get CUDA backend for GPU execution.

This function checks if CUDA.jl is available and functional,
and returns an appropriate CUDA backend.

# Returns
- CUDA backend object if CUDA is available and functional

# Throws
- `CTBase.Exceptions.ExtensionError`: If CUDA is not loaded or not functional

# Notes
- Issues a warning if CUDA is loaded but not functional
- Uses CUDA.CUDABackend() for GPU execution
"""
function __get_cuda_backend(::Type{<:GPU})
    throw(
        Exceptions.ExtensionError(
            :CUDA;
            message="to use GPU backend with Exa modeler",
            feature="GPU computation with ExaModels",
            context="Load CUDA extension first: using CUDA",
        ),
    )
end

"""
$(TYPEDSIGNATURES)

Check if backend is consistent with parameter type.

# Arguments
- `parameter_type::Type{<:AbstractStrategyParameter}`: CPU or GPU parameter
- `backend`: Backend to check consistency for

# Returns
- `Bool`: true if consistent, false otherwise

# Notes
- Default implementation returns true (all combinations allowed)
- Specific implementations in extensions provide actual consistency checks
"""
function __consistent_backend(::Type{<:AbstractStrategyParameter}, backend)
    return true
end

# NOTE: GPU options removed - not relevant for current implementation
# __exa_model_auto_detect_gpu() = true
# __exa_model_gpu_preference() = :cuda
# __exa_model_precision_mode() = :standard

"""
$(TYPEDEF)

Modeler for building ExaModels from discretized optimal control problems.

This modeler uses the ExaModels.jl package to create NLP models with
support for various execution backends (CPU, GPU) and floating-point types.

## Parameterized Types

The modeler supports parameterization for execution backend:
- `Exa{CPU}`: CPU execution (default)
- `Exa{GPU}`: GPU execution (requires CUDA.jl)

# Constructors

```julia
# Default constructor (CPU)
Modelers.Exa(; mode::Symbol=:strict, kwargs...)

# Explicit parameter specification
Modelers.Exa{CPU}(; mode::Symbol=:strict, kwargs...)
Modelers.Exa{GPU}(; mode::Symbol=:strict, kwargs...)
```

# Arguments
- `mode::Symbol=:strict`: Validation mode (`:strict` or `:permissive`)
  - `:strict` (default): Rejects unknown options with detailed error message
  - `:permissive`: Accepts unknown options with warning, stores with `:user` source
- `kwargs...`: Modeler options (see Options section)

# Options

## Basic Options
- `base_type::Type{<:AbstractFloat}`: Floating-point type (default: `Float64`)
- `backend`: Execution backend (default depends on parameter: `nothing` for CPU, CUDA backend for GPU)

# Examples

## Basic Usage
```julia
# Default modeler (Float64, CPU)
modeler = Modelers.Exa()

# Explicit CPU modeler
modeler = Modelers.Exa{CPU}()

# GPU modeler (requires CUDA.jl)
modeler = Modelers.Exa{GPU}()
```

## Type Specification
```julia
# Single precision
modeler = Modelers.Exa(base_type=Float32)

# Double precision (default)
modeler = Modelers.Exa(base_type=Float64)
```

## Backend Configuration
```julia
# CPU backend (default for Exa{CPU})
modeler = Modelers.Exa{CPU}(backend=nothing)

# GPU backend (default for Exa{GPU})
modeler = Modelers.Exa{GPU}()  # Uses CUDA backend automatically
```

## Validation Modes
```julia
# Strict mode (default) - rejects unknown options
modeler = Modelers.Exa(base_type=Float64)

# Permissive mode - accepts unknown options with warning
modeler = Modelers.Exa(
    base_type=Float64,
    custom_option=123;
    mode=:permissive
)
```

## Complete Configuration
```julia
# Full configuration with type and backend
modeler = Modelers.Exa{GPU}(
    base_type=Float32;
    mode=:permissive
)
```

# Throws

- `CTBase.Exceptions.IncorrectArgument`: If option validation fails
- `CTBase.Exceptions.IncorrectArgument`: If invalid mode is provided
- `CTBase.Exceptions.ExtensionError`: If GPU backend requested but CUDA not available

# See also

- `Modelers.ADNLP`: Alternative modeler using ADNLPModels
- `build_model`: Build model from problem and modeler
- `solve!`: Solve optimization problem
- `CPU`, `GPU`: Strategy parameters

# Notes

- The `base_type` option affects the precision of all computations
- CPU backend (`backend=nothing`) is always available
- GPU backends require CUDA.jl to be loaded and functional
- ExaModels.jl provides efficient GPU acceleration for large problems
- Default backend is automatically selected based on the parameter type

# References

- ExaModels.jl: [https://github.com/JuliaSmoothOptimizers/ExaModels.jl](https://github.com/JuliaSmoothOptimizers/ExaModels.jl)
- KernelAbstractions.jl: [https://github.com/JuliaGPU/KernelAbstractions.jl](https://github.com/JuliaGPU/KernelAbstractions.jl)
"""
struct Exa{P<:Union{CPU,GPU}} <: AbstractNLPModeler
    options::Strategies.StrategyOptions
end

# Strategy identification
Strategies.id(::Type{<:Modelers.Exa}) = :exa

"""
$(TYPEDSIGNATURES)

Return the description for the Exa modeler.
"""
function Strategies.description(::Type{<:Modelers.Exa})
    "NLP modeler using ExaModels, supporting CPU and GPU execution.\n" *
    "See: https://exanauts.github.io/ExaModels.jl"
end

"""
$(TYPEDSIGNATURES)

Default parameter type for Exa when not explicitly specified.

Returns `CPU` as the default execution parameter.

# Implementation Notes

This method is part of the `AbstractStrategy` parameter contract and must be
implemented by all parameterized strategies.

See also: `Exa`, `CPU`
"""
Strategies._default_parameter(::Type{<:Modelers.Exa}) = CPU

# Strategy metadata with option definitions (parameterized)
"""
$(TYPEDSIGNATURES)

Stub — real implementation provided by the CTSolversExaModels extension.

# Throws
- `CTBase.Exceptions.ExtensionError`: If the ExaModels extension is not loaded

See also: `Modelers.Exa`, `Strategies.StrategyMetadata`
"""
function Strategies.metadata(::Type{<:Modelers.Exa{P}}) where {P<:Union{CPU,GPU}}
    throw(
        Exceptions.ExtensionError(
            :ExaModels;
            message="to access Exa{$P} options metadata",
            feature="Exa metadata",
            context="Load ExaModels first: using ExaModels",
        ),
    )
end

"""
$(TYPEDSIGNATURES)

Fallback for non-parameterized `Exa` type that delegates to `Exa{CPU}`.

This provides backward compatibility and a sensible default when the parameter
is not specified. The call will delegate to `metadata(Exa{CPU})`.

# Returns
- `StrategyMetadata`: Metadata for `Exa{CPU}`
"""
function Strategies.metadata(::Type{Modelers.Exa})
    return Strategies.metadata(Modelers.Exa{Strategies._default_parameter(Modelers.Exa)})
end

# ============================================================================
# Constructor with Tag Dispatch
# ============================================================================

"""
$(TYPEDSIGNATURES)

Create a parameterized Modelers.Exa with validated options.

Requires the CTSolversExaModels extension to be loaded.

# Arguments
- `mode::Symbol=:strict`: Validation mode (`:strict` or `:permissive`)
  - `:strict` (default): Rejects unknown options with detailed error message
  - `:permissive`: Accepts unknown options with warning, stores with `:user` source
- `kwargs...`: Modeler options (see `Modelers.Exa` documentation)

# Returns
- `Modelers.Exa{P}`: Configured modeler instance with specified parameter

# Throws
- `CTBase.Exceptions.ExtensionError`: If the ExaModels extension is not loaded
- `CTBase.Exceptions.IncorrectArgument`: If option validation fails

See also: `Modelers.Exa`, `build_exa_modeler`
"""
function Modelers.Exa{P}(;
    mode::Symbol=:strict, kwargs...
) where {P<:AbstractStrategyParameter}
    return build_exa_modeler(ExaTag, P; mode=mode, kwargs...)
end

"""
$(TYPEDSIGNATURES)

Stub function that throws ExtensionError if CTSolversExaModels extension is not loaded.
Real implementation provided by the extension.

# Throws
- `CTBase.Exceptions.ExtensionError`: Always thrown by this stub implementation

See also: `Modelers.Exa`, `Strategies.metadata`
"""
function build_exa_modeler(
    ::Type{<:Core.AbstractTag}, parameter::Type{<:AbstractStrategyParameter}; kwargs...
)
    throw(
        Exceptions.ExtensionError(
            :ExaModels;
            message="to create Exa, access options, and build NLP models",
            feature="Exa modeler functionality",
            context="Load ExaModels first: using ExaModels",
        ),
    )
end

# Simple constructor
"""
$(TYPEDSIGNATURES)

Create an Modelers.Exa with validated options (defaults to CPU).

Requires the CTSolversExaModels extension to be loaded.

# Arguments
- `mode::Symbol=:strict`: Validation mode (`:strict` or `:permissive`)
  - `:strict` (default): Rejects unknown options with detailed error message
  - `:permissive`: Accepts unknown options with warning, stores with `:user` source
- `kwargs...`: Modeler options (see `Modelers.Exa` documentation)

# Returns
- `Modelers.Exa{CPU}`: Configured modeler instance with CPU parameter

# Throws
- `CTBase.Exceptions.ExtensionError`: If the ExaModels extension is not loaded
- `CTBase.Exceptions.IncorrectArgument`: If option validation fails

See also: `Modelers.Exa`, `Modelers.Exa{CPU}`, `Modelers.Exa{GPU}`, `build_exa_modeler`
"""
function Modelers.Exa(; mode::Symbol=:strict, kwargs...)
    P = Strategies._default_parameter(Modelers.Exa)
    return Modelers.Exa{P}(; mode=mode, kwargs...)
end

# Model building / solution building are implemented by multiple dispatch on
# `(prob, ::Modelers.Exa)` in the package providing the problem type (e.g.
# CTDirect), via `Optimization.build_model` / `Optimization.build_solution`.
