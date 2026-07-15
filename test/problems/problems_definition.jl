# Helper optimization problem type used by benchmark test problems.
#
# `OptimizationProblem` wraps the per-backend model builders as plain functions
# and implements the CTSolvers `build_model` / `build_solution` contract by
# multiple dispatch on the modeler type.

import CTSolvers.Optimization
import CTSolvers.Modelers
import CTBase.Strategies

struct OptimizationProblem{A,E} <: CTSolvers.AbstractOptimizationProblem
    build_adnlp_model::A
    build_exa_model::E
end

# Build the ADNLP model from the wrapped builder, forwarding all modeler options.
function Optimization.build_model(
    prob::OptimizationProblem, initial_guess, modeler::Modelers.ADNLP
)
    options = Strategies.options_dict(modeler)
    nlp = prob.build_adnlp_model(initial_guess; options...)
    return Optimization.BuiltModel(prob, nlp, Optimization.NoCache())
end

# Build the Exa model from the wrapped builder, using the modeler base type and
# forwarding all remaining options (e.g. backend).
function Optimization.build_model(
    prob::OptimizationProblem, initial_guess, modeler::Modelers.Exa
)
    options = Strategies.options_dict(modeler)
    base_type = pop!(options, :base_type)
    nlp = prob.build_exa_model(base_type, initial_guess; options...)
    return Optimization.BuiltModel(prob, nlp, Optimization.NoCache())
end

# These benchmark problems return the raw NLP solver statistics as the solution.
function Optimization.build_solution(
    ::Optimization.BuiltModel{<:OptimizationProblem},
    nlp_solution::SolverCore.AbstractExecutionStats,
    ::Modelers.AbstractNLPModeler,
)
    return nlp_solution
end

#
struct DummyProblem <: CTSolvers.AbstractOptimizationProblem end
