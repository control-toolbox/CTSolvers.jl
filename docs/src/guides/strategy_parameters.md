# Strategy Parameters

```@meta
CurrentModule = CTSolvers
```

This guide explains the **Strategy Parameters** system in CTSolvers. Parameters allow strategies to specialize their behavior and default options based on execution context (e.g., CPU vs GPU).

!!! tip "Prerequisites"
    Read [Implementing a Strategy](@ref) first. Parameters extend the strategy system with type-based specialization.

## Concept

**Strategy parameters** are singleton types that enable:
- **Type-based dispatch** for different execution backends
- **Specialized default options** per parameter
- **Compile-time optimization** through type inference

Parameters are **not** runtime values — they exist purely for dispatch and metadata specialization.

## Built-in Parameters

CTSolvers provides two built-in parameters:

### CPU Parameter

```julia
struct CPU <: Strategies.AbstractStrategyParameter end
Strategies.id(::Type{CPU}) = :cpu
```

Indicates CPU-based execution with CPU-optimized defaults.

### GPU Parameter

```julia
struct GPU <: Strategies.AbstractStrategyParameter end
Strategies.id(::Type{GPU}) = :gpu
```

Indicates GPU-based execution with GPU-optimized defaults.

## Parameter Contract

Every parameter type must:

1. **Subtype `AbstractStrategyParameter`**
2. **Be a singleton** (no fields)
3. **Implement `id(::Type{<:YourParameter})`**

### Example: Custom Parameter

```julia
using CTSolvers.Strategies

# Define parameter type
struct Distributed <: AbstractStrategyParameter end

# Implement contract
Strategies.id(::Type{Distributed}) = :distributed
```

## Using Parameters in Strategies

Parameters enable strategies to provide **specialized metadata** based on execution context.

### Parameterized Metadata

Strategies can define metadata functions that accept a parameter type:

```julia
"""
Return metadata for MadNLP solver.

The metadata is parameterized by execution backend (CPU or GPU).
For GPU execution, the default linear solver is automatically set to
`MadNLPGPU.CUDSSSolver` instead of `MadNLP.MumpsSolver`.
"""
function Strategies.metadata(
    ::Type{<:Solvers.MadNLP},
    ::Type{P}
) where {P<:AbstractStrategyParameter}
    # Get backend-specific default
    default_linear_solver = __madnlp_default_linear_solver(P)
    
    return Strategies.StrategyMetadata(
        Options.OptionDefinition(
            name = :linear_solver,
            type = Type,
            default = default_linear_solver,
            description = "Linear solver for MadNLP"
        ),
        # ... other options
    )
end

# Specialized defaults per parameter
function __madnlp_default_linear_solver(::Type{CPU})
    return MadNLP.MumpsSolver
end

function __madnlp_default_linear_solver(::Type{GPU})
    return MadNLPGPU.CUDSSSolver
end
```

### Registry with Parameters

Parameters must be registered alongside strategies:

```julia
registry = Strategies.create_registry(
    # Strategy families
    AbstractNLPSolver => (Solvers.Ipopt, Solvers.MadNLP),
    # Parameters
    parameters = (CPU, GPU)
)
```

## Real-World Example: MadNLP

The `Solvers.MadNLP` strategy uses parameters to switch between CPU and GPU backends:

```julia
# CPU execution (default)
solver_cpu = Solvers.MadNLP(CPU; max_iter=1000)
# Uses MadNLP.MumpsSolver as default linear solver

# GPU execution
solver_gpu = Solvers.MadNLP(GPU; max_iter=1000)
# Uses MadNLPGPU.CUDSSSolver as default linear solver
```

The parameter is passed as the **first positional argument** to the constructor.

### Constructor Pattern with Parameters

