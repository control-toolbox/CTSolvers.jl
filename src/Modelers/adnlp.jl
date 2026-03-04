# ADNLP modeler
#
# Implementation of `Modelers.ADNLP` using the `Strategies.AbstractStrategy`
# contract.

# Default option values
"""
$(TYPEDSIGNATURES)

Return the default automatic differentiation backend for [`Modelers.ADNLP`](@ref).

Default is `:optimized`.
"""
__adnlp_model_backend() = :optimized

"""
$(TYPEDEF)

Modeler for building ADNLPModels from discretized optimal control problems.

This modeler uses the ADNLPModels.jl package to create NLP models with
automatic differentiation support. It provides configurable options for
timing information, AD backend selection, memory optimization, and model
identification.

## Parameterized Types

The modeler supports parameterization for execution backend:
- `ADNLP{CPU}`: CPU execution (default and only supported parameter)

**Note:** Unlike `Exa`, `MadNLP`, and `MadNCL`, this modeler only supports CPU execution.
GPU execution is not available for ADNLP.

# Constructors

```julia
# Default constructor (CPU)
Modelers.ADNLP(; mode::Symbol=:strict, kwargs...)

# Explicit parameter specification (only CPU supported)
Modelers.ADNLP{CPU}(; mode::Symbol=:strict, kwargs...)
```

# Arguments
- `mode::Symbol=:strict`: Validation mode (`:strict` or `:permissive`)
  - `:strict` (default): Rejects unknown options with detailed error message
  - `:permissive`: Accepts unknown options with warning, stores with `:user` source
- `kwargs...`: Modeler options (see Options section)

# Parameter Behavior

## CPU Parameter (Default)

The CPU parameter indicates standard CPU-based execution:
- Uses CPU-optimized automatic differentiation backends
- No GPU acceleration available
- Compatible with all standard Julia environments
- Default AD backend: `:optimized`

# Options

## Basic Options
- `show_time::Bool`: Enable timing information for model building (default: `false`)
- `backend::Symbol`: AD backend to use (default: `:optimized`)
- `matrix_free::Bool`: Enable matrix-free mode (default: `false`)
- `name::String`: Model name for identification (default: `"CTSolvers-ADNLP"`)

## Advanced Backend Overrides (expert users)

Each backend option accepts `nothing` (use default), a `Type{<:ADBackend}` (constructed by ADNLPModels),
or an `ADBackend` instance (used directly).

- `gradient_backend`: Override backend for gradient computation
- `hprod_backend`: Override backend for Hessian-vector product
- `jprod_backend`: Override backend for Jacobian-vector product
- `jtprod_backend`: Override backend for transpose Jacobian-vector product
- `jacobian_backend`: Override backend for Jacobian matrix computation
- `hessian_backend`: Override backend for Hessian matrix computation
- `ghjvprod_backend`: Override backend for g^T ∇²c(x)v computation

# Examples

## Basic Usage
```julia
# Default modeler (CPU)
modeler = Modelers.ADNLP()

# Explicit CPU specification
modeler = Modelers.ADNLP{CPU}()

# With custom options
modeler = Modelers.ADNLP(
    backend=:optimized,
    matrix_free=true,
    name="MyOptimizationProblem"
)
```

## Invalid Usage
```julia
# GPU is NOT supported - will throw IncorrectArgument
modeler = Modelers.ADNLP{GPU}()  # ❌ Error!
```

## Advanced Backend Configuration
```julia
# Override with nothing (use default)
modeler = Modelers.ADNLP(
    gradient_backend=nothing,
    hessian_backend=nothing
)

# Override with a Type (ADNLPModels constructs it)
modeler = Modelers.ADNLP(
    gradient_backend=ADNLPModels.ForwardDiffADGradient
)

# Override with an instance (used directly)
modeler = Modelers.ADNLP(
    gradient_backend=ADNLPModels.ForwardDiffADGradient()
)
```

## Validation Modes
```julia
# Strict mode (default) - rejects unknown options
modeler = Modelers.ADNLP(backend=:optimized)

# Permissive mode - accepts unknown options with warning
modeler = Modelers.ADNLP(
    backend=:optimized,
    custom_option=123;
    mode=:permissive
)
```

# Throws

- `CTBase.Exceptions.IncorrectArgument`: If GPU or other unsupported parameter is specified
- `CTBase.Exceptions.IncorrectArgument`: If option validation fails
- `CTBase.Exceptions.IncorrectArgument`: If invalid mode is provided

# See also

- [`CPU`](@ref): CPU parameter type
- [`Modelers.Exa`](@ref): Alternative modeler using ExaModels (supports GPU)
- [`Optimization.build_model`](@ref): Build a backend NLP model from a problem and a modeler
- [`Optimization.build_solution`](@ref): Build a problem-level solution from execution statistics

# Notes

- The `backend` option supports: `:default`, `:optimized`, `:generic`, `:enzyme`, `:zygote`
- Advanced backend overrides are for expert users only
- Matrix-free mode reduces memory usage but may increase computation time
- Model name is used for identification in solver output

# References

- ADNLPModels.jl: [https://github.com/JuliaSmoothOptimizers/ADNLPModels.jl](https://github.com/JuliaSmoothOptimizers/ADNLPModels.jl)
- Automatic Differentiation in Julia: [https://github.com/JuliaDiff/](https://github.com/JuliaDiff/)
"""
struct ADNLP{P<:AbstractStrategyParameter} <: AbstractNLPModeler
    "Solver configuration options containing validated option values"
    options::Strategies.StrategyOptions
