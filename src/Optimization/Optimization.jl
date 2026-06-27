# Optimization
#
# General optimization problem types, builders, and the
# `AbstractOptimizationProblem` contract.

"""
Optimization module.

This module defines the abstract optimization problem interface
(`AbstractOptimizationProblem`) and the backend-agnostic model/solution building
contract (`build_model` / `build_solution`). Concrete problem types (e.g.
`DiscretizedModel`) and the packages providing them implement these by multiple
dispatch on `(problem, modeler)`.

Solver-side utilities (e.g. `extract_solver_infos`) live in `Solvers`.
"""
module Optimization

# Imports
import CTBase.Core
import CTBase.Exceptions
import DocStringExtensions: TYPEDEF, TYPEDSIGNATURES
using SolverCore: SolverCore

# Submodules
include(joinpath(@__DIR__, "abstract_types.jl"))
include(joinpath(@__DIR__, "built_model.jl"))
include(joinpath(@__DIR__, "building.jl"))

# Public API - Abstract types
export AbstractOptimizationProblem

# Public API - Built model bundle
export BuiltModel, NoCache

# Public API - Model building functions
export build_model, build_solution

end # module Optimization
