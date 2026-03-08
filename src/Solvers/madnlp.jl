# ============================================================================
# Tag dispatch infrastructure
# ============================================================================

"""
$(TYPEDEF)

Tag type for MadNLP-specific implementation dispatch.
"""
struct MadNLPTag <: AbstractTag end

# ============================================================================
# Solver type definition
# ============================================================================

"""
$(TYPEDEF)

Pure-Julia interior point solver with GPU support.

MadNLP is a modern implementation of an interior point method written entirely in Julia,
with support for GPU acceleration and various linear solver backends. It provides excellent
performance for large-scale optimization problems.

## Parameterized Types

The solver supports parameterization for execution backend:
- `MadNLP{CPU}`: CPU execution (default)
- `MadNLP{GPU}`: GPU execution (requires CUDA.jl)

# Fields

$(TYPEDFIELDS)

# Solver Options

- `max_iter::Integer`: Maximum number of iterations (default: 3000, must be ≥ 0)
- `tol::Real`: Convergence tolerance (default: 1e-8, must be > 0)
- `print_level::MadNLP.LogLevels`: MadNLP log level (default: MadNLP.INFO)
  - MadNLP.DEBUG: Detailed debugging output
  - MadNLP.INFO: Standard informational output
  - MadNLP.WARN: Warning messages only
  - MadNLP.ERROR: Error messages only
- `linear_solver::Type{<:MadNLP.AbstractLinearSolver}`: Linear solver backend
  - Default for CPU: `MadNLP.MumpsSolver`
  - Default for GPU: `MadNLPGPU.CUDSSSolver` (requires MadNLPGPU.jl)
- `backend`: Execution backend (default depends on parameter: CPU backend for CPU, CUDA backend for GPU)

# Example

```julia
# Conceptual usage pattern (requires MadNLP extension)
using MadNLP
solver = MadNLP(max_iter=1000, tol=1e-6, print_level=MadNLP.DEBUG)
nlp = ADNLPModel(x -> sum(x.^2), zeros(10))
stats = solver(nlp, display=true)
```

# Extension Required

This solver requires the `MadNLP` package:
```julia
using MadNLP
```

# Implementation Notes

- Implements the `AbstractStrategy` contract via `Strategies.id`, `Strategies.metadata`, and `Strategies.options`
- Options are validated at construction time using enriched `Exceptions.IncorrectArgument`
- Callable interface: `(solver::MadNLP{P}(nlp; display=true)`
- Supports GPU acceleration when appropriate backends are loaded
- Default backend is automatically selected based on the parameter type
- **GPU linear solver**: When using `MadNLP{GPU}`, the linear solver automatically defaults to `MadNLPGPU.CUDSSSolver` instead of `MadNLP.MumpsSolver`. This ensures compatibility with GPU execution and avoids attempting to use CPU-only solvers on CUDA backends.

See also: [`AbstractNLPSolver`](@ref), [`Ipopt`](@ref), [`Solvers.MadNCL`](@ref), [`CPU`](@ref), [`GPU`](@ref)
"""
struct MadNLP{P<:Union{CPU, GPU}} <: AbstractNLPSolver
    "Solver configuration options containing validated option values"
    options::Strategies.StrategyOptions
end

# ============================================================================
# AbstractStrategy Contract Implementation
# ============================================================================

"""
$(TYPEDSIGNATURES)

Return the unique identifier for MadNLP.
"""
Strategies.id(::Type{<:Solvers.MadNLP}) = :madnlp

"""
$(TYPEDSIGNATURES)

Default parameter type for MadNLP when not explicitly specified.

Returns `CPU` as the default execution parameter.

See also: [`MadNLP`](@ref), [`CPU`](@ref)
"""
Strategies._default_parameter(::Type{<:Solvers.MadNLP}) = CPU

# ============================================================================
# Constructor with tag dispatch
# ============================================================================

