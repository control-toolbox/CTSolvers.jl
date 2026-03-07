# DOCP
#
# Defines the `DiscretizedModel` (DOCP) type and implements the
# `Optimization.AbstractOptimizationProblem` contract.

"""
DOCP (Discretized Optimal Control Problem) module.

This module defines the `DiscretizedModel` type and the associated API to build
NLP models and reconstruct OCP solutions via the `Optimization` and `Modelers`
contracts.

The DOCP layer is the bridge between continuous-time models (from `CTModels`) and
the solver/modeler infrastructure provided by CTSolvers.
"""
module DOCP

# Imports
import DocStringExtensions: TYPEDEF, TYPEDSIGNATURES
using NLPModels: NLPModels
using SolverCore: SolverCore
using CTModels: CTModels

# Internal CTSolvers API
using ..CTSolvers.Optimization
using ..CTSolvers.Modelers

# Submodules
include(joinpath(@__DIR__, "types.jl"))
include(joinpath(@__DIR__, "contract_impl.jl"))
include(joinpath(@__DIR__, "accessors.jl"))
include(joinpath(@__DIR__, "building.jl"))

# Public API
export DiscretizedModel
export ocp_model
export nlp_model, ocp_solution

end # module DOCP
