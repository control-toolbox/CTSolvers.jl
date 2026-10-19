module TestAqua

using Test: Test
using CTBase: CTBase
using CTSolvers: CTSolvers
using Aqua: Aqua

# Load every extension before checking extension quality. The test suite runs in one
# process, but the quality check must not depend on another test file being visited first.
using ADNLPModels: ADNLPModels
using CUDA: CUDA
using CUDSS: CUDSS
using Enzyme: Enzyme
using ExaModels: ExaModels
using ForwardDiff: ForwardDiff
using MadNCL: MadNCL
using MadNLP: MadNLP
using MadNLPGPU: MadNLPGPU
using NLPModels: NLPModels
using NLPModelsIpopt: NLPModelsIpopt

# KNITRO_jll ships no binary for macOS x64: loading Knitro raises there. Loading it is
# therefore optional, and the extension-quality check is skipped when it is unavailable
# (CTBase.DevTools.test_extensions_quality requires every extension to be loaded).
const KNITRO_LOADABLE = try
    @eval using NLPModelsKnitro: NLPModelsKnitro
    true
catch
    false
end

using OrdinaryDiffEqTsit5: OrdinaryDiffEqTsit5
using DiffEqBase: DiffEqBase
using SciMLBase: SciMLBase
using UnoSolver: UnoSolver
using Zygote: Zygote

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

function test_aqua()
    Test.@testset "Aqua.jl" verbose = VERBOSE showtiming = SHOWTIMING begin
        Aqua.test_all(
            CTSolvers;
            ambiguities=false,
            # KernelAbstractions is a hard dep used only by the CTSolversExaModels
            # extension (so ExaModels alone triggers it, and CTDirect needn't load
            # KernelAbstractions); it is not referenced by the main module.
            stale_deps=(ignore=[:KernelAbstractions],),
            deps_compat=(ignore=[:LinearAlgebra, :Unicode],),
            piracies=true,
        )
        # do not warn about ambiguities in dependencies
        Aqua.test_ambiguities(CTSolvers)
        if KNITRO_LOADABLE
            CTBase.DevTools.test_extensions_quality(CTSolvers)
        else
            Test.@test_skip "extensions quality: NLPModelsKnitro cannot be loaded on this platform"
        end
    end
end

end # module

test_aqua() = TestAqua.test_aqua()
