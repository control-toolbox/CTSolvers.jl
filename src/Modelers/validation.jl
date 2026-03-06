# Modelers validation
#
# Validation helpers used by the `Modelers.ADNLP` and `Modelers.Exa` constructors.

# ============================================================================
# Tag dispatch infrastructure
# ============================================================================

"""
$(TYPEDSIGNATURES)

Fallback method for invalid ADNLP backends using tag dispatch.

# Arguments
- `tag::AbstractTag`: Tag for dispatch (e.g., ADNLPTag, DummyTag)
- `backend::Val`: Backend type as Val for dispatch (invalid backend)

# Throws
- `CTBase.Exceptions.IncorrectArgument`: Always thrown for invalid backends

# Notes
- This method is called when no more specific method matches the backend
- Provides comprehensive error message with valid backend options
- Uses structured exception with got/expected/suggestion fields

See also: [`validate_adnlp_backend(::AbstractTag, ::Val{:default})`](@ref), [`get_validate_adnlp_backend`](@ref)
"""
function validate_adnlp_backend(tag::AbstractTag, backend::Val)
    # This is the generic fallback - should never be reached
    throw(Exceptions.IncorrectArgument(
        "Invalid ADNLPModels backend",
        got="backend=$(backend)",
        expected="one of (:default, :optimized, :generic, :enzyme, :zygote, :manual)",
        suggestion="Use :default for general purpose, :optimized for performance, or :enzyme/:zygote for specific AD backends",
        context="Modelers.ADNLP backend validation"
    ))
end

"""
$(TYPEDSIGNATURES)

Validate always-available ADNLP backends using tag dispatch.

# Arguments
- `tag::AbstractTag`: Tag for dispatch (e.g., ADNLPTag, DummyTag)
- `backend::Val{:default}`: Default backend type
- `backend::Val{:optimized}`: Optimized backend type
- `backend::Val{:generic}`: Generic backend type
- `backend::Val{:manual}`: Manual backend type

# Returns
- `Symbol`: Validated backend symbol (unchanged)

# Notes
- These methods handle backends that are always available regardless of extensions
- Uses Julia's multiple dispatch for type-safe validation
- Extensions can override these methods for tag-specific behavior

See also: [`validate_adnlp_backend(::AbstractTag, ::Val{:enzyme})`](@ref), [`get_validate_adnlp_backend`](@ref)
"""
validate_adnlp_backend(tag::AbstractTag, ::Val{:default}) = :default
validate_adnlp_backend(tag::AbstractTag, ::Val{:optimized}) = :optimized
validate_adnlp_backend(tag::AbstractTag, ::Val{:generic}) = :generic
validate_adnlp_backend(tag::AbstractTag, ::Val{:manual}) = :manual

"""
$(TYPEDSIGNATURES)

Validate Enzyme backend using tag dispatch.

# Arguments
- `tag::AbstractTag`: Tag for dispatch (e.g., ADNLPTag, DummyTag)
- `backend::Val{:enzyme}`: Enzyme backend type

# Throws
- `CTBase.Exceptions.ExtensionError`: If CTSolversEnzyme extension is not loaded

# Notes
- Default implementation throws ExtensionError for all tags except ADNLPTag with extension
- CTSolversEnzyme extension overrides this method for ADNLPTag when Enzyme is available
- Provides clear error message directing users to load the extension

See also: [`validate_adnlp_backend(::AbstractTag, ::Val{:zygote})`](@ref), [`get_validate_adnlp_backend`](@ref)
"""
function validate_adnlp_backend(tag::AbstractTag, ::Val{:enzyme})
    throw(Exceptions.ExtensionError(
        :Enzyme;
        message="to use Enzyme backend with ADNLP modeler",
        feature="Enzyme automatic differentiation",
        context="Load Enzyme extension first: using Enzyme"
    ))
end

"""
$(TYPEDSIGNATURES)

Validate Zygote backend using tag dispatch.

# Arguments
- `tag::AbstractTag`: Tag for dispatch (e.g., ADNLPTag, DummyTag)
- `backend::Val{:zygote}`: Zygote backend type

# Throws
- `CTBase.Exceptions.ExtensionError`: If CTSolversZygote extension is not loaded

# Notes
- Default implementation throws ExtensionError for all tags except ADNLPTag with extension
- CTSolversZygote extension overrides this method for ADNLPTag when Zygote is available
- Provides clear error message directing users to load the extension

See also: [`validate_adnlp_backend(::AbstractTag, ::Val{:enzyme})`](@ref), [`get_validate_adnlp_backend`](@ref)
"""
function validate_adnlp_backend(tag::AbstractTag, ::Val{:zygote})
    throw(Exceptions.ExtensionError(
        :Zygote;
        message="to use Zygote backend with ADNLP modeler",
        feature="Zygote automatic differentiation",
        context="Load Zygote extension first: using Zygote"
    ))
