# CTSolvers.jl

```@meta
CurrentModule = CTSolvers
```

The `CTSolvers.jl` package is part of the [control-toolbox ecosystem](https://github.com/control-toolbox).
It provides the **solution layer** for optimal control problems:

- **discretization methods** for transforming continuous optimal control problems into finite-dimensional optimization problems;
- **modeler backends** (ADNLPModels, ExaModels) for building NLP models;
- **optimization strategies** for configuring solution approaches;
- **solver integration** with popular NLP solvers (Ipopt, Knitro, MadNLP);
- a unified **CommonSolve interface** for solving optimal control problems.

!!! info "CTSolvers vs CTModels"

    **CTSolvers** focuses on **solving** optimal control problems (discretization, NLP backends, optimization strategies).
    For **defining** these problems and representing their solutions,
    see [CTModels.jl](https://github.com/control-toolbox/CTModels.jl).

!!! note

    The root package is [OptimalControl.jl](https://github.com/control-toolbox/OptimalControl.jl) which aims
    to provide tools to model and solve optimal control problems with ordinary differential equations
    by direct and indirect methods, both on CPU and GPU.

!!! warning "Qualified Module Access"

    CTSolvers does **not** export functions directly. All functions and types must be accessed
    via qualified module paths to avoid namespace conflicts.

    ```julia-repl
    julia> using CTSolvers
    julia> CTSolvers.Options.extract_options(config)  # Correct
    julia> extract_options(config)  # Error: not exported
    ```

    This design ensures:
    - **Namespace clarity** - Explicit module qualification
    - **No conflicts** - Avoids name collisions with other packages
    - **Explicit dependencies** - Clear which module provides what
    - **Consistency** - Matches CTModels.jl ecosystem pattern

## What CTSolvers provides

### Options System

A flexible configuration system for managing solver options:

- `CTSolvers.Options.OptionDefinition` - Define option schemas with types and defaults
- `CTSolvers.Options.OptionValue` - Store and validate option values
- `CTSolvers.Options.extract_options` - Extract options from various sources
- `CTSolvers.Options.NotProvided` - Sentinel for optional parameters

### Planned Features

- **DOCP** - Discretized Optimal Control Problem types and operations
- **Modelers** - Backend implementations (ADNLPModeler, ExaModeler)
- **Optimization** - General optimization abstractions and builders
- **Orchestration** - High-level coordination and method routing
- **Strategies** - Strategy patterns for solution approaches
- **Solvers** - Solver integration and CommonSolve API

## How this documentation is organized

- **API Reference** - Detailed documentation for all modules and functions

## Quick start guide

```julia
using CTSolvers

# Configure options
options = CTSolvers.Options.extract_options(
    :solver => :ipopt,
    :max_iter => 1000,
    :tol => 1e-6
)

# More examples coming as modules are integrated...