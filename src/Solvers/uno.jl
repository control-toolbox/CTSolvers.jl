# ============================================================================
# Tag dispatch infrastructure
# ============================================================================

"""
$(TYPEDEF)

Tag type for Uno-specific implementation dispatch.
"""
struct UnoTag <: AbstractTag end

# ============================================================================
# Solver type definition
# ============================================================================

"""
$(TYPEDEF)

Unified nonlinear optimization solver using the Uno backend.

Uno (Unifying Nonlinear Optimization) is a C++ library that unifies Lagrange-Newton methods
(essentially SQP and interior-point) by breaking them down into modular building blocks.
It solves nonlinearly constrained optimization problems by iteratively solving the optimality
(KKT) conditions with Newton's method.

## Unification Framework

Uno implements a modular framework with the following strategies:
- **Constraint relaxation**: feasibility restoration
- **Inequality handling**: inequality constrained method, interior-point method
- **Hessian models**: exact, L-BFGS, identity, zero
- **Inertia control**: primal, primal-dual, none
- **Globalization strategies**: filter method, funnel method, merit function
- **Globalization mechanisms**: backtracking line search, trust-region method

## Presets

Uno provides presets that mimic existing solvers:
- `"ipopt"`: Line-search feasibility restoration filter barrier method with exact Hessian
  and primal-dual inertia correction (mimics IPOPT)
- `"filtersqp"`: Trust-region feasibility restoration filter SQP method with exact Hessian
  (mimics filterSQP)

## Parameterized Types

The solver supports parameterization for execution backend:
- `Uno{CPU}`: CPU execution (default and only supported parameter)

**Note:** This solver only supports CPU execution with ADNLP modeler.
GPU execution is not available for Uno.

# Constructors

```julia
# Default constructor (CPU)
Solvers.Uno(; mode::Symbol=:strict, kwargs...)

# Explicit parameter specification (only CPU supported)
Solvers.Uno{CPU}(; mode::Symbol=:strict, kwargs...)
```

# Fields

$(TYPEDFIELDS)

# Parameter Behavior

## CPU Parameter (Default)

The CPU parameter indicates standard CPU-based execution:
- Uses Uno's unified algorithmic framework
- Supports multiple presets (ipopt, filtersqp)
- Compatible with ADNLP modeler only
- No GPU acceleration available

# Solver Options

Solver options are defined in the CTSolversUno extension.
Load the extension to access option definitions and documentation:
```julia
using UnoSolver
```

# Examples

## Basic Usage
```julia
# Conceptual usage pattern (requires UnoSolver extension)
using UnoSolver

# Default solver (CPU) with ipopt preset
solver = Uno(max_iterations=1000, primal_tolerance=1e-6, preset="ipopt")

# Using filtersqp preset
solver_sqp = Uno(max_iterations=1000, preset="filtersqp")

# Explicit CPU specification
solver_cpu = Uno{CPU}(max_iterations=1000, dual_tolerance=1e-6)

nlp = ADNLPModel(x -> sum(x.^2), zeros(10))
stats = solver(nlp, display=true)
```

## Invalid Usage
```julia
# GPU is NOT supported - will throw IncorrectArgument
solver = Uno{GPU}()  # ❌ Error!
```

# Extension Required

This solver requires the `UnoSolver` package to be loaded:
```julia
using UnoSolver
```

# Implementation Notes

- Implements the `AbstractStrategy` contract via `Strategies.id()`
- Metadata and constructor implementation provided by CTSolversUno extension
- Options are validated at construction time using enriched `Exceptions.IncorrectArgument`
- Callable interface: `(solver::Uno)(nlp; display=true)` provided by extension
- Only compatible with ADNLP modeler (not ExaModeler)
- Based on the unified framework described in Vanaret & Leyffer (2026)

# Throws

- `CTBase.Exceptions.IncorrectArgument`: If GPU or other unsupported parameter is specified
- `CTBase.Exceptions.ExtensionError`: If the UnoSolver extension is not loaded

# References

Vanaret, C., & Leyffer, S. (2026). Implementing a unified solver for nonlinearly 
constrained optimization. Mathematical Programming Computation (accepted).

See also: `CPU`, `AbstractNLPSolver`, `Ipopt`, `MadNLP`
"""
struct Uno{P<:CPU} <: AbstractNLPSolver
    "Solver configuration options containing validated option values"
    options::Strategies.StrategyOptions
end

# ============================================================================
# AbstractStrategy Contract Implementation
# ============================================================================

"""
$(TYPEDSIGNATURES)

Return the unique identifier for Uno.
"""
Strategies.id(::Type{<:Solvers.Uno}) = :uno

"""
$(TYPEDSIGNATURES)

Return the description for the Uno solver.
"""
Strategies.description(::Type{<:Solvers.Uno}) =
    "Composite-step interior-point NLP solver.\n" *
    "See: https://unosolver.readthedocs.io/en/latest/"

