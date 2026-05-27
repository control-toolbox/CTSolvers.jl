# Terminology and Naming Conventions

## Core Concepts

### Strategy
A component in the CTSolvers framework that can be configured and registered.
- **Types**: Modeler, Solver, Builder
- **Base type**: AbstractStrategy
- **Requires**: `id()`, `metadata()`, `options()`

### StrategyMetadata
Schema defining available options for a strategy type.
- Contains: OptionDefinition specs
- Provides: Iteration interface (keys, values, pairs)
- **Do not access**: `.specs` field directly

### StrategyOptions
Validated option values for a strategy instance.
- Contains: OptionValue wrappers with source tracking
- Provides: Iteration interface (returns unwrapped values)
- **Do not access**: `.options` field directly

### OptionDefinition
Schema for a single option.
- Fields: name, type, default, description, aliases, validator
- Created by: `@option` macro or constructor

### OptionValue
Wrapper combining value + source tracking.
- Fields: value (Any), source (:user/:default/:computed)
- Purpose: Track option provenance

### RoutedOption
Disambiguated option for multiple strategies.
- Created by: `route_to(strategy1=val1, strategy2=val2)`
- Provides: Iteration interface over routes

## Naming Patterns

### Functions
- **Getters**: `option_value()`, `option_source()`, `option_type()`
- **Queries**: `has_option()`, `is_user()`, `is_default()`
- **Extraction**: `extract_option()`, `extract_options()`, `extract_raw_options()`
- **Validation**: `validate_strategy()`, `validate_modeler()`
- **Building**: `build_strategy_options()`, `build_docp()`
- **Registration**: `register_strategy!()`, `register_modeler!()`

### Types
- **Abstract**: Prefix with `Abstract` (AbstractStrategy, AbstractModeler)
- **Concrete**: Descriptive name + purpose (ADNLPModeler, IpoptSolver)
- **Info/Result**: Suffix with `Info` or `Result` (SolverInfo)

### Modules
- **PascalCase**: CTSolvers, Strategies, Options, Modelers, Solvers
- **Submodules**: Match parent (Strategies.api, Strategies.contract)

## Consistent Terminology

### Prefer
- **option** (not "parameter", "setting")
- **strategy** (not "component", "module" in this context)
- **validation mode** (`:strict` or `:permissive`)
- **source** (`:user`, `:default`, `:computed`)
- **route** (for RoutedOption targeting)
- **extract** (for option processing)
- **build** (for construction with validation)

### Avoid
- "config" / "configuration" (use "options" or "StrategyOptions")
- "spec" (internal field, use "metadata" or "definition")
- "param" (use "option" or "argument")

## Validation Modes

- **`:strict`** - All unknown options rejected
- **`:permissive`** - Unknown options generate warnings but proceed
- Default: `:strict` for safety

## Source Tracking Values

- **`:user`** - Explicitly provided by user
- **`:default`** - From OptionDefinition default
- **`:computed`** - Derived/calculated value

## Module Prefixes in Examples

### Exported Symbols
```julia
# ✅ Correct (no prefix)
modeler = ADNLPModeler(backend=:default)
```

### Internal Symbols
```julia
# ✅ Correct (with prefix)
meta = Strategies.metadata(MyStrategy)
defs = Options.extract_options(kwargs, defs)
```

## File Organization Conventions

### Modules
- `ModuleName/ModuleName.jl` - Module definition and exports
- `ModuleName/api/` - Public API implementations
- `ModuleName/contract/` - Abstract types and contracts
- `ModuleName/types.jl` - Type definitions

### Extensions
- `ext/CTSolvers[Package].jl` - Extension for external package

## Documentation Sections Order

For functions:
1. Signature (`$(TYPEDSIGNATURES)`)
2. One-sentence purpose
3. Detailed description
4. `# Arguments`
5. `# Returns`
6. `# Throws`
7. `# Example` or `# Examples`
8. `# Notes`
9. `See also:`

For types:
1. Type definition (`$(TYPEDEF)`)
2. One-sentence purpose
3. Detailed description
4. `# Fields`
5. `# Constructor Validation` (if applicable)
6. `# Interface Requirements` (for abstract types)
7. `# Available API` (for abstract types)
8. `# Example`
9. `# Notes`
10. `See also:`

## Cross-Reference Patterns

Within CTSolvers:
```markdown
See also: [`function_name`](@ref), [`TypeName`](@ref)
```

External packages:
```markdown
See also: [ADNLPModels.jl](https://github.com/JuliaSmoothOptimizers/ADNLPModels.jl)
```

Same file:
```markdown
See also: [`Options.extract_option`](@ref) for single option extraction.
```

## Common Docstring Mistakes to Avoid

1. ❌ Using `.specs` or `.options` in examples
2. ❌ Claiming "fast" without benchmarks
3. ❌ Examples with file I/O or network
4. ❌ Conflating arguments and options
5. ❌ Missing exception documentation
6. ❌ Invented features not yet implemented
7. ❌ Inconsistent module prefixes
8. ❌ Missing `$(TYPEDSIGNATURES)` or `$(TYPEDEF)`
