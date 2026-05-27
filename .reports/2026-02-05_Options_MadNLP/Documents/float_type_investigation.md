# MadNLP Options Default Values Investigation

## Date

2026-02-05

## Problem Statement

During the implementation of Priority 1 termination options for MadNLPSolver, we encountered test failures related to type mismatches when using Float32 models (ExaModels) with Float64 option values.

### Error Observed

```
MethodError: no method matching parse_option(::Type{Float32}, ::Float64)
```

This error occurred when:

- Using `ExaModeler` with `base_type=Float32`
- Passing options with Float64 default values (e.g., `acceptable_tol=1e-6`, `max_wall_time=1e6`)

## Experimental Investigation

### Test Setup

We created a minimal test script (`test/extras/madnlp/debug_madnlp_float_types.jl`) to systematically investigate MadNLP's behavior with different type combinations.

**Simple problem**: `min (x-1)^2`

**Test scenarios**:

1. Float64 model + Float64 options (baseline)
2. Float32 model + Float64 options (problematic case)
3. Float32 model + only `tol` in Float64
4. Float32 model + explicit Float32 options

### Test Results

#### ✅ Test 1: Float64 model + Float64 options

```
Model: ExaModel{Float64, ...}
Options: all Float64 (tol=1e-8, acceptable_tol=1e-6, etc.)
Result: ✓ SOLVED
```

**Conclusion**: Baseline works as expected.

#### ❌ Test 2: Float32 model + Float64 options

```
Model: ExaModel{Float32, ...}
Options: all Float64 (same as Test 1)
Result: ✗ MethodError: parse_option(Float32, 1.0e-6)
Fails on: acceptable_tol=1e-6 (Float64)
```

**Conclusion**: MadNLP **cannot** accept Float64 values for most options when working with Float32 models.

#### ✅ Test 3: Float32 model + only `tol` in Float64

```
Model: ExaModel{Float32, ...}
Options: tol=1e-8 (Float64), print_level=ERROR
Result: ✓ SOLVED
```

**Conclusion**: The `tol` option has special handling or automatic conversion in MadNLP!

#### ✅ Test 4: Float32 model + explicit Float32 options

```
Model: ExaModel{Float32, ...}
Options: all Float32 (tol=Float32(1e-8), acceptable_tol=Float32(1e-6), etc.)
Result: ✓ SOLVED
```

**Conclusion**: Explicit Float32 conversions work perfectly.

### Key Findings

1. **Type Sensitivity**: Most MadNLP options are type-sensitive and must match the model's precision type.

2. **Exception for `tol`**: The `tol` option appears to have automatic type conversion or special handling in MadNLP, which is why it didn't cause issues in our earlier tests.

3. **No Automatic Conversion**: MadNLP does **not** perform automatic type conversion for options like:
   - `acceptable_tol`
   - `max_wall_time`
   - `diverging_iterates_tol`

4. **Error Location**: The error occurs in `MadNLP.parse_option` during `set_options!`, before the solver even starts.

## Root Cause Analysis

### The Issue

When an option is defined with a concrete `default` value in `Strategies.OptionDefinition`, that default value is **always included** in the options dictionary passed to MadNLP, even if the user doesn't explicitly specify it.

The flow is:

1. `Strategies.metadata` defines options with defaults
2. `Strategies.options_dict(solver)` extracts ALL options (including defaults)
3. `Options.extract_raw_options` filters out `NotProvided` values but keeps concrete defaults
4. All options with concrete defaults are passed to `MadNLP.MadNLPSolver`

### Why This Causes Problems

When we defined:

```julia
Strategies.OptionDefinition(;
    name=:acceptable_tol,
    type=Real,
    default=1e-6,  # Float64
    ...
)
```

This Float64 value (`1e-6`) was **always** passed to MadNLP, even for Float32 models. MadNLP's `parse_option` function expects options to match the model's precision type, causing the `MethodError`.

## Solution

### Use `NotProvided` as Default

Instead of concrete Float64 defaults, use `Options.NotProvided`:

```julia
Strategies.OptionDefinition(;
    name=:acceptable_tol,
    type=Real,
    default=Options.NotProvided,  # ← No concrete default
    description="...",
    aliases=(:acc_tol,),
    validator=x -> x > 0 || throw(...)
)
```

### Benefits

1. **No Type Conflicts**: Options with `NotProvided` are filtered out by `extract_raw_options` and not passed to MadNLP
2. **MadNLP's Defaults**: MadNLP uses its own internal default values
3. **User Control**: Users can still explicitly set these options when needed
4. **Type Safety**: When users provide values, they can match the model's precision

### Design Principle

**Do not define concrete default values unless there's a specific project requirement.**

This aligns with the project's philosophy:

- Let backend solvers (MadNLP) manage their own defaults
- Expose options for user control, not to override solver defaults
- Avoid unnecessary coupling between CTSolvers and solver internals

## Implementation

### Changed Options

All four Priority 1 termination options now use `NotProvided`:

| Option | Type | Old Default | New Default |
|--------|------|-------------|-------------|
| `acceptable_tol` | `Real` | `1e-6` | `NotProvided` |
| `acceptable_iter` | `Integer` | `15` | `NotProvided` |
| `max_wall_time` | `Real` | `1e6` | `NotProvided` |
| `diverging_iterates_tol` | `Real` | `1e20` | `NotProvided` |

### Test Updates

Tests now verify that these options have `NotProvided` as their default:

```julia
Test.@test meta[:acceptable_tol].default isa Options.NotProvidedType
Test.@test meta[:acceptable_iter].default isa Options.NotProvidedType
Test.@test meta[:max_wall_time].default isa Options.NotProvidedType
Test.@test meta[:diverging_iterates_tol].default isa Options.NotProvidedType
```

## Validation Tests

Validation tests still work correctly because they explicitly provide invalid values:

```julia
Test.@test_throws Exceptions.IncorrectArgument Solvers.MadNLPSolver(;
    acceptable_tol=-1.0  # ← Explicitly provided, triggers validator
)
```

## Future Considerations

### For Priority 2+ Options

When implementing additional MadNLP options:

1. Use `NotProvided` as default unless there's a specific reason not to
2. Document why any concrete default is chosen
3. Consider type compatibility with Float32/Float64 models
4. Test with both `ADNLPModeler` (Float64) and `ExaModeler(base_type=Float32)`

### Alternative Approaches (Not Chosen)

We considered but rejected:

1. **Type Conversion in `solve_with_madnlp`**: Too invasive, hides the real issue
2. **Float32 Defaults**: Would require maintaining two sets of defaults
3. **Conditional Defaults**: Complex and error-prone

## Conclusion

Using `NotProvided` as the default for solver options is the correct approach when:

- We don't have a specific project requirement for a default value
- We want to let the backend solver manage its own defaults
- We want to avoid type compatibility issues

This solution is clean, maintainable, and aligns with the project's design principles.

The experimental results confirm that:

- **`tol` is special**: MadNLP has built-in conversion for this option
- **Other options are strict**: Type must match the model's precision
- **Our solution works**: Using `NotProvided` avoids the conflict entirely

## References

- `src/Options/not_provided.jl`: Definition of `NotProvided` and `NotProvidedType`
- `src/Options/option_definition.jl`: `OptionDefinition` constructor handling
- `src/Options/extraction.jl`: `extract_raw_options` filtering logic
- `ext/CTSolversMadNLP.jl`: MadNLP solver metadata and options
- `test/extras/madnlp/debug_madnlp_float_types.jl`: Experimental test script
