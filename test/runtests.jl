# Select tests to run
using OrderedCollections: OrderedDict

function default_tests()
    return OrderedDict(
        :notrigger => OrderedDict(
            :ctsolvers_extensions_notrigger => true,
        ),
        :aqua => OrderedDict(
            :aqua => true,
        ),
        :ctmodels => OrderedDict(
            :ctmodels_problem_core    => true,
            :ctmodels_options_schema  => true,
            :ctmodels_nlp_backends    => true,
            :ctmodels_discretized_ocp => true,
            :ctmodels_model_api       => true,
            :ctmodels_initial_guess   => true,
        ),
        :ctparser => OrderedDict(
            :ctparser_initial_guess_macro => true,
        ),
        :ctdirect => OrderedDict(
            :ctdirect_core_types         => true,
            :ctdirect_discretization_api => true,
            :ctdirect_collocation_impl   => true,
        ),
        :ctsolvers => OrderedDict(
            :ctsolvers_backends_types   => true,
            :ctsolvers_common_solve_api => true,
            :ctsolvers_extension_stubs  => true,
        ),
        :extensions => OrderedDict(
            :ctsolvers_extensions_ipopt   => true,
            :ctsolvers_extensions_madnlp  => true,
            :ctsolvers_extensions_madncl  => true,
            :ctsolvers_extensions_knitro  => true,
        ),
        :optimalcontrol => OrderedDict(
            :optimalcontrol_solve_api    => true,
        ),
    )
end

# Main test runner orchestrating all CTSolvers test suites.
using Test
using Aqua
using CTBase
using CTModels: CTModels
using CTParser: CTParser, @def
using CTSolvers: CTSolvers, @init
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

const TEST_SELECTION = isempty(ARGS) ? nothing : Symbol(ARGS[1])

const TEST_GROUP_INFO = Dict(
    :aqua           => (title = "Aqua",           subdir = ""),
    :ctmodels       => (title = "CTModels",       subdir = "ctmodels"),
    :ctparser       => (title = "CTParser",       subdir = "ctparser"),
    :ctsolvers      => (title = "CTSolvers",      subdir = "ctsolvers"),
    :ctdirect       => (title = "CTDirect",       subdir = "ctdirect"),
    :optimalcontrol => (title = "OptimalControl", subdir = "optimalcontrol"),
)

function selected_tests()
    tests = default_tests()
    sel = TEST_SELECTION

    if sel === nothing
        return tests
    elseif sel === :all
        # Activer tous les tests de tous les groupes
        for (_, group_tests) in tests
            for k in keys(group_tests)
                group_tests[k] = true
            end
        end
        return tests
    end

    # Pour toute autre sélection, on part d'un dictionnaire entièrement à false
    for (_, group_tests) in tests
        for k in keys(group_tests)
            group_tests[k] = false
        end
    end

    # sel = clé de groupe (ex: :aqua, :ctmodels, :extensions, :notrigger, ...)
    if haskey(tests, sel)
        for k in keys(tests[sel])
            tests[sel][k] = true
        end
        return tests
    end

    # sel = clé feuille (ex: :ctmodels_nlp_backends, :ctsolvers_extensions_ipopt, ...)
    for (_, group_tests) in tests
        if haskey(group_tests, sel)
            group_tests[sel] = true
            break
        end
    end

    return tests
end

const SELECTED_TESTS = selected_tests()

selected_notrigger_tests() = get(SELECTED_TESTS, :notrigger, OrderedDict{Symbol,Bool}())

selected_extensions_tests() = get(SELECTED_TESTS, :extensions, OrderedDict{Symbol,Bool}())

function selected_group_tests(group::Symbol)
    return get(SELECTED_TESTS, group, OrderedDict{Symbol,Bool}())
end

function run_test_group(group::Symbol, tests)
    any(values(tests)) || return
    info = TEST_GROUP_INFO[group]
    println("========== $(info.title) tests ==========")
    Test.@testset "$(info.title)" verbose=VERBOSE showtiming=SHOWTIMING begin
        for (name, enabled) in tests
            enabled || continue
            Test.@testset "$name" verbose=VERBOSE showtiming=SHOWTIMING begin
                test_name = Symbol(:test_, name)
                include(joinpath(info.subdir, string(test_name, ".jl")))
                @eval $test_name()
            end
        end
    end
    println("✓ $(info.title) tests passed\n")
end

function run_extension_exceptions(tests)
    any(values(tests)) || return
    println("========== Extension exceptions tests ==========")
    Test.@testset "Extension exceptions" verbose=VERBOSE showtiming=SHOWTIMING begin
        for (name, enabled) in tests
            enabled || continue
            Test.@testset "$name" verbose=VERBOSE showtiming=SHOWTIMING begin
                test_name = Symbol(:test_, name)
                include(joinpath("ctsolvers_ext", string(test_name, ".jl")))
                @eval $test_name()
            end
        end
    end
    println("✓ Extension exceptions tests passed\n")
end

function run_extensions_backends(tests)
    any(values(tests)) || return
    println("========== CTSolvers extensions tests ==========")
    Test.@testset "CTSolvers extensions" verbose=VERBOSE showtiming=SHOWTIMING begin
        for (name, enabled) in tests
            enabled || continue
            Test.@testset "$name" verbose=VERBOSE showtiming=SHOWTIMING begin
                test_name = Symbol(:test_, name)
                include(joinpath("ctsolvers_ext", string(test_name, ".jl")))
                @eval $test_name()
            end
        end
    end
    println("✓ CTSolvers extensions tests passed\n")
end

# Test extension exceptions: before loading the extensions
run_extension_exceptions(selected_notrigger_tests())

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
run_extensions_backends(selected_extensions_tests())

# Run all other tests
for (group, _) in TEST_GROUP_INFO
    run_test_group(group, selected_group_tests(group))
end
  