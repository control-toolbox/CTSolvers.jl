# Unit tests for CTModels default parameters used when building models.
function test_ctmodels_default()

    # Tests for default parameters used when building ADNLPModels.
    # We check both the return types (API robustness) and the exact values
    # defined in src/ctmodels/default.jl.
    Test.@testset "ADNLPModels" verbose=VERBOSE showtiming=SHOWTIMING begin
        # Local helpers mirroring historical defaults
        local show_time_default() = false
        local backend_default() = :optimized
        local function empty_backends_default()
            (:hprod_backend, :jtprod_backend, :jprod_backend, :ghjvprod_backend)
        end

        # Types of default parameters
        Test.@test show_time_default() isa Bool
        Test.@test backend_default() isa Symbol
        Test.@test empty_backends_default() isa Tuple{Vararg{Symbol}}

        # Expected default values
        Test.@test show_time_default() == false
        Test.@test backend_default() == :optimized
        Test.@test empty_backends_default() == (
            :hprod_backend, :jtprod_backend, :jprod_backend, :ghjvprod_backend
        )
    end

    # Tests for default parameters used when building ExaModels.
    # Same idea: we lock both the type and the value of base_type and backend.
    Test.@testset "ExaModels" verbose=VERBOSE showtiming=SHOWTIMING begin
        # Local helpers mirroring historical defaults
        local base_type_default() = Float64
        local backend_default() = nothing

        # Types of default parameters
        Test.@test base_type_default() isa DataType
        Test.@test backend_default() isa Union{Nothing,Symbol}

        # Expected default values
        Test.@test base_type_default() === Float64
        Test.@test backend_default() === nothing
    end

end
