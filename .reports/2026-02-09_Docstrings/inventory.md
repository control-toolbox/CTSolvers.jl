# File Inventory for Docstring Review

## src/ Directory

### CTSolvers.jl (Root Module)
- `src/CTSolvers.jl` - Main module file

### DOCP Module (5 files)
- `src/DOCP/DOCP.jl` - Module definition
- `src/DOCP/accessors.jl` - Accessor functions
- `src/DOCP/building.jl` - Building utilities
- `src/DOCP/contract_impl.jl` - Contract implementations
- `src/DOCP/types.jl` - Type definitions

### Modelers Module (5 files)
- `src/Modelers/Modelers.jl` - Module definition
- `src/Modelers/abstract_modeler.jl` - Abstract type and interface
- `src/Modelers/adnlp_modeler.jl` - ADNLPModels integration
- `src/Modelers/exa_modeler.jl` - ExaModels integration
- `src/Modelers/validation.jl` - Validation logic

### Optimization Module (6 files)
- `src/Optimization/Optimization.jl` - Module definition
- `src/Optimization/abstract_types.jl` - Abstract types
- `src/Optimization/builders.jl` - Builder patterns
- `src/Optimization/building.jl` - Building utilities
- `src/Optimization/contract.jl` - Contract definitions
- `src/Optimization/solver_info.jl` - Solver information

### Options Module (5 files)
- `src/Options/Options.jl` - Module definition
- `src/Options/extraction.jl` - Option extraction logic
- `src/Options/not_provided.jl` - NotProvided sentinel
- `src/Options/option_definition.jl` - OptionDefinition type
- `src/Options/option_value.jl` - OptionValue type

### Orchestration Module (3 files)
- `src/Orchestration/Orchestration.jl` - Module definition
- `src/Orchestration/disambiguation.jl` - Option routing (recently refactored)
- `src/Orchestration/routing.jl` - Strategy routing

### Solvers Module (8 files)
- `src/Solvers/Solvers.jl` - Module definition
- `src/Solvers/abstract_solver.jl` - Abstract type and interface
- `src/Solvers/common_solve_api.jl` - CommonSolve integration
- `src/Solvers/ipopt_solver.jl` - Ipopt integration
- `src/Solvers/knitro_solver.jl` - Knitro integration
- `src/Solvers/madncl_solver.jl` - MadNCL integration
- `src/Solvers/madnlp_solver.jl` - MadNLP integration
- `src/Solvers/validation.jl` - Validation logic

### Strategies Module (11 files)

#### API (8 files)
- `src/Strategies/api/builders.jl` - Strategy builders
- `src/Strategies/api/configuration.jl` - Configuration logic (Phase 2 refactored)
- `src/Strategies/api/disambiguation.jl` - RoutedOption (Phase 1 refactored)
- `src/Strategies/api/introspection.jl` - Introspection utilities (Phase 3 refactored)
- `src/Strategies/api/registry.jl` - Strategy registry
- `src/Strategies/api/utilities.jl` - Utility functions (Phase 3 refactored)
- `src/Strategies/api/validation_helpers.jl` - Validation helpers (Phase 2 refactored)
- `src/Strategies/api/validation.jl` - Validation logic (Phase 2 refactored)

#### Contract (3 files)
- `src/Strategies/contract/abstract_strategy.jl` - Abstract strategy interface
- `src/Strategies/contract/metadata.jl` - StrategyMetadata (Phase 2 refactored)
- `src/Strategies/contract/strategy_options.jl` - StrategyOptions (Phase 3 refactored)

- `src/Strategies/Strategies.jl` - Module definition

## ext/ Directory (Extensions)

### Solver Extensions (4 files)
- `ext/CTSolversIpopt.jl` - Ipopt extension (24.5 KB)
- `ext/CTSolversKnitro.jl` - Knitro extension (9.4 KB)
- `ext/CTSolversMadNCL.jl` - MadNCL extension (16.3 KB)
- `ext/CTSolversMadNLP.jl` - MadNLP extension (16.5 KB)

## Summary

**Total files**: 47
- `src/`: 43 files
- `ext/`: 4 files

**Priority for review**:
1. **High**: Recently refactored files (Phases 1-3)
2. **High**: Public API (abstract types, exported functions)
3. **Medium**: Internal utilities
4. **Medium**: Extensions
5. **Low**: Simple accessors/getters

**Recently refactored files requiring update**:
- `src/Orchestration/disambiguation.jl` - RoutedOption iteration (Phase 1)
- `src/Strategies/contract/metadata.jl` - StrategyMetadata (Phase 2)
- `src/Strategies/contract/strategy_options.jl` - StrategyOptions (Phase 3)
- `src/Strategies/api/configuration.jl` - Uses meta interface (Phase 2)
- `src/Strategies/api/introspection.jl` - Uses opts interface (Phase 3)
- `src/Strategies/api/utilities.jl` - Uses _raw_options helper (Phase 3)
- `src/Strategies/api/validation.jl` - Uses meta/opts interfaces (Phase 2)
- `src/Strategies/api/validation_helpers.jl` - Uses meta interface (Phase 2)
