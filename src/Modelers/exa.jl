# Exa Modeler
#
# Implementation of Modelers.Exa using the AbstractStrategy contract.
# This modeler converts discretized optimal control problems to ExaModels.
#
# Author: CTSolvers Development Team
# Date: 2026-01-25

# Default option values
"""
$(TYPEDSIGNATURES)

Return the default floating-point type for [`Modelers.Exa`](@ref).

Default is `Float64`.
"""
__exa_model_base_type() = Float64

"""
$(TYPEDSIGNATURES)

Return the default execution backend for [`Modelers.Exa`](@ref).

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
function __exa_model_backend(::Type{GPU})
    return __get_cuda_backend()
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
- Uses KernelAbstractions.CUDABackend() for GPU execution
"""
function __get_cuda_backend()
    if !isdefined(Main, :CUDA)
        throw(Exceptions.ExtensionError(
            :CUDA;
            message="to use GPU backend with Exa modeler",
            feature="GPU computation with ExaModels",
            context="Load CUDA extension first: using CUDA",
            suggestion="Install and load CUDA.jl before using GPU parameter"
        ))
    end
    if !Main.CUDA.functional()
        @warn "CUDA is loaded but not functional. GPU backend may not work properly." maxlog=1
    end
    return KernelAbstractions.CUDABackend()
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

- [`Modelers.ADNLP`](@ref): Alternative modeler using ADNLPModels
- [`build_model`](@ref): Build model from problem and modeler
- [`solve!`](@ref): Solve optimization problem
- [`CPU`](@ref), [`GPU`](@ref): Strategy parameters

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
struct Exa{P<:AbstractStrategyParameter} <: AbstractNLPModeler
    options::Strategies.StrategyOptions
end

# Strategy identification
Strategies.id(::Type{<:Modelers.Exa}) = :exa

"""
Default parameter type for Exa when not explicitly specified.

Returns `CPU` as the default execution parameter.
"""
_default_parameter(::Type{<:Modelers.Exa}) = CPU

