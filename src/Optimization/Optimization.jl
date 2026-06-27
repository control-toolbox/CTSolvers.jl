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
"""
module Optimization

# Imports
import CTBase.Exceptions
import DocStringExtensions: TYPEDEF, TYPEDSIGNATURES
using SolverCore: SolverCore

# Submodules
include(joinpath(@__DIR__, "abstract_types.jl"))
include(joinpath(@__DIR__, "building.jl"))
include(joinpath(@__DIR__, "solver_info.jl"))

# Public API - Abstract types
export AbstractOptimizationProblem

# Public API - Model building functions
export build_model, build_solution

# Public API - Solver utilities
export extract_solver_infos

end # module Optimization