end

# Strategy identification
Strategies.id(::Type{<:Modelers.ADNLP}) = :adnlp

"""
$(TYPEDSIGNATURES)

Default parameter type for ADNLP when not explicitly specified.

Returns `CPU` as the default execution parameter.

# Implementation Notes

This method is part of the `AbstractStrategy` parameter contract and must be
implemented by all parameterized strategies.

See also: [`ADNLP`](@ref), [`CPU`](@ref), [`_supported_parameters`](@ref)
"""
Strategies._default_parameter(::Type{<:Modelers.ADNLP}) = CPU

"""
$(TYPEDSIGNATURES)

Supported parameter types for ADNLP.

Returns a tuple of parameter types that this strategy accepts. ADNLP
only supports CPU execution.

# Implementation Notes

This method is part of the `AbstractStrategy` parameter contract and must be
implemented by all parameterized strategies.

See also: [`ADNLP`](@ref), [`CPU`](@ref), [`GPU`](@ref), [`_default_parameter`](@ref)
"""
Strategies._supported_parameters(::Type{<:Modelers.ADNLP}) = (CPU,)

# Strategy metadata with option definitions (parameterized)
function Strategies.metadata(::Type{<:Modelers.ADNLP{P}}) where {P<:AbstractStrategyParameter}
    # Validate parameter support
    validate_supported_parameter(Modelers.ADNLP, P)
    return Strategies.StrategyMetadata(
        # === Existing Options (unchanged) ===
        Strategies.OptionDefinition(;
            name=:show_time,
            type=Bool,
            default=Options.NotProvided,
            description="Whether to show timing information while building the ADNLP model"
        ),
        Strategies.OptionDefinition(;
            name=:backend,
            type=Symbol,
            default=__adnlp_model_backend(),
            description="Automatic differentiation backend used by ADNLPModels",
            validator=validate_adnlp_backend,
            aliases=(:adnlp_backend,)
        ),
        
        # === New High-Priority Options ===
        Strategies.OptionDefinition(;
            name=:matrix_free,
            type=Bool,
            default=Options.NotProvided,
            description="Enable matrix-free mode (avoids explicit Hessian/Jacobian matrices)",
            validator=validate_matrix_free
        ),
        Strategies.OptionDefinition(;
            name=:name,
            type=String,
            default=Options.NotProvided,
            description="Name of the optimization model for identification",
            validator=validate_model_name
        ),
        # NOTE: minimize option is commented out as it will be automatically set
        # when building the model based on the problem structure
        # Strategies.OptionDefinition(;
        #     name=:minimize,
        #     type=Bool,
        #     default=Options.NotProvided,
        #     description="Optimization direction (true for minimization, false for maximization)",
        #     validator=validate_optimization_direction
        # ),
        
        # === Advanced Backend Overrides (expert users) ===
        Strategies.OptionDefinition(;
            name=:gradient_backend,
            type=Union{Nothing, Type{<:ADNLPModels.ADBackend}, ADNLPModels.ADBackend},
            default=Options.NotProvided,
            description="Override backend for gradient computation (advanced users only)",
            validator=validate_backend_override
        ),
        Strategies.OptionDefinition(;
            name=:hprod_backend,
            type=Union{Nothing, Type{<:ADNLPModels.ADBackend}, ADNLPModels.ADBackend},
            default=Options.NotProvided,
            description="Override backend for Hessian-vector product (advanced users only)",
            validator=validate_backend_override
        ),
        Strategies.OptionDefinition(;
            name=:jprod_backend,
            type=Union{Nothing, Type{<:ADNLPModels.ADBackend}, ADNLPModels.ADBackend},
            default=Options.NotProvided,
            description="Override backend for Jacobian-vector product (advanced users only)",
            validator=validate_backend_override
        ),
        Strategies.OptionDefinition(;
            name=:jtprod_backend,
            type=Union{Nothing, Type{<:ADNLPModels.ADBackend}, ADNLPModels.ADBackend},
            default=Options.NotProvided,
            description="Override backend for transpose Jacobian-vector product (advanced users only)",
            validator=validate_backend_override
        ),
        Strategies.OptionDefinition(;
            name=:jacobian_backend,
            type=Union{Nothing, Type{<:ADNLPModels.ADBackend}, ADNLPModels.ADBackend},
            default=Options.NotProvided,
            description="Override backend for Jacobian matrix computation (advanced users only)",
            validator=validate_backend_override
        ),
        Strategies.OptionDefinition(;
            name=:hessian_backend,
            type=Union{Nothing, Type{<:ADNLPModels.ADBackend}, ADNLPModels.ADBackend},
            default=Options.NotProvided,
            description="Override backend for Hessian matrix computation (advanced users only)",
            validator=validate_backend_override
        ),
        Strategies.OptionDefinition(;
            name=:ghjvprod_backend,
            type=Union{Nothing, Type{<:ADNLPModels.ADBackend}, ADNLPModels.ADBackend},
            default=Options.NotProvided,
            description="Override backend for g^T ∇²c(x)v computation (advanced users only)",
            validator=validate_backend_override
        )
        
        # # === Advanced Backend Overrides for NLS (expert users) ===
        # Strategies.OptionDefinition(;
        #     name=:hprod_residual_backend,
        #     type=Union{Nothing, Type{<:ADNLPModels.ADBackend}, ADNLPModels.ADBackend},
        #     default=Options.NotProvided,
        #     description="Override backend for Hessian-vector product of residuals (NLS) (advanced users only)",
        #     validator=validate_backend_override
        # ),
        # Strategies.OptionDefinition(;
        #     name=:jprod_residual_backend,
        #     type=Union{Nothing, Type{<:ADNLPModels.ADBackend}, ADNLPModels.ADBackend},
        #     default=Options.NotProvided,
        #     description="Override backend for Jacobian-vector product of residuals (NLS) (advanced users only)",
        #     validator=validate_backend_override
        # ),
        # Strategies.OptionDefinition(;
        #     name=:jtprod_residual_backend,
        #     type=Union{Nothing, Type{<:ADNLPModels.ADBackend}, ADNLPModels.ADBackend},
        #     default=Options.NotProvided,
        #     description="Override backend for transpose Jacobian-vector product of residuals (NLS) (advanced users only)",
        #     validator=validate_backend_override
        # ),
        # Strategies.OptionDefinition(;
        #     name=:jacobian_residual_backend,
        #     type=Union{Nothing, Type{<:ADNLPModels.ADBackend}, ADNLPModels.ADBackend},
        #     default=Options.NotProvided,
        #     description="Override backend for Jacobian matrix of residuals (NLS) (advanced users only)",
        #     validator=validate_backend_override
        # ),
        # Strategies.OptionDefinition(;
        #     name=:hessian_residual_backend,
        #     type=Union{Nothing, Type{<:ADNLPModels.ADBackend}, ADNLPModels.ADBackend},
        #     default=Options.NotProvided,
        #     description="Override backend for Hessian matrix of residuals (NLS) (advanced users only)",
        #     validator=validate_backend_override
        # )
    )
