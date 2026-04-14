# ============================================================================
# Tag dispatch infrastructure
# ============================================================================

"""
$(TYPEDEF)

Tag type for Ipopt-specific implementation dispatch.
"""
struct IpoptTag <: AbstractTag end

# ============================================================================
# Solver type definition
# ============================================================================

"""
$(TYPEDEF)

Interior point optimization solver using the Ipopt backend.

Ipopt (Interior Point OPTimizer) is an open-source software package for large-scale
nonlinear optimization. It implements a primal-dual interior point method with proven
global convergence properties.

## Parameterized Types

The solver supports parameterization for execution backend:
- `Ipopt{CPU}`: CPU execution (default and only supported parameter)

**Note:** Unlike `MadNLP` and `MadNCL`, this solver only supports CPU execution.
GPU execution is not available for Ipopt.

# Constructors

```julia
# Default constructor (CPU)
Solvers.Ipopt(; mode::Symbol=:strict, kwargs...)

# Explicit parameter specification (only CPU supported)
Solvers.Ipopt{CPU}(; mode::Symbol=:strict, kwargs...)
```

# Fields

$(TYPEDFIELDS)

# Parameter Behavior

## CPU Parameter (Default)

The CPU parameter indicates standard CPU-based execution:
- Uses Ipopt's standard interior point algorithm
- No GPU acceleration available
- Compatible with all standard Julia environments
- Proven global convergence properties

# Solver Options

Solver options are defined in the CTSolversIpopt extension.
Load the extension to access option definitions and documentation:
```julia
using NLPModelsIpopt
```

# Examples

## Basic Usage
```julia
# Conceptual usage pattern (requires NLPModelsIpopt extension)
using NLPModelsIpopt

# Default solver (CPU)
solver = Ipopt(max_iter=1000, tol=1e-6, print_level=3)

# Explicit CPU specification
solver_cpu = Ipopt{CPU}(max_iter=1000, tol=1e-6)

nlp = ADNLPModel(x -> sum(x.^2), zeros(10))
stats = solver(nlp, display=true)
```

## Invalid Usage
```julia
# GPU is NOT supported - will throw IncorrectArgument
solver = Ipopt{GPU}()  # ❌ Error!
```

# Extension Required

This solver requires the `NLPModelsIpopt` package to be loaded:
```julia
using NLPModelsIpopt
```

# Implementation Notes

- Implements the `AbstractStrategy` contract via `Strategies.id()`
- Metadata and constructor implementation provided by CTSolversIpopt extension
- Options are validated at construction time using enriched `Exceptions.IncorrectArgument`
- Callable interface: `(solver::Ipopt)(nlp; display=true)` provided by extension

# Throws

- `CTBase.Exceptions.IncorrectArgument`: If GPU or other unsupported parameter is specified
- `CTBase.Exceptions.ExtensionError`: If the NLPModelsIpopt extension is not loaded

See also: `CPU`, `AbstractNLPSolver`, `MadNLP`, `Knitro`
"""
struct Ipopt{P<:CPU} <: AbstractNLPSolver
    "Solver configuration options containing validated option values"
    options::Strategies.StrategyOptions
end

# ============================================================================
# AbstractStrategy Contract Implementation
# ============================================================================

"""
$(TYPEDSIGNATURES)

Return the unique identifier for Ipopt.
"""
Strategies.id(::Type{<:Solvers.Ipopt}) = :ipopt

"""
$(TYPEDSIGNATURES)

Return the description for the Ipopt solver.
"""
Strategies.description(::Type{<:Solvers.Ipopt}) =
    "Interior-point NLP solver (COIN-OR Ipopt).\n" *
    "See: https://coin-or.github.io/Ipopt/OPTIONS.html"

"""
$(TYPEDSIGNATURES)

Default parameter type for Ipopt when not explicitly specified.

Returns `CPU` as the default execution parameter.

# Implementation Notes

This method is part of the `AbstractStrategy` parameter contract and must be
implemented by all parameterized strategies.

See also: `Ipopt`, `CPU`
"""
Strategies._default_parameter(::Type{<:Solvers.Ipopt}) = CPU

# ============================================================================
# Constructor with Tag Dispatch
# ============================================================================

