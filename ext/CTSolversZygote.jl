"""
CTSolversZygote Extension

Extension providing Zygote backend validation for ADNLP modeler.
Implements Zygote-specific backend validation by overriding the default
ExtensionError behavior for the ADNLPTag.
"""

module CTSolversZygote

import CTSolvers.Modelers
import DocStringExtensions: TYPEDSIGNATURES

"""
$(TYPEDSIGNATURES)

Validate Zygote backend for ADNLPTag when Zygote extension is loaded.

# Arguments
- `tag::Modelers.ADNLPTag`: ADNLP tag (dispatch target)
- `backend::Val{:zygote}`: Zygote backend type

# Returns
- `Symbol`: Validated backend symbol (`:zygote`)

# Notes
- Overrides the default ExtensionError behavior for ADNLPTag
- Only applies to ADNLPTag, other tags still throw ExtensionError
- Enables Zygote backend usage when extension is loaded
"""
function Modelers.validate_adnlp_backend(tag::Modelers.ADNLPTag, ::Val{:zygote})
    return :zygote
end

end # module CTSolversZygote
