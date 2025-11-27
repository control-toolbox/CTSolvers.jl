# ------------------------------------------------------------------------------
# Discretized optimal control problem
# ------------------------------------------------------------------------------
# Helpers
abstract type AbstractOCPSolutionBuilder <: AbstractSolutionBuilder end

struct ADNLPSolutionBuilder{T<:Function} <: AbstractOCPSolutionBuilder
    f::T
end
function (builder::ADNLPSolutionBuilder)(nlp_solution::SolverCore.AbstractExecutionStats)
    return builder.f(nlp_solution)
end

struct ExaSolutionBuilder{T<:Function} <: AbstractOCPSolutionBuilder
    f::T
end
function (builder::ExaSolutionBuilder)(nlp_solution::SolverCore.AbstractExecutionStats)
    return builder.f(nlp_solution)
end

# Problem
struct DiscretizedOptimalControlProblem{
    TO<:AbstractOptimalControlProblem,TB<:NamedTuple,TS<:NamedTuple
} <: AbstractOptimizationProblem
    optimal_control_problem::TO
    model_builders::TB
    solution_builders::TS
    function DiscretizedOptimalControlProblem(
        optimal_control_problem::TO, model_builders::TB, solution_builders::TS
    ) where {TO<:AbstractOptimalControlProblem,TB<:NamedTuple,TS<:NamedTuple}
        return new{TO,TB,TS}(optimal_control_problem, model_builders, solution_builders)
    end
    # Convenience constructor from Tuple-of-Pairs (backwards compatible)
    function DiscretizedOptimalControlProblem(
        optimal_control_problem::AbstractOptimalControlProblem,
        model_builders::Tuple{Vararg{Pair{Symbol,<:AbstractModelBuilder}}},
        solution_builders::Tuple{Vararg{Pair{Symbol,<:AbstractOCPSolutionBuilder}}},
    )
        return DiscretizedOptimalControlProblem(
            optimal_control_problem, (; model_builders...), (; solution_builders...)
        )
    end
    function DiscretizedOptimalControlProblem(
        optimal_control_problem::AbstractOptimalControlProblem,
        adnlp_model_builder::ADNLPModelBuilder,
        exa_model_builder::ExaModelBuilder,
        adnlp_solution_builder::ADNLPSolutionBuilder,
        exa_solution_builder::ExaSolutionBuilder,
    )
        return DiscretizedOptimalControlProblem(
            optimal_control_problem,
            (; adnlp=adnlp_model_builder, exa=exa_model_builder),
            (; adnlp=adnlp_solution_builder, exa=exa_solution_builder),
        )
    end
end

function ocp_model(prob::DiscretizedOptimalControlProblem)
    return prob.optimal_control_problem
end

function get_adnlp_model_builder(prob::DiscretizedOptimalControlProblem)
    for (name, builder) in pairs(prob.model_builders)
        if name === :adnlp
            return builder
        end
    end
    throw(ArgumentError("no :adnlp model builder registered"))
end

function get_exa_model_builder(prob::DiscretizedOptimalControlProblem)
    for (name, builder) in pairs(prob.model_builders)
        if name === :exa
            return builder
        end
    end
    throw(ArgumentError("no :exa model builder registered"))
end

function get_adnlp_solution_builder(prob::DiscretizedOptimalControlProblem)
    for (name, builder) in pairs(prob.solution_builders)
        if name === :adnlp
            return builder
        end
    end
    throw(ArgumentError("no :adnlp solution builder registered"))
end

function get_exa_solution_builder(prob::DiscretizedOptimalControlProblem)
    for (name, builder) in pairs(prob.solution_builders)
        if name === :exa
            return builder
        end
    end
    throw(ArgumentError("no :exa solution builder registered"))
end
