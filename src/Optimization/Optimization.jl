# Optimization
#
# General optimization problem types, builders, and the
# `AbstractOptimizationProblem` contract.

"""
Optimization module.

This module defines the abstract optimization problem interface
(`AbstractOptimizationProblem`) together with the builder pattern used by
modelers:
- model builders construct backend NLP models from an initial guess
- solution builders convert solver statistics into domain-level solutions

The functions `build_model` and `build_solution` provide a backend-agnostic API
delegating the actual work to the selected modeler strategy.
"""
module Optimization

# Imports
import CTBase.Exceptions
import DocStringExtensions: TYPEDEF, TYPEDSIGNATURES
import NLPModels
import SolverCore

# Submodules
include(joinpath(@__DIR__, "abstract_types.jl"))
include(joinpath(@__DIR__, "builders.jl"))
include(joinpath(@__DIR__, "contract.jl"))
include(joinpath(@__DIR__, "building.jl"))
include(joinpath(@__DIR__, "solver_info.jl"))

# Public API - Abstract types
export AbstractOptimizationProblem
export AbstractBuilder, AbstractModelBuilder, AbstractSolutionBuilder
export AbstractOCPSolutionBuilder

# Public API - Concrete builder types
export ADNLPModelBuilder, ExaModelBuilder
export ADNLPSolutionBuilder, ExaSolutionBuilder

# Public API - Contract functions
export get_adnlp_model_builder, get_exa_model_builder
export get_adnlp_solution_builder, get_exa_solution_builder

# Public API - Model building functions
export build_model, build_solution

# Public API - Solver utilities
export extract_solver_infos

end # module Optimization
