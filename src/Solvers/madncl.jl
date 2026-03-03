# ============================================================================
# Tag Dispatch Infrastructure
# ============================================================================

"""
$(TYPEDEF)

Tag type for MadNCL-specific implementation dispatch.
"""
struct MadNCLTag <: AbstractTag end

# ============================================================================
# Solver Type Definition
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

# Examples

```julia
# Load the extension first
using MadNCL, MadNLP

# Create solver with default options (CPU)
solver = Solvers.MadNCL()

# Explicit CPU solver
solver = Solvers.MadNCL{CPU}()

# GPU solver (requires CUDA.jl)
solver = Solvers.MadNCL{GPU}()

# Create solver with custom options
solver = Solvers.MadNCL(max_iter=1000, tol=1e-6, print_level=MadNLP.DEBUG)

# Solve an NLP problem
using ADNLPModels
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
struct MadNCL{P<:AbstractStrategyParameter} <: AbstractNLPSolver
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

# ============================================================================
# Constructor with Tag Dispatch
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

# Examples
```julia
using MadNCL, MadNLP

# Default solver (CPU)
solver = Solvers.MadNCL()

# Strict mode (default) - rejects unknown options
solver = Solvers.MadNCL(max_iter=1000, tol=1e-6)

# Permissive mode - accepts unknown options with warning
solver = Solvers.MadNCL(max_iter=1000, custom_option=123; mode=:permissive)
```

# Throws
- `Strategies.Exceptions.ExtensionError`: If the MadNCL extension is not loaded
"""
function Solvers.MadNCL(; mode::Symbol=:strict, kwargs...)
    return build_madncl_solver(MadNCLTag(), CPU(); mode=mode, kwargs...)
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

# Examples
```julia
using MadNCL, MadNLP

# Explicit CPU solver
solver = Solvers.MadNCL{CPU}()

# GPU solver (requires CUDA.jl)
solver = Solvers.MadNCL{GPU}()

# With custom options
solver = Solvers.MadNCL{GPU}(max_iter=1000, tol=1e-6)

# Permissive mode
solver = Solvers.MadNCL{GPU}(max_iter=1000, custom_option=123; mode=:permissive)
```

# Throws
- `Strategies.Exceptions.ExtensionError`: If the MadNCL extension is not loaded
- `Strategies.Exceptions.ExtensionError`: If GPU parameter used but CUDA not available
"""
function Solvers.MadNCL{P}(; mode::Symbol=:strict, kwargs...) where {P<:AbstractStrategyParameter}
    return build_madncl_solver(MadNCLTag(), P(); mode=mode, kwargs...)
end

"""
$(TYPEDSIGNATURES)

Stub function that throws ExtensionError if CTSolversMadNCL extension is not loaded.
Real implementation provided by the extension.

# Throws
- `Strategies.Exceptions.ExtensionError`: Always thrown by this stub implementation
"""
function build_madncl_solver(::AbstractTag, parameter::AbstractStrategyParameter; kwargs...)
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

# Throws
- `Strategies.Exceptions.ExtensionError`: Always thrown by this stub implementation
"""
function Strategies.metadata(::Type{<:Solvers.MadNCL})
    throw(Exceptions.ExtensionError(
        :MadNCL, :MadNLP;
        message="to access MadNCL options metadata",
        feature="MadNCL metadata",
        context="Load MadNCL extension first: using MadNCL, MadNLP"
    ))
end
