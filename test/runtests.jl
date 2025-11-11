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

# ------------------------------------------------------------------------------
# Problems definition
struct OptimizationProblem <: CTSolvers.AbstractOptimizationProblem
    build_adnlp_model::CTSolvers.ADNLPProblem
    build_exa_model::CTSolvers.ExaProblem
end
include("rosenbrock.jl")

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
