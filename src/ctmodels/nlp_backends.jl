# ------------------------------------------------------------------------------
# Model backends
# ------------------------------------------------------------------------------
abstract type AbstractOptimizationModeler end

function _options(modeler::AbstractOptimizationModeler)
    throw(
        CTBase.NotImplemented("_options not implemented for $(typeof(modeler))"),
    )
end

function _option_sources(modeler::AbstractOptimizationModeler)
    throw(
        CTBase.NotImplemented("_option_sources not implemented for $(typeof(modeler))"),
    )
end

# ------------------------------------------------------------------------------
# ADNLPModels
# ------------------------------------------------------------------------------
struct ADNLPModeler{Vals,Srcs} <: AbstractOptimizationModeler
    options_values::Vals
    options_sources::Srcs
end

function ADNLPModeler(; kwargs...)
    defaults = (
        show_time=__adnlp_model_show_time(),
        backend=__adnlp_model_backend(),
    )
    user_nt = NamedTuple(kwargs)
    values = merge(defaults, user_nt)

    src_pairs = Pair{Symbol,Symbol}[]
    for name in keys(values)
        src = haskey(user_nt, name) ? :user : :ct_default
        push!(src_pairs, name => src)
    end
    sources = (; src_pairs...)

    return ADNLPModeler{typeof(values),typeof(sources)}(values, sources)
end

function _options(modeler::ADNLPModeler)
    return modeler.options_values
end

function _option_sources(modeler::ADNLPModeler)
    return modeler.options_sources
end

function (modeler::ADNLPModeler)(
    prob::AbstractOptimizationProblem, 
    initial_guess,
)::ADNLPModels.ADNLPModel
    vals = _options(modeler)
    builder = get_adnlp_model_builder(prob)
    return builder(initial_guess; vals...)
end

function (modeler::ADNLPModeler)(
    prob::AbstractOptimizationProblem, 
    nlp_solution::SolverCore.AbstractExecutionStats
)
    builder = get_adnlp_solution_builder(prob)
    return builder(nlp_solution)
end

# ------------------------------------------------------------------------------
# ExaModels
# ------------------------------------------------------------------------------
struct ExaModeler{
    BaseType<:AbstractFloat,Vals,Srcs
} <: AbstractOptimizationModeler
    options_values::Vals
    options_sources::Srcs
end

function ExaModeler(; kwargs...)
    defaults = (
        base_type=__exa_model_base_type(),
        backend=__exa_model_backend(),
    )
    user_nt = NamedTuple(kwargs)
    values = merge(defaults, user_nt)

    src_pairs = Pair{Symbol,Symbol}[]
    for name in keys(values)
        src = haskey(user_nt, name) ? :user : :ct_default
        push!(src_pairs, name => src)
    end
    sources = (; src_pairs...)

    BaseType = values.base_type
    return ExaModeler{BaseType,typeof(values),typeof(sources)}(values, sources)
end

function _options(modeler::ExaModeler)
    return modeler.options_values
end

function _option_sources(modeler::ExaModeler)
    return modeler.options_sources
end

function (modeler::ExaModeler{BaseType})(
    prob::AbstractOptimizationProblem, 
    initial_guess,
)::ExaModels.ExaModel{BaseType} where {BaseType<:AbstractFloat}
    vals = _options(modeler)
    backend = vals.backend
    extra_pairs = Pair{Symbol,Any}[]
    for (k, v) in pairs(vals)
        if k === :base_type || k === :backend
            continue
        end
        push!(extra_pairs, k => v)
    end
    builder = get_exa_model_builder(prob)
    return builder(BaseType, initial_guess; backend=backend, extra_pairs...)
end

function (modeler::ExaModeler)(
    prob::AbstractOptimizationProblem, 
    nlp_solution::SolverCore.AbstractExecutionStats,
)
    builder = get_exa_solution_builder(prob)
    return builder(nlp_solution)
end
