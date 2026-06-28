# Optimization
#
# General optimization problem types, builders, and the
# `AbstractOptimizationProblem` contract.

"""
Optimization module.

This module defines the abstract optimization problem interface
(`AbstractOptimizationProblem`) and the value types of the model/solution building
contract (`BuiltModel`, `NoCache`). The generic `build_model` / `build_solution`
functions are *owned* here (and re-exported) but their canonical `NotImplemented`
stubs — the modeler contract — live in `Modelers` (`Modelers/contract.jl`), typed on
`AbstractNLPModeler`; concrete methods live in the package providing the problem
(e.g. CTDirect), dispatched on `(problem, modeler)`.

Solver-side utilities (e.g. `extract_solver_infos`) live in `Solvers`.
"""
module Optimization

# Imports
import CTBase.Core
import DocStringExtensions: TYPEDEF

# Submodules
include(joinpath(@__DIR__, "abstract_types.jl"))
include(joinpath(@__DIR__, "built_model.jl"))
# Declares the generic `build_model` / `build_solution`; contract stubs live in Modelers.
include(joinpath(@__DIR__, "building.jl"))

# Public API - Abstract types
export AbstractOptimizationProblem

# Public API - Built model bundle
export BuiltModel, NoCache

# Public API - Model building functions
# (declared in `building.jl`; contract stubs in `Modelers/contract.jl`)
export build_model, build_solution

end # module Optimization
