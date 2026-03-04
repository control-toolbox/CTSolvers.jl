# ============================================================================
# Tag dispatch infrastructure
# ============================================================================

"""
$(TYPEDEF)

Tag type for Knitro-specific implementation dispatch.
"""
struct KnitroTag <: AbstractTag end

# ============================================================================
# Solver type definition
# ============================================================================

"""
$(TYPEDEF)

Commercial optimization solver with advanced algorithms.

Knitro is a commercial solver offering state-of-the-art algorithms for
nonlinear optimization, including interior point, active set, and SQP methods.
It provides excellent performance and robustness for large-scale problems.

## Parameterized Types

The solver supports parameterization for execution backend:
- `Knitro{CPU}`: CPU execution (default and only supported parameter)

**Note:** Unlike `MadNLP` and `MadNCL`, this solver only supports CPU execution.
GPU execution is not available for Knitro.

# Constructors

```julia
# Default constructor (CPU)
Solvers.Knitro(; mode::Symbol=:strict, kwargs...)

# Explicit parameter specification (only CPU supported)
Solvers.Knitro{CPU}(; mode::Symbol=:strict, kwargs...)
```

# Fields

$(TYPEDFIELDS)

# Parameter Behavior

## CPU Parameter (Default)

The CPU parameter indicates standard CPU-based execution:
- Uses Knitro's advanced optimization algorithms
- No GPU acceleration available
- Compatible with all standard Julia environments
- Requires valid Knitro license

# Solver Options

Solver options are defined in the CTSolversKnitro extension.
Load the extension to access option definitions and documentation:
```julia
using NLPModelsKnitro
```

# Examples

## Basic Usage
```julia
# Conceptual usage pattern (requires NLPModelsKnitro extension)
using NLPModelsKnitro

# Default solver (CPU)
solver = Knitro(maxit=1000, maxtime=3600, ftol=1e-10, outlev=2)

# Explicit CPU specification
solver_cpu = Knitro{CPU}(maxit=1000, outlev=2)

nlp = ADNLPModel(x -> sum(x.^2), zeros(10))
stats = solver(nlp, display=true)
```

## Invalid Usage
```julia
# GPU is NOT supported - will throw IncorrectArgument
solver = Knitro{GPU}()  # ❌ Error!
```

# Extension Required

This solver requires the `NLPModelsKnitro` package:
```julia
using NLPModelsKnitro
```

**Note:** Knitro is a commercial solver requiring a valid license.

# Implementation Notes

- Implements the `AbstractStrategy` contract via `Strategies.id()`
- Metadata and constructor implementation provided by CTSolversKnitro extension
- Options are validated at construction time using enriched `Exceptions.IncorrectArgument`
- Callable interface: `(solver::Knitro)(nlp; display=true)` provided by extension
- Requires valid Knitro license for operation

# Throws

- `CTBase.Exceptions.IncorrectArgument`: If GPU or other unsupported parameter is specified
- `CTBase.Exceptions.ExtensionError`: If the NLPModelsKnitro extension is not loaded

See also: [`CPU`](@ref), [`AbstractNLPSolver`](@ref), [`Ipopt`](@ref), [`MadNLP`](@ref)
"""
struct Knitro{P<:CPU} <: AbstractNLPSolver
    "Solver configuration options containing validated option values"
    options::Strategies.StrategyOptions
end

# ============================================================================
# AbstractStrategy Contract Implementation
# ============================================================================

"""
$(TYPEDSIGNATURES)

Return the unique identifier for Knitro.
"""
Strategies.id(::Type{<:Solvers.Knitro}) = :knitro

"""
$(TYPEDSIGNATURES)

Default parameter type for Knitro when not explicitly specified.

Returns `CPU` as the default execution parameter.

# Implementation Notes

This method is part of the `AbstractStrategy` parameter contract and must be
implemented by all parameterized strategies.

See also: [`Knitro`](@ref), [`CPU`](@ref)
"""
Strategies._default_parameter(::Type{<:Solvers.Knitro}) = CPU

# ============================================================================
# Constructor with Tag Dispatch
# ============================================================================

