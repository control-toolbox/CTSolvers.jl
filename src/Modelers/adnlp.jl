# ADNLP modeler
#
# Implementation of `Modelers.ADNLP` using the `Strategies.AbstractStrategy`
# contract.

# ============================================================================
# Tag dispatch infrastructure
# ============================================================================

"""
$(TYPEDEF)

Tag type for ADNLP-specific implementation dispatch.
"""
struct ADNLPTag <: Core.AbstractTag end

# Default option values
"""
$(TYPEDSIGNATURES)

Return the default automatic differentiation backend for `Modelers.ADNLP`.

Default is `:optimized`.
"""
__adnlp_model_backend() = :optimized

"""
$(TYPEDSIGNATURES)

Return the list of available AD backends for `Modelers.ADNLP` via tag dispatch.

Stub — throws [`CTBase.Exceptions.ExtensionError`](@extref) by default.
Overridden by the `CTSolversADNLPModels` extension for `ADNLPTag`.

# Throws
- `CTBase.Exceptions.ExtensionError`: always, until overridden by the extension

See also: [`CTSolvers.Modelers.get_adnlp_available_backends`](@ref),
[`CTSolvers.Modelers.ADNLPTag`](@ref)
"""
function __get_adnlp_available_backends(::Type{<:Core.AbstractTag})
    throw(
        Exceptions.ExtensionError(
            :ADNLPModels;
            message="to list available ADNLP backends",
            feature="ADNLP backends listing",
            context="Load ADNLPModels first: using ADNLPModels",
        ),
    )
end

"""
$(TYPEDSIGNATURES)

Return the list of available automatic differentiation backends for `Modelers.ADNLP`.

Requires the `CTSolversADNLPModels` extension (`using ADNLPModels`) to be loaded.

# Returns
- `Vector{Symbol}`: available backend names (e.g. `:default`, `:optimized`, `:manual`)

# Throws
- `CTBase.Exceptions.ExtensionError`: if `ADNLPModels` is not loaded

See also: [`CTSolvers.Modelers.ADNLP`](@ref),
[`CTSolvers.Modelers.get_validate_adnlp_backend`](@ref)
"""
get_adnlp_available_backends() = __get_adnlp_available_backends(ADNLPTag)

"""
$(TYPEDEF)

Modeler for building ADNLPModels from discretized optimal control problems.

This modeler uses the ADNLPModels.jl package to create NLP models with
automatic differentiation support. It provides configurable options for
timing information, AD backend selection, memory optimization, and model
identification.

## Parameterized Types

The modeler supports parameterization for execution backend:
- `ADNLP{CPU}`: CPU execution (default and only supported parameter)

**Note:** Unlike `Exa`, `MadNLP`, and `MadNCL`, this modeler only supports CPU execution.
GPU execution is not available for ADNLP.

# Constructors

```julia
# Default constructor (CPU)
Modelers.ADNLP(; mode::Symbol=:strict, kwargs...)

# Explicit parameter specification (only CPU supported)
Modelers.ADNLP{CPU}(; mode::Symbol=:strict, kwargs...)
```

# Arguments
- `mode::Symbol=:strict`: Validation mode (`:strict` or `:permissive`)
  - `:strict` (default): Rejects unknown options with detailed error message
  - `:permissive`: Accepts unknown options with warning, stores with `:user` source
- `kwargs...`: Modeler options (see Options section)

# Parameter Behavior

## CPU Parameter (Default)

The CPU parameter indicates standard CPU-based execution:
- Uses CPU-optimized automatic differentiation backends
- No GPU acceleration available
- Compatible with all standard Julia environments
- Default AD backend: `:optimized`

# Options

## Basic Options
- `show_time::Bool`: Enable timing information for model building (default: `false`)
- `backend::Symbol`: AD backend to use (default: `:optimized`)
- `matrix_free::Bool`: Enable matrix-free mode (default: `false`)
- `name::String`: Model name for identification (default: `"CTSolvers-ADNLP"`)

## Advanced Backend Overrides (expert users)

Each backend option accepts `nothing` (use default), a `Type{<:ADBackend}` (constructed by ADNLPModels),
or an `ADBackend` instance (used directly).

- `gradient_backend`: Override backend for gradient computation
- `hprod_backend`: Override backend for Hessian-vector product
- `jprod_backend`: Override backend for Jacobian-vector product
- `jtprod_backend`: Override backend for transpose Jacobian-vector product
- `jacobian_backend`: Override backend for Jacobian matrix computation
- `hessian_backend`: Override backend for Hessian matrix computation
- `ghjvprod_backend`: Override backend for g^T ∇²c(x)v computation

# Examples

## Basic Usage
```julia
# Default modeler (CPU)
modeler = Modelers.ADNLP()

# Explicit CPU specification
modeler = Modelers.ADNLP{CPU}()

# With custom options
modeler = Modelers.ADNLP(
    backend=:optimized,
    matrix_free=true,
    name="MyOptimizationProblem"
)
```

## Invalid Usage
```julia
# GPU is NOT supported - will throw IncorrectArgument
modeler = Modelers.ADNLP{GPU}()  # ❌ Error!
```

## Advanced Backend Configuration
```julia
# Override with nothing (use default)
modeler = Modelers.ADNLP(
    gradient_backend=nothing,
    hessian_backend=nothing
)

# Override with a Type (ADNLPModels constructs it)
modeler = Modelers.ADNLP(
    gradient_backend=ADNLPModels.ForwardDiffADGradient
)

# Override with an instance (used directly)
modeler = Modelers.ADNLP(
    gradient_backend=ADNLPModels.ForwardDiffADGradient()
)
```

## Validation Modes
```julia
# Strict mode (default) - rejects unknown options
modeler = Modelers.ADNLP(backend=:optimized)

# Permissive mode - accepts unknown options with warning
modeler = Modelers.ADNLP(
    backend=:optimized,
    custom_option=123;
    mode=:permissive
)
```

# Throws

- `CTBase.Exceptions.IncorrectArgument`: If GPU or other unsupported parameter is specified
- `CTBase.Exceptions.IncorrectArgument`: If option validation fails
- `CTBase.Exceptions.IncorrectArgument`: If invalid mode is provided

# See also

- `CPU`: CPU parameter type
- `Modelers.Exa`: Alternative modeler using ExaModels (supports GPU)
- `Optimization.build_model`: Build a backend NLP model from a problem and a modeler
- `Optimization.build_solution`: Build a problem-level solution from execution statistics

# Notes

- The `backend` option supports: `:default`, `:optimized`, `:generic`, `:enzyme`, `:zygote`
- Advanced backend overrides are for expert users only
- Matrix-free mode reduces memory usage but may increase computation time
- Model name is used for identification in solver output

# References

- ADNLPModels.jl: [https://github.com/JuliaSmoothOptimizers/ADNLPModels.jl](https://github.com/JuliaSmoothOptimizers/ADNLPModels.jl)
- Automatic Differentiation in Julia: [https://github.com/JuliaDiff/](https://github.com/JuliaDiff/)
"""
struct ADNLP{P<:CPU} <: AbstractNLPModeler
    "Solver configuration options containing validated option values"
    options::Strategies.StrategyOptions
