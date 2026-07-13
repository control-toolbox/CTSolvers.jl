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

To activate the extension, load any of:
- `using OrdinaryDiffEqTsit5` (minimal)
- `using OrdinaryDiffEq`
- `using DifferentialEquations`

# Fields

$(TYPEDFIELDS)
"""
struct SciML{O<:Strategies.StrategyOptions, OP<:Dict{Symbol, Any}, OT<:Dict{Symbol, Any}} <: AbstractSciMLIntegrator
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

Return the execution parameter type of the `SciML` integrator.

Returns `nothing` because `SciML` is a non-parameterized strategy: it has no
execution parameter and does not require one.

# Returns
- `Nothing`: `SciML` is not parameterized.

See also: [`CTSolvers.Integrators.SciML`](@ref)
"""
Strategies.parameter(::Type{<:SciML}) = nothing

"""
$(TYPEDSIGNATURES)

Return the description for the SciML integrator.
"""
function Strategies.description(::Type{<:SciML})
    "SciML ODE integrator.\n" *
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

Construct a `SciML` integrator. Delegates to `build_sciml_integrator`, which
is overridden by the `CTSolversSciMLIntegrator` package extension.

# Arguments
- `mode::Symbol=:strict`: Validation mode (`:strict` or `:permissive`).
- `kwargs...`: Options forwarded to the integrator builder (see extension documentation).

# Throws
- `CTBase.Exceptions.ExtensionError`: If the `CTSolversSciMLIntegrator` extension is not loaded.

See also: [`CTSolvers.Integrators.SciML`](@ref), [`CTSolvers.Integrators.build_sciml_integrator`](@ref).
"""
function SciML(; mode::Symbol = :strict, kwargs...)
    return build_sciml_integrator(SciMLTag; mode = mode, kwargs...)
end

"""
$(TYPEDSIGNATURES)

Stub builder for `SciML`. The real implementation is provided by
`CTSolversSciMLIntegrator`; this stub throws `ExtensionError` until the extension
is loaded.
"""
function build_sciml_integrator(::Type{<:Core.AbstractTag}; kwargs...)
    throw(
        Exceptions.ExtensionError(
            :OrdinaryDiffEqTsit5;
            message = "to construct a SciML integrator",
            feature = "ODE integration via SciML",
            context = "Load OrdinaryDiffEqTsit5, OrdinaryDiffEq, or DifferentialEquations to activate the CTSolversSciMLIntegrator extension.",
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
    throw(
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
