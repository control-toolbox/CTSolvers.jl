# Changelog
<!-- markdownlint-disable MD024 -->

All notable changes to CTSolvers.jl will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [0.4.14] - 2026-04-12

### Added

- **Positional syntax for route_to()** - New method `route_to(args::Vararg{Any})` accepting alternating Symbol-value pairs
  - Alternative to keyword syntax: `route_to(:solver, 100, :modeler, 50)` instead of `route_to(solver=100, modeler=50)`
  - Both syntaxes are equivalent and produce identical `RoutedOption` results
  - Validates even number of arguments and Symbol types for strategy identifiers
  - Clear error messages for invalid inputs (odd count, non-Symbol identifiers, no arguments)

### Changed

- **Internal refactoring** - Added `_route_to_from_namedtuple()` helper function to avoid code duplication
  - Both keyword and positional methods delegate to shared internal helper
  - Reduced code duplication while maintaining identical behavior
  - Improved maintainability and consistency

### Improved

- **Documentation** - Updated docstrings for both `route_to()` methods to show both syntaxes
  - Examples demonstrate keyword and positional syntax equivalence
  - Clear notes on when to use each syntax
  - Comprehensive error documentation with suggestions

- **Unknown option error messages** - Enhanced error messages when an option doesn't belong to any strategy in the current method
  - Searches the registry for strategies not in the current method that have the option
  - Suggests the user may have selected the wrong strategy if the option exists elsewhere
  - Lists all matching strategies with their IDs and family names
  - Example: "This option exists in other strategies: :madnlp (solver). Perhaps you selected the wrong strategy? Consider using a different method."

### Tests

- **Positional syntax test coverage** - Added 23 new tests covering:
  - Single and multiple strategy routing
  - Different value types (Integer, Float, String, Boolean, Symbol)
  - Error cases (no arguments, odd count, non-Symbol identifiers)
  - Syntax equivalence between keyword and positional forms

- **Registry search error messages** - Added 5 new tests for `_find_option_in_registry()`:
  - Option exists in other strategies
  - Option doesn't exist in registry
  - Option only in current method strategies
  - Option exists in multiple strategies across families
  - Method with different strategy selection

- **Integration test** - Added test verifying error message includes registry match suggestion

---

## [0.4.13] - 2026-04-07

### Changed

- **Strategy header display** - `describe()` now shows clean base type names without parameters in strategy headers
  - Strategy headers display as `ADNLP (strategy)` instead of `ADNLP{CPU} (strategy)`
  - Parameter information remains available in the "parameters" section below
  - Reduced redundancy while preserving complete information

- **Options display order** - Computed options now appear before common options in multi-parameter strategies
  - Computed options are displayed first for each parameter
  - Common options appear after all computed options
  - Improved information hierarchy with most dynamic content first

### Added

- **Base type name extraction** - New `_strategy_base_name()` function for clean type name extraction
  - `_strategy_base_name(T::DataType)` for concrete types
  - `_strategy_base_name(T::UnionAll)` for generic types  
  - `_strategy_base_name(T::Type)` as fallback
  - Used specifically for strategy headers to avoid parameter redundancy

### Improved

- **Visual hierarchy** - Better organization of multi-parameter strategy descriptions
  - Computed options prioritized for immediate visibility of parameter-specific behavior
  - Cleaner strategy headers with essential information first
  - Maintained complete parameter information in dedicated sections

---

## [Unreleased]

### Changed

- **Strategy type display** - `describe()` functions now show clean type names without module prefixes
  - Strategy types display as `Exa{CPU}` instead of `CTSolvers.Modelers.Exa{CTSolvers.Strategies.CPU}`
  - Preserves parameter information (e.g., `{CPU}`, `{GPU}`) while removing module clutter
  - Improved readability in `describe(:cpu, registry)` and `describe(:gpu, registry)` output

### Added

- **Multiple dispatch implementation** - Refactored `_strategy_type_name` with specialized methods
  - `_strategy_type_name(T::DataType)` for concrete instantiated types (most common case)
  - `_strategy_type_name(T::UnionAll)` for generic types not yet instantiated
  - `_strategy_type_name(T::Type)` as ultimate fallback for edge cases
  - Each method has comprehensive docstring with examples and cross-references

