# CTSolvers Display Tests - REPL Style

This directory contains REPL-style test scripts for CTSolvers display functionality, specifically testing the `display=false` keyword argument behavior.

## Files Overview

### 📁 Display Test Scripts
- `01_solver_display.jl` - Solver display tests: Ipopt, MadNLP, MadNCL, Knitro
- `02_modeler_display.jl` - Modeler display tests: ADNLPModeler, ExaModeler
- `03_routing_display.jl` - Routing display tests: option routing with display parameter
- `04_extraction_display.jl` - Extraction display tests: option extraction and validation
- `05_scenarios_display.jl` - Complete scenarios: verbose vs quiet comparisons
- `06_types_display.jl` - REPL-style display examples focused on display functionality

## 🎨 REPL Style Convention

- 🟢 `julia>` : Green REPL prompt
- 📋 Output/Results : Structured information display
- 🔹 Details : Indented elements
- ⚠️  Errors : Clear messages with suggestions
- ✅ Success : Visual confirmations

## 🚀 Usage

```bash
# From CTSolvers root directory
julia --project=test/extras test/extras/kwarg/01_solver_display.jl
julia --project=test/extras test/extras/kwarg/02_modeler_display.jl
# ... etc
```

Each script tests specific aspects of display functionality and output suppression.
