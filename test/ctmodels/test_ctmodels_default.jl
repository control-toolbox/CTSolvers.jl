function test_ctmodels_default()

    # ADNLPModels
    Test.@testset "ADNLPModels" verbose=VERBOSE showtiming=SHOWTIMING begin
        Test.@test CTSolvers.__adnlp_model_show_time() isa Bool
        Test.@test CTSolvers.__adnlp_model_backend() isa Symbol
        Test.@test CTSolvers.__adnlp_model_empty_backends() isa Tuple{Vararg{Symbol}}
    end

    # ExaModels
    Test.@testset "ExaModels" verbose=VERBOSE showtiming=SHOWTIMING begin
        Test.@test CTSolvers.__exa_model_base_type() isa DataType
        Test.@test CTSolvers.__exa_model_backend() isa Union{Nothing,Symbol}
    end

end
