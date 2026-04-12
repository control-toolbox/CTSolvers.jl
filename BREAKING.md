# Breaking Changes

This document describes all breaking changes introduced in CTSolvers.jl releases
and provides migration guides for users upgrading between versions.

---

## v0.4.14 (2026-04-12)

**No breaking changes.**

This release improves unknown option error messages with registry search functionality.

### Summary - v0.4.14

- Enhanced error messages when an option doesn't belong to any strategy in the current method
- Added `_find_option_in_registry()` helper function to search for options across all registered strategies
- Error messages now suggest if an option exists in other strategies not in the current method
- Lists all matching strategies with their IDs and family names
- Added comprehensive test coverage for registry search functionality

### Migration - v0.4.14

**No action required.** All existing code continues to work without changes.

**Improved behavior:**

When users provide an unknown option that doesn't exist in any strategy of the current method, the error message now includes helpful suggestions if the option exists in other registered strategies.

**Example:**

```julia
# Before: Generic error message
solve(ocp, :collocation, :adnlp, :ipopt; custom_opt=123)
# → Error: "Option :custom_opt doesn't belong to any strategy in method (:collocation, :adnlp, :ipopt). Available options: ..."

# After: Enhanced error with registry match
solve(ocp, :collocation, :adnlp, :ipopt; custom_opt=123)
# → Error: "Option :custom_opt doesn't belong to any strategy in method (:collocation, :adnlp, :ipopt).
#         This option exists in other strategies: :madnlp (solver).
#         Perhaps you selected the wrong strategy? Consider using a different method."
```

**Benefits:**

- **Better UX**: Users get actionable guidance when they may have chosen the wrong strategy
- **Faster debugging**: Identifies alternative strategies that support the requested option
- **No API changes**: Purely an enhancement of error messages

---

## v0.4.13 (2026-04-07)

### Display Changes (Non-Breaking)

The following changes improve the display format without breaking existing functionality:

#### Strategy Header Display

**Before:**

```text
ADNLP{CPU} (strategy)
```

**After:**

```text
ADNLP (strategy)
```

**Impact:** No functional changes - this is purely a display improvement. The parameter information (`{CPU}`) is still displayed in the "parameters" section below the header.

#### Options Display Order

**Before:**

```text
common options (1 option):
   base_type::DataType (default: Float64)

computed options for CPU:
   backend::Any (default: nothing [computed])
```

**After:**

```text
computed options for CPU:
   backend::Any (default: nothing [computed])

common options (1 option):
   base_type::DataType (default: Float64)
```

**Impact:** No functional changes - this reorders the display to show computed options (parameter-specific) before common options (shared across parameters).

### Migration Notes

No code changes are required. These are display improvements that:

1. **Reduce redundancy** in strategy headers by removing parameter information that's already shown elsewhere
2. **Improve information hierarchy** by showing dynamic computed options before static common options
3. **Maintain all existing information** in a more logical order

---

## v0.4.12 (2026-03-31)

**No breaking changes.**

This release applies code formatting for consistency.

### Summary - v0.4.12

- Applied JuliaFormatter to `src/Strategies/api/describe_registry.jl`
- Minor whitespace formatting for consistency

### Migration - v0.4.12

**No action required.** All existing code continues to work without changes.

---

## v0.4.11-beta (2026-03-29)

**No breaking changes.**

This release improves strategy type display and refactors internal implementation for better maintainability.

### Summary - v0.4.11-beta

- Strategy types in `describe()` output now show clean names without module prefixes
- `Exa{CPU}` instead of `CTSolvers.Modelers.Exa{CTSolvers.Strategies.CPU}`
- Preserves parameter information while removing module clutter
- Refactored `_strategy_type_name` with multiple dispatch for extensibility
- Applied comprehensive documentation standards to all methods

### Migration - v0.4.11-beta

**No action required.** All existing code continues to work without changes.

**Improved behavior:**

- `describe(:cpu, registry)` and `describe(:gpu, registry)` output is more readable
- Strategy type names are cleaner while preserving parameter information
- Internal implementation is more maintainable and follows Julia best practices

**Potential compatibility notes:**

- Output format has changed (improved) but no API changes
- Tests that check exact string output may need updating to expect cleaner type names
- This is purely a display improvement with no functional changes

---

## v0.4.10-beta (2026-03-17)

**No breaking changes.**

This release forces ANSI color codes in all contexts for consistent display.

### Summary - v0.4.10-beta

