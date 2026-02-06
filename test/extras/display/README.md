# CTSolvers Display Scripts - REPL Style

This directory contains REPL-style demonstration scripts for CTSolvers display functionality.

## Files Overview

### 📁 Display Scripts (Core Types)
- `01_options_repl.jl` - Options types: OptionValue, OptionDefinition, NotProvided
- `02_strategies_repl.jl` - Strategies: StrategyOptions, StrategyRegistry, introspection
- `03_orchestration_repl.jl` - Orchestration: routing, extraction, disambiguation
- `04_modelers_repl.jl` - Modelers: ADNLPModeler, ExaModeler construction
- `05_solvers_repl.jl` - Solvers: IpoptSolver, MadNLPSolver, MadNCLSolver, KnitroSolver
- `06_docp_repl.jl` - DOCP: Discretized Optimal Control Problem types

## 🎨 REPL Style Convention

- 🟢 `julia>` : Green REPL prompt
- 📋 Output/Results : Structured information display
- 🔹 Details : Indented elements
- ⚠️  Errors : Clear messages with suggestions
- ✅ Success : Visual confirmations

## 🚀 Usage

```bash
# From CTSolvers root directory
julia --project=test/extras test/extras/display/01_options_repl.jl
julia --project=test/extras test/extras/display/02_strategies_repl.jl
# ... etc
```

Each script is self-contained and demonstrates specific display capabilities.
