"""
Core utilities and common types for CTSolvers.

This module provides:
- Common abstract types used across the package
- Display formatting utilities for consistent output
- Shared constants and helper functions
"""
module Core

import DocStringExtensions: TYPEDEF

# ==============================================================================
# Abstract Types
# ==============================================================================

"""
$(TYPEDEF)

Abstract type for tag dispatch pattern used to handle extension-dependent implementations.

This type is used for multiple dispatch in validation functions and other contexts
where behavior depends on loaded extensions (e.g., Enzyme, Zygote, CUDA).

# Example
```julia
struct MyTag <: AbstractTag end

function validate_backend(tag::MyTag, backend::Symbol)
    # Tag-specific validation logic
end
```

See also: Extension-based validation patterns in `Modelers` module
"""
abstract type AbstractTag end

# ==============================================================================
# Display Formatting
# ==============================================================================

"""
    get_format_codes(io::IO) -> NamedTuple

Get ANSI formatting codes based on terminal color support.

Returns a NamedTuple with formatting codes for consistent display across all show() methods.

# Fields
- `bold`: Bold text
- `reset`: Reset all formatting
- `name`: Bold blue for names (options, types, etc.)
- `type`: Cyan for types
- `value`: Green for values
- `keyword`: Yellow for keywords/aliases
- `count`: Magenta for counts
- `label`: Gray for labels/descriptions

# Example
```julia
fmt = get_format_codes(io)
print(io, fmt.name, "option_name", fmt.reset, "::", fmt.type, "Int", fmt.reset)
```

# Notes
- Automatically detects color support via `get(io, :color, false)`
- Returns empty strings for all codes if colors are not supported
- Ensures consistent color scheme across the entire package
"""
function get_format_codes(io::IO)
    supports_color = true # get(io, :color, false)
    
    return (
        # Text formatting
        bold = supports_color ? "\033[1m" : "",
        reset = supports_color ? "\033[0m" : "",
        
        # Colors for different semantic elements
        name = supports_color ? "\033[1m\033[34m" : "",      # Bold blue for names
        type = supports_color ? "\033[36m" : "",             # Cyan for types
        value = supports_color ? "\033[32m" : "",            # Green for values
        keyword = supports_color ? "\033[33m" : "",          # Yellow for keywords/aliases
        count = supports_color ? "\033[35m" : "",            # Magenta for counts
        label = supports_color ? "\033[90m" : "",            # Gray for labels
    )
end

# ==============================================================================
# Exports
# ==============================================================================

export AbstractTag, get_format_codes

end # module Core