### Improved

- **Documentation standards** - Applied project docstring standards to all `_strategy_type_name` methods
  - Uses `$(TYPEDSIGNATURES)` for auto-generated signatures
  - Structured sections: Arguments, Returns, Examples, Notes, See also
  - Method-specific documentation explaining each dispatch case
  - Safe, reproducible examples following project guidelines

---

## [0.4.12] - 2026-03-31

### Changed

- Applied JuliaFormatter to `src/Strategies/api/describe_registry.jl` for consistency

## [0.4.11-beta] - 2026-03-29

### Changed

- **Strategy type display** - `describe()` functions now show clean type names without module prefixes
  - Strategy types display as `Exa{CPU}` instead of `CTSolvers.Modelers.Exa{CTSolvers.Strategies.CPU}`
  - Preserves parameter information (e.g., `{CPU}`, `{GPU}`) while removing module clutter
  - Improved readability in `describe(:cpu, registry)` and `describe(:gpu, registry)` output

### Added

- **Multiple dispatch implementation** - Refactored `_strategy_type_name` with specialized methods
  - `_strategy_type_name(T::DataType)` for concrete instantiated types (most common case)
  - `_strategy_type_name(T::UnionAll)` for generic types not yet instantiated
  - `_strategy_type_name(T::Type)` as ultimate fallback for edge cases
  - Each method has comprehensive docstring with examples and cross-references

### Improved

- **Documentation standards** - Applied project docstring standards to all `_strategy_type_name` methods
  - Uses `$(TYPEDSIGNATURES)` for auto-generated signatures
  - Structured sections: Arguments, Returns, Examples, Notes, See also
  - Method-specific documentation explaining each dispatch case
  - Safe, reproducible examples following project guidelines

---

## [0.4.10-beta] - 2026-03-17

### Changed

- **Forced ANSI colors** - `get_format_codes()` now always enables ANSI escape sequences for consistent display
  - Colors now appear in Documenter documentation (local and remote)
  - Improved `describe()`, `OptionDefinition`, `StrategyMetadata`, and `StrategyOptions` display
  - Removed color detection to ensure colors work in all contexts (terminal, docs, CI)

### Fixed

- **Missing colors in documentation** - Pretty-printed objects now display colors in generated HTML documentation
- **Inconsistent color display** - Colors are now consistent across all environments and contexts

## [0.4.8-beta] - 2026-03-16

### Added

- **Parameter description methods** - New `description` contract method for `AbstractStrategyParameter` with `NotImplemented` fallback
- **Parameter describe functions** - New `describe` methods for parameters (type-direct and registry-aware)
  - `describe(CPU)` and `describe(GPU)` show parameter ID, hierarchy, and description
  - `describe(:cpu, registry)` and `describe(:gpu, registry)` list strategies using each parameter
- **Enhanced hierarchy display** - All `describe` methods now show full hierarchy chain instead of just immediate supertype
  - Strategy hierarchy: `Type → Parent → AbstractStrategy`
  - Parameter hierarchy: `Type → AbstractStrategyParameter`
- **Parameter-strategy disambiguation** - Registry-aware `describe` handles both strategy and parameter IDs with clear error messages
- **Helper functions** - Added `_supertype_chain` for consistent hierarchy display across all describe methods
- **Comprehensive testing** - Added 23 tests for parameter describe functionality following `.windsurf` standards
- **New exports** - Export `description` function for parameters

### Improved

- **Strategy describe consistency** - Both type-direct and registry-aware `describe` now show full hierarchy chains
- **Error messages** - Enhanced `IncorrectArgument` errors with clear disambiguation between strategy and parameter IDs
- **Visual formatting** - Consistent tree-like display with proper hierarchy arrows across all describe methods

### Fixed

- **Missing hierarchy in registry-aware describe** - Fixed missing hierarchy display in `describe(id, registry)` for strategies

## [0.4.7-beta] - 2026-03-15

### Added

