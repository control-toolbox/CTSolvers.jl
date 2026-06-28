# Solver orchestration
#
# High-level composition: discretized problem → NLP model (via the modeler
# contract) → solver stats (via the solver contract) → problem-level solution.
# The contracts themselves live in `Modelers/contract.jl` and `Solvers/contract.jl`;
# this file only composes them (`__display` is defined alongside the solver contract).

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
