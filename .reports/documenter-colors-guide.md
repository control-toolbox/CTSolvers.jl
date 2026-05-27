# Guide: Fixing Colors in Documenter Documentation

## Problem Description

When using Julia's `printstyled()` function in code that gets executed during Documenter documentation generation, the colors do not appear in the generated HTML documentation. This happens because:

1. `printstyled()` writes terminal-specific escape sequences directly to the terminal
2. Documenter captures output but cannot convert `printstyled()` calls to HTML CSS classes
3. Only raw ANSI escape sequences are automatically converted by Documenter

## Solution: Use Raw ANSI Escape Sequences

### The Issue with `printstyled`

```julia
# ❌ This won't work in Documenter
printstyled(io, "text"; color=:cyan, bold=true)
```

### The Working Solution

```julia
# ✅ This works in Documenter
print(io, "\033[1;36m", "text", "\033[0m")
```

## Implementation Pattern

### 1. Create ANSI Helper Functions

```julia
"""
Generate ANSI escape sequence for the specified color and formatting.
"""
function _ansi_color(color::Symbol, bold::Bool=false)
    color_codes = Dict(
        :black => 30, :red => 31, :green => 32, :yellow => 33,
        :blue => 34, :magenta => 35, :cyan => 36, :white => 37,
        :default => 39
    )
    
    code = get(color_codes, color, 39)
    return bold ? "\033[1;$(code)m" : "\033[$(code)m"
end

"""Generate ANSI reset sequence to clear formatting."""
_ansi_reset() = "\033[0m"

"""
Print text with ANSI color formatting for Documenter compatibility.
"""
function _print_ansi_styled(io, text::Union{String,Symbol,Type}, color::Symbol, bold::Bool=false)
    print(io, _ansi_color(color, bold), text, _ansi_reset())
end
```

### 2. Replace All `printstyled` Calls

```julia
# Before:
printstyled(io, label; bold=true)
printstyled(io, pkg; color=:cyan, bold=true)

# After:
_print_ansi_styled(io, label, :default, true)
_print_ansi_styled(io, pkg, :cyan, true)
```

### 3. Support Multiple Text Types

Make sure your helper function accepts both `String` and `Symbol`:

```julia
function _print_ansi_styled(io, text::Union{String,Symbol}, color::Symbol, bold::Bool=false)
    print(io, _ansi_color(color, bold), string(text), _ansi_reset())
end
```

## Why This Works

### Documenter's ANSI Processing

Documenter uses the `ANSIColoredPrinters.jl` package to automatically convert ANSI escape sequences to CSS classes:

- `\033[36m` → `<span class="sgr36">`
- `\033[1;36m` → `<span class="sgr1"><span class="sgr36">` (bold + cyan)
- `\033[0m` → `</span></span>` (reset)

### Example Conversion

**Input (ANSI):**
```
\033[1;36mDiscretizer\033[0m: \033[1;36mcollocation\033[0m
```

**Output (HTML):**
```html
<span class="sgr1"><span class="sgr36">Discretizer</span></span>: <span class="sgr1"><span class="sgr36">collocation</span></span>
```

## Color Code Reference

| Color | ANSI Code | CSS Class |
|-------|-----------|-----------|
| Black | 30 | sgr30 |
| Red | 31 | sgr31 |
| Green | 32 | sgr32 |
| Yellow | 33 | sgr33 |
| Blue | 34 | sgr34 |
| Magenta | 35 | sgr35 |
| Cyan | 36 | sgr36 |
| White | 37 | sgr37 |
| Default | 39 | sgr39 |

Bold formatting adds `1;` prefix: `\033[1;36m` for bold cyan.

## Implementation Checklist

- [ ] Create ANSI helper functions
- [ ] Replace all `printstyled` calls with ANSI equivalents
- [ ] Support both `String` and `Symbol` inputs
- [ ] Test locally with `julia --project=@. make.jl`
- [ ] Verify colors appear in generated HTML
- [ ] Commit and push changes

## Common Pitfalls

1. **Type Mismatches**: Make sure to convert `Symbol` to `String` if needed
2. **Missing Reset**: Always include `\033[0m` to close formatting
3. **Wrong Color Names**: Use exact color names from the mapping
4. **Incomplete Replacement**: Make sure ALL `printstyled` calls are replaced

## Real-World Example

From OptimalControl.jl's `print.jl`:

```julia
# Before (no colors in documentation):
function _print_component_with_param(io, component_id, show_inline, param_sym)
    printstyled(io, component_id; color=:cyan, bold=true)
    if show_inline && param_sym !== nothing
        print(io, " (")
        printstyled(io, string(param_sym); color=:magenta, bold=true)
        print(io, ")")
    end
end

# After (colors work in documentation):
function _print_component_with_param(io, component_id, show_inline, param_sym)
    _print_ansi_styled(io, component_id, :cyan, true)
    if show_inline && param_sym !== nothing
        print(io, " (")
        _print_ansi_styled(io, param_sym, :magenta, true)
        print(io, ")")
    end
end
```

## Testing

1. **Local Testing**: Generate documentation locally and check `build/` directory
2. **HTML Inspection**: Look for `sgrXX` CSS classes in the generated HTML
3. **Remote Testing**: Verify colors appear in deployed documentation

## Conclusion

By replacing `printstyled()` with raw ANSI escape sequences, you enable Documenter to automatically convert terminal colors to web-compatible HTML CSS classes, ensuring consistent color display across local and remote documentation.