end

"""
$(TYPEDSIGNATURES)

Validate that the specified base type is appropriate for ExaModels.

# Arguments
- `T::Type{<:AbstractFloat}`: The floating-point type to validate

# Returns
- `Type{<:AbstractFloat}`: The validated type (unchanged)

# Notes
- Uses Julia's dispatch system for type-safe validation
- Valid types include `Float64`, `Float32`, `Float16`, `BigFloat`
- Invalid types throw `IncorrectArgument` with helpful error message

# Examples
```julia-repl
julia> using CTSolvers.Modelers

julia> validate_exa_base_type(Float64)
Float64

julia> validate_exa_base_type(Float32)
Float32

# Throws IncorrectArgument for invalid types
julia> validate_exa_base_type(Int)
ERROR: Control Toolbox Error
❌ Error: CTBase.Exceptions.IncorrectArgument, Invalid base type for Modelers.Exa
```

See also: [`Modelers.Exa`](@ref)
"""
function validate_exa_base_type(T::Type{<:AbstractFloat})
    return T
end

"""
$(TYPEDSIGNATURES)

Fallback method for invalid base types in ExaModels validation.

# Arguments
- `T::Type`: The type to validate (not a subtype of AbstractFloat)

# Throws
- `CTBase.Exceptions.IncorrectArgument`: Always thrown for invalid types

# Notes
- This method is called when no more specific method matches
- Provides clear error message with suggestions for valid types
- Uses structured exception with got/expected/suggestion fields

See also: [`validate_exa_base_type(::Type{<:AbstractFloat})`](@ref)
"""
function validate_exa_base_type(T)
    throw(Exceptions.IncorrectArgument(
        "Invalid base type for Modelers.Exa",
        got="base_type=$T",
        expected="subtype of AbstractFloat (e.g., Float64, Float32)",
        suggestion="Use Float64 for standard precision or Float32 for GPU performance",
        context="Modelers.Exa base type validation"
    ))
end

"""
$(TYPEDSIGNATURES)

Validate the GPU backend preference.

# Arguments
- `preference::Symbol`: Preferred GPU backend

# Throws
- `CTBase.Exceptions.IncorrectArgument`: If the preference is invalid

# Examples
```julia
validate_gpu_preference(:cuda)
validate_gpu_preference(:rocm)

# Throws CTBase.Exceptions.IncorrectArgument
validate_gpu_preference(:invalid)
```
"""
function validate_gpu_preference(preference::Symbol)
    valid_preferences = (:cuda, :rocm, :oneapi)
    
    if preference ∉ valid_preferences
        throw(Exceptions.IncorrectArgument(
            "Invalid GPU backend preference",
            got="gpu_preference=$preference",
            expected="one of $(valid_preferences)",
            suggestion="Use :cuda for NVIDIA GPUs, :rocm for AMD GPUs, or :oneapi for Intel GPUs",
            context="Modelers.Exa GPU preference validation"
        ))
    end
    
    return preference
end

"""
$(TYPEDSIGNATURES)

Validate the precision mode setting.

# Arguments
- `mode::Symbol`: Precision mode (:standard, :high, :mixed)

# Throws
- `CTBase.Exceptions.IncorrectArgument`: If the mode is invalid

# Examples
```julia
validate_precision_mode(:standard)

# Throws CTBase.Exceptions.IncorrectArgument
validate_precision_mode(:invalid)
```
"""
function validate_precision_mode(mode::Symbol)
    valid_modes = (:standard, :high, :mixed)
    
    if mode ∉ valid_modes
        throw(Exceptions.IncorrectArgument(
            "Invalid precision mode",
            got="precision_mode=$mode",
            expected="one of $(valid_modes)",
            suggestion="Use :standard for default precision, :high for maximum accuracy, or :mixed for performance",
            context="Modelers.Exa precision mode validation"
        ))
    end
    
    # Provide guidance on precision modes
    if mode == :high
        @info "High precision mode may impact performance. Use for problems requiring high numerical accuracy."
    elseif mode == :mixed
        @info "Mixed precision mode can improve performance while maintaining accuracy for many problems."
    end
    
    return mode
end