end

# Strategy identification
Strategies.id(::Type{<:Modelers.ADNLP}) = :adnlp

"""
$(TYPEDSIGNATURES)

Return the description for the ADNLP modeler.
"""
function Strategies.description(::Type{<:Modelers.ADNLP})
    "NLP modeler using ADNLPModels with automatic differentiation.\n" *
    "See: https://jso.dev/ADNLPModels.jl"
end

"""
$(TYPEDSIGNATURES)

Default parameter type for ADNLP when not explicitly specified.

Returns `CPU` as the default execution parameter.

# Implementation Notes

This method is part of the `AbstractStrategy` parameter contract and must be
implemented by all parameterized strategies.

See also: `ADNLP`, `CPU`
"""
Strategies.default_parameter(::Type{<:Modelers.ADNLP}) = CPU

"""
$(TYPEDSIGNATURES)

Return the execution parameter type of an `ADNLP` strategy.

Extracts the type parameter `P` from `ADNLP{P}`, which is always `CPU` since
ADNLP is CPU-only.

# Returns
- `Type{CPU}`: the execution parameter type.

See also: [`CTSolvers.Modelers.ADNLP`](@ref), [`CTBase.Strategies.CPU`](@extref)
"""
Strategies.parameter(::Type{<:Modelers.ADNLP{P}}) where {P<:CPU} = P

# Strategy metadata with option definitions (parameterized)
"""
$(TYPEDSIGNATURES)

Stub — real implementation provided by the CTSolversADNLPModels extension.

# Throws
- `CTBase.Exceptions.ExtensionError`: If the ADNLPModels extension is not loaded

See also: `Modelers.ADNLP`, `Strategies.StrategyMetadata`
"""
function Strategies.metadata(::Type{<:Modelers.ADNLP{P}}) where {P<:CPU}
    throw(
        Exceptions.ExtensionError(
            :ADNLPModels;
            message="to access ADNLP{$P} options metadata",
            feature="ADNLP metadata",
            context="Load ADNLPModels first: using ADNLPModels",
        ),
    )
end

# Fallback metadata for non-parameterized type (delegates to CPU)
function Strategies.metadata(::Type{Modelers.ADNLP})
    return Strategies.metadata(
        Modelers.ADNLP{Strategies.default_parameter(Modelers.ADNLP)}
    )
end

# ============================================================================
# Constructor with Tag Dispatch
# ============================================================================

"""
$(TYPEDSIGNATURES)

Create a parameterized Modelers.ADNLP with validated options.

Requires the CTSolversADNLPModels extension to be loaded.

# Arguments
- `mode::Symbol=:strict`: Validation mode (`:strict` or `:permissive`)
  - `:strict` (default): Rejects unknown options with detailed error message
  - `:permissive`: Accepts unknown options with warning, stores with `:user` source
- `kwargs...`: Modeler options (see `Modelers.ADNLP` documentation)

# Returns
- `Modelers.ADNLP{P}`: Configured modeler instance with specified parameter

# Throws
- `CTBase.Exceptions.ExtensionError`: If the ADNLPModels extension is not loaded
- `CTBase.Exceptions.IncorrectArgument`: If option validation fails

See also: `Modelers.ADNLP`, `build_adnlp_modeler`
"""
function Modelers.ADNLP{P}(; mode::Symbol=:strict, kwargs...) where {P<:CPU}
    return build_adnlp_modeler(ADNLPTag, P; mode=mode, kwargs...)
