# Unit tests for CTSolvers extension stubs throwing CTBase.ExtensionError when backends are unavailable.
function test_ctsolvers_extension_stubs()
    Test.@testset "ctsolvers/extension_stubs: solve_with_* throws ExtensionError" verbose=VERBOSE showtiming=SHOWTIMING begin

        # NLPModelsIpopt stub must throw a CTBase.ExtensionError when the
        # Ipopt extension is not loaded.
        Test.@test_throws CTBase.ExtensionError CTSolvers.solve_with_ipopt(nothing)

        # MadNLP stub
        Test.@test_throws CTBase.ExtensionError CTSolvers.solve_with_madnlp(nothing)

        # MadNCL stub
        Test.@test_throws CTBase.ExtensionError CTSolvers.solve_with_madncl(nothing)

        # Knitro stub
        Test.@test_throws CTBase.ExtensionError CTSolvers.solve_with_knitro(nothing)
    end
end
