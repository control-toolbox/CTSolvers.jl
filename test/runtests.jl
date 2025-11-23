using Test
using Aqua
using CTBase
using CTModels: CTModels
using CTParser: CTParser, @def
using CTSolvers
using ADNLPModels
using ExaModels
using NLPModels
using CommonSolve
using CUDA
using MadNLPGPU
using SolverCore

# CUDA
is_cuda_on() = CUDA.functional()
if is_cuda_on()
    println("✓ CUDA functional, GPU tests enabled")
else
    println("⚠️  CUDA not functional, GPU tests will be skipped")
end

# Problems definition
include(joinpath("problems", "problems_definition.jl"))
include(joinpath("problems", "rosenbrock.jl"))
include(joinpath("problems", "elec.jl"))
include(joinpath("problems", "beam.jl"))

# Tests parameters
const VERBOSE = false
const SHOWTIMING = true

# Select tests to run
const TESTS = Dict(
    :extensions => false,
    :aqua       => false,
    :ctmodels   => true,
    :ctsolvers  => false,
    :ctdirect   => false,
)

# Test extension exceptions: before loading the extensions
if TESTS[:extensions]
    println("========== Extension exceptions tests ==========")
    @testset "Extension exceptions" verbose=VERBOSE showtiming=SHOWTIMING begin
        include(joinpath("ctsolvers_ext", "test_extensions.jl"))
        test_extensions()
    end
    println("✓ Extension exceptions tests passed\n")
end

# Load extensions
using NLPModelsIpopt
using MadNLPMumps
using MadNLP
using MadNCL
using NLPModelsKnitro

const CTSolversIpopt = Base.get_extension(CTSolvers, :CTSolversIpopt)
const CTSolversMadNLP = Base.get_extension(CTSolvers, :CTSolversMadNLP)
const CTSolversMadNCL = Base.get_extension(CTSolvers, :CTSolversMadNCL)
const CTSolversKnitro = Base.get_extension(CTSolvers, :CTSolversKnitro)

# CTSolvers extensions tests: after loading the extensions
if TESTS[:extensions]
    println("========== CTSolvers extensions tests ==========")
    @testset "CTSolvers extensions" verbose=VERBOSE showtiming=SHOWTIMING begin
        for name in (
            :ctsolvers_extensions_unit,
            :ctsolvers_extensions_integration,
            :ctsolvers_extensions_gpu,
        )
            @testset "$(name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                test_name = Symbol(:test_, name)
                include(joinpath("ctsolvers_ext", "$(test_name).jl"))
                @eval $test_name()
            end
        end
    end
    println("✓ CTSolvers extensions tests passed\n")
end

# Aqua
if TESTS[:aqua]
    println("========== Aqua tests ==========")
    @testset "Aqua" verbose=VERBOSE showtiming=SHOWTIMING begin
        for name in (
            :aqua,
        )
            @testset "$(name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                test_name = Symbol(:test_, name)
                include("$(test_name).jl")
                @eval $test_name()
            end
        end
    end
    println("✓ Aqua tests passed\n")
end

# Model
if TESTS[:ctmodels]
    println("========== CTModels tests ==========")
    @testset "CTModels" verbose=VERBOSE showtiming=SHOWTIMING begin
        for name in (
            :ctmodels_default,
            :ctmodels_problem_core,
            :ctmodels_nlp_backends,
            :ctmodels_discretized_ocp,
            :ctmodels_model_api,
            :ctmodels_initial_guess,
        )
            @testset "$(name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                test_name = Symbol(:test_, name)
                include(joinpath("ctmodels", "$(test_name).jl"))
                @eval $test_name()
            end
        end
    end
    println("✓ CTModels tests passed\n")
end

# Solver
if TESTS[:ctsolvers]
    println("========== CTSolvers tests ==========")
    @testset "CTSolvers" verbose=VERBOSE showtiming=SHOWTIMING begin
        for name in (
            :ctsolvers_default,
            :ctsolvers_backends_types,
            :ctsolvers_common_solve_api,
            :ctsolvers_extension_stubs,
        )
            @testset "$(name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                test_name = Symbol(:test_, name)
                include(joinpath("ctsolvers", "$(test_name).jl"))
                @eval $test_name()
            end
        end
    end
    println("✓ CTSolvers tests passed\n")
end

# Direct
if TESTS[:ctdirect]
    println("========== CTDirect tests ==========")
    @testset "CTDirect" verbose=VERBOSE showtiming=SHOWTIMING begin
        for name in (
            :ctdirect_default,
            :ctdirect_core_types,
            :ctdirect_discretization_api,
            :ctdirect_collocation_impl,
        )
            @testset "$(name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                test_name = Symbol(:test_, name)
                include(joinpath("ctdirect", "$(test_name).jl"))
                @eval $test_name()
            end
        end
    end
    println("✓ CTDirect tests passed\n")
end
