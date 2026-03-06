# Modelers
#
# Strategy-based modelers for converting discretized optimization problems into
# NLP backend models.

"""
Modelers module.

This module defines `AbstractNLPModeler` and concrete modeler strategies such as
`ADNLP` and `Exa`. Modelers are strategies that:
- Build NLP backend models from an `Optimization.AbstractOptimizationProblem` and an initial guess.
- Build problem-specific solution objects from solver execution statistics.

Modelers implement the `Strategies.AbstractStrategy` contract and participate in
orchestration and option routing.
"""
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
