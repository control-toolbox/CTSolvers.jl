# DOCP Module
#
# This module provides the DiscretizedOptimalControlProblem type and implements
# the AbstractOptimizationProblem contract.
#
# Author: CTSolvers Development Team
# Date: 2026-01-26

module DOCP

using DocStringExtensions
using NLPModels
using SolverCore
using CTModels: AbstractOptimalControlProblem
using ..CTSolvers.Optimization: AbstractOptimizationProblem
using ..CTSolvers.Optimization: AbstractBuilder, AbstractModelBuilder, AbstractSolutionBuilder
using ..CTSolvers.Optimization: AbstractOCPSolutionBuilder
using ..CTSolvers.Optimization: build_model, build_solution
import ..CTSolvers.Optimization: get_adnlp_model_builder, get_exa_model_builder
import ..CTSolvers.Optimization: get_adnlp_solution_builder, get_exa_solution_builder

# Include submodules
include(joinpath(@__DIR__, "types.jl"))
include(joinpath(@__DIR__, "contract_impl.jl"))
include(joinpath(@__DIR__, "accessors.jl"))
include(joinpath(@__DIR__, "building.jl"))

# Public API
export DiscretizedOptimalControlProblem
export ocp_model
export nlp_model, ocp_solution

end # module DOCP