- Forced ANSI colors in `get_format_codes()` for consistent display across all contexts
- Colors now appear in Documenter documentation (local and remote)
- Improved `describe()`, `OptionDefinition`, `StrategyMetadata`, and `StrategyOptions` display
- Removed color detection to ensure colors work in all environments

### Migration - v0.4.10-beta

**No action required.** All existing code continues to work without changes.

**Improved behavior:**

- All pretty-printed objects now display colors in documentation
- Colors are consistent across terminal, documentation, and CI environments
- `describe()` functions show colored hierarchical output in generated HTML docs

**Potential compatibility notes:**

- Very old terminals that don't support ANSI codes may show escape sequences
- Log files will contain ANSI color codes (generally harmless)
- This follows modern Julia package conventions for colored output

---

## v0.4.8-beta (2026-03-16)

**No breaking changes.**

This release adds parameter description methods and improves hierarchy display across all describe functions.

### Summary - v0.4.8-beta

- Added `description` contract method for `AbstractStrategyParameter` with `NotImplemented` fallback
- Implemented `description` for built-in `CPU` and `GPU` parameters
- Added `describe` methods for parameters (type-direct and registry-aware)
- Display parameter ID, hierarchy chain, and description
- Registry-aware `describe` lists strategies using each parameter
- Improved strategy `describe` to show full hierarchy chain instead of just supertype
- Added `_supertype_chain` helper function for consistent hierarchy display
- Added comprehensive tests following `.windsurf` standards
- Export `description` function for parameters

### Migration - v0.4.8-beta

**No action required.** All existing code continues to work without changes.

**Improved behavior:**

- All `describe` methods now show full hierarchy: `Type → Parent → AbstractStrategy`
- New `describe(CPU)` and `describe(GPU)` provide parameter introspection
- New `describe(:cpu, registry)` and `describe(:gpu, registry)` show strategies using parameters
- Registry-aware `describe` now handles both strategy and parameter IDs with clear disambiguation

---

## v0.4.7-beta (2026-03-15)

**No breaking changes.**

This release adds registry-aware strategy description and enhanced display formatting.

### Summary - v0.4.7-beta

- Added new `Core` module with exception handling and utilities
- Added `describe(id::Symbol, registry::StrategyRegistry)` for comprehensive strategy introspection
- Enhanced pretty printing for strategy options with structured output
- Improved StrategyRegistry display without duplicate IDs
- Added visual separation between parameters and options
- Enhanced extension error display with red coloring and exact names
- Improved module organization and exports across the codebase
- Enhanced strategy registry and contract metadata handling
- Added comprehensive test suite with 53 tests

### Migration - v0.4.7-beta

**No action required.** All existing code continues to work without changes.

**Improved behavior:**

- Strategy registry display is now clearer without duplicate strategy IDs
- Extension errors are displayed in red with exact extension names
- New `describe` function provides detailed strategy introspection from registry
- Visual formatting improvements make output more readable

---

## v0.4.6 (2026-03-10)

**No breaking changes.**

This release fixes a bug in option validation that caused `MethodError` instead of clear error messages.

### Summary - v0.4.6

- Fixed option validator to check types before calling validators
- Improved error messages when wrong types are passed to options
- Added comprehensive tests for type validation

### Migration - v0.4.6

**No action required.** All existing code continues to work without changes.

**Improved behavior:** Code that previously threw `MethodError` (e.g., `ADNLP(backend=CUDABackend())`) now throws clear `IncorrectArgument` with helpful suggestions.

---

## v0.4.5 (2026-03-09)

**No breaking changes.**

This release applies code formatting for consistency.

### Summary - v0.4.5

- Applied JuliaFormatter to entire codebase

### Migration - v0.4.5

**No action required.** All existing code continues to work without changes.

---

## v0.4.3-beta (2026-03-07)

**Breaking change:** Extension-based backend validation for ADNLP modelers.

### Summary - v0.4.3-beta

- Replaced fragile `isdefined(Main, :Enzyme)` checks with Julia's extension system
- ADNLP backend validation now uses proper extension mechanism with tag dispatch
- Missing extensions now throw `ExtensionError` instead of warnings
- New extensions `CTSolversEnzyme` and `CTSolversZygote` required for AD backends

### Breaking Changes - v0.4.3-beta

#### 1. Extension-based backend validation

**Before:** Backend validation used fragile runtime checks:

```julia
# Old approach (fragile)
if isdefined(Main, :Enzyme)
    # Use Enzyme backend
else
    @warn "Enzyme not loaded, using fallback"
end
```

**After:** Backend validation uses Julia's extension system:

```julia
# New approach (robust)
validate_adnlp_backend(Val(:enzyme))  # Throws ExtensionError if not loaded
```