- **Core module** - New `Core` module with exception handling and utilities
- **Registry-aware describe function** - New `describe(id::Symbol, registry::StrategyRegistry)` for comprehensive strategy introspection
  - Display strategy family, parameters, and default parameter
  - Group options into common vs computed categories
  - Show computed option values per parameter with visual separation
  - Handle `ExtensionError` gracefully with red display and extension names
  - Support for both single and multi-parameter strategies
- **Enhanced StrategyRegistry display** - Improved formatting without duplicate strategy IDs
  - Group strategies by ID with parameterized variants
  - Show full type names with parameters in tree structure
  - Clear visual hierarchy with proper indentation
- **Display formatting for Strategies** - Enhanced pretty printing for strategy options with structured output
- **Strategy display improvements** - Better formatting and organization of strategy option displays
- **Comprehensive test suite** - Added 53 tests covering all describe functionality scenarios

### Changed

- **Module organization** - Restructured module exports and includes across the codebase
- **Strategy registry** - Enhanced strategy registry and contract metadata handling
- **Display formatting** - Improved display formatting for strategy options and metadata
- **Extension error display** - Missing extensions now shown in red with exact extension names
- **Visual formatting** - Added vertical separators between parameters and options sections

---

## [0.4.6] - 2026-03-10

### Fixed

- **Option validator MethodError** - Fixed bug where passing wrong type to option validators (e.g., `ADNLP(backend=CUDABackend())`) threw cryptic `MethodError` instead of clear `IncorrectArgument`
  - Type check now runs before validator call in option extraction
  - Validators provide helpful error messages suggesting correct types
  - Added explicit type validation in `get_validate_adnlp_backend`
  - Removed dead code from typed validators
  - Added comprehensive tests for wrong-type inputs

---

## [0.4.5] - 2026-03-09

### Changed

- **Code formatting** - Applied JuliaFormatter to entire codebase for consistency

---

## [0.4.4] - 2026-03-08

### Added

- **DocumenterMermaid compatibility** - Added support for Mermaid diagrams in documentation

### Changed

- **Documentation updates** - Improved compatibility with latest Documenter.jl features

## [0.4.3-beta] - 2026-03-07

### Added

- **Computed option source support** - New `ComputedSource` type for dynamic option computation
- **MadNLP and MadNCL extensions** - New solver extensions for enhanced MadNLP/MadNCL support
- **Force alias for bypass** - Added `force` as an alias for `bypass` function for more intuitive naming

### Changed

- **Option handling improvements** - Enhanced extraction and validation for computed sources
- **Routing function refactoring** - Extracted 8 private helper functions for improved SRP
- **Strategy constructor standardization** - Standardized solver constructor pattern across all solvers
- **Extension-based backend validation** - Robust extension system for ADNLP backend validation using Julia's extension mechanism

### Fixed

- **Backend validation robustness** - Replaced fragile `isdefined(Main, :Enzyme)` checks with proper extension system
- **Code duplication** - Eliminated duplication in ADNLP and Exa constructors
- **Dispatch patterns** - Replaced if statements with proper dispatch on default types

### Tests

- **Comprehensive export tests** - Added 635 export tests covering all public API symbols across 7 modules
- **Computed source tests** - Complete test coverage for new computed source functionality
- **Extension validation tests** - 4-test strategy covering all extension scenarios

## [0.4.2-beta] - 2026-03-06

### Added

- **Comprehensive export tests** - Added complete export verification for all modules (635 tests total)
- **Internal function verification** - Tests to ensure private symbols stay private

### Changed

- **Test organization** - Consolidated and improved export testing patterns across all modules

## [0.4.1-beta] - 2026-03-05

### Added

- **GPU support for Max1MinusX2** - Enabled GPU tests for maximization problems
- **Shared suite functions** - Simplified MadNLP/MadNCL architecture with shared test functions
- **Dispatch-based validation** - Implemented Exa GPU consistency checks with method dispatch

### Changed

- **Architecture simplification** - Refactored MadNLP/MadNCL consistency checks with dispatch-based validation
- **Test references** - Fixed test references to use shared suite functions

