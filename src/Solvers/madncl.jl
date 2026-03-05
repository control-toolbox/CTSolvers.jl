# ============================================================================
# Tag dispatch infrastructure
# ============================================================================

"""
$(TYPEDEF)

Tag type for MadNCL-specific implementation dispatch.
"""
struct MadNCLTag <: AbstractTag end

# ============================================================================
# Solver type definition
# ============================================================================

"""
$(TYPEDEF)

NCL (Non-Convex Lagrangian) variant of MadNLP solver.

MadNCL extends MadNLP with specialized handling for non-convex problems
using a modified Lagrangian approach, providing improved convergence for
challenging nonlinear optimization problems.

## Parameterized Types

The solver supports parameterization for execution backend:
- `MadNCL{CPU}`: CPU execution (default)
- `MadNCL{GPU}`: GPU execution (requires CUDA.jl)

# Fields

$(TYPEDFIELDS)

# Solver Options

Solver options are defined in the CTSolversMadNCL extension.
Load the extension to access option definitions and documentation:
```julia
using MadNCL, MadNLP
```

# Example

```julia
# Conceptual usage pattern (requires MadNCL, MadNLP extensions)
using MadNCL, MadNLP
solver = Solvers.MadNCL(max_iter=1000, tol=1e-6, print_level=MadNLP.DEBUG)
nlp = ADNLPModel(x -> sum(x.^2), zeros(10))
stats = solver(nlp, display=true)
```

# Extension Required

This solver requires the `MadNCL` package:
```julia
using MadNCL, MadNLP
```

# Implementation Notes

- Implements the `AbstractStrategy` contract via `Strategies.id`, `Strategies.metadata`, and `Strategies.options`
- Options are validated at construction time using enriched `Exceptions.IncorrectArgument`
- Callable interface: `(solver::MadNCL{P})(nlp; display=true)`
- Extends MadNLP with NCL-specific optimizations
- Default backend is automatically selected based on the parameter type
- **GPU linear solver**: When using `MadNCL{GPU}`, the linear solver automatically defaults to `MadNLPGPU.CUDSSSolver` instead of `MadNLP.MumpsSolver`. This ensures compatibility with GPU execution and avoids attempting to use CPU-only solvers on CUDA backends.

See also: [`AbstractNLPSolver`](@ref), [`MadNLP`](@ref), [`Ipopt`](@ref), [`CPU`](@ref), [`GPU`](@ref)
"""
struct MadNCL{P<:Union{CPU, GPU}} <: AbstractNLPSolver
    "Solver configuration options containing validated option values"
    options::Strategies.StrategyOptions
end

# ============================================================================
# AbstractStrategy Contract Implementation
# ============================================================================

"""
$(TYPEDSIGNATURES)

Return the unique identifier for Solvers.MadNCL.
"""
Strategies.id(::Type{<:Solvers.MadNCL}) = :madncl

"""
$(TYPEDSIGNATURES)

Default parameter type for MadNCL when not explicitly specified.

Returns `CPU` as the default execution parameter.

See also: [`MadNCL`](@ref), [`CPU`](@ref)
"""
Strategies._default_parameter(::Type{<:Solvers.MadNCL}) = CPU

# ============================================================================
# Constructor with tag dispatch
# ============================================================================

"""
$(TYPEDSIGNATURES)

Create a Solvers.MadNCL with specified options (defaults to CPU).

Requires the CTSolversMadNCL extension to be loaded.

# Arguments
- `mode::Symbol=:strict`: Validation mode (`:strict` or `:permissive`)
  - `:strict` (default): Rejects unknown options with detailed error message
  - `:permissive`: Accepts unknown options with warning, stores with `:user` source
- `kwargs...`: Solver options (see extension documentation for available options)

# Example

```julia
# Conceptual usage (requires MadNCL, MadNLP extensions)
using MadNCL, MadNLP
solver = Solvers.MadNCL(max_iter=1000, tol=1e-6)
solver_permissive = Solvers.MadNCL(max_iter=1000, custom_option=123; mode=:permissive)
```

# Throws
- `CTBase.Exceptions.ExtensionError`: If the MadNCL extension is not loaded

See also: [`MadNCL`](@ref), [`build_madncl_solver`](@ref)
"""
function Solvers.MadNCL(; mode::Symbol=:strict, kwargs...)
    return build_madncl_solver(MadNCLTag, Strategies._default_parameter(Solvers.MadNCL); mode=mode, kwargs...)
