"""
CTSolversADNLPModels Extension

Extension providing ADNLP modeler metadata and constructor implementation.
Triggered when ADNLPModels is loaded; implements the complete Modelers.ADNLP
functionality that requires ADNLPModels types.
"""
module CTSolversADNLPModels

import DocStringExtensions: TYPEDSIGNATURES
import CTSolvers.Modelers
import CTBase.Strategies
import CTBase.Core
import CTBase.Exceptions
using ADNLPModels: ADNLPModels

using CTBase.Strategies: CPU, AbstractStrategyParameter

# ============================================================================
# ADBackend type-check helpers (override weak-dep stubs in core)
# ============================================================================

"""
$(TYPEDSIGNATURES)

Return `true` for types that are subtypes of `ADNLPModels.ADBackend`.

Overrides the core stub in `CTSolvers.Modelers` when `ADNLPModels` is loaded.

# Returns
- `Bool`: `true`

See also: [`CTSolvers.Modelers.__is_adbackend_type`](@ref),
[`CTSolvers.Modelers.__is_adbackend_instance`](@ref)
"""
Modelers.__is_adbackend_type(::Type{<:ADNLPModels.ADBackend}) = true

"""
$(TYPEDSIGNATURES)

Return `true` for instances of `ADNLPModels.ADBackend`.

Overrides the core stub in `CTSolvers.Modelers` when `ADNLPModels` is loaded.

# Returns
- `Bool`: `true`

See also: [`CTSolvers.Modelers.__is_adbackend_instance`](@ref),
[`CTSolvers.Modelers.__is_adbackend_type`](@ref)
"""
Modelers.__is_adbackend_instance(x::ADNLPModels.ADBackend) = true

# ============================================================================
# Available backends (override weak-dep stub in core)
# ============================================================================

"""
$(TYPEDSIGNATURES)

Return the list of available AD backends for `Modelers.ADNLP` using `ADNLPModels`.

Overrides the core stub; called via [`CTSolvers.Modelers.get_adnlp_available_backends`](@ref).
Includes all predefined backends from `ADNLPModels.predefined_backend` plus `:manual`.

# Returns
- `Vector{Symbol}`: available backend names (e.g. `:default`, `:optimized`, `:manual`)

See also: [`CTSolvers.Modelers.get_adnlp_available_backends`](@ref),
[`CTSolvers.Modelers.ADNLPTag`](@ref)
"""
function Modelers.__get_adnlp_available_backends(::Type{Modelers.ADNLPTag})
    backends = collect(keys(ADNLPModels.predefined_backend))
    push!(backends, :manual)
    return backends
end

# ============================================================================
# Metadata definition
# ============================================================================

