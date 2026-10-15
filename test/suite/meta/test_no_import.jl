"""
Regression guard for the ct-conventions rules "using, never import" (`MOD3`) and
"qualified external imports" (`MOD4`): flags any tracked `.jl` or `.md` file that
still uses the `import` keyword (`MOD3`), or the forbidden dotted `using Pkg.Sub`
form (`MOD4`; the canonical spelling is `using Pkg: Sub`).
"""

module TestNoImport

using Test: Test

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

const IMPORT_RE = r"^\s*import\b"
const DOTTED_USING_RE = r"^\s*using\s+[A-Za-z_]\w*\.[A-Za-z_]"

# CHANGELOG.md quotes `import` verbatim inside dated past-release entries describing what
# shipped at the time — historical fact, not a current-convention violation.
const IMPORT_EXEMPT = ("CHANGELOG.md",)
const DOTTED_USING_EXEMPT = ()

function test_no_import()
    Test.@testset "No `import` / no dotted `using Pkg.Sub` (MOD3, MOD4)" verbose =
        VERBOSE showtiming = SHOWTIMING begin
        repo_root = joinpath(@__DIR__, "..", "..", "..")
        tracked = filter(
            f -> endswith(f, ".jl") || endswith(f, ".md"),
            readlines(Cmd(`git ls-files`; dir=repo_root)),
        )
        for relpath in tracked
            path = joinpath(repo_root, relpath)
            check_import = !(basename(relpath) in IMPORT_EXEMPT)
            check_dotted = !(basename(relpath) in DOTTED_USING_EXEMPT)
            for line in eachline(path)
                if check_import
                    Test.@test !occursin(IMPORT_RE, line)
                end
                if check_dotted
                    Test.@test !occursin(DOTTED_USING_RE, line)
                end
            end
        end
    end
end

end # module

test_no_import() = TestNoImport.test_no_import()
