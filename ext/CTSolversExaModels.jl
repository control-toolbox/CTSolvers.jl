"""
CTSolversExaModels Extension

Extension providing Exa modeler metadata and constructor implementation.
Triggered when ExaModels is loaded; implements the complete Modelers.Exa
functionality that requires ExaModels/KernelAbstractions types.
"""
module CTSolversExaModels

import DocStringExtensions: TYPEDSIGNATURES
import CTSolvers.Modelers
import CTBase.Strategies
import CTBase.Core
using ExaModels: ExaModels
using KernelAbstractions: KernelAbstractions

using CTBase.Strategies: CPU, GPU, AbstractStrategyParameter

# ============================================================================
# Metadata definition
# ============================================================================

"""
$(TYPEDSIGNATURES)

Return metadata defining all options for `Modelers.Exa{P}` modelers.

Overrides the core `ExtensionError` stub when `ExaModels` and `KernelAbstractions`
are loaded. Covers `:base_type` (floating-point precision) and `:backend`
(KernelAbstractions execution backend, validated for consistency with `P`).

# Returns
- `CTBase.Strategies.StrategyMetadata`: metadata object with all option definitions

See also: [`CTSolvers.Modelers.Exa`](@ref),
[`CTSolvers.Modelers.build_exa_modeler`](@ref)
"""
function Strategies.metadata(::Type{Modelers.Exa{P}}) where {P<:Union{CPU,GPU}}
    return Strategies.StrategyMetadata(
        Strategies.OptionDefinition(;
            name=:base_type,
            type=DataType,
            default=Modelers.__exa_model_base_type(),
            description="Base floating-point type used by ExaModels",
            validator=Modelers.validate_exa_base_type,
        ),
        Strategies.OptionDefinition(;
            name=:backend,
            type=Union{Nothing,KernelAbstractions.Backend},
            default=Modelers.__exa_model_backend(P),
            description="Execution backend for ExaModels (CPU, GPU, etc.)",
            computed=true,
            aliases=(:exa_backend,),
            validator=function (backend)
                if !Modelers.__consistent_backend(P, backend)
                    param_str = P == CPU ? "CPU" : "GPU"
                    backend_str =
                        backend === nothing ? "no backend" : string(typeof(backend))
                    @warn "Inconsistent backend ($backend_str) for $param_str parameter" maxlog=1
                end
                return backend
            end,
        ),
    )
end

# ============================================================================
# Constructor implementation (override tag-dispatch stub in core)
# ============================================================================

"""
$(TYPEDSIGNATURES)

Build a `Modelers.Exa{parameter}` modeler with validated options.

Overrides the core `ExtensionError` stub when `ExaModels` and `KernelAbstractions`
are loaded. Whenever the deprecated keyword `:exa_backend` is passed, a warning
is issued and `:backend` should be used instead.

# Arguments
- `parameter::Type{<:AbstractStrategyParameter}`: strategy parameter type (e.g. `CPU`, `GPU`)
- `mode::Symbol`: validation mode, `:strict` (default) or `:permissive`
- `kwargs...`: options forwarded to [`CTBase.Strategies.build_strategy_options`](@extref)

# Returns
- `CTSolvers.Modelers.Exa{parameter}`: configured modeler instance

See also: [`CTSolvers.Modelers.Exa`](@ref),
[`CTSolvers.Modelers.build_exa_modeler`](@ref)
"""
function Modelers.build_exa_modeler(
    ::Type{Modelers.ExaTag},
    parameter::Type{<:AbstractStrategyParameter};
    mode::Symbol=:strict,
    kwargs...,
)
    if haskey(kwargs, :exa_backend)
        @warn "exa_backend is deprecated, use backend instead" maxlog=1
    end
    opts = Strategies.build_strategy_options(Modelers.Exa{parameter}; mode=mode, kwargs...)
    return Modelers.Exa{parameter}(opts)
end

end # module CTSolversExaModels
