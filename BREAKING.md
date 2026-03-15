# Breaking Changes

This document describes all breaking changes introduced in CTSolvers.jl releases
and provides migration guides for users upgrading between versions.

---

## v0.4.7-beta (2026-03-15)

**No breaking changes.**

This release adds a Core module and enhances display formatting for Strategies.

### Summary - v0.4.7-beta

- Added new `Core` module with exception handling and utilities
- Enhanced pretty printing for strategy options with structured output
- Improved module organization and exports across the codebase
- Enhanced strategy registry and contract metadata handling

### Migration - v0.4.7-beta

**No action required.** All existing code continues to work without changes.

**Improved behavior:** Strategy options now display with better formatting and organization.

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
