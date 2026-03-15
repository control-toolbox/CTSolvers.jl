# Display formatting utilities
#
# Unified color and formatting constants for consistent display across all show() methods

"""
Get ANSI formatting codes based on terminal color support.

Returns a NamedTuple with formatting codes for consistent display.
"""
function get_format_codes(io::IO)
    # Use the CTCore module function to ensure consistency
    return CTCore.get_format_codes(io)
end
