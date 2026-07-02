# Error Messages Reference

```@meta
CurrentModule = CTSolvers
```

This page catalogues all exception types used in CTSolvers, with live examples and recommended fixes. CTSolvers uses enriched exceptions from `CTBase.Exceptions` that carry structured fields (`got`, `expected`, `suggestion`, `context`) for actionable error messages.

## Exception Types

CTSolvers uses three exception types from `CTBase.Exceptions`:

| Type | Purpose |
|------|---------|
| `NotImplemented` | Contract method not implemented by a concrete type |
| `IncorrectArgument` | Invalid argument value, type, or routing |
| `ExtensionError` | Required package extension not loaded |

All three accept keyword arguments for structured messages:

```@example errors
using CTSolvers
using CTBase: CTBase
const Exceptions = CTBase.Exceptions
nothing # hide
```

## NotImplemented — Contract Not Implemented

Thrown when a concrete type doesn't implement a required contract method.

### Strategy contract — missing `id`

```@example errors
abstract type IncompleteStrategy <: CTBase.Strategies.AbstractStrategy end
nothing # hide
```

```@repl errors
try # hide
CTBase.Strategies.id(IncompleteStrategy)
catch e # hide
showerror(IOContext(stdout, :color => false), e) # hide
end # hide
```

**Fix**: Implement the missing method:

```julia
CTBase.Strategies.id(::Type{<:IncompleteStrategy}) = :my_strategy
```

### Strategy contract — missing `metadata`

```@repl errors
try # hide
CTBase.Strategies.metadata(IncompleteStrategy)
catch e # hide
showerror(IOContext(stdout, :color => false), e) # hide
end # hide
```

### Optimization problem contract — missing build_model

Define a problem type and a modeler, but no `(problem, modeler)` method. A dedicated block
label (`optprob`) keeps these throwaway types out of the shared `errors` scope:

```@example optprob
using CTSolvers
struct MinimalProblem <: CTSolvers.Optimization.AbstractOptimizationProblem end
struct MinimalModeler <: CTSolvers.Modelers.AbstractNLPModeler end
nothing # hide
```

The generic stub in `Modelers/contract.jl` throws `NotImplemented` as soon as `build_model`
is called with a `(problem, modeler)` pair for which no concrete method exists:

```@repl optprob
try # hide
CTSolvers.Optimization.build_model(MinimalProblem(), nothing, MinimalModeler())
catch e # hide
showerror(IOContext(stdout, :color => false), e) # hide
end # hide
```

**Fix**: Implement `build_model` and `build_solution` in the package providing the
problem, dispatching on the concrete `(problem, modeler)` pair (see
[Implementing an Optimization Problem](@ref)).

### Where it's thrown

| Method | Context |
|--------|---------|
| `CTBase.Strategies.id(::Type{T})` | Strategy type missing `id` |
| `CTBase.Strategies.metadata(::Type{T})` | Strategy type missing `metadata` |
| `CTBase.Strategies.options(strategy)` | Strategy instance has no `options` field and no custom getter |
| `Optimization.build_model(prob, init, modeler)` | No concrete method for this `(problem, modeler)` pair |
| `Optimization.build_solution(built, stats, modeler)` | No concrete method for this `(built, modeler)` pair |

## IncorrectArgument — Invalid Arguments

Thrown for invalid values, types, or routing errors. This is the most common exception in CTSolvers.

### Type mismatch in extraction

When `extract_option` receives a value of the wrong type:

```@repl errors
def = CTBase.Options.OptionDefinition(
    name = :max_iter, type = Integer, default = 100,
    description = "Maximum iterations",
)
try # hide
CTBase.Options.extract_option((max_iter = "hello",), def)
catch e # hide
showerror(IOContext(stdout, :color => false), e) # hide
end # hide
```

**Fix**: Provide a value of the correct type.

### Validator failure

When a value doesn't satisfy the validator constraint:

```@example errors
bad_def = CTBase.Options.OptionDefinition(
    name = :tol, type = Real, default = 1e-8,
    description = "Tolerance",
    validator = x -> x > 0 || throw(Exceptions.IncorrectArgument(
        "Invalid tolerance value",
        got = "tol=$x",
        expected = "positive real number (> 0)",
        suggestion = "Provide a positive tolerance value (e.g., 1e-6, 1e-8)",
        context = "tol validation",
    )),
)
nothing # hide
```

```@repl errors
try # hide
CTBase.Options.extract_option((tol = -1.0,), bad_def)
catch e # hide
showerror(IOContext(stdout, :color => false), e) # hide
end # hide
```

**Fix**: Provide a value that satisfies the validator constraint.

### Type mismatch in OptionDefinition constructor

When the default value doesn't match the declared type:

```@repl errors
try # hide
CTBase.Options.OptionDefinition(
    name = :count, type = Integer, default = "hello",
    description = "A count",
)
catch e # hide
showerror(IOContext(stdout, :color => false), e) # hide
end # hide
```

**Fix**: Ensure the default value matches the declared type.

### Invalid OptionValue source

```@repl errors
try # hide
CTBase.Options.OptionValue(42, :invalid_source)
catch e # hide
showerror(IOContext(stdout, :color => false), e) # hide
end # hide
```

**Fix**: Use `:default`, `:user`, or `:computed`.

## ExtensionError — Extension Not Loaded

Thrown when a solver requires a package extension that hasn't been loaded.

```@repl errors
try # hide
CTSolvers.Solvers.MadNLP()
catch e # hide
showerror(IOContext(stdout, :color => false), e) # hide
end # hide
```

**Fix**: Load the required package before using the solver:

```julia
using MadNLP  # loads the CTSolversMadNLP extension
solver = Solvers.MadNLP(max_iter = 1000)
```

### Where it's thrown

| Solver | Required package |
|--------|-----------------|
| `Solvers.Ipopt` | `NLPModelsIpopt` |
| `Solvers.MadNLP` | `MadNLP` |
| `Solvers.Knitro` | `KNITRO` |
| `Solvers.MadNCL` | `MadNCL` |

## Best Practices for Error Messages

When implementing new validators or error paths, follow the CTSolvers convention:

```julia
throw(Exceptions.IncorrectArgument(
    "Short, clear description of the problem",
    got        = "what the user actually provided",
    expected   = "what was expected instead",
    suggestion = "actionable fix the user can apply",
    context    = "ModuleName.function_name - specific validation step",
))
```

- **`got`**: Show the actual value, including its type if relevant
- **`expected`**: Be specific about valid values or ranges
- **`suggestion`**: Provide a concrete example the user can copy
- **`context`**: Include the module and function name for traceability
