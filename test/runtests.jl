using Test
using Aqua
using CTSolvers

#
using ADNLPModels
using ExaModels
using NLPModels
using CommonSolve
using MadNLP
using MadNLPMumps
using CTBase
using MadNCL

# ------------------------------------------------------------------------------
# Problems definition
struct OptimizationProblem <: CTSolvers.AbstractCTOptimizationProblem
    build_adnlp_model::CTSolvers.ADNLPModelBuilder
    build_exa_model::CTSolvers.ExaModelBuilder
end
function CTSolvers.get_build_adnlp_model(prob::OptimizationProblem)
    return prob.build_adnlp_model
end
function CTSolvers.get_build_exa_model(prob::OptimizationProblem)
    return prob.build_exa_model
end
include("rosenbrock.jl")
include("elec.jl")

struct DummyProblem <: CTSolvers.AbstractCTOptimizationProblem end

# ------------------------------------------------------------------------------
# Tests
const VERBOSE = true
const SHOWTIMING = true

@testset verbose=VERBOSE showtiming=SHOWTIMING "CTSolvers tests" begin
    for name in (
        # :aqua,
        :models,
        :solvers,
    )
        @testset "$(name)" verbose=VERBOSE showtiming=SHOWTIMING begin
            test_name = Symbol(:test_, name)
            include("$(test_name).jl")
            @eval $test_name()
        end
    end
end
