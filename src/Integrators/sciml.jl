"""
$(TYPEDEF)

Tag type for SciML integrator dispatch. Used to target the implementation
provided by the `CTSolversSciMLIntegrator` package extension.
"""
struct SciMLTag <: Core.AbstractTag end

"""
$(TYPEDEF)

Tag type for Tsit5-specific default algorithm dispatch. Used to target
the implementation provided by the `CTSolversOrdinaryDiffEqTsit5` package extension.
"""
struct Tsit5Tag <: Core.AbstractTag end

"""
$(TYPEDEF)

Abstract supertype for SciML-based ODE integrator strategies.

This type defines the interface for all integrator strategies that use SciML solvers.
Concrete subtypes should store strategy options and implement the required contract methods.

# Interface Requirements

Subtypes must implement:
- `CTBase.Strategies.id(::Type{<:SubType})`: Return unique identifier.
- `CTBase.Strategies.description(::Type{<:SubType})`: Return description.
- `CTBase.Strategies.metadata(::Type{<:SubType})`: Return option metadata.

See also: [`CTSolvers.Integrators.SciML`](@ref), [`CTSolvers.Integrators.SciMLTag`](@ref).
"""
abstract type AbstractSciMLIntegrator <: AbstractIntegrator end

"""
$(TYPEDEF)

Generic SciML ODE integrator strategy.

Wraps any SciML algorithm (e.g. `Tsit5`, `Rodas4`) through a unified
`CTBase.Strategies`-backed option system. The full implementation (metadata, builder
and solve) is provided by the `CTSolversSciMLIntegrator` package extension; this
file declares the type and **stubs** that throw `ExtensionError` until the
extension is loaded.

Parameterized on the execution device `P`:
- `SciML{CPU}`: CPU execution (default);
- `SciML{GPU}`: GPU execution (state on device arrays, e.g. `CuArray`).

`SciML(...)` builds a `SciML{CPU}` — the device parameterization is fully backward
compatible with existing call sites.

To activate the extension, load any of:
- `using OrdinaryDiffEqTsit5` (minimal)
- `using OrdinaryDiffEq`
- `using DifferentialEquations`

# Fields

$(TYPEDFIELDS)
"""
struct SciML{
    P<:Union{CPU,GPU},
    O<:Strategies.StrategyOptions,
    OP<:Dict{Symbol,Any},
    OT<:Dict{Symbol,Any},
} <: AbstractSciMLIntegrator
    "Validated option bundle."
    options::O
    "Pre-computed options for point (final-state) integration."
    options_point::OP
    "Pre-computed options for trajectory integration."
    options_trajectory::OT
end

# ============================================================================
# AbstractStrategy Contract Implementation
# ============================================================================

"""
$(TYPEDSIGNATURES)

Return the unique identifier for the SciML integrator.
"""
Strategies.id(::Type{<:SciML}) = :sciml

"""
$(TYPEDSIGNATURES)

Return the execution parameter of the non-parameterized `SciML` type: `nothing`.

The bare `SciML` (device unspecified) resolves to `nothing`, matching the general
`AbstractStrategy` contract and preserving backward compatibility for consumers that
register `SciML` without a parameter (e.g. CTFlows' flow registry) and query
`parameter` on the bare type. A concrete `SciML{P}` resolves to `P` via the more
specific method below.

See also: [`CTSolvers.Integrators.SciML`](@ref), [`CTBase.Strategies.default_parameter`](@extref)
"""
Strategies.parameter(::Type{<:SciML}) = nothing

"""
$(TYPEDSIGNATURES)

Return the execution parameter type of a parameterized `SciML{P}` integrator.

Extracts the type parameter `P` from `SciML{P}`, which can be either `CPU` or `GPU`
since `SciML` supports both execution devices. More specific than the bare
`parameter(::Type{<:SciML})` above, so it wins for a concrete `SciML{P}`.

# Returns
- `Type{<:Union{CPU,GPU}}`: the execution parameter type.

See also: [`CTSolvers.Integrators.SciML`](@ref), [`CTBase.Strategies.CPU`](@extref), [`CTBase.Strategies.GPU`](@extref)
"""
Strategies.parameter(::Type{<:SciML{P}}) where {P<:Union{CPU,GPU}} = P

"""
$(TYPEDSIGNATURES)

Return the default execution parameter for `SciML` when none is specified.

Returns `CPU`, so `SciML(...)` builds a `SciML{CPU}` and every existing call site is
unaffected by the device parameterization.

See also: [`CTSolvers.Integrators.SciML`](@ref), [`CTBase.Strategies.CPU`](@extref)
"""
Strategies.default_parameter(::Type{<:SciML}) = CPU

"""
$(TYPEDSIGNATURES)

Return the description for the SciML integrator.
"""
function Strategies.description(::Type{<:SciML})
    return "SciML ODE integrator.\n" *
           "See: https://docs.sciml.ai/DiffEqDocs\n" *
           "Solver options: https://docs.sciml.ai/DiffEqDocs/stable/basics/common_solver_opts/"
end

# ============================================================================
# Accessors (co-located with the type, per the contract-co-location convention)
# ============================================================================

"""
$(TYPEDSIGNATURES)

Return the pre-computed option dictionary for point (final-state) integration.

See also: [`CTSolvers.Integrators.options_trajectory`](@ref).
"""
options_point(integ::SciML) = integ.options_point

"""
$(TYPEDSIGNATURES)

Return the pre-computed option dictionary for trajectory integration.

See also: [`CTSolvers.Integrators.options_point`](@ref).
"""
options_trajectory(integ::SciML) = integ.options_trajectory

# ============================================================================
# Constructor with Tag Dispatch
# ============================================================================