## [0.4.0-beta] - 2026-03-04

### Breaking Changes

- **Strategy parameter contract enforcement** - All strategies must now explicitly implement `_supported_parameters` and `_default_parameter` methods
- **Non-parameterized strategies disallowed** - Attempting to create non-parameterized strategies now throws `IncorrectArgument`
- **Fallback methods removed** - Default implementations of `_supported_parameters` and `_default_parameter` now throw `NotImplemented`

### Added

- **Strategy parameter contract system** - Complete framework for CPU/GPU specialization of strategies
- **Comprehensive parameter validation** - Automatic validation with detailed error messages
- **New parameter types** - `CPU` and `GPU` parameter types for execution backend specification
- **Full API documentation** - Complete docstrings for all parameter-related functions
- **Comprehensive test suite** - 3078 tests passing with full contract enforcement coverage
- **Strategy parameters guide** - Complete documentation for the new parameter system

### Changed

- **Strategy construction** - All strategies now require parameter specification (e.g., `Ipopt{CPU}()`)
- **Error messages** - Enhanced error messages with actionable suggestions for contract implementation
- **Extension stubs** - Added parameter validation before `ExtensionError` in all solver stubs
- **CUDA backend access** - Fixed Exa modeler to use `CUDA.CUDABackend()` instead of `KernelAbstractions.CUDABackend()`

### Migration

**For strategy construction:**

```julia
# Old (no longer supported)
solver = Ipopt()

# New (parameterized)
solver = Ipopt{CPU}()
```

**For strategy implementations:**

```julia
# Must now implement these methods
function Strategies._supported_parameters(::Type{<:MyStrategy})
    return (CPU,)  # or (CPU, GPU)
end

function Strategies._default_parameter(::Type{<:MyStrategy})
    return CPU  # or GPU
end
```

**For non-parameterized strategies:**

```julia
# Old: Could create parameterless strategies
# New: Must use parameter type
MyStrategy()  # → throws IncorrectArgument
MyStrategy{CPU}()  # → correct usage
```

### Benefits

- **Type safety** - Explicit parameter specification prevents runtime errors
- **Clear contracts** - Strategies must declare their parameter support
- **Better error messages** - Detailed guidance for implementing contracts
- **GPU support** - Clean separation between CPU and GPU execution paths
- **Extensibility** - Framework supports future parameter types beyond CPU/GPU

---

## [0.3.7-beta] - 2026-02-20

### Added

- **Action option shadowing detection** - `@info` warning emitted when user-provided action options also exist in strategy families
- **Fixed `route_to` bypass** - `route_to(strategy=val)` now correctly bypasses action option extraction
- **Enhanced user guidance** - Warning messages suggest using `route_to` for explicit strategy targeting
- **Comprehensive test coverage** - 3 new tests in `test_routing.jl` covering shadowing detection and bypass behavior

### Fixed

- **Route extraction bug** - `RoutedOption` values are now excluded from action extraction and re-integrated for strategy routing
- **Type error in route_to** - Fixed `IncorrectArgument` when using `route_to` with action-shadowed options

### Changed

- **Improved UX** - Users are now informed when action options shadow strategy options with clear suggestions
- **Better error messages** - Shadowing warnings include affected strategy families and `route_to` usage examples

### Migration

No code changes required - these improvements are **non-breaking** and only add helpful warnings while fixing a bug.

**New behavior examples:**
```julia
# Action option that also exists in solver
solve(ocp; display=false)
# → Action gets false, solver gets default
# → @info warning: "Option `display` was intercepted as a global action option..."

# Explicit routing to strategy (now works correctly)
solve(ocp; display=route_to(solver=false))
# → Action gets default, solver gets false
# → No warning (user was explicit)
```

### Benefits

- **Better developer experience** - Clear warnings prevent silent shadowing surprises
- **Fixed functionality** - `route_to` now works correctly with action-shadowed options
- **Explicit intent** - Users can clearly distinguish between action and strategy targeting

---

## [0.3.6-beta] - 2026-02-19

### Breaking Changes

