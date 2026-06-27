"""
CommonSolve API implementation for optimization solvers.

Provides unified solve interface for optimization problems at multiple levels:
1. High-level: OptimizationProblem → Solution
2. Mid-level: NLP → ExecutionStats
3. Low-level: Flexible solve with any compatible types
"""

# Default display setting
"""
$(TYPEDSIGNATURES)

Internal helper to define default display behavior.
"""
__display() = true

"""
$(TYPEDSIGNATURES)

High-level solve: Build NLP model, solve it, and build solution.

# Arguments
- `problem::Optimization.AbstractOptimizationProblem`: The optimization problem
- `initial_guess`: Initial guess for the solution
- `modeler::Modelers.AbstractNLPModeler`: Modeler to build NLP
- `solver::AbstractNLPSolver`: Solver to use
- `display::Bool`: Whether to show solver output (default: true)

# Returns
- Solution object from the optimization problem

# Example
```julia
# Conceptual usage pattern
# problem = ...
# x0 = ...
# modeler = Modelers.ADNLP()
# solver = Solvers.Ipopt(max_iter=1000)
# solution = solve(problem, x0, modeler, solver, display=true)
```

See also: `Optimization.build_model`, `Optimization.build_solution`
"""
function CommonSolve.solve(
    problem::Optimization.AbstractOptimizationProblem,
    initial_guess,
    modeler::Modelers.AbstractNLPModeler,
    solver::AbstractNLPSolver;
    display::Bool=__display(),
)
    # Build NLP model (bundled with its immutable build-time cache)
    built = Optimization.build_model(problem, initial_guess, modeler)

    # Solve NLP
    nlp_solution = CommonSolve.solve(built.nlp, solver; display=display)

    # Build OCP solution
    solution = Optimization.build_solution(built, nlp_solution, modeler)

    return solution
end

"""
$(TYPEDSIGNATURES)

Mid-level solve: Solve an NLP problem directly.

# Contract
Concrete solvers implement this method, typically in a backend extension,
dispatching on both the problem type and the solver type, e.g.
`CommonSolve.solve(nlp::NLPModels.AbstractNLPModel, solver::Ipopt; display)` in
the `CTSolversIpopt` extension. This generic stub throws `NotImplemented`.
`NLPModels` is a weak dep — the typed method lives in each solver extension.

# Arguments
- `nlp`: The NLP problem to solve (type depends on backend)
- `solver::AbstractNLPSolver`: Solver to use
- `display::Bool`: Whether to show solver output (default: true)

# Returns
- `SolverCore.AbstractExecutionStats`: Solver execution statistics

See also: `AbstractNLPSolver`
"""
function CommonSolve.solve(
    nlp, solver::AbstractNLPSolver; display::Bool=__display()
)
    throw(
        Exceptions.NotImplemented(
            "Solve not implemented for this solver";
            required_method="CommonSolve.solve(nlp, solver::$(typeof(solver)); display)",
            suggestion="Load the backend extension providing $(typeof(solver)) (e.g. `using NLPModelsIpopt`)",
            context="Solvers.solve - required method implementation",
        ),
    )
end
