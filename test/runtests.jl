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
using CUDA
using MadNLPGPU

# CUDA
is_cuda_on() = CUDA.functional()

# ------------------------------------------------------------------------------
# Problems definition
include("problems_definition.jl")
include("rosenbrock.jl")
include("elec.jl")

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