"""
$(TYPEDSIGNATURES)

Validate that the model name is appropriate.

# Arguments
- `name::String`: The model name to validate

# Throws
- `CTBase.Exceptions.IncorrectArgument`: If the name is invalid

# Examples
```julia
validate_model_name("MyProblem")

# Throws CTBase.Exceptions.IncorrectArgument
validate_model_name("")
```
"""
function validate_model_name(name::String)
    if !isa(name, String)
        throw(Exceptions.IncorrectArgument(
            "Invalid model name type",
            got="name of type $(typeof(name))",
            expected="String",
            suggestion="Provide a non-empty string for the model name",
            context="Model name validation"
        ))
    end
    
    if isempty(name)
        throw(Exceptions.IncorrectArgument(
            "Empty model name",
            got="name=\"\" (empty string)",
            expected="non-empty String",
            suggestion="Provide a descriptive name for your optimization model",
            context="Model name validation"
        ))
    end
    
    # Check for valid characters (alphanumeric, underscore, hyphen)
    if !occursin(r"^[a-zA-Z0-9_-]+$", name)
        @warn "Model name contains special characters. Consider using only letters, numbers, underscores, and hyphens."
    end
    
    return name
end

"""
$(TYPEDSIGNATURES)

Validate matrix-free mode setting and provide recommendations.

# Arguments
- `matrix_free::Bool`: Whether to use matrix-free mode
- `problem_size::Int`: Size of the optimization problem (default: 1000)

# Returns
- `Bool`: Validated matrix-free setting

# Examples
```julia
validate_matrix_free(true, 10_000)
validate_matrix_free(false, 1_000_000)
```
"""
function validate_matrix_free(matrix_free::Bool, problem_size::Int = 1000)
    if !isa(matrix_free, Bool)
        throw(Exceptions.IncorrectArgument(
            "Invalid matrix_free type",
            got="matrix_free of type $(typeof(matrix_free))",
            expected="Bool (true or false)",
            suggestion="Use matrix_free=true for large problems or matrix_free=false for small problems",
            context="Matrix-free mode validation"
        ))
    end
    
    # Provide recommendations based on problem size
    if problem_size > 100_000 && !matrix_free
        @info "Consider using matrix_free=true for large problems (n > 100000) " *
              "to reduce memory usage by 50-80%"
    elseif problem_size < 1_000 && matrix_free
        @info "matrix_free=true may have overhead for small problems. " *
              "Consider matrix_free=false for problems with n < 1000"
    end
    
    return matrix_free
end

"""
$(TYPEDSIGNATURES)

Validate that the optimization direction is a boolean value.

# Arguments
- `minimize::Bool`: The optimization direction to validate

# Throws
- `CTBase.Exceptions.IncorrectArgument`: If the value is not a boolean

# Examples
```julia
validate_optimization_direction(true)
validate_optimization_direction(false)
```
"""
function validate_optimization_direction(minimize::Bool)
    if !isa(minimize, Bool)
        throw(Exceptions.IncorrectArgument(
            "Invalid optimization direction type",
            got="minimize of type $(typeof(minimize))",
            expected="Bool (true for minimization, false for maximization)",
            suggestion="Use minimize=true for minimization problems or minimize=false for maximization problems",
            context="Optimization direction validation"
        ))
    end
    return minimize
end

"""
$(TYPEDSIGNATURES)

Validate that a backend override is either `nothing`, a `Type{<:ADBackend}`, or an `ADBackend` instance.

ADNLPModels.jl accepts both types (to be constructed internally) and pre-constructed instances.

# Arguments
- `backend`: The backend to validate (any value accepted for dispatch)

# Throws
- `CTBase.Exceptions.IncorrectArgument`: If the backend is not `nothing`, a `Type{<:ADBackend}`, or an `ADBackend` instance

# Examples
```julia
validate_backend_override(nothing)
validate_backend_override(ADNLPModels.ForwardDiffADGradient)
validate_backend_override(ADNLPModels.ForwardDiffADGradient())

# Throws CTBase.Exceptions.IncorrectArgument
validate_backend_override("invalid")
```
"""
function validate_backend_override(backend)
    # nothing means "use default backend"
    backend === nothing && return backend
    # Accept a Type that is a subtype of ADBackend (e.g., ForwardDiffADGradient)
    isa(backend, Type) && backend <: ADNLPModels.ADBackend && return backend
    # Accept an ADBackend instance (e.g., ForwardDiffADGradient())
    isa(backend, ADNLPModels.ADBackend) && return backend
    throw(Exceptions.IncorrectArgument(
        "Backend override must be nothing, a Type{<:ADBackend}, or an ADBackend instance",
        got=string(typeof(backend)),
        expected="nothing, Type{<:ADBackend}, or ADBackend instance",
        suggestion="Use nothing for default backend, a Type like ForwardDiffADGradient, or an instance like ForwardDiffADGradient()"
    ))
end