end

"""
$(TYPEDSIGNATURES)

Stub function that throws ExtensionError if CTSolversADNLPModels extension is not loaded.
Real implementation provided by the extension.

# Throws
- `CTBase.Exceptions.ExtensionError`: Always thrown by this stub implementation

See also: `Modelers.ADNLP`, `Strategies.metadata`
"""
function build_adnlp_modeler(
    ::Type{<:Core.AbstractTag}, parameter::Type{<:AbstractStrategyParameter}; kwargs...
)
    throw(
        Exceptions.ExtensionError(
            :ADNLPModels;
            message="to create ADNLP, access options, and build NLP models",
            feature="ADNLP modeler functionality",
            context="Load ADNLPModels first: using ADNLPModels",
        ),
    )
end

# Simple constructor
"""
$(TYPEDSIGNATURES)

Create an Modelers.ADNLP with validated options (defaults to CPU).

# Arguments
- `mode::Symbol=:strict`: Validation mode (`:strict` or `:permissive`)
  - `:strict` (default): Rejects unknown options with detailed error message
  - `:permissive`: Accepts unknown options with warning, stores with `:user` source
- `kwargs...`: Modeler options (see `Modelers.ADNLP` documentation)

# Returns
- `Modelers.ADNLP{CPU}`: Configured modeler instance with CPU parameter

# Examples
```julia
# Default modeler (CPU)
modeler = Modelers.ADNLP()

# With custom options
modeler = Modelers.ADNLP(backend=:optimized, matrix_free=true)

# With permissive mode
modeler = Modelers.ADNLP(backend=:optimized, custom_option=123; mode=:permissive)
```

# Throws
- `CTBase.Exceptions.ExtensionError`: If the ADNLPModels extension is not loaded
- `CTBase.Exceptions.IncorrectArgument`: If option validation fails

See also: `Modelers.ADNLP`, `Modelers.ADNLP{CPU}`, `build_adnlp_modeler`
"""
function Modelers.ADNLP(; mode::Symbol=:strict, kwargs...)
    P = Strategies.default_parameter(Modelers.ADNLP)
    return Modelers.ADNLP{P}(; mode=mode, kwargs...)
end

# Model building / solution building are implemented by multiple dispatch on
# `(prob, ::Modelers.ADNLP)` in the package providing the problem type (e.g.
# CTDirect), via `Optimization.build_model` / `Optimization.build_solution`.

# ============================================================================
# Backend validation factory
# ============================================================================

"""
$(TYPEDSIGNATURES)

Factory function that returns a backend validator for the specified tag type.

# Arguments
- `T::Type{<:Core.AbstractTag}`: Tag type for dispatch (e.g., ADNLPTag, DummyTag)

# Returns
- `Function`: Validator function that takes `backend` and validates it

# Examples
```julia-repl
julia> using CTSolvers.Modelers

julia> # Get validator for ADNLP (with extensions loaded)
julia> validator = get_validate_adnlp_backend(ADNLPTag)
(backend)->validate_adnlp_backend(#=method=#1, #=generic#=)

julia> validator(:default)
:default

julia> validator(:enzyme)  # Works with CTSolversEnzyme extension
:enzyme

julia> # Get validator for dummy tag (no extensions)
julia> dummy_validator = get_validate_adnlp_backend(DummyTag)
(backend)->validate_adnlp_backend(#=method=#1, #=generic#=)

julia> dummy_validator(:enzyme)  # Throws ExtensionError
ERROR: Control Toolbox Error
❌ Error: CTBase.Exceptions.ExtensionError, to use Enzyme backend with ADNLP modeler
```

# Notes
- Creates a closure that converts `Symbol` to `Val` for type-safe dispatch
- Used by ADNLP metadata system for runtime validation
- Extensions enable specific backends for their tag types
- Default implementations throw `ExtensionError` for Enzyme/Zygote backends

See also: `validate_adnlp_backend`, `ADNLPTag`, `Modelers.ADNLP`
"""
function get_validate_adnlp_backend(T::Type{<:Core.AbstractTag})
    return function (backend)
        if !isa(backend, Symbol)
            throw(
                Exceptions.IncorrectArgument(
                    "ADNLP backend must be a Symbol";
                    got="backend of type $(typeof(backend))",
                    expected="Symbol (one of :default, :optimized, :generic, :enzyme, :zygote, :manual)",
                    suggestion="Use a Symbol like :optimized for ADNLP. For GPU execution with CUDABackend, use Exa{GPU} instead of ADNLP",
                    context="Modelers.ADNLP backend validation",
                ),
            )
        end
        return validate_adnlp_backend(T(), Val(backend))
    end
end