# Strategy metadata with option definitions (parameterized)
function Strategies.metadata(::Type{<:Modelers.Exa{P}}) where {P<:AbstractStrategyParameter}
    return Strategies.StrategyMetadata(
        # === Existing Options (enhanced) ===
        Strategies.OptionDefinition(;
            name=:base_type,
            type=DataType,
            default=__exa_model_base_type(),
            description="Base floating-point type used by ExaModels",
            validator=validate_exa_base_type
        ),
        Strategies.OptionDefinition(;
            name=:backend,
            type=Union{Nothing, KernelAbstractions.Backend},  # More permissive for various backend types
            default=__exa_model_backend(P),
            description="Execution backend for ExaModels (CPU, GPU, etc.)",
            aliases=(:exa_backend,)
        )
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
    return Strategies.metadata(Modelers.Exa{_default_parameter(Modelers.Exa)})
end

# Simple constructor
"""
$(TYPEDSIGNATURES)

Create an Modelers.Exa with validated options (defaults to CPU).

# Arguments
- `mode::Symbol=:strict`: Validation mode (`:strict` or `:permissive`)
  - `:strict` (default): Rejects unknown options with detailed error message
  - `:permissive`: Accepts unknown options with warning, stores with `:user` source
- `kwargs...`: Modeler options (see [`Modelers.Exa`](@ref) documentation)

# Returns
- `Modelers.Exa{CPU}`: Configured modeler instance with CPU parameter

# Examples
```julia
# Default modeler (CPU)
modeler = Modelers.Exa()

# With custom options
modeler = Modelers.Exa(base_type=Float32, backend=nothing)

# With permissive mode
modeler = Modelers.Exa(base_type=Float64, custom_option=123; mode=:permissive)
```

# Throws

- `CTBase.Exceptions.IncorrectArgument`: If option validation fails
- `CTBase.Exceptions.IncorrectArgument`: If invalid mode is provided

# See also

- [`Modelers.Exa`](@ref): Type documentation
- [`Modelers.Exa{CPU}`](@ref): Explicit CPU constructor
- [`Modelers.Exa{GPU}`](@ref): GPU constructor
- [`Strategies.build_strategy_options`](@ref): Option validation function
"""
function Modelers.Exa(; mode::Symbol=:strict, kwargs...)
    # Check for deprecated aliases
    if haskey(kwargs, :exa_backend)
        @warn "exa_backend is deprecated, use backend instead" maxlog=1
    end
    
    opts = Strategies.build_strategy_options(
        Modelers.Exa{CPU}; mode=mode, kwargs...
    )
    return Modelers.Exa{_default_parameter(Modelers.Exa)}(opts)
end

# Parameterized constructor
"""
$(TYPEDSIGNATURES)

Create a parameterized Modelers.Exa with validated options.

# Arguments
- `mode::Symbol=:strict`: Validation mode (`:strict` or `:permissive`)
  - `:strict` (default): Rejects unknown options with detailed error message
  - `:permissive`: Accepts unknown options with warning, stores with `:user` source
- `kwargs...`: Modeler options (see [`Modelers.Exa`](@ref) documentation)

# Returns
- `Modelers.Exa{P}`: Configured modeler instance with specified parameter

# Examples
```julia
# Explicit CPU modeler
modeler = Modelers.Exa{CPU}()

# Explicit GPU modeler (requires CUDA.jl)
modeler = Modelers.Exa{GPU}()

# With custom options
modeler = Modelers.Exa{GPU}(base_type=Float32)

# With permissive mode
modeler = Modelers.Exa{GPU}(base_type=Float64, custom_option=123; mode=:permissive)
```

# Throws

- `CTBase.Exceptions.IncorrectArgument`: If option validation fails
- `CTBase.Exceptions.IncorrectArgument`: If invalid mode is provided
- `CTBase.Exceptions.ExtensionError`: If GPU parameter used but CUDA not available

# See also

- [`Modelers.Exa`](@ref): Type documentation
- [`Strategies.build_strategy_options`](@ref): Option validation function
"""
function Modelers.Exa{P}(; mode::Symbol=:strict, kwargs...) where {P<:AbstractStrategyParameter}
    # Check for deprecated aliases
    if haskey(kwargs, :exa_backend)
        @warn "exa_backend is deprecated, use backend instead" maxlog=1
    end
    
    opts = Strategies.build_strategy_options(
        Modelers.Exa{P}; mode=mode, kwargs...
    )
    return Modelers.Exa{P}(opts)
end

# Access to strategy options
Strategies.options(m::Modelers.Exa) = m.options

# Model building interface
"""
$(TYPEDSIGNATURES)

Build an ExaModel from a discretized optimal control problem.

# Arguments
- `modeler::Modelers.Exa{P}`: Configured modeler instance
- `prob::AbstractOptimizationProblem`: Discretized optimal control problem
- `initial_guess`: Initial guess for optimization variables

# Returns
- `ExaModels.ExaModel`: Built NLP model

# Examples
```julia
# Create modeler
modeler = Modelers.Exa(base_type=Float64)

# Build model from problem
nlp = modeler(problem, initial_guess)

# Solve the model
stats = solve(nlp, solver)
```

# See also

- [`Modelers.Exa`](@ref): Type documentation
- [`build_model`](@ref): Generic model building interface
- [`ExaModels.ExaModel`](@ref): NLP model type
"""
function (modeler::Modelers.Exa{P})(
    prob::AbstractOptimizationProblem,
    initial_guess
)::ExaModels.ExaModel where {P<:AbstractStrategyParameter}
    # Get the appropriate builder for this problem type
    builder = get_exa_model_builder(prob)
    
    # Extract options as Dict
    options = Strategies.options_dict(modeler)
    
    # Extract BaseType and remove it from options to avoid passing it as named argument
    BaseType = options[:base_type]
    delete!(options, :base_type)
    
    # Build the ExaModel passing BaseType as first argument and remaining options as named arguments
    return builder(BaseType, initial_guess; options...)
end

# Solution building interface
"""
$(TYPEDSIGNATURES)

Build a solution object from NLP solver statistics.

# Arguments
- `modeler::Modelers.Exa{P}`: Configured modeler instance
- `prob::AbstractOptimizationProblem`: Original optimization problem
- `nlp_solution::SolverCore.AbstractExecutionStats`: NLP solver statistics

# Returns
- Solution object appropriate for the problem type

# Examples
```julia
# Create modeler and solve
modeler = Modelers.Exa()
nlp = modeler(problem, initial_guess)
stats = solve(nlp, solver)

# Build solution object
solution = modeler(problem, stats)
```

# See also

- [`Modelers.Exa`](@ref): Type documentation
- [`SolverCore.AbstractExecutionStats`](@ref): Solver statistics type
- [`solve`](@ref): Generic solve interface
"""
function (modeler::Modelers.Exa{P})(
    prob::AbstractOptimizationProblem,
    nlp_solution::SolverCore.AbstractExecutionStats
) where {P<:AbstractStrategyParameter}
    # Get the appropriate solution builder for this problem type
    builder = get_exa_solution_builder(prob)
    return builder(nlp_solution)
end
