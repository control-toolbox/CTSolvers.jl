# DOCP
 #
 # Defines the `DiscretizedModel` (DOCP) type and implements the
 # `Optimization.AbstractOptimizationProblem` contract.
 
 module DOCP
 
 # Imports
 import DocStringExtensions: TYPEDEF, TYPEDSIGNATURES
 import NLPModels
 import SolverCore
 import CTModels
 
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
