module TestAqua

using Test: Test
using CTSolvers: CTSolvers
using Aqua: Aqua
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
    end
end

end # module

test_aqua() = TestAqua.test_aqua()