#### 2. Required extensions for AD backends

**Before:** AD backends worked if modules were loaded in Main scope.

**After:** Explicit extensions must be loaded:

```julia
# For Enzyme backend
using CTSolversEnzyme

# For Zygote backend  
using CTSolversZygote
```

#### 3. ExtensionError instead of warnings

**Before:** Missing backends emitted warnings:

```julia
@warn "Enzyme not loaded, using fallback backend"
```

**After:** Missing extensions throw structured errors:

```julia
throw(CTBase.ExtensionError(
    "Enzyme extension not loaded",
    suggestion="using CTSolversEnzyme"
))
```

### Migration - v0.4.3-beta

**For ADNLP backend users:**

```julia
# Add explicit extension loading
# Before
using CTSolvers
adnlp = ADNLP{CPU}()

# After
using CTSolvers
using CTSolversEnzyme  # or CTSolversZygote
adnlp = ADNLP{CPU}(backend=:enzyme)  # now works reliably
```

**For custom ADNLP extensions:**

```julia
# Use the new extension pattern
module CTSolversMyBackend
using CTSolvers
import CTSolvers.Modelers: validate_adnlp_backend, ADNLPTag

function validate_adnlp_backend(::Val{:mybackend})
    # Your validation logic here
    return true
end
end
```

### Benefits

- **Robust detection**: Extension loading works regardless of module context
- **Type safety**: Proper dispatch using Julia's multiple dispatch
- **Clear errors**: Structured exceptions with actionable suggestions
- **Consistency**: Matches existing CUDA and solver extension patterns

---

## v0.4.0-beta (2026-03-04)

**Breaking change:** Strategy parameter contract enforcement and mandatory parameterization.

### Summary - v0.4.0-beta

- All strategies must now explicitly implement parameter contract methods
- Non-parameterized strategy construction is no longer allowed
- Fallback implementations have been removed and now throw `NotImplemented`
- Enhanced error messages with actionable implementation guidance

### Breaking Changes - v0.4.0-beta

#### 1. Mandatory strategy parameterization

**Before:** Strategies could be constructed without parameters.

```julia
# Old (no longer supported)
solver = Ipopt()
modeler = ADNLP()
```

**After:** All strategies must specify a parameter type.

```julia
# New (required parameterization)
solver = Ipopt{CPU}()
modeler = ADNLP{CPU}()
```

#### 2. Required contract implementation

**Before:** Strategies could rely on default fallback implementations.

**After:** Strategies must implement explicit parameter contract methods:

```julia
# Required for all strategy implementations
function Strategies._supported_parameters(::Type{<:MyStrategy})
    return (CPU,)  # or (CPU, GPU) depending on support
end

function Strategies._default_parameter(::Type{<:MyStrategy})
    return CPU  # or GPU depending on default
end
```

#### 3. Fallback methods removed

**Before:** Default implementations existed for `_supported_parameters` and `_default_parameter`.

**After:** These methods now throw `NotImplemented` with detailed error messages:

```julia
# Now throws: NotImplemented with required_method, suggestion, and context
Strategies._supported_parameters(MyStrategy)  # → NotImplemented
Strategies._default_parameter(MyStrategy)     # → NotImplemented
```

#### 4. Non-parameterized strategies rejected

**Before:** Parameterless strategy types were accepted.

**After:** Attempting to create non-parameterized strategies throws `IncorrectArgument`:

```julia
MyStrategy()  # → IncorrectArgument: "Strategy must be parameterized"
```

### Migration - v0.4.0-beta

**For existing strategy users:**

```julia
# Update all strategy instantiations
# Old
solver = Ipopt()
modeler = ADNLP()

# New
solver = Ipopt{CPU}()
modeler = ADNLP{CPU}()
```

**For custom strategy implementations:**

```julia
# Add these required methods to your strategy
struct MyStrategy{P<:AbstractStrategyParameter} <: AbstractStrategy
    options::StrategyOptions
end

# Required contract methods
function Strategies._supported_parameters(::Type{<:MyStrategy})
    return (CPU,)  # Specify which parameters you support
end

function Strategies._default_parameter(::Type{<:MyStrategy})
    return CPU  # Specify your default parameter
end
```

**For GPU-enabled strategies:**

```julia
# Support both CPU and GPU
function Strategies._supported_parameters(::Type{<:MyGPUStrategy})
    return (CPU, GPU)
end

function Strategies._default_parameter(::Type{<:MyGPUStrategy})
    return CPU  # Default to CPU for compatibility
end
```

### Benefits