```julia
function Solvers.MadNLP(
    parameter::Type{<:AbstractStrategyParameter} = CPU;
    mode::Symbol = :strict,
    kwargs...
)
    # Get parameterized metadata
    meta = Strategies.metadata(Solvers.MadNLP, parameter)
    
    # Build options with specialized defaults
    opts = Strategies.build_strategy_options(
        Solvers.MadNLP;
        metadata = meta,
        mode = mode,
        kwargs...
    )
    
    return Solvers.MadNLP(opts)
end
```

## Parameter Validation

The `Strategies` module provides validation helpers:

```julia
# Check if a type is a parameter
Strategies.is_parameter_type(CPU)  # true
Strategies.is_parameter_type(Int)  # false

# Get parameter ID
Strategies.parameter_id(CPU)  # :cpu

# Validate parameter contract
Strategies.validate_parameter_type(CPU)  # returns nothing if valid
```

### Validation Rules

A valid parameter must:
- Be a **concrete type** (not abstract)
- Be a **singleton** (zero fields)
- **Implement `id`** (returns a Symbol)

```julia
# ✅ Valid parameter
struct MyParam <: AbstractStrategyParameter end
Strategies.id(::Type{MyParam}) = :my_param

# ❌ Invalid: has fields
struct BadParam <: AbstractStrategyParameter
    value::Int  # ERROR: parameters must be singletons
end

# ❌ Invalid: abstract
abstract type BadParam2 <: AbstractStrategyParameter end
```

## Orchestration with Parameters

Parameters integrate with the orchestration system for automatic routing:

```julia
# User provides parameter via keyword
solve(problem, x0, modeler, :madnlp; parameter=:gpu, max_iter=1000)

# Orchestration:
# 1. Resolves :madnlp → Solvers.MadNLP
# 2. Resolves :gpu → GPU parameter type
# 3. Calls Solvers.MadNLP(GPU; max_iter=1000)
# 4. Uses GPU-specific defaults
```

## When to Use Parameters

Use parameters when:
- ✅ Strategy behavior depends on **execution context** (CPU/GPU, serial/parallel)
- ✅ Different backends require **different default options**
- ✅ Specialization is **type-based** (compile-time)

Don't use parameters when:
- ❌ Configuration is **runtime-dependent** (use regular options instead)
- ❌ Behavior is **data-dependent** (use conditional logic)
- ❌ Only one backend exists (no need for specialization)

## Advanced: Custom Parameters

### Example: Precision Parameter

```julia
# Define precision parameters
struct Float32Precision <: AbstractStrategyParameter end
struct Float64Precision <: AbstractStrategyParameter end

Strategies.id(::Type{Float32Precision}) = :float32
Strategies.id(::Type{Float64Precision}) = :float64

# Use in strategy metadata
function Strategies.metadata(
    ::Type{<:MyStrategy},
    ::Type{P}
) where {P<:AbstractStrategyParameter}
    tol = __default_tolerance(P)
    
    return Strategies.StrategyMetadata(
        Options.OptionDefinition(
            name = :tol,
            type = Float64,
            default = tol,
            description = "Convergence tolerance"
        )
    )
end

__default_tolerance(::Type{Float32Precision}) = 1e-6
__default_tolerance(::Type{Float64Precision}) = 1e-12
```

## Summary

| Aspect | Description |
|--------|-------------|
| **Purpose** | Type-based specialization of strategy behavior and defaults |
| **Contract** | Singleton type + `id(::Type)` implementation |
| **Built-in** | `CPU`, `GPU` |
| **Usage** | First positional argument to strategy constructors |
| **Registry** | Must be registered with `parameters = (...)` |
| **Validation** | `validate_parameter_type`, `is_parameter_type`, `parameter_id` |

## See Also

- [Implementing a Strategy](@ref) — Strategy contract and metadata
- [Orchestration and Routing](@ref) — How parameters integrate with routing
- `Strategies.AbstractStrategyParameter` — API reference
- `Solvers.MadNLP` — Real-world example with CPU/GPU parameters
