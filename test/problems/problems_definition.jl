# Helper optimization problem type used by benchmark test problems.
#
# `OptimizationProblem` wraps the per-backend model builders as plain functions
# and implements the CTSolvers `build_model` / `build_solution` contract by
# multiple dispatch on the modeler type.

import CTSolvers.Optimization
import CTSolvers.Modelers

struct OptimizationProblem{A,E} <: CTSolvers.AbstractOptimizationProblem
    build_adnlp_model::A
    build_exa_model::E
end

# Build the ADNLP model from the wrapped builder.
function Optimization.build_model(
    prob::OptimizationProblem, initial_guess, ::Modelers.ADNLP
)
    return prob.build_adnlp_model(initial_guess)
end

# Build the Exa model from the wrapped builder, using the modeler base type.
function Optimization.build_model(
    prob::OptimizationProblem, initial_guess, modeler::Modelers.Exa
)
    return prob.build_exa_model(modeler[:base_type], initial_guess)
end

# These benchmark problems return the raw NLP solver statistics as the solution.
function Optimization.build_solution(
    ::OptimizationProblem,
    nlp_solution::SolverCore.AbstractExecutionStats,
    ::Modelers.AbstractNLPModeler,
)
    return nlp_solution
end

#
struct DummyProblem <: CTSolvers.AbstractOptimizationProblem end
