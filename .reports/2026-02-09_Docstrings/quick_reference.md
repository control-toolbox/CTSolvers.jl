# Quick Reference - Documentation Standards

## Core Principles

1. **Accuracy** over marketing
2. **Clarity** over verbosity  
3. **Examples** when valuable, not mandatory
4. **Consistency** in terminology and style

## Required Docstring Structure

### Functions
```julia
"""
$(TYPEDSIGNATURES)

One-sentence purpose.

Detailed explanation (if needed).

# Arguments
- `arg::Type`: Description

# Returns
- `ReturnType`: Description

# Throws
- `ExceptionType`: When/why

# Example
\`\`\`julia-repl
julia> using CTSolvers.ModuleName

julia> result = func(arg)
output
\`\`\`

See also: [`related_func`](@ref)
"""
function func(arg::Type)
    # implementation
end
```

### Types (Structs)
```julia
"""
$(TYPEDEF)

One-sentence description.

# Fields
- `field::Type`: Description

# Example
\`\`\`julia-repl
julia> obj = TypeName(value)
TypeName(...)
\`\`\`

See also: [`RelatedType`](@ref)
"""
struct TypeName
    field::Type
end
```

### Abstract Types
```julia
"""
$(TYPEDEF)

One-sentence description of abstraction.

# Interface Requirements

Subtypes must implement:
- `required_method(::SubType)`: Description

# Available API

After implementation, subtypes get:
- `derived_method(::SubType)`: Description

# Example
\`\`\`julia-repl
julia> MyType <: AbstractTypeName
true
\`\`\`

See also: [`ConcreteType`](@ref)
"""
abstract type AbstractTypeName end
```

## Safe Example Policy

### ✅ Safe (runnable)
- Pure computations
- Constructors with valid inputs
- Queries on created objects
- Deterministic results

### ❌ Unsafe (avoid or use plain code blocks)
- File I/O
- Network requests
- Database operations
- Non-deterministic behavior
- Long computations (>1s)
- External state dependencies

## Module Prefix Convention

- **Exported**: Use directly (`function_name()`)
- **Internal**: Use prefix (`ModuleName.internal_func()`)

## Cross-References

- Functions/types: `` [`name`](@ref) ``
- External packages: `[PackageName.jl](url)`

## What to Avoid

- ❌ "Fast", "optimized", "efficient" (unless benchmarked)
- ❌ "Flexible", "powerful" (marketing language)
- ❌ Examples for trivial getters
- ❌ Invented features not yet implemented
- ❌ Verbose descriptions of obvious behavior

## Quality Checklist

- [ ] Directly above declaration
- [ ] Uses `$(TYPEDSIGNATURES)` or `$(TYPEDEF)`
- [ ] Clear one-sentence summary
- [ ] Arguments/fields documented
- [ ] Exceptions documented
- [ ] Example adds value (if included)
- [ ] Cross-references present
- [ ] No code changes
- [ ] Consistent terminology