"""
$(TYPEDSIGNATURES)

Create an Ipopt with specified options.

Requires the CTSolversIpopt extension to be loaded.

# Arguments
- `mode::Symbol=:strict`: Validation mode (`:strict` or `:permissive`)
  - `:strict` (default): Rejects unknown options with detailed error message
  - `:permissive`: Accepts unknown options with warning, stores with `:user` source
- `kwargs...`: Solver options (see extension documentation for available options)

# Example

```julia
# Conceptual usage (requires NLPModelsIpopt extension)
using NLPModelsIpopt
solver = Ipopt(max_iter=1000, tol=1e-6)
solver_permissive = Ipopt(max_iter=1000, custom_option=123; mode=:permissive)
```

# Throws
- `CTBase.Exceptions.ExtensionError`: If the NLPModelsIpopt extension is not loaded

See also: `Ipopt`, `build_ipopt_solver`
"""
function Solvers.Ipopt(; mode::Symbol=:strict, kwargs...)
    P = Strategies._default_parameter(Solvers.Ipopt)
    return Solvers.Ipopt{P}(; mode=mode, kwargs...)
end

"""
$(TYPEDSIGNATURES)

Create a parameterized Ipopt with specified options.

Requires the CTSolversIpopt extension to be loaded.

# Arguments
- `mode::Symbol=:strict`: Validation mode (`:strict` or `:permissive`)
  - `:strict` (default): Rejects unknown options with detailed error message
  - `:permissive`: Accepts unknown options with warning, stores with `:user` source
- `kwargs...`: Solver options (see extension documentation for available options)

# Example

```julia
# Conceptual usage (requires NLPModelsIpopt extension)
using NLPModelsIpopt
solver_cpu = Solvers.Ipopt{CPU}(max_iter=1000, tol=1e-6)
```

# Throws
- `CTBase.Exceptions.IncorrectArgument`: If GPU or other unsupported parameter is specified
- `CTBase.Exceptions.ExtensionError`: If the NLPModelsIpopt extension is not loaded

See also: `Ipopt`, `CPU`
"""
function Solvers.Ipopt{P}(; mode::Symbol=:strict, kwargs...) where {P<:CPU}
    return build_ipopt_solver(IpoptTag, P; mode=mode, kwargs...)
end

"""
$(TYPEDSIGNATURES)

Stub function that throws ExtensionError if CTSolversIpopt extension is not loaded.
Real implementation provided by the extension.

# Throws
- `CTBase.Exceptions.ExtensionError`: Always thrown by this stub implementation

See also: `Ipopt`, `Strategies.metadata`
"""
function build_ipopt_solver(
    ::Type{<:AbstractTag}, parameter::Type{<:AbstractStrategyParameter}; kwargs...
)
    throw(
        Exceptions.ExtensionError(
            :NLPModelsIpopt;
            message="to create Ipopt, access options, and solve problems",
            feature="Ipopt functionality",
            context="Load NLPModelsIpopt extension first: using NLPModelsIpopt",
        ),
    )
end

"""
$(TYPEDSIGNATURES)

Stub function that throws ExtensionError if CTSolversIpopt extension is not loaded.
Real metadata implementation provided by the extension.

This stub is for parameterized types `Ipopt{P}` where `P <: AbstractStrategyParameter`.

# Throws
- `CTBase.Exceptions.ExtensionError`: Always thrown by this stub implementation

See also: `Ipopt`, `Strategies.StrategyMetadata`
"""
function Strategies.metadata(::Type{<:Solvers.Ipopt{P}}) where {P<:CPU}
    # Extension is missing
    throw(
        Exceptions.ExtensionError(
            :NLPModelsIpopt;
            message="to access Ipopt{$P} options metadata",
            feature="Ipopt metadata",
            context="Load NLPModelsIpopt extension first: using NLPModelsIpopt",
        ),
    )
end

"""
$(TYPEDSIGNATURES)

Fallback for non-parameterized `Ipopt` type that delegates to `Ipopt{CPU}`.

This provides backward compatibility and a sensible default when the parameter
is not specified. The call will delegate to `metadata(Ipopt{CPU})`, which will
either use the extension implementation (if loaded) or throw an ExtensionError
(if not loaded).

# Returns
- `StrategyMetadata`: Metadata for `Ipopt{CPU}` (if extension loaded)

# Throws
- `CTBase.Exceptions.ExtensionError`: If extension not loaded (via delegation)

See also: `Ipopt`, `Strategies.metadata`
"""
function Strategies.metadata(::Type{Solvers.Ipopt})
    return Strategies.metadata(Solvers.Ipopt{Strategies._default_parameter(Solvers.Ipopt)})
end