"""
$(TYPEDSIGNATURES)

Default parameter type for Uno when not explicitly specified.

Returns `CPU` as the default execution parameter.

# Implementation Notes

This method is part of the `AbstractStrategy` parameter contract and must be
implemented by all parameterized strategies.

See also: `Uno`, `CPU`
"""
Strategies._default_parameter(::Type{<:Solvers.Uno}) = CPU

# ============================================================================
# Constructor with Tag Dispatch
# ============================================================================

"""
$(TYPEDSIGNATURES)

Create a Uno with specified options.

Requires the CTSolversUno extension to be loaded.

# Arguments
- `mode::Symbol=:strict`: Validation mode (`:strict` or `:permissive`)
  - `:strict` (default): Rejects unknown options with detailed error message
  - `:permissive`: Accepts unknown options with warning, stores with `:user` source
- `kwargs...`: Solver options (see extension documentation for available options)

# Example

```julia
# Conceptual usage (requires UnoSolver extension)
using UnoSolver
solver = Uno(max_iter=1000, tol=1e-6)
solver_permissive = Uno(max_iter=1000, custom_option=123; mode=:permissive)
```

# Throws
- `CTBase.Exceptions.ExtensionError`: If the UnoSolver extension is not loaded

See also: `Uno`, `build_uno_solver`
"""
function Solvers.Uno(; mode::Symbol=:strict, kwargs...)
    P = Strategies._default_parameter(Solvers.Uno)
    return Solvers.Uno{P}(; mode=mode, kwargs...)
end

"""
$(TYPEDSIGNATURES)

Create a parameterized Uno with specified options.

Requires the CTSolversUno extension to be loaded.

# Arguments
- `mode::Symbol=:strict`: Validation mode (`:strict` or `:permissive`)
  - `:strict` (default): Rejects unknown options with detailed error message
  - `:permissive`: Accepts unknown options with warning, stores with `:user` source
- `kwargs...`: Solver options (see extension documentation for available options)

# Example

```julia
# Conceptual usage (requires UnoSolver extension)
using UnoSolver
solver_cpu = Solvers.Uno{CPU}(max_iter=1000, tol=1e-6)
```

# Throws
- `CTBase.Exceptions.IncorrectArgument`: If GPU or other unsupported parameter is specified
- `CTBase.Exceptions.ExtensionError`: If the UnoSolver extension is not loaded

See also: `Uno`, `CPU`
"""
function Solvers.Uno{P}(; mode::Symbol=:strict, kwargs...) where {P<:CPU}
    return build_uno_solver(UnoTag, P; mode=mode, kwargs...)
end

"""
$(TYPEDSIGNATURES)

Stub function that throws ExtensionError if CTSolversUno extension is not loaded.
Real implementation provided by the extension.

# Throws
- `CTBase.Exceptions.ExtensionError`: Always thrown by this stub implementation

See also: `Uno`, `Strategies.metadata`
"""
function build_uno_solver(
    ::Type{<:AbstractTag}, parameter::Type{<:AbstractStrategyParameter}; kwargs...
)
    throw(
        Exceptions.ExtensionError(
            :UnoSolver;
            message="to create Uno, access options, and solve problems",
            feature="Uno functionality",
            context="Load UnoSolver extension first: using UnoSolver",
        ),
    )
end

"""
$(TYPEDSIGNATURES)

Stub function that throws ExtensionError if CTSolversUno extension is not loaded.
Real metadata implementation provided by the extension.

This stub is for parameterized types `Uno{P}` where `P <: AbstractStrategyParameter`.

# Throws
- `CTBase.Exceptions.ExtensionError`: Always thrown by this stub implementation

See also: `Uno`, `Strategies.StrategyMetadata`
"""
function Strategies.metadata(::Type{<:Solvers.Uno{P}}) where {P<:CPU}
    # Extension is missing
    throw(
        Exceptions.ExtensionError(
            :UnoSolver;
            message="to access Uno{$P} options metadata",
            feature="Uno metadata",
            context="Load UnoSolver extension first: using UnoSolver",
        ),
    )
end

"""
$(TYPEDSIGNATURES)

Fallback for non-parameterized `Uno` type that delegates to `Uno{CPU}`.

This provides backward compatibility and a sensible default when the parameter
is not specified. The call will delegate to `metadata(Uno{CPU})`, which will
either use the extension implementation (if loaded) or throw an ExtensionError
(if not loaded).

# Returns
- `StrategyMetadata`: Metadata for `Uno{CPU}` (if extension loaded)

# Throws
- `CTBase.Exceptions.ExtensionError`: If extension not loaded (via delegation)

See also: `Uno`, `Strategies.metadata`
"""
function Strategies.metadata(::Type{Solvers.Uno})
    return Strategies.metadata(Solvers.Uno{Strategies._default_parameter(Solvers.Uno)})
end
