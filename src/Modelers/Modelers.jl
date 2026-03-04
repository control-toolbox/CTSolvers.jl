# Modelers
#
# Strategy-based modelers for converting discretized optimization problems into
# NLP backend models.

module Modelers

# Imports
import CTBase.Exceptions
import DocStringExtensions: TYPEDEF, TYPEDSIGNATURES
import SolverCore
import ADNLPModels
import ExaModels
import KernelAbstractions

# Internal CTSolvers API
using ..Options
using ..Strategies
using ..Optimization

# Submodules
include(joinpath(@__DIR__, "abstract_modeler.jl"))
include(joinpath(@__DIR__, "validation.jl"))
include(joinpath(@__DIR__, "adnlp.jl"))
include(joinpath(@__DIR__, "exa.jl"))

# Public API
export AbstractNLPModeler
export ADNLP, Exa

end # module Modelers