- **Removed `mode` parameter** from `Orchestration.route_all_options()` - routing function now focuses solely on routing without validation
- **Replaced `mode=:permissive`** with explicit `bypass(val)` wrapper for validation bypass
- **Updated error handling** - invalid mode parameters now throw `MethodError` instead of `IncorrectArgument`

### Added

- **New bypass mechanism** - `Strategies.BypassValue{T}` type and `bypass(val)` function for explicit validation bypass
- **Enhanced error messages** - Unknown option errors now suggest using `bypass()` for confident users
- **Simplified architecture** - Clear separation: `route_all_options` routes, `build_strategy_options` validates
- **Comprehensive test coverage** - 27 new tests in `test_bypass.jl` covering all bypass scenarios
- **Type safety improvements** - `BypassValue{T}` preserves type information through routing pipeline

### Changed

- **API simplification** - Removed complexity from routing layer, moved validation logic to strategy construction
- **Error messages** - More helpful suggestions for unknown options with bypass examples
- **Test updates** - All existing tests adapted to new bypass API, maintaining backward compatibility for `mode=:permissive`

### Migration

**For unknown options:**
```julia
# Old
MySolver(unknown_opt=42; mode=:permissive)

# New
MySolver(unknown_opt=Strategies.bypass(42))
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

**Remove mode parameter:**
```julia
# Old
routed = Orchestration.route_all_options(
    method, families, action_defs, kwargs, registry;
    mode=:strict  # or :permissive
)

# New
routed = Orchestration.route_all_options(
    method, families, action_defs, kwargs, registry
)
```

### Benefits

- **Clearer intent** - Explicit `bypass(val)` makes validation bypass obvious
- **Better separation** - Routing and validation concerns are properly separated
- **Type preservation** - `BypassValue{T}` maintains type information through the pipeline
- **Improved UX** - Better error messages guide users to appropriate solutions

---

## [0.3.5-beta] - 2026-02-18

### Added

- **Build solution contract tests** — Comprehensive test suite verifying compatibility between solver extensions and CTModels' `build_solution` function
- **SolverInfos construction verification** — Tests ensuring extracted solver data can construct `SolverInfos` objects correctly
- **Generic extract_solver_infos tests** — New test file with `MockStats` for testing generic solver interface
- **Contract safety verification** — Type checking and structure validation for all 6 return values from `extract_solver_infos`
- **Integration tests** — End-to-end verification of MadNLP, MadNCL, and generic solver extensions

### Changed

- **Test coverage** — Increased from 488 to 548 tests (+60 new tests)
- **Extension test structure** — Enhanced MadNLP and MadNCL test files with complete contract verification
- **Testing standards compliance** — All mock structs properly defined at module level

### Fixed

- **Contract compliance** — Verified that `extract_solver_infos` returns correct types expected by `build_solution`:
  - `objective::Float64`
  - `iterations::Int`
  - `constraints_violation::Float64`
  - `message::String`
  - `status::Symbol`
  - `successful::Bool`

---

## [0.3.3-beta] - 2026-02-16

### Changed

- **Solver abstract type rename** — `AbstractOptimizationSolver` was renamed to
  `AbstractNLPSolver` for consistency with `AbstractNLPModeler` naming
- **Docs maintenance** — Updated references to the new abstract solver type
  across orchestration/routing examples and solver documentation

### Fixed

- **Test alignment** — Tests updated to use `AbstractNLPSolver`, keeping
  inheritance and contract checks consistent with the new naming

---

## [0.3.2-beta] - 2026-02-15

### Added

- **Options getters** — New getters/exported helpers for `StrategyOptions`

### Changed

- **Encapsulation** — Internal access to strategy options now goes through
  `_raw_options`/getter helpers; docs updated accordingly
- **Docs** — Options system guide expanded and translated to English sections

### Fixed

- **Test refactor** — Tests updated to use the new getters and encapsulation
  pattern

---

## [0.3.1-beta] - 2026-02-14

### Added

- **Backend override flexibility** — `Modelers.ADNLP` now accepts both `Type{<:ADBackend}` and `ADBackend` instances for advanced backend options
- **Comprehensive test coverage** for backend override validation with `nothing`, types, and instances
- **Detailed documentation** with examples for all three backend override patterns
- **Technical report** documenting the backend override implementation (`.reports/2026-02_14_backend/`)

### Changed

- **Backend option types** — Updated type declarations for all 7 active backend options:
  - `gradient_backend`, `hprod_backend`, `jprod_backend`, `jtprod_backend`
  - `jacobian_backend`, `hessian_backend`, `ghjvprod_backend`
  - From: `Union{Nothing, ADNLPModels.ADBackend}`
  - To: `Union{Nothing, Type{<:ADNLPModels.ADBackend}, ADNLPModels.ADBackend}`
- **Solver abstract type rename** — `AbstractOptimizationSolver` was renamed to
  `AbstractNLPSolver` for consistency with `AbstractNLPModeler` naming
- **Validation logic** — `validate_backend_override()` now correctly handles three forms:
  - `nothing` (use default)
  - `Type{<:ADBackend}` (constructed by ADNLPModels)
  - `ADBackend` instance (used directly)
- **Test imports** — Refactored to use `import` instead of `using` in test modules for better namespace control
- **Coverage tracking** — Removed coverage directory from version control (added to `.gitignore`)

### Fixed

- **Test compatibility** — Fixed `@testset` macro calls after import refactoring
- **Validation tests** — Updated tests to use proper `ADBackend` subtypes instead of generic types
- **Error messages** — Enhanced backend override validation with clear error messages and suggestions

### Technical Details

#### Backend Override Usage

```julia
# Three accepted forms:
Modelers.ADNLP(gradient_backend=nothing)                              # Use default
Modelers.ADNLP(gradient_backend=ADNLPModels.ForwardDiffADGradient)   # Type
Modelers.ADNLP(gradient_backend=ADNLPModels.ForwardDiffADGradient())  # Instance
```

#### Type Declaration Change

```julia
# Before
type=Union{Nothing, ADNLPModels.ADBackend}

