# Unit tests for package-wide quality checks using Aqua.jl (API, dependencies, ambiguities).
function test_aqua()
    @testset "Aqua.jl" begin
        Aqua.test_all(
            CTSolvers;
            ambiguities=false,
            #stale_deps=(ignore=[:SomePackage],),
            deps_compat=(ignore=[:LinearAlgebra, :Unicode],),
            piracies=true,
        )
        # do not warn about ambiguities in dependencies
        Aqua.test_ambiguities(CTSolvers)
    end
end
