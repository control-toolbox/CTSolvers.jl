# Migration Guide: Options Validation System

This guide helps you migrate to the new strict/permissive validation system and understand the changes.

## 📋 Table of Contents

1. [Overview of Changes](#overview-of-changes)
2. [Migration Steps](#migration-steps)
3. [Common Scenarios](#common-scenarios)
4. [Troubleshooting](#troubleshooting)
5. [Compatibility](#compatibility)

---

## 🔄 Overview of Changes

### What Changed

- **New parameter**: `mode::Symbol` added to strategy constructors
- **Two modes**: `:strict` (default) and `:permissive`
- **New helper**: `route_to()` for option disambiguation
- **Better errors**: More helpful error messages with suggestions

### What Stayed the Same

- **Default behavior**: Strict mode maintains existing safety
- **Known options**: Always validated the same way
- **API compatibility**: Existing code works without changes

---

## 🚀 Migration Steps

### Step 1: No Action Required (Default)

Most existing code continues to work unchanged:

```julia
# ✅ This still works exactly the same
solver = Solvers.IpoptSolver(max_iter=1000, tol=1e-6)
```

### Step 2: Add Permissive Mode When Needed

If you have unknown options that should be accepted:

```julia
# Before (would error)
solver = Solvers.IpoptSolver(custom_option="value")

# After (works with warning)
solver = Solvers.IpoptSolver(
    custom_option="value";
    mode=:permissive
)
```

### Step 3: Fix Disambiguation Issues

If you encounter "ambiguous option" errors:

```julia
# Before (ambiguous)
solve(ocp, method; max_iter=1000)

# After (clear routing)
solve(ocp, method; 
    max_iter = route_to(solver=1000)
)
```

---

## 📋 Common Scenarios

### Scenario 1: Backend-Specific Options

**Problem**: You need options not defined in CTSolvers

```julia
# ❌ Old approach (would error)
solver = Solvers.IpoptSolver(advanced_ipopt_option="value")

# ✅ New approach
solver = Solvers.IpoptSolver(
    advanced_ipopt_option="value";
    mode=:permissive
)
```

### Scenario 2: Legacy Code

**Problem**: Old code uses options not yet defined

```julia
# ✅ Gradual migration
function create_solver(options...)
    try
        # Try strict mode first
        Solvers.IpoptSolver(; options...)
    catch e
        # Fall back to permissive mode
        Solvers.IpoptSolver(; options..., mode=:permissive)
    end
end
```

### Scenario 3: Development vs Production

**Problem**: Different needs for different environments

```julia
# Development: Strict mode for early error detection
if ENV["ENV"] == "development"
    solver = Solvers.IpoptSolver(max_iter=1000)
else
    # Production: Permissive mode for flexibility
    solver = Solvers.IpoptSolver(
        max_iter=1000,
        custom_production_option="optimized";
        mode=:permissive
    )
end
```

### Scenario 4: Multiple Strategy Options

**Problem**: Same option name in multiple strategies

```julia
# ❌ Ambiguous
solve(ocp, method; max_iter=1000)

# ✅ Clear disambiguation
solve(ocp, method; 
    max_iter = route_to(solver=1000, modeler=500)
)
```

---

## 🔧 Troubleshooting

### Issue: "Unknown option" Error

**Symptoms**:
```
ERROR: Unknown options provided for IpoptSolver
Unrecognized options: [:custom_option]
```

**Solutions**:
1. **Fix typo**: Check option name spelling
2. **Use permissive mode**: Add `mode=:permissive`
3. **Define option**: Add to strategy metadata (advanced)

```julia
# Solution 1: Fix typo
solver = Solvers.IpoptSolver(max_iter=1000)  # not max_itter

# Solution 2: Use permissive mode
solver = Solvers.IpoptSolver(custom_option=123; mode=:permissive)

# Solution 3: Define option (advanced)
# Add to strategy metadata
```

### Issue: "Ambiguous option" Error

**Symptoms**:
```
ERROR: Option :max_iter is ambiguous between strategies
```

**Solution**: Use `route_to()` for disambiguation

```julia
# Before
solve(ocp, method; max_iter=1000)

# After
solve(ocp, method; 
    max_iter = route_to(solver=1000)  # Clear routing
)
```

### Issue: Too Many Warnings

**Symptoms**: Permissive mode generates many warnings

**Solutions**:
1. **Define options**: Add to metadata
2. **Suppress warnings**: Use Julia's warning system
3. **Clean up code**: Fix option names

```julia
# Solution 1: Define options (recommended)
# Add option definitions to strategy metadata

# Solution 2: Suppress warnings (temporary)
@warn "Suppressing warnings temporarily" max=1
solver = Solvers.IpoptSolver(unknown=123; mode=:permissive)

# Solution 3: Clean up code
# Fix option names and remove mode=:permissive
```

---

## 🔍 Compatibility

### Backward Compatibility

✅ **Fully Compatible**: All existing code continues to work

```julia
# ✅ These all work exactly the same
solver1 = Solvers.IpoptSolver()
solver2 = Solvers.IpoptSolver(max_iter=1000)
solver3 = Solvers.IpoptSolver(max_iter=1000, tol=1e-6)
```

### Forward Compatibility

✅ **Future-Proof**: New features won't break existing code

```julia
# ✅ Safe for future additions
solver = Solvers.IpoptSolver(
    max_iter=1000,
    future_option="value";  # Will work in future versions
    mode=:permissive
)
```

### Version Requirements

- **Minimum**: Julia 1.9+
- **CTSolvers**: v0.2.0+
- **Dependencies**: No additional dependencies required

---

## 📚 Migration Checklist

### Pre-Migration

- [ ] Identify code using unknown options
- [ ] Test current behavior
- [ ] Review error messages
- [ ] Plan migration strategy

### Migration

- [ ] Add `mode=:permissive` where needed
- [ ] Replace ambiguous options with `route_to()`
- [ ] Fix typos in option names
- [ ] Test permissive mode behavior

### Post-Migration

- [ ] Verify all tests pass
- [ ] Check warning messages
- [ ] Validate performance
- [ ] Update documentation

---

## 🎯 Best Practices

### Do's

✅ **Start with strict mode** for safety  
✅ **Use permissive mode sparingly**  
✅ **Read error messages** for guidance  
✅ **Use `route_to()`** for ambiguous options  
✅ **Define options in metadata** when possible  
✅ **Test both modes** in your code  

### Don'ts

❌ **Ignore warnings** in permissive mode  
❌ **Rely on unknown options** without testing  
❌ **Use permissive mode as default**  
❌ **Forget to test** after migration  

---

## 🔄 Advanced Migration Patterns

### Pattern 1: Environment-Based Mode

```julia
function create_solver(; kwargs...)
    mode = get(ENV, "CTSOLVERS_MODE", "strict") |> Symbol
    
    if mode == :strict
        Solvers.IpoptSolver(; kwargs...)
    elseif mode == :permissive
        Solvers.IpoptSolver(; kwargs..., mode=:permissive)
    else
        error("Invalid CTSOLVERS_MODE: $mode")
    end
end
```

### Pattern 2: Gradual Validation

```julia
function validate_options(options)
    # Try strict mode first
    try
        Solvers.IpoptSolver(; options...)
        return :valid
    catch e
        # Check if it's an unknown option error
        if occursin("Unknown options", string(e))
            return :unknown_options
        else
            rethrow(e)
        end
    end
end

function create_solver_safe(; kwargs...)
    validation = validate_options(kwargs)
    
    if validation == :valid
        Solvers.IpoptSolver(; kwargs...)
    elseif validation == :unknown_options
        @warn "Unknown options detected, using permissive mode"
        Solvers.IpoptSolver(; kwargs..., mode=:permissive)
    else
        error("Validation failed: $validation")
    end
end
```

### Pattern 3: Option Registry

```julia
# Define known options for your project
const KNOWN_OPTIONS = Set([
    :max_iter,
    :tol,
    :print_level,
    :linear_solver,
    # Add your project-specific options
])

function is_known_option(option::Symbol)
    return option in KNOWN_OPTIONS
end

function create_solver_with_validation(; kwargs...)
    unknown_options = filter(k -> !is_known_option(k), keys(kwargs))
    
    if isempty(unknown_options)
        Solvers.IpoptSolver(; kwargs...)
    else
        @warn "Unknown options detected: $(unknown_options)"
        Solvers.IpoptSolver(; kwargs..., mode=:permissive)
    end
end
```

---

## 📞 Support

### Getting Help

- **Documentation**: `docs/src/options_validation.md`
- **Examples**: `examples/options_validation_examples.jl`
- **API Reference**: `?CTSolvers.Strategies.route_to`
- **Tests**: `test/suite/strategies/test_validation_*.jl`

### Reporting Issues

If you encounter issues during migration:

1. **Check the error message** for guidance
2. **Try the examples** in the documentation
3. **Search existing issues** on GitHub
4. **Create a new issue** with:
   - Julia version
   - CTSolvers version
   - Minimal reproducible example
   - Error message

---

## ✅ Migration Summary

| Phase | Action | Status |
|-------|--------|--------|
| **Assessment** | Identify unknown options | ✅ Done |
| **Planning** | Choose migration strategy | ✅ Done |
| **Implementation** | Add `mode` and `route_to()` | ✅ Done |
| **Testing** | Verify behavior | ✅ Done |
| **Documentation** | Update docs | ✅ Done |
| **Deployment** | Roll out changes | ✅ Ready |

---

**🎉 Congratulations!** You're now ready to use the new options validation system with confidence and flexibility.
