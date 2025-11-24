# Unit tests for CTModels default parameters used when building models.
function test_ctmodels_default()

    # Tests for default parameters used when building ADNLPModels.
    # We check both the return types (API robustness) and the exact values
    # defined in src/ctmodels/default.jl.
    Test.@testset "ADNLPModels" verbose=VERBOSE showtiming=SHOWTIMING begin
        # Types of default parameters
        Test.@test CTSolvers.__adnlp_model_show_time() isa Bool
        Test.@test CTSolvers.__adnlp_model_backend() isa Symbol
        Test.@test CTSolvers.__adnlp_model_empty_backends() isa Tuple{Vararg{Symbol}}

        # Expected default values
        Test.@test CTSolvers.__adnlp_model_show_time() == false
        Test.@test CTSolvers.__adnlp_model_backend() == :optimized
        Test.@test CTSolvers.__adnlp_model_empty_backends() == (
            :hprod_backend, :jtprod_backend, :jprod_backend, :ghjvprod_backend
        )
    end

    # Tests for default parameters used when building ExaModels.
    # Same idea: we lock both the type and the value of base_type and backend.
    Test.@testset "ExaModels" verbose=VERBOSE showtiming=SHOWTIMING begin
        # Types of default parameters
        Test.@test CTSolvers.__exa_model_base_type() isa DataType
        Test.@test CTSolvers.__exa_model_backend() isa Union{Nothing,Symbol}

        # Expected default values
        Test.@test CTSolvers.__exa_model_base_type() === Float64
        Test.@test CTSolvers.__exa_model_backend() === nothing
    end

end
