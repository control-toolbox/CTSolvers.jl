"""
CTSolversEnzyme Extension

Extension providing Enzyme backend validation for ADNLP modeler.
Implements Enzyme-specific backend validation by overriding the default
ExtensionError behavior for the ADNLPTag.
"""

module CTSolversEnzyme

import DocStringExtensions: TYPEDSIGNATURES
import CTSolvers.Modelers

"""
$(TYPEDSIGNATURES)

Validate Enzyme backend for ADNLPTag when Enzyme extension is loaded.

# Arguments
- `tag::Modelers.ADNLPTag`: ADNLP tag (dispatch target)
- `backend::Val{:enzyme}`: Enzyme backend type

# Returns
- `Symbol`: Validated backend symbol (`:enzyme`)

# Notes
- Overrides the default ExtensionError behavior for ADNLPTag
- Only applies to ADNLPTag, other tags still throw ExtensionError
- Enables Enzyme backend usage when extension is loaded
"""
function Modelers.validate_adnlp_backend(tag::Modelers.ADNLPTag, ::Val{:enzyme})
    return :enzyme
end

end # module CTSolversEnzyme