- **Type safety**: Explicit parameter specification prevents runtime errors
- **Clear contracts**: Strategies must declare their parameter support upfront
- **Better error messages**: Detailed guidance for implementing contracts correctly
- **GPU support**: Clean separation between CPU and GPU execution paths
- **Extensibility**: Framework supports future parameter types beyond CPU/GPU

---

## v0.3.7-beta (2026-02-20)

**Breaking change:** Action option shadowing detection and `route_to` bypass behavior.

### Summary - v0.3.7-beta

- Action options that also exist in strategy families now trigger an `@info` warning
- `route_to(strategy=val)` correctly bypasses action option extraction
- Improved user guidance when action options shadow strategy options

### Breaking Changes - v0.3.7-beta

#### 1. Action option shadowing detection

**Before:** No warning when action options shadow strategy options.

**After:** An `@info` message is emitted when a user-provided action option also exists in a strategy family.

```julia
# Now emits: "Option `display` was intercepted as a global action option. 
# It is also available for the following strategy families: solver. 
# To pass it specifically to a strategy, use `route_to(display=...)`."
solve(ocp; display=false)
```

#### 2. Fixed `route_to` bypass for action options

**Before:** `route_to(strategy=val)` would fail with type error when the option was also defined as an action.

**After:** `route_to` correctly bypasses action extraction and reaches the strategy.

```julia
# Now works correctly - action gets default, strategy gets false
solve(ocp; display=route_to(solver=false))
```

### Migration Guide - v0.3.7-beta

#### No code changes required

These changes are **non-breaking** for existing code. They only add helpful warnings and fix a bug that previously prevented `route_to` from working with action-shadowed options.

#### Understanding the new behavior

```julia
# Action option that also exists in solver
solve(ocp; display=false)
# → Action gets false, solver gets default
# → @info warning emitted about shadowing

# Explicit routing to strategy
solve(ocp; display=route_to(solver=false))
# → Action gets default, solver gets false
# → No warning (user was explicit)
```

### Benefits

- **Better UX**: Users are warned when action options shadow strategy options
- **Fixed bug**: `route_to` now works correctly with action-shadowed options
- **Clear guidance**: Warning messages suggest `route_to` for explicit targeting

---

## v0.3.6-beta (2026-02-19)

**Breaking change:** The routing and validation system has been refactored to simplify responsibilities and introduce a new bypass mechanism.

### Summary - v0.3.6-beta

- `route_all_options()` no longer accepts a `mode` parameter
- `mode=:permissive` behavior is replaced by explicit `bypass(val)` wrapper
- New `BypassValue{T}` type and `bypass(val)` function for validation bypass
- Simplified separation of concerns: routing vs validation

### Breaking Changes - v0.3.6-beta

#### 1. Removed `mode` parameter from `route_all_options`

**Before:**
```julia
routed = Orchestration.route_all_options(
    method, families, action_defs, kwargs, registry;
    mode=:permissive  # or :strict
)
```

**After:**
```julia
routed = Orchestration.route_all_options(
    method, families, action_defs, kwargs, registry
)
```

#### 2. Replaced `mode=:permissive` with explicit bypass

**Before:**
```julia
# Accept unknown options with warning
strat = MySolver(unknown_opt=42; mode=:permissive)
```

**After:**
```julia
# Explicit bypass for unknown options
strat = MySolver(unknown_opt=Strategies.bypass(42))
```

#### 3. Updated `route_to` usage for unknown options

**Before:**
```julia
# Would fail even in permissive mode for unknown options
kwargs = (custom_opt = Strategies.route_to(my_solver=42),)
```

**After:**
```julia
# Explicit bypass for unknown options
kwargs = (custom_opt = Strategies.route_to(my_solver=Strategies.bypass(42)),)
```

### Migration Guide - v0.3.6-beta

#### Replace `mode=:permissive` usage

**For unknown options:**
```julia
# Old
MySolver(custom_opt=42; mode=:permissive)

# New
MySolver(custom_opt=Strategies.bypass(42))
```

**For routing unknown options:**
```julia
# Old
kwargs = (opt = Strategies.route_to(strategy=42),)
routed = Orchestration.route_all_options(...; mode=:permissive)

# New
kwargs = (opt = Strategies.route_to(strategy=Strategies.bypass(42)),)
routed = Orchestration.route_all_options(...)
```

#### Remove `mode` parameter from `route_all_options`

```julia
# Old
routed = Orchestration.route_all_options(
    method, families, action_defs, kwargs, registry;
    mode=:strict  # or :permissive
)

# New (no mode parameter)
routed = Orchestration.route_all_options(
    method, families, action_defs, kwargs, registry
)
```

