# MadNLP Float Type Investigation

This directory contains diagnostic scripts for investigating MadNLP behavior with different floating-point precision types (Float32 vs Float64).

## Files Overview

### 📁 Diagnostic Scripts
- `debug_madnlp_float_types.jl` - Test Float32/Float64 compatibility with MadNLP options

## 🎯 Purpose

These scripts investigate whether MadNLP can accept Float64 option values when working with Float32 models (ExaModels), which is critical for understanding the type compatibility requirements for solver options.

## 🧪 Test Scenarios

The debug script tests four scenarios:

1. **Float64 model + Float64 options** (baseline)
2. **Float32 model + Float64 options** (potential issue)
3. **Float32 model + only `tol` in Float64** (minimal test)
4. **Float32 model + explicit Float32 options** (workaround)

Each test attempts to:
- Create an ExaModel with the specified precision
- Pass options (with different type combinations)
- Create a MadNLP solver
- Solve a simple optimization problem: `min (x-1)^2`

## 🚀 Usage

```bash
# From CTSolvers root directory
julia --project=test/extras test/extras/madnlp/debug_madnlp_float_types.jl
```

## 📊 Expected Output

Each test reports:
- ✓ **Success**: Solver accepts the options and solves successfully
- ✗ **Error**: Type mismatch or parsing error with stack trace

## 🔍 Key Findings

This investigation helps determine:
- Whether MadNLP performs automatic type conversion for options
- Which options are sensitive to Float32/Float64 mismatches
- Whether using `NotProvided` as default is necessary to avoid type conflicts

## 📖 Related Documentation

See `.reports/2026-02-05_Options_MadNLP/Documents/float_type_investigation.md` for detailed analysis of the type compatibility issue and the solution using `NotProvided` defaults.