"""
$(TYPEDSIGNATURES)

Construct a `SciML{CPU}` integrator (the default device). Equivalent to
`SciML{CPU}(...)`; delegates through [`CTBase.Strategies.default_parameter`](@extref).

# Arguments
- `mode::Symbol=:strict`: Validation mode (`:strict` or `:permissive`).
- `kwargs...`: Options forwarded to the integrator builder (see extension documentation).

# Throws
- `CTBase.Exceptions.ExtensionError`: If the `CTSolversSciMLIntegrator` extension is not loaded.

See also: [`CTSolvers.Integrators.SciML`](@ref), [`CTSolvers.Integrators.build_sciml_integrator`](@ref).
"""
function SciML(; mode::Symbol=:strict, kwargs...)
    P = Strategies.default_parameter(SciML)
    return SciML{P}(; mode=mode, kwargs...)
end

"""
$(TYPEDSIGNATURES)

Construct a parameterized `SciML{P}` integrator for the execution device `P`
(`CPU` or `GPU`). Delegates to `build_sciml_integrator`, which is overridden by the
`CTSolversSciMLIntegrator` package extension.

# Arguments
- `mode::Symbol=:strict`: Validation mode (`:strict` or `:permissive`).
- `kwargs...`: Options forwarded to the integrator builder (see extension documentation).

# Throws
- `CTBase.Exceptions.ExtensionError`: If the `CTSolversSciMLIntegrator` extension is not loaded.

See also: [`CTSolvers.Integrators.SciML`](@ref), [`CTSolvers.Integrators.build_sciml_integrator`](@ref).
"""
function SciML{P}(; mode::Symbol=:strict, kwargs...) where {P<:AbstractStrategyParameter}
    return build_sciml_integrator(SciMLTag, P; mode=mode, kwargs...)
end

"""
$(TYPEDSIGNATURES)

Stub builder for `SciML`. The real implementation is provided by
`CTSolversSciMLIntegrator`; this stub throws `ExtensionError` until the extension
is loaded.
"""
function build_sciml_integrator(
    ::Type{<:Core.AbstractTag}, ::Type{<:AbstractStrategyParameter}; kwargs...
)
    return throw(
        Exceptions.ExtensionError(
            :OrdinaryDiffEqTsit5;
            message="to construct a SciML integrator",
            feature="ODE integration via SciML",
            context="Load OrdinaryDiffEqTsit5, OrdinaryDiffEq, or DifferentialEquations to activate the CTSolversSciMLIntegrator extension.",
        ),
    )
end

"""
$(TYPEDSIGNATURES)

Stub function that throws `ExtensionError` if the `CTSolversSciMLIntegrator` extension is
not loaded. The real metadata implementation is provided by the extension.

# Throws
- `CTBase.Exceptions.ExtensionError`: Always thrown by this stub implementation.

See also: [`CTSolvers.Integrators.SciML`](@ref), [`CTBase.Strategies.StrategyMetadata`](@extref).
"""
function Strategies.metadata(::Type{<:AbstractSciMLIntegrator})
    return throw(
        Exceptions.ExtensionError(
            :OrdinaryDiffEqTsit5;
            message="to access SciML options metadata",
            feature="SciML metadata",
            context="Load OrdinaryDiffEqTsit5, OrdinaryDiffEq, or DifferentialEquations to activate the CTSolversSciMLIntegrator extension.",
        ),
    )
end

"""
$(TYPEDSIGNATURES)

Fallback for the non-parameterized `SciML` type that delegates to `SciML{CPU}`.

Preserves backward compatibility for `metadata(SciML)` once the extension defines only
the parameterized `metadata(SciML{P})`. Delegates through
[`CTBase.Strategies.default_parameter`](@extref).

See also: [`CTSolvers.Integrators.SciML`](@ref), [`CTBase.Strategies.StrategyMetadata`](@extref).
"""
function Strategies.metadata(::Type{SciML})
    return Strategies.metadata(SciML{Strategies.default_parameter(SciML)})
end

"""
$(TYPEDSIGNATURES)

Return the default SciML ODE algorithm for the given tag type.

This stub returns `missing` for the abstract tag type. The actual implementation
for `Tsit5Tag` is provided by `CTSolversOrdinaryDiffEqTsit5`.

# Returns
- `missing`: Default stub implementation.

See also: [`CTSolvers.Integrators.SciML`](@ref), [`CTSolvers.Integrators.Tsit5Tag`](@ref).
"""
function __default_sciml_algorithm(::Type{<:Core.AbstractTag})
    return missing
end

"""
$(TYPEDSIGNATURES)

Check whether an initial condition `u0` is consistent with the execution parameter `P`
of a `SciML{P}` integrator.

Mirrors `Modelers.__consistent_backend`: the default returns `true` (all combinations
allowed); the `CTSolversCUDA` extension adds the device-aware methods that flag a `CuArray`
`u0` under `SciML{CPU}`, or a host `Array` `u0` under `SciML{GPU}`. The seam is defined here,
next to the integrator; the consuming package (e.g. CTFlows) calls it where a concrete `u0`
is available (problem construction / solve), since `SciML` does not receive `u0` at build time.

# Arguments
- `parameter_type::Type{<:AbstractStrategyParameter}`: `CPU` or `GPU`.
- `u0`: The initial condition array to check.

# Returns
- `Bool`: `true` if consistent, `false` otherwise.

See also: [`CTSolvers.Integrators.SciML`](@ref), [`CTBase.Strategies.CPU`](@extref), [`CTBase.Strategies.GPU`](@extref).
"""
function __consistent_initial_condition(::Type{<:AbstractStrategyParameter}, u0)
    return true
end
