# Unit tests for extension stubs before loading CTSolvers extensions (ensure CTBase.ExtensionError is thrown).
function test_extensions_not_triggered()
    # NLPModelsIpopt
    @test_throws CTBase.ExtensionError CTSolvers.solve_with_ipopt(nothing)

    # MadNLP
    @test_throws CTBase.ExtensionError CTSolvers.solve_with_madnlp(nothing)

    # MadNCL
    @test_throws CTBase.ExtensionError CTSolvers.solve_with_madncl(nothing)

    # Knitro
    @test_throws CTBase.ExtensionError CTSolvers.solve_with_knitro(nothing)
end