"""
$(TYPEDSIGNATURES)

Return metadata defining all options for `Modelers.ADNLP{P}` modelers.

Overrides the core `ExtensionError` stub when `ADNLPModels` is loaded. Covers
basic options (`:show_time`, `:backend`, `:matrix_free`, `:name`) and expert-level
AD backend overrides for individual derivative operations.

# Returns
- `CTBase.Strategies.StrategyMetadata`: metadata object with all option definitions

See also: [`CTSolvers.Modelers.ADNLP`](@ref),
[`CTSolvers.Modelers._build_adnlp_modeler`](@ref)
"""
function Strategies.metadata(::Type{Modelers.ADNLP{P}}) where {P<:CPU}
    return Strategies.StrategyMetadata(
        # === Basic Options ===
        Strategies.OptionDefinition(;
            name=:show_time,
            type=Bool,
            default=Core.NotProvided,
            description="Whether to show timing information while building the ADNLP model",
        ),
        Strategies.OptionDefinition(;
            name=:backend,
            type=Symbol,
            default=Modelers.__adnlp_model_backend(),
            description="Automatic differentiation backend used by ADNLPModels.\nAvailable: $(join(Modelers.get_adnlp_available_backends(), ", ", " and ")).",
            validator=Modelers.get_validate_adnlp_backend(Modelers.ADNLPTag),
            aliases=(:adnlp_backend,),
        ),

        # === High-Priority Options ===
        Strategies.OptionDefinition(;
            name=:matrix_free,
            type=Bool,
            default=Core.NotProvided,
            description="Enable matrix-free mode (avoids explicit Hessian/Jacobian matrices)",
            validator=Modelers.validate_matrix_free,
        ),
        Strategies.OptionDefinition(;
            name=:name,
            type=String,
            default=Core.NotProvided,
            description="Name of the optimization model for identification",
            validator=Modelers.validate_model_name,
        ),

        # === Advanced Backend Overrides (expert users) ===
        Strategies.OptionDefinition(;
            name=:gradient_backend,
            type=Union{Nothing,Type{<:ADNLPModels.ADBackend},ADNLPModels.ADBackend},
            default=Core.NotProvided,
            description="Override backend for gradient computation (advanced users only)",
            validator=Modelers.validate_backend_override,
        ),
        Strategies.OptionDefinition(;
            name=:hprod_backend,
            type=Union{Nothing,Type{<:ADNLPModels.ADBackend},ADNLPModels.ADBackend},
            default=Core.NotProvided,
            description="Override backend for Hessian-vector product (advanced users only)",
            validator=Modelers.validate_backend_override,
        ),
        Strategies.OptionDefinition(;
            name=:jprod_backend,
            type=Union{Nothing,Type{<:ADNLPModels.ADBackend},ADNLPModels.ADBackend},
            default=Core.NotProvided,
            description="Override backend for Jacobian-vector product (advanced users only)",
            validator=Modelers.validate_backend_override,
        ),
        Strategies.OptionDefinition(;
            name=:jtprod_backend,
            type=Union{Nothing,Type{<:ADNLPModels.ADBackend},ADNLPModels.ADBackend},
            default=Core.NotProvided,
            description="Override backend for transpose Jacobian-vector product (advanced users only)",
            validator=Modelers.validate_backend_override,
        ),
        Strategies.OptionDefinition(;
            name=:jacobian_backend,
            type=Union{Nothing,Type{<:ADNLPModels.ADBackend},ADNLPModels.ADBackend},
            default=Core.NotProvided,
            description="Override backend for Jacobian matrix computation (advanced users only)",
            validator=Modelers.validate_backend_override,
        ),
        Strategies.OptionDefinition(;
            name=:hessian_backend,
            type=Union{Nothing,Type{<:ADNLPModels.ADBackend},ADNLPModels.ADBackend},
            default=Core.NotProvided,
            description="Override backend for Hessian matrix computation (advanced users only)",
            validator=Modelers.validate_backend_override,
        ),
        Strategies.OptionDefinition(;
            name=:ghjvprod_backend,
            type=Union{Nothing,Type{<:ADNLPModels.ADBackend},ADNLPModels.ADBackend},
            default=Core.NotProvided,
            description="Override backend for g^T ∇²c(x)v computation (advanced users only)",
            validator=Modelers.validate_backend_override,
        ),
    )
end

# ============================================================================
# Constructor implementation (override tag-dispatch stub in core)
# ============================================================================

"""
$(TYPEDSIGNATURES)

Build a `Modelers.ADNLP{parameter}` modeler with validated options.

Overrides the core `ExtensionError` stub when `ADNLPModels` is loaded.
Whenever the deprecated keyword `:adnlp_backend` is passed, a warning is issued
and `:backend` should be used instead.

# Arguments
- `parameter::Type{<:AbstractStrategyParameter}`: strategy parameter type (e.g. `CPU`)
- `mode::Symbol`: validation mode, `:strict` (default) or `:permissive`
- `kwargs...`: options forwarded to [`CTBase.Strategies.build_strategy_options`](@extref)

# Returns
- `CTSolvers.Modelers.ADNLP{parameter}`: configured modeler instance

See also: [`CTSolvers.Modelers.ADNLP`](@ref),
[`CTSolvers.Modelers._build_adnlp_modeler`](@ref)
"""
function Modelers._build_adnlp_modeler(
    ::Type{Modelers.ADNLPTag},
    parameter::Type{<:AbstractStrategyParameter};
    mode::Symbol=:strict,
    kwargs...,
)
    if haskey(kwargs, :adnlp_backend)
        @warn "adnlp_backend is deprecated, use backend instead" maxlog=1
    end
    opts = Strategies.build_strategy_options(
        Modelers.ADNLP{parameter}; mode=mode, kwargs...
    )
    return Modelers.ADNLP{parameter}(opts)
end

end # module CTSolversADNLPModels
