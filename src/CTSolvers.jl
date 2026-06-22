"""
    CTSolvers

Control Toolbox Solvers (CTSolvers) - A Julia package for solving optimal control problems.

This module provides a comprehensive framework for solving optimal control problems
with a modular architecture that separates concerns and facilitates extensibility.

# Architecture Overview

CTSolvers is organized into specialized modules, each with clear responsibilities:

## Generic Infrastructure (provided by CTBase)

- **CTBase.Options**: Configuration and options management system
  - Option definitions and validation
  - Option extraction API
  - NotProvided sentinel for optional parameters

- **CTBase.Strategies**: Strategy contract and registry
  - Abstract strategy types and interface
  - Strategy registry for explicit dependency management
  - Strategy building and validation utilities

- **CTBase.Orchestration**: High-level coordination and method routing
  - Option routing with disambiguation support
  - Method resolution from strategy families

## Implemented Modules

- **DOCP**: Discretized Optimal Control Problem types and operations
- **Modelers**: Backend modeler implementations (Modelers.ADNLP, Modelers.Exa)
- **Optimization**: General optimization abstractions and builders
- **Solvers**: Solver integration and CommonSolve API

# Loading Order

Modules are loaded in dependency order to ensure all types and functions are available
when needed.

# Public API

All functions and types are accessible via qualified module paths (e.g., `CTBase.Options.extract_options()`).
The modular architecture ensures that:

- Types are defined where they belong
- Dependencies are explicit and minimal
- Extensions can target specific modules
- The public API remains stable and clean
- No direct exports to avoid namespace conflicts
"""
module CTSolvers

# Optimization module - general optimization abstractions and builders
include(joinpath(@__DIR__, "Optimization", "Optimization.jl"))
using .Optimization

# Modelers module - backend modeler implementations (Modelers.ADNLP, Modelers.Exa)
include(joinpath(@__DIR__, "Modelers", "Modelers.jl"))
using .Modelers

# DOCP module - Discretized Optimal Control Problem types and operations
include(joinpath(@__DIR__, "DOCP", "DOCP.jl"))
using .DOCP

# Solvers module - optimization solver implementations and CommonSolve API
include(joinpath(@__DIR__, "Solvers", "Solvers.jl"))
using .Solvers

end