end

# Fallback metadata for non-parameterized type (delegates to CPU)
function Strategies.metadata(::Type{Modelers.ADNLP})
    return Strategies.metadata(Modelers.ADNLP{Strategies._default_parameter(Modelers.ADNLP)})
end

# Constructor with option validation
"""
$(TYPEDSIGNATURES)

Create an Modelers.ADNLP with validated options.

# Arguments
- `mode::Symbol=:strict`: Validation mode (`:strict` or `:permissive`)
  - `:strict` (default): Rejects unknown options with detailed error message
  - `:permissive`: Accepts unknown options with warning, stores with `:user` source
- `kwargs...`: Modeler options (see [`Modelers.ADNLP`](@ref) documentation)

# Returns
- `Modelers.ADNLP`: Configured modeler instance

# Examples
```julia
# Default modeler
modeler = Modelers.ADNLP()

# With custom options
modeler = Modelers.ADNLP(backend=:optimized, matrix_free=true)

# With permissive mode
modeler = Modelers.ADNLP(backend=:optimized, custom_option=123; mode=:permissive)
```

# Throws

- `CTBase.Exceptions.IncorrectArgument`: If option validation fails
- `CTBase.Exceptions.IncorrectArgument`: If invalid mode is provided

# See also

- [`Modelers.ADNLP`](@ref): Type documentation
- [`Strategies.build_strategy_options`](@ref): Option validation function
"""
function Modelers.ADNLP(; mode::Symbol=:strict, kwargs...)
    # Check for deprecated aliases
    if haskey(kwargs, :adnlp_backend)
        @warn "adnlp_backend is deprecated, use backend instead" maxlog=1
    end
    
    opts = Strategies.build_strategy_options(
        Modelers.ADNLP{CPU}; mode=mode, kwargs...
    )
    return Modelers.ADNLP{Strategies._default_parameter(Modelers.ADNLP)}(opts)
