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
            # Heuristic: RUNNER_NAME is set automatically by the GitHub Actions runner agent
            # itself (no .github/workflows/CI.yml or CTActions change needed) and equals
            # "kkt" for the self-hosted GPU runner (see CI.yml's `runs_on: '[["kkt"]]'`). If
            # the runner is ever renamed, update the literal below — this check then just
            # silently stops firing rather than failing loudly.
            if get(ENV, "RUNNER_NAME", "") == "kkt"
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
    end
end

end # module

test_environment_contract() = TestEnvironmentContract.test_environment_contract()
