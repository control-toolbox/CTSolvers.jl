# Solver contract
#
# Canonical contract for solver strategies: the mid-level `CommonSolve.solve(nlp,
# solver)` method, dispatched on `AbstractNLPSolver`. This is a `NotImplemented`
# stub; the typed method (on the external NLP format) lives in each backend
# extension (e.g. `CTSolversIpopt`). Also defines `__display`, the default
# display setting shared by the contract stub and the orchestrator.

"""
$(TYPEDSIGNATURES)

Internal helper defining the default solver-display behavior.
"""
__display() = true

"""
$(TYPEDSIGNATURES)

Mid-level solve: solve an NLP problem directly with a solver strategy.

# Contract
Concrete solvers implement this method, typically in a backend extension,
dispatching on both the problem type and the solver type, e.g.
`CommonSolve.solve(nlp::NLPModels.AbstractNLPModel, solver::Ipopt; display)` in
the `CTSolversIpopt` extension. This generic stub throws `NotImplemented`.
`NLPModels` is a weak dep — the typed method lives in each solver extension.

# Arguments
- `nlp`: The NLP problem to solve (type depends on backend).
- `solver::AbstractNLPSolver`: Solver to use.
- `display::Bool`: Whether to show solver output (default: `true`).

# Returns
- `SolverCore.AbstractExecutionStats`: Solver execution statistics.

# Throws
- [`CTBase.Exceptions.NotImplemented`](@extref): until a backend extension provides
  the typed method.

See also: `AbstractNLPSolver`.
"""
function CommonSolve.solve(nlp, solver::AbstractNLPSolver; display::Bool=__display())
    return throw(
        Exceptions.NotImplemented(
            "Solve not implemented for this solver";
            required_method="CommonSolve.solve(nlp, solver::$(typeof(solver)); display)",
            suggestion="Load the backend extension providing $(typeof(solver)) (e.g. `using NLPModelsIpopt`)",
            context="Solvers.solve - required method implementation",
        ),
    )
end
