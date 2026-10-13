# Modelers
#
# Strategy-based modelers for converting discretized optimization problems into
# NLP backend models.

"""
Modelers module.

This module defines `AbstractNLPModeler` and concrete modeler strategies such as
`ADNLP` and `Exa`. A modeler selects an NLP backend and carries its validated options;
it does not build anything itself. The NLP model and the problem-level solution are
produced by `Optimization.build_model` / `Optimization.build_solution`, implemented by
the package providing the problem (e.g. CTDirect) for each concrete `(problem, modeler)`
pair. The generic `NotImplemented` stubs of this contract live in this module.

Modelers implement the `Strategies.AbstractStrategy` contract and participate in
orchestration and option routing.
"""
module Modelers

# Imports
using CTBase: Exceptions
using DocStringExtensions: TYPEDEF, TYPEDSIGNATURES
using SolverCore: SolverCore
using CTBase: Core

# CTBase generic infrastructure
using CTBase: Options
using CTBase: Strategies

# Internal CTSolvers API
using ..Optimization

# Submodules
include(joinpath(@__DIR__, "abstract_modeler.jl"))
include(joinpath(@__DIR__, "contract.jl"))
include(joinpath(@__DIR__, "validation.jl"))
include(joinpath(@__DIR__, "adnlp.jl"))
include(joinpath(@__DIR__, "exa.jl"))

# Public API
export AbstractNLPModeler
export ADNLP, Exa

end # module Modelers
