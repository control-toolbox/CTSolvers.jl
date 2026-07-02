# Generic build functions (declarations)
#
# `Optimization` owns and re-exports the generic functions `build_model` and
# `build_solution`. They are *declared* here so the binding exists and the export is
# valid. The canonical `NotImplemented` contract stubs — with method-level docstrings —
# live in `Modelers/contract.jl`; concrete methods live in the package providing the
# problem (e.g. CTDirect).

"""
Build a backend NLP model from an optimization problem and an initial guess.

Generic function for the model-building contract. Concrete methods must be provided
by the package supplying the optimization problem (e.g. CTDirect for
[`CTSolvers.DOCP.DiscretizedModel`](@ref)), dispatching on the concrete
`(problem, modeler)` pair.

# Arguments
- `prob::CTSolvers.Optimization.AbstractOptimizationProblem`: The optimization problem.
- `initial_guess`: Initial guess passed to the NLP backend.
- `modeler::CTSolvers.Modelers.AbstractNLPModeler`: The modeler strategy (e.g. `ADNLP`, `Exa`).

# Returns
- [`CTSolvers.Optimization.BuiltModel`](@ref): immutable bundle of the problem, the
  backend NLP model, and an optional build-time cache.

# Throws
- [`CTBase.Exceptions.NotImplemented`](@extref): when no concrete method exists for
  this `(problem, modeler)` pair.

See also: [`CTSolvers.Optimization.build_solution`](@ref), [`CTSolvers.Optimization.BuiltModel`](@ref).
"""
function build_model end

"""
Build a problem-level solution from NLP solver statistics.

Generic function for the solution-building contract. Concrete methods must be provided
by the package supplying the optimization problem, dispatching on the concrete
`(built, modeler)` pair.

# Arguments
- `built::CTSolvers.Optimization.BuiltModel`: The bundle returned by
  [`CTSolvers.Optimization.build_model`](@ref).
- `model_solution`: NLP solver output (execution statistics from SolverCore).
- `modeler::CTSolvers.Modelers.AbstractNLPModeler`: The modeler strategy used to build.

# Returns
- A solution object appropriate for the problem type.

# Throws
- [`CTBase.Exceptions.NotImplemented`](@extref): when no concrete method exists for
  this `(built, modeler)` pair.

See also: [`CTSolvers.Optimization.build_model`](@ref), [`CTSolvers.Optimization.BuiltModel`](@ref).
"""
function build_solution end
