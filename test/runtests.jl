using Test
using Aqua
using CTSolvers
using CTBase
using ADNLPModels
using ExaModels
using NLPModels
using CommonSolve
using MadNLPMumps
using CUDA
using MadNLPGPU

# Test extension exceptions: before loading the extensions
@testset "Extension exceptions" begin
    include("test_extensions.jl")
    test_extensions()
end

# Load extensions
using NLPModelsIpopt
using MadNLP
using MadNCL
using NLPModelsKnitro

const CTSolversIpopt = Base.get_extension(CTSolvers, :CTSolversIpopt)
const CTSolversMadNLP = Base.get_extension(CTSolvers, :CTSolversMadNLP)
const CTSolversMadNCL = Base.get_extension(CTSolvers, :CTSolversMadNCL)
const CTSolversKnitro = Base.get_extension(CTSolvers, :CTSolversKnitro)

# CUDA
is_cuda_on() = CUDA.functional()
if is_cuda_on()
    println("✓ CUDA functional, GPU benchmarks enabled")
else
    println("⚠️  CUDA not functional, GPU models will be skipped")
end

# ------------------------------------------------------------------------------
# Problems definition
include("problems_definition.jl")
include(joinpath("problems", "rosenbrock.jl"))
include(joinpath("problems", "elec.jl"))

# ------------------------------------------------------------------------------
# Tests
const VERBOSE = true
const SHOWTIMING = true

# tests to run
const SOLVERS_RUNTESTS = Dict(
    :specific => Symbol[
        :ipopt,
        :madnlp,
        :madncl,
    ],
    :generic => Symbol[
        :ipopt,
        :madnlp,
        :madncl,
    ],
    :default => Symbol[
        :ipopt,
        :madnlp,
        :madncl,
    ],
    :gpu => Symbol[
        :madnlp,
        :madncl,
    ],
)

@testset verbose=VERBOSE showtiming=SHOWTIMING "CTSolvers tests" begin
    for name in (
        :aqua,
        :default,
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
