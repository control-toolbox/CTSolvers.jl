# ==============================================================================
# CTSolvers Test Runner
# ==============================================================================
#
# See test/README.md for usage instructions (running specific tests, coverage, etc.)
#
# ==============================================================================

# Test dependencies
using Test
using CTBase
using CTSolvers

# Trigger loading of optional extensions
const TestRunner = Base.get_extension(CTBase, :TestRunner)

# Controls nested testset output formatting (used by individual test files)
module TestData
const VERBOSE = true
const SHOWTIMING = true
end
using .TestData: VERBOSE, SHOWTIMING

# CUDA availability check
using CUDA

# Capability constants computed once, here, where a top-level `using` is guaranteed to bind
# into Main. Test files must read Main.TestCapabilities.* instead of `isdefined(Main, :X)`
# checks: `using X` inside a suite/*/test_*.jl file's own module binds X into that submodule,
# not into Main, so such checks are always false regardless of what is actually loaded.
#
# `CUDA_FUNCTIONAL` is the suite's single CUDA-device predicate — never define a local
# `is_cuda_on()` in a test file (duplicated copies drift; see Handbook philosophy/testing.md).
# `ON_GPU_RUNNER` turns the device tier from *skipped* into *required* on the self-hosted GPU
# runners: `RUNNER_NAME` is set by the GitHub Actions runner agent itself (no CI.yml/CTActions
# change needed) and equals the runner label — `kkt` or `occidata` (see CI.yml). Enforcement
# lives centrally in test/suite/environment/test_environment_contract.jl.
module TestCapabilities
using CUDA: CUDA
using CUDSS: CUDSS          # with CUDA, arms MadNLPGPUCUDAExt
using MadNLPGPU: MadNLPGPU

const CUDA_FUNCTIONAL = CUDA.functional()
const ON_GPU_RUNNER = get(ENV, "RUNNER_NAME", "") in ("kkt", "occidata")
const GPU_SOLVER_ARMED = MadNLPGPU.CUDSSSolver isa Type
const GPU_SOLVER = GPU_SOLVER_ARMED ? MadNLPGPU.CUDSSSolver : nothing
end

if TestCapabilities.CUDA_FUNCTIONAL
    println("✓ CUDA functional, GPU tests enabled")
else
    println("⚠️  CUDA not functional, GPU device tests will be skipped (Test.@test_skip)")
end

# Run tests using the TestRunner extension
CTBase.run_tests(;
    args=String.(ARGS),
    testset_name="CTSolvers tests",
    available_tests=("suite/*/test_*",),
    filename_builder=name -> Symbol(:test_, name),
    funcname_builder=name -> Symbol(:test_, name),
    verbose=VERBOSE,
    showtiming=SHOWTIMING,
    test_dir=@__DIR__,
    progress_bar_threshold=100,
    show_progress_bar=false,
)

# If running with coverage enabled, remind the user to run the post-processing script
# because .cov files are flushed at process exit and cannot be cleaned up by this script.
if Base.JLOptions().code_coverage != 0
    println(
        """

================================================================================
[CTSolvers] Coverage files generated.

To process them, move them to the coverage/ directory, and generate a report,
please run:

    julia --project=@. -e 'using Pkg; Pkg.test("CTSolvers"; coverage=true); include("test/coverage.jl")'
================================================================================
""",
    )
end
