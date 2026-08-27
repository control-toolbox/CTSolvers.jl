module TestEnvironmentContract

using Test: Test

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

"""
    _isdefined_main_offenders()

Recursively find, under `test/suite/` (located via `@__DIR__`, not `pwd()`, so this works
regardless of the caller's working directory), source lines matching `isdefined(Main, ...)`
for a package symbol other than the two legitimate idioms:
- `TestData` — the `VERBOSE`/`SHOWTIMING` idiom used at the top of every suite test file;
  `TestData` is a module defined directly in `test/runtests.jl`, i.e. genuinely in `Main`.
- `CUDA` — `runtests.jl` does `using CUDA` at its own top level, so `CUDA` genuinely ends up
  bound in `Main` too; unlike every other package (e.g. `MadNLPGPU`), which is only ever
  `using`'d *inside* a suite file's own test module and therefore never leaks into `Main`.

Any other such check is the anti-pattern this file exists to catch (see
control-toolbox/CTSolvers.jl#189): it is always `false` no matter what is actually loaded,
because `Base.include(Main, filename)` only binds each test file's own top-level module into
`Main`, not whatever that module `using`s internally. (Note: this docstring itself avoids
writing the literal pattern it searches for, so it doesn't flag itself.)
"""
function _isdefined_main_offenders()
    suite_dir = joinpath(@__DIR__, "..")
    offenders = Tuple{String,Int,String}[]
    pattern = r"isdefined\(Main,\s*:(\w+)\)"
    for (root, _, files) in walkdir(suite_dir)
        for f in files
            endswith(f, ".jl") || continue
            path = joinpath(root, f)
            for (lineno, line) in enumerate(eachline(path))
                m = match(pattern, line)
                if m !== nothing && m.captures[1] ∉ ("TestData", "CUDA")
                    push!(offenders, (relpath(path, suite_dir), lineno, m.captures[1]))
                end
            end
        end
    end
    return offenders
end

"""
    _silent_cuda_guard_offenders()

Recursively find, under `test/suite/` (located via `@__DIR__`, not `pwd()`), lines that open
an `if` block directly on a CUDA-device predicate — a local `is_cuda_on()` call or a bare
`CUDA.functional()` call — the anti-pattern that makes a correctly-skipped run (no device, as
expected on a CPU/developer machine) and a silently-broken run (device *should* be present
but isn't) produce the same output: a green testset with zero assertions (see Handbook
`philosophy/testing.md` §"Capability-gated tests", and control-toolbox/CTSolvers.jl#189).

The fix is `if Main.TestCapabilities.CUDA_FUNCTIONAL ... else Test.@test_skip ... end`, with
the device tier made *required* on the GPU runners centrally, in the testset below.

This file is excluded from the walk: it necessarily spells out the very patterns it searches
for (regex source, comments, warning text).
"""
function _silent_cuda_guard_offenders()
    suite_dir = joinpath(@__DIR__, "..")
    offenders = Tuple{String,Int,String}[]
    # Assembled from two literals so this line does not match itself.
    pattern = Regex("if\\s+(is_cuda_on\\(\\)|CUDA" * "\\.functional\\(\\))")
    this_file = basename(@__FILE__)
    for (root, _, files) in walkdir(suite_dir)
        for f in files
            (endswith(f, ".jl") && f != this_file) || continue
            path = joinpath(root, f)
            for (lineno, line) in enumerate(eachline(path))
                if match(pattern, line) !== nothing
                    push!(offenders, (relpath(path, suite_dir), lineno, strip(line)))
                end
            end
        end
    end
    return offenders
end

function test_environment_contract()
    Test.@testset "Test-environment contract" verbose=VERBOSE showtiming=SHOWTIMING begin
        Test.@testset "GPU solver extension is armed" begin
            # Runs on every runner, including CPU-only laptops: "armed" comes from packages
            # being loaded (Project.toml + using in test/runtests.jl), not from a driver
            # being present. This is the assertion that catches control-toolbox/CTSolvers.jl#189
            # itself: it fails the moment CUDSS falls out of the dependency wiring again.
            Test.@test Main.TestCapabilities.GPU_SOLVER_ARMED
        end

        Test.@testset "GPU driver required on the GPU runner" begin
            # Central enforcement of the Handbook's capability-gated-test contract: on a
            # machine that is supposed to have a GPU, a missing/broken device fails loudly
            # here rather than being silently skipped everywhere else.
            #
            # Heuristic: RUNNER_NAME is set automatically by the GitHub Actions runner agent
            # itself (no .github/workflows/CI.yml or CTActions change needed) to the runner's
            # registered name — `kkt-runner` / `occidata-runner` for our self-hosted GPU
            # runners (the CI.yml `runs_on` label is the bare `kkt`/`occidata`). `ON_GPU_RUNNER`
            # (test/runtests.jl) matches the `kkt`/`occidata` substring, so it survives the
            # `-runner` suffix; if a runner is renamed past that, the check stops firing
            # silently rather than failing loudly.
            if Main.TestCapabilities.ON_GPU_RUNNER
                Test.@test Main.TestCapabilities.CUDA_FUNCTIONAL
            end
        end

        Test.@testset "isdefined(Main, ...) anti-pattern has not returned" begin
            offenders = _isdefined_main_offenders()
            Test.@test isempty(offenders)
            for (file, lineno, sym) in offenders
                @warn "isdefined(Main, :$sym) anti-pattern at $file:$lineno — use Main.TestCapabilities instead"
            end
        end

        Test.@testset "silent CUDA-guard anti-pattern has not returned" begin
            offenders = _silent_cuda_guard_offenders()
            Test.@test isempty(offenders)
            for (file, lineno, text) in offenders
                @warn "silent CUDA guard at $file:$lineno — use Main.TestCapabilities.CUDA_FUNCTIONAL with a Test.@test_skip else branch" text
            end
        end
    end
end

end # module

test_environment_contract() = TestEnvironmentContract.test_environment_contract()
