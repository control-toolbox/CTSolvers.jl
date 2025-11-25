module CTSolvers

using ADNLPModels
using CommonSolve: CommonSolve, solve
using CTBase: CTBase
using CTDirect: CTDirect
using CTModels: CTModels
using ExaModels
using KernelAbstractions
using NLPModels
using SolverCore
using CTParser: CTParser
using MLStyle: @match

#
const AbstractOptimalControlProblem = CTModels.AbstractModel
const AbstractOptimalControlSolution = CTModels.AbstractSolution

# Public API
export @init

# Model
include(joinpath("ctmodels", "options_schema.jl"))
include(joinpath("ctmodels", "default.jl"))
include(joinpath("ctmodels", "problem_core.jl"))
include(joinpath("ctmodels", "nlp_backends.jl"))
include(joinpath("ctmodels", "discretized_ocp.jl"))
include(joinpath("ctmodels", "model_api.jl"))
include(joinpath("ctmodels", "initial_guess.jl"))

# Parser / macros pour l'initial guess
include(joinpath("ctparser", "initial_guess.jl"))

# Direct
include(joinpath("ctdirect", "core_types.jl"))
include(joinpath("ctdirect", "default.jl"))
include(joinpath("ctdirect", "discretization_api.jl"))
include(joinpath("ctdirect", "collocation_impl.jl"))

# Solver
include(joinpath("ctsolvers", "default.jl"))
include(joinpath("ctsolvers", "extension_stubs.jl"))
include(joinpath("ctsolvers", "common_solve_api.jl"))
include(joinpath("ctsolvers", "backends_types.jl"))

# OptimalControl
include(joinpath("optimalcontrol", "default.jl"))
include(joinpath("optimalcontrol", "solve_api.jl"))

end