end

"""
$(TYPEDSIGNATURES)

Create a parameterized Solvers.MadNCL with specified options.

Requires the CTSolversMadNCL extension to be loaded.

# Arguments
- `mode::Symbol=:strict`: Validation mode (`:strict` or `:permissive`)
  - `:strict` (default): Rejects unknown options with detailed error message
  - `:permissive`: Accepts unknown options with warning, stores with `:user` source
- `kwargs...`: Solver options (see extension documentation for available options)

# Example

```julia
# Conceptual usage (requires MadNCL, MadNLP extensions)
using MadNCL, MadNLP
solver_cpu = Solvers.MadNCL{CPU}(max_iter=1000, tol=1e-6)
solver_gpu = Solvers.MadNCL{GPU}(max_iter=1000, tol=1e-6)  # requires CUDA.jl
```

# Throws
- `CTBase.Exceptions.ExtensionError`: If the MadNCL extension is not loaded
- `CTBase.Exceptions.ExtensionError`: If GPU parameter used but CUDA not available

See also: [`MadNCL`](@ref), [`CPU`](@ref), [`GPU`](@ref)
"""
function Solvers.MadNCL{P}(; mode::Symbol=:strict, kwargs...) where {P<:AbstractStrategyParameter}
    return build_madncl_solver(MadNCLTag, P; mode=mode, kwargs...)
end

"""
$(TYPEDSIGNATURES)

Stub function that throws ExtensionError if CTSolversMadNCL extension is not loaded.
Real implementation provided by the extension.

# Throws
- `CTBase.Exceptions.ExtensionError`: Always thrown by this stub implementation

See also: [`MadNCL`](@ref), [`Strategies.metadata`](@ref)
"""
function build_madncl_solver(::Type{<:AbstractTag}, parameter::Type{<:AbstractStrategyParameter}; kwargs...)
    throw(Exceptions.ExtensionError(
        :MadNCL, :MadNLP;
        message="to create MadNCL, access options, and solve problems",
        feature="MadNCL functionality",
        context="Load MadNCL extension first: using MadNCL, MadNLP"
    ))
end

"""
$(TYPEDSIGNATURES)

Stub function that throws ExtensionError if CTSolversMadNCL extension is not loaded.
Real metadata implementation provided by the extension.

This stub is for parameterized types `MadNCL{P}` where `P <: AbstractStrategyParameter`.

# Throws
- `CTBase.Exceptions.ExtensionError`: Always thrown by this stub implementation

See also: [`MadNCL`](@ref), [`Strategies.StrategyMetadata`](@ref)
"""
function Strategies.metadata(::Type{<:Solvers.MadNCL{P}}) where {P<:AbstractStrategyParameter}
    throw(Exceptions.ExtensionError(
        :MadNCL, :MadNLP;
        message="to access MadNCL{$P} options metadata",
        feature="MadNCL metadata",
        context="Load MadNCL extension first: using MadNCL, MadNLP"
    ))
end

"""
$(TYPEDSIGNATURES)

Fallback for non-parameterized `MadNCL` type that delegates to `MadNCL{CPU}`.

This provides backward compatibility and a sensible default when the parameter
is not specified. The call will delegate to `metadata(MadNCL{CPU})`, which will
either use the extension implementation (if loaded) or throw an ExtensionError
(if not loaded).

# Returns
- `StrategyMetadata`: Metadata for `MadNCL{CPU}` (if extension loaded)

# Throws
- `CTBase.Exceptions.ExtensionError`: If extension not loaded (via delegation)

See also: [`MadNCL`](@ref), [`Strategies.metadata`](@ref)
"""
function Strategies.metadata(::Type{Solvers.MadNCL})
    return Strategies.metadata(Solvers.MadNCL{Strategies._default_parameter(Solvers.MadNCL)})
end

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
- CPU implementation provided by CTSolversMadNCL extension
- GPU implementation provided by CTSolversMadNLPGPU extension
"""
function __madncl_default_linear_solver(::Type{<:GPU})
    throw(Exceptions.ExtensionError(
        :MadNLPGPU;
        message="to use GPU linear solver with MadNCL",
        feature="GPU computation with MadNCL",
        context="Load MadNLPGPU extension first: using MadNLPGPU"
    ))
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
function __madncl_consistent_linear_solver(::Type{<:AbstractStrategyParameter}, linear_solver::Type)
    return true
end