# After  
type=Union{Nothing, Type{<:ADNLPModels.ADBackend}, ADNLPModels.ADBackend}
```

---

## [0.3.0-beta] - 2026-02-13

### 🎉 BREAKING CHANGES

See [BREAKING.md](BREAKING.md) for a detailed migration guide.

- **Type renaming** — all public types have been renamed for consistency and clarity:
  - `ADNLPModeler` → `Modelers.ADNLP`
  - `ExaModeler` → `Modelers.Exa`
  - `AbstractOptimizationModeler` → `AbstractNLPModeler`
  - `IpoptSolver` → `Solvers.Ipopt`
  - `MadNLPSolver` → `Solvers.MadNLP`
  - `MadNCLSolver` → `Solvers.MadNCL`
  - `KnitroSolver` → `Solvers.Knitro`
  - `DiscretizedOptimalControlProblem` → `DiscretizedModel`
- **File renaming** — source files renamed to match new type names:
  - `adnlp_modeler.jl` → `adnlp.jl`
  - `exa_modeler.jl` → `exa.jl`
  - `ipopt_solver.jl` → `ipopt.jl`
  - `madnlp_solver.jl` → `madnlp.jl`
  - `madncl_solver.jl` → `madncl.jl`
  - `knitro_solver.jl` → `knitro.jl`
- **Removed** `src/Solvers/validation.jl` (validation now handled by strategy framework)
- **CTModels 0.9 compatibility** — upgraded to match CTModels 0.9-beta API

### Changed

- **Test output** cleaned up: suppressed noisy stdout/stderr from strategy display, validation errors, and GPU skip messages
- **CUDA status** now reported once in `runtests.jl` instead of per-extension file
- **Spell check** configured with custom `_typos.toml` for intentional typos in test examples
- **Test imports** refactored to use local `TestProblems` module instead of `Main.TestProblems`

### Fixed

- **Extension stub error messages** updated to match renamed types
- **Import references** fixed across all test files for renamed modules and types
- **Namespace pollution** reduced by using `import` instead of `using` in test modules

---

## [0.2.4-beta] - 2026-02-11

### Added

- **GPU support** for MadNLP and MadNCL extensions with proper MadNLPGPU integration
- **CUDA availability checks** with informative status messages in test suites
- **GPU test scenarios** including solve via CommonSolve, direct solve functions, and initial guess tests

### Changed

- **Import strategy** refactored across all modules to avoid namespace pollution
  - External packages now use `import` instead of `using`
  - Internal CTSolvers modules use `using` for API access
- **GPU test implementation** completely rewritten from placeholder to functional tests
- **Code organization** improved with clear separation between external and internal dependencies

### Fixed

- **Missing TYPEDFIELDS import** in Solvers module that caused precompilation errors
- **Dead GPU test code** removed (commented MadNLPGPU imports, undefined linear_solver_gpu)
- **Namespace pollution** reduced by using qualified imports for external packages

### Technical Details

#### Import Refactoring

```julia
# Before
using DocStringExtensions
using NLPModels