"""
$(TYPEDSIGNATURES)

Create a Knitro with specified options.

Requires the CTSolversKnitro extension to be loaded.

# Arguments
- `mode::Symbol=:strict`: Validation mode (`:strict` or `:permissive`)
  - `:strict` (default): Rejects unknown options with detailed error message
  - `:permissive`: Accepts unknown options with warning, stores with `:user` source
- `kwargs...`: Solver options (see extension documentation for available options)

# Example

```julia
# Conceptual usage (requires NLPModelsKnitro extension)
using NLPModelsKnitro
solver = Knitro(maxit=1000, outlev=2)
solver_permissive = Knitro(maxit=1000, custom_option=123; mode=:permissive)
```

# Throws
- `CTBase.Exceptions.ExtensionError`: If the NLPModelsKnitro extension is not loaded

See also: [`Knitro`](@ref), [`build_knitro_solver`](@ref)
"""
function Solvers.Knitro(; mode::Symbol=:strict, kwargs...)
    return build_knitro_solver(KnitroTag, Strategies._default_parameter(Solvers.Knitro); mode=mode, kwargs...)
end

"""
$(TYPEDSIGNATURES)

Create a parameterized Knitro with specified options.

Requires the CTSolversKnitro extension to be loaded.

# Arguments
- `mode::Symbol=:strict`: Validation mode (`:strict` or `:permissive`)
  - `:strict` (default): Rejects unknown options with detailed error message
  - `:permissive`: Accepts unknown options with warning, stores with `:user` source
- `kwargs...`: Solver options (see extension documentation for available options)

# Example

```julia
# Conceptual usage (requires NLPModelsKnitro extension)
using NLPModelsKnitro
solver_cpu = Solvers.Knitro{CPU}(maxit=1000, outlev=2)
```

# Throws
- `CTBase.Exceptions.IncorrectArgument`: If GPU or other unsupported parameter is specified
- `CTBase.Exceptions.ExtensionError`: If the NLPModelsKnitro extension is not loaded

See also: [`Knitro`](@ref), [`CPU`](@ref)
"""
function Solvers.Knitro{P}(; mode::Symbol=:strict, kwargs...) where {P<:CPU}
    return build_knitro_solver(KnitroTag, P; mode=mode, kwargs...)
end

"""
$(TYPEDSIGNATURES)

Stub function that throws ExtensionError if CTSolversKnitro extension is not loaded.
Real implementation provided by the extension.

# Throws
- `CTBase.Exceptions.ExtensionError`: Always thrown by this stub implementation

See also: [`Knitro`](@ref), [`Strategies.metadata`](@ref)
"""
function build_knitro_solver(::Type{<:AbstractTag}, parameter::Type{<:AbstractStrategyParameter}; kwargs...)
    throw(Exceptions.ExtensionError(
        :NLPModelsKnitro;
        message="to create Knitro, access options, and solve problems",
        feature="Knitro functionality",
        context="Load NLPModelsKnitro extension first: using NLPModelsKnitro"
    ))
end

"""
$(TYPEDSIGNATURES)

Stub function that throws ExtensionError if CTSolversKnitro extension is not loaded.
Real metadata implementation provided by the extension.

This stub is for parameterized types `Knitro{P}` where `P <: AbstractStrategyParameter`.

# Throws
- `CTBase.Exceptions.ExtensionError`: Always thrown by this stub implementation

See also: [`Knitro`](@ref), [`Strategies.StrategyMetadata`](@ref)
"""
function Strategies.metadata(::Type{<:Solvers.Knitro{P}}) where {P<:CPU}
    # Extension is missing
    throw(Exceptions.ExtensionError(
        :NLPModelsKnitro;
        message="to access Knitro{$P} options metadata",
        feature="Knitro metadata",
        context="Load NLPModelsKnitro extension first: using NLPModelsKnitro"
    ))
end

"""
$(TYPEDSIGNATURES)

Fallback for non-parameterized `Knitro` type that delegates to `Knitro{CPU}`.

This provides backward compatibility and a sensible default when the parameter
is not specified. The call will delegate to `metadata(Knitro{CPU})`, which will
either use the extension implementation (if loaded) or throw an ExtensionError
(if not loaded).

# Returns
- `StrategyMetadata`: Metadata for `Knitro{CPU}` (if extension loaded)

# Throws
- `CTBase.Exceptions.ExtensionError`: If extension not loaded (via delegation)

See also: [`Knitro`](@ref), [`Strategies.metadata`](@ref)
"""
function Strategies.metadata(::Type{Solvers.Knitro})
    return Strategies.metadata(Solvers.Knitro{Strategies._default_parameter(Solvers.Knitro)})
end