"""
$(TYPEDSIGNATURES)

Create a MadNLP with specified options (defaults to CPU).

Requires the CTSolversMadNLP extension to be loaded.

# Arguments
- `mode::Symbol=:strict`: Validation mode (`:strict` or `:permissive`)
  - `:strict` (default): Rejects unknown options with detailed error message
  - `:permissive`: Accepts unknown options with warning, stores with `:user` source
- `kwargs...`: Solver options (see extension documentation for available options)

# Example

```julia
# Conceptual usage (requires MadNLP extension)
using MadNLP
solver = MadNLP(max_iter=1000, tol=1e-6)
solver_permissive = MadNLP(max_iter=1000, custom_option=123; mode=:permissive)
```

# Throws
- `CTBase.Exceptions.ExtensionError`: If the MadNLP extension is not loaded

See also: [`MadNLP`](@ref), [`build_madnlp_solver`](@ref)
"""
function Solvers.MadNLP(; mode::Symbol=:strict, kwargs...)
    P = Strategies._default_parameter(Solvers.MadNLP)
    return Solvers.MadNLP{P}(; mode=mode, kwargs...)
end

"""
$(TYPEDSIGNATURES)

Create a parameterized MadNLP with specified options.

Requires the CTSolversMadNLP extension to be loaded.

# Arguments
- `mode::Symbol=:strict`: Validation mode (`:strict` or `:permissive`)
  - `:strict` (default): Rejects unknown options with detailed error message
  - `:permissive`: Accepts unknown options with warning, stores with `:user` source
- `kwargs...`: Solver options (see extension documentation for available options)

# Example

```julia
# Conceptual usage (requires MadNLP extension)
using MadNLP
solver_cpu = MadNLP{CPU}(max_iter=1000, tol=1e-6)
solver_gpu = MadNLP{GPU}(max_iter=1000, tol=1e-6)  # requires CUDA.jl
```

# Throws
- `CTBase.Exceptions.ExtensionError`: If the MadNLP extension is not loaded
- `CTBase.Exceptions.ExtensionError`: If GPU parameter used but CUDA not available

See also: [`MadNLP`](@ref), [`CPU`](@ref), [`GPU`](@ref)
"""
function Solvers.MadNLP{P}(; mode::Symbol=:strict, kwargs...) where {P<:AbstractStrategyParameter}
    return build_madnlp_solver(MadNLPTag, P; mode=mode, kwargs...)
end

"""
$(TYPEDSIGNATURES)

Stub function that throws ExtensionError if CTSolversMadNLP extension is not loaded.
Real implementation provided by the extension.

# Throws
- `CTBase.Exceptions.ExtensionError`: Always thrown by this stub implementation

See also: [`MadNLP`](@ref), [`Strategies.metadata`](@ref)
"""
function build_madnlp_solver(::Type{<:AbstractTag}, parameter::Type{<:AbstractStrategyParameter}; kwargs...)
    throw(Exceptions.ExtensionError(
        :MadNLP;
        message="to create MadNLP, access options, and solve problems",
        feature="MadNLP functionality",
        context="Load MadNLP extension first: using MadNLP"
    ))
end

"""
$(TYPEDSIGNATURES)

Stub function that throws ExtensionError if CTSolversMadNLP extension is not loaded.
Real metadata implementation provided by the extension.

This stub is for parameterized types `MadNLP{P}` where `P <: AbstractStrategyParameter`.

# Throws
- `CTBase.Exceptions.ExtensionError`: Always thrown by this stub implementation

See also: [`MadNLP`](@ref), [`Strategies.StrategyMetadata`](@ref)
"""
function Strategies.metadata(::Type{<:Solvers.MadNLP{P}}) where {P<:AbstractStrategyParameter}
    throw(Exceptions.ExtensionError(
        :MadNLP;
        message="to access MadNLP{$P} options metadata",
        feature="MadNLP metadata",
        context="Load MadNLP extension first: using MadNLP"
    ))
end

"""
$(TYPEDSIGNATURES)

Fallback for non-parameterized `MadNLP` type that delegates to `MadNLP{CPU}`.

This provides backward compatibility and a sensible default when the parameter
is not specified. The call will delegate to `metadata(MadNLP{CPU})`, which will
either use the extension implementation (if loaded) or throw an ExtensionError
(if not loaded).

# Returns
- `StrategyMetadata`: Metadata for `MadNLP{CPU}` (if extension loaded)

# Throws
- `CTBase.Exceptions.ExtensionError`: If extension not loaded (via delegation)

See also: [`MadNLP`](@ref), [`Strategies.metadata`](@ref)
"""
function Strategies.metadata(::Type{Solvers.MadNLP})
    return Strategies.metadata(Solvers.MadNLP{Strategies._default_parameter(Solvers.MadNLP)})
end