# After  
import DocStringExtensions: TYPEDEF, TYPEDSIGNATURES, TYPEDFIELDS
import NLPModels
```

#### GPU Test Implementation

```julia
# Before (dead code)
# using MadNLPGPU
# linear_solver_gpu = MadNLPGPU.CUDSSSolver

# After (functional)
import MadNLPGPU
gpu_solver = Solvers.MadNLP(linear_solver=MadNLPGPU.CUDSSSolver)
```

#### CUDA Availability Helper

```julia
is_cuda_on() = CUDA.functional()
if is_cuda_on()
    println("✓ CUDA functional, GPU tests enabled")
else
    println("⚠️  CUDA not functional, GPU tests will be skipped")
end
```

### Testing

- **MadNLP extension**: 177/177 tests pass (GPU tests skipped gracefully without CUDA)
- **MadNCL extension**: 82/82 tests pass (GPU tests skipped gracefully without CUDA)
- **GPU test coverage**: 3 test scenarios per extension (solve, direct solve, initial guess)

---

## [0.2.3-beta] - 2026-02-11

### Added

- Performance benchmarks for validation modes
- Comprehensive documentation for options validation
- Migration guide for new validation system
- Examples and tutorials for strict/permissive modes

### Changed

- Improved error messages with better suggestions
- Enhanced documentation with Mermaid diagrams
- Updated examples to use new `route_to()` syntax

---

## [0.2.1-beta.1] - 2026-02-10

### Added

- **`:manual` backend** support for ADNLP modelers validation
- **GitHub Actions workflows** for Coverage and Documentation with CT registry integration

### Changed

- **Version bump** to 0.2.1-beta.1
- **Coverage workflow** now uses CT registry with codecov token integration
- **Documentation workflow** now uses CT registry for improved build process

### Fixed

- **Repository cleanup** removed temporary and IDE files from version control
- **.gitignore** updated to exclude `.reports/`, `.resources/`, `.windsurf/`, `.vscode/` directories

---

## [0.2.0] - 2026-02-06

### 🎉 BREAKING CHANGES

### Added

- **New option validation system** with strict and permissive modes
- **`mode::Symbol` parameter** to strategy constructors (`:strict` default, `:permissive`)
- **`route_to()` helper function** for option disambiguation
- **`RoutedOption` type** for type-safe option routing
- **Enhanced error messages** with Levenshtein distance suggestions
- **Comprehensive test suite** with 66 tests covering all scenarios

### Changed

- **`build_strategy_options()`** now supports `mode` parameter
- **`route_all_options()`** now supports `mode` parameter
- **Error handling** uses CTBase `Exceptions.IncorrectArgument` and `Exceptions.PreconditionError`
- **Warning system** for unknown options in permissive mode
- **Documentation** completely updated with examples and tutorials

### Deprecated

- **Tuple syntax for disambiguation** (still supported but deprecated)
  - Old: `max_iter = (1000, :solver)`
  - New: `max_iter = route_to(solver=1000)`

### Fixed

- **Option validation** now provides helpful error messages
- **Disambiguation** works clearly with `route_to()`
- **Type safety** improved with `RoutedOption` type
- **Memory usage** optimized for validation system

### Security

- **Strict mode by default** prevents unknown option errors
- **Input validation** enhanced with type checking
- **Error messages** don't leak sensitive information

### Performance

- **Minimal overhead**: < 1% for strict mode, < 5% for permissive mode
- **Type stability** maintained throughout validation system
- **Memory efficiency** optimized for large option sets

### Documentation

- **Complete user guide** with examples and best practices
- **Migration guide** for existing code
- **API reference** with detailed examples
- **Performance benchmarks** and analysis
- **Troubleshooting guide** and FAQ

---

## [0.1.0] - 2025-XX-XX

### Added

- Initial release of CTSolvers.jl
- Basic strategy construction and management
- Option handling and validation
- Strategy registry and metadata system
- Integration with NLPModels and solvers

### Features

- Strategy builders and constructors
- Option extraction and validation
- Strategy registry with metadata
- Basic error handling and messaging
- Integration with popular solvers (Ipopt, MadNLP, Knitro)

---

## Migration Guide for v0.2.0

### For Users

**No action required for most users!** The default strict mode maintains existing behavior.

### For Advanced Users

If you need backend-specific options:

```julia
# Before (would error)
solver = Solvers.Ipopt(custom_option="value")