end

# Parameterized constructor
function Modelers.ADNLP{P}(; mode::Symbol=:strict, kwargs...) where {P<:AbstractStrategyParameter}
    # Validate parameter support
    validate_supported_parameter(Modelers.ADNLP, P)
    
    # Check for deprecated aliases
    if haskey(kwargs, :adnlp_backend)
        @warn "adnlp_backend is deprecated, use backend instead" maxlog=1
    end
    
    opts = Strategies.build_strategy_options(
        Modelers.ADNLP{P}; mode=mode, kwargs...
    )
    return Modelers.ADNLP{P}(opts)
end

# Access to strategy options
Strategies.options(m::Modelers.ADNLP) = m.options

# Model building interface
"""
$(TYPEDSIGNATURES)

Build an ADNLPModel from a discretized optimal control problem.

# Arguments
- `modeler::Modelers.ADNLP`: Configured modeler instance
- `prob::AbstractOptimizationProblem`: Discretized optimal control problem
- `initial_guess`: Initial guess for optimization variables

# Returns
- `ADNLPModels.ADNLPModel`: Built NLP model

# Examples
```julia
# Create modeler
modeler = Modelers.ADNLP(backend=:optimized)

# Build model from problem
nlp = modeler(problem, initial_guess)

# Solve the model
stats = solve(nlp, solver)
```

# See also

- [`Modelers.ADNLP`](@ref): Type documentation
- [`build_model`](@ref): Generic model building interface
- [`ADNLPModels.ADNLPModel`](@ref): NLP model type
"""
function (modeler::Modelers.ADNLP)(
    prob::AbstractOptimizationProblem,
    initial_guess
)::ADNLPModels.ADNLPModel
    # Get the appropriate builder for this problem type
    builder = get_adnlp_model_builder(prob)
    
    # Extract options as Dict
    options = Strategies.options_dict(modeler)
    
    # Build the ADNLP model passing all options generically
    return builder(initial_guess; options...)
end

# Solution building interface
"""
$(TYPEDSIGNATURES)

Build a solution object from NLP solver statistics.

# Arguments
- `modeler::Modelers.ADNLP`: Configured modeler instance
- `prob::AbstractOptimizationProblem`: Original optimization problem
- `nlp_solution::SolverCore.AbstractExecutionStats`: NLP solver statistics

# Returns
- Solution object appropriate for the problem type

# Examples
```julia
# Create modeler and solve
modeler = Modelers.ADNLP()
nlp = modeler(problem, initial_guess)
stats = solve(nlp, solver)

# Build solution object
solution = modeler(problem, stats)
```

# See also

- [`Modelers.ADNLP`](@ref): Type documentation
- [`SolverCore.AbstractExecutionStats`](@ref): Solver statistics type
- [`solve`](@ref): Generic solve interface
"""
function (modeler::Modelers.ADNLP)(
    prob::AbstractOptimizationProblem,
    nlp_solution::SolverCore.AbstractExecutionStats
)
    # Get the appropriate solution builder for this problem type
    builder = get_adnlp_solution_builder(prob)
    return builder(nlp_solution)
end