#### Update error handling

`mode=:invalid_mode` now throws `MethodError` instead of `IncorrectArgument`:

```julia
# Old: Would throw IncorrectArgument
try
    Orchestration.route_all_options(...; mode=:invalid_mode)
catch e
    @test e isa Exceptions.IncorrectArgument
end

# New: Throws MethodError
try
    Orchestration.route_all_options(...; mode=:invalid_mode)
catch e
    @test e isa MethodError
end
```

### Benefits

- **Clearer API**: Explicit bypass makes intent obvious
- **Simpler architecture**: `route_all_options` only routes, `build_strategy_options` validates
- **Better error messages**: Unknown option errors now suggest `bypass()` usage
- **Type safety**: `BypassValue{T}` preserves type information through routing

---

## v0.3.3-beta (2026-02-16)

**Breaking change:** The base solver abstract type was renamed from
`AbstractOptimizationSolver` to `AbstractNLPSolver` for consistency with the
`AbstractNLPModeler` naming introduced in v0.3.0.

### Migration

Replace any references to the old abstract type:

```text
AbstractOptimizationSolver → AbstractNLPSolver
```

No other API changes are required.

---

## v0.3.2-beta (2026-02-15)

No breaking changes. This release focused on options getters/encapsulation
and documentation updates.

---

## v0.3.1-beta (2026-02-14)

No breaking changes.

---

## Breaking Changes — v0.3.0-beta

This document describes all breaking changes introduced in CTSolvers.jl v0.3.0-beta
and provides a migration guide for users upgrading from v0.2.x.

---

## Summary

All public types have been renamed to use shorter, module-qualified names.
This aligns with Julia conventions (`Module.Type`) and improves readability.

---

## Type Renaming

### Modelers

| v0.2.x                       | v0.3.0                 |
|------------------------------|------------------------|
| `ADNLPModeler`               | `Modelers.ADNLP`       |
| `ExaModeler`                 | `Modelers.Exa`         |
| `AbstractOptimizationModeler`| `AbstractNLPModeler`   |

### Solvers

| v0.2.x        | v0.3.0           |
|---------------|------------------|
| `IpoptSolver` | `Solvers.Ipopt`  |
| `MadNLPSolver`| `Solvers.MadNLP` |
| `MadNCLSolver`| `Solvers.MadNCL` |
| `KnitroSolver`| `Solvers.Knitro` |

### DOCP

| v0.2.x                             | v0.3.0             |
|------------------------------------|--------------------|
| `DiscretizedOptimalControlProblem` | `DiscretizedModel` |

---

## Migration Guide

### Search-and-replace

The simplest migration is a global search-and-replace in your codebase:

```text
ADNLPModeler                      →  Modelers.ADNLP
ExaModeler                        →  Modelers.Exa
AbstractOptimizationModeler       →  AbstractNLPModeler
IpoptSolver                       →  Solvers.Ipopt
MadNLPSolver                      →  Solvers.MadNLP
MadNCLSolver                      →  Solvers.MadNCL
KnitroSolver                      →  Solvers.Knitro
DiscretizedOptimalControlProblem  →  DiscretizedModel
```

### Code examples

**Before (v0.2.x):**

```julia
using CTSolvers

# Create modeler and solver
modeler = ADNLPModeler(backend=:sparse)
solver = IpoptSolver(max_iter=1000, tol=1e-6)

# Create DOCP
docp = DiscretizedOptimalControlProblem(ocp, builder)
```

**After (v0.3.0):**

```julia
using CTSolvers

# Create modeler and solver
modeler = Modelers.ADNLP(backend=:sparse)
solver = Solvers.Ipopt(max_iter=1000, tol=1e-6)

# Create DOCP
docp = DiscretizedModel(ocp, builder)
```

### Registry creation

**Before:**

```julia
registry = create_registry(
    AbstractOptimizationModeler => (ADNLPModeler, ExaModeler),
    AbstractNLPSolver => (IpoptSolver, MadNLPSolver)
)
```

**After:**

```julia
registry = create_registry(
    AbstractNLPModeler => (Modelers.ADNLP, Modelers.Exa),
    AbstractNLPSolver => (Solvers.Ipopt, Solvers.MadNLP)
)
```

---

## Other Changes

- **`src/Solvers/validation.jl`** has been removed. Validation is now handled
  entirely by the strategy framework (`Strategies.build_strategy_options`).
- **CTModels 0.9 compatibility** — this version requires CTModels v0.9.0-beta or later.