# After (works with warning)
solver = Solvers.Ipopt(
    custom_option="value";
    mode=:permissive
)
```

### For Disambiguation

If you encounter "ambiguous option" errors:

```julia
# Before (ambiguous)
solve(ocp, method; max_iter=1000)

# After (clear routing)
solve(ocp, method; 
    max_iter = route_to(solver=1000)
)
```

### For Developers

- Use `Exceptions.IncorrectArgument` for validation errors
- Use `Exceptions.PreconditionError` for precondition violations
- Use `route_to()` for option disambiguation
- Support both `:strict` and `:permissive` modes

---

## Technical Details

### New Types

```julia
struct RoutedOption
    routes::Vector{Pair{Symbol, Any}}
end
```

### New Functions

```julia
route_to(; kwargs...) -> RoutedOption
route_to(strategy=value) -> RoutedOption
route_to(strategy1=value1, strategy2=value2, ...) -> RoutedOption
```

### New Parameters

```julia
build_strategy_options(strategy_type; mode::Symbol=:strict, kwargs...)
route_all_options(method, families, action_defs, kwargs, registry; mode::Symbol=:strict)
```

### Enhanced Error Messages

```julia
ERROR: Unknown options provided for Solvers.Ipopt
Unrecognized options: [:max_itter]
Available options: [:max_iter, :tol, :print_level, ...]
Suggestions for :max_itter:
  - :max_iter (Levenshtein distance: 2)
If you are certain these options exist for the backend,
use permissive mode:
  Solvers.Ipopt(...; mode=:permissive)
```

---

## Performance Impact

| Operation | Before | After (Strict) | After (Permissive) | Overhead |
| ----------- | -------- | ---------------- | -------------------- | ---------- |
| Strategy construction | 100μs | 101μs | 105μs | < 1% / < 5% |
| Option validation | 50μs | 50μs | 52μs | 0% / < 4% |
| Disambiguation | N/A | 1μs | 1μs | < 1% |

---

## Testing

- **66 new tests** covering all validation scenarios
- **100% test coverage** for new functionality
- **Performance benchmarks** ensuring < 1% overhead
- **Integration tests** with real solvers
- **Error handling tests** for all edge cases

---

## Support

- **Documentation**: `docs/src/options_validation.md`
- **Examples**: `examples/options_validation_examples.jl`
- **Migration Guide**: `docs/src/migration_guide.md`
- **API Reference**: `?CTSolvers.Strategies.route_to`
- **Tests**: `test/suite/strategies/test_validation_*.jl`

---

## Contributors

- **@cascade-ai** - Implementation and documentation
- **@control-toolbox** - Design and review

---

## Questions?

- **GitHub Issues**: <https://github.com/control-toolbox/CTSolvers.jl/issues>
- **Discord**: <https://discord.gg/control-toolbox>
- **Documentation**: <https://control-toolbox.github.io/CTSolvers.jl/>
