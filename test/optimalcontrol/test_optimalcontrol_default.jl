# Unit tests for OptimalControl default parameters
function test_optimalcontrol_default()

    # Discretizer
    Test.@test CTSolvers.__grid_size() isa Int
    Test.@test CTSolvers.__grid_size() > 0
    Test.@test CTSolvers.__scheme() isa CTSolvers.AbstractIntegratorScheme
    Test.@test CTSolvers.__scheme() isa CTSolvers.Midpoint
    Test.@test CTSolvers.__discretizer() isa CTSolvers.AbstractOptimalControlDiscretizer
    Test.@test CTSolvers.__discretizer() isa CTSolvers.Collocation

    # Collocation default constructor wrapper
    local default_grid = CTSolvers.__grid_size()
    local default_scheme = CTSolvers.__scheme()

    colloc = CTSolvers.Collocation()
    Test.@test colloc isa CTSolvers.Collocation
    Test.@test CTSolvers.grid_size(colloc) == default_grid
    Test.@test CTSolvers.scheme(colloc) === default_scheme

    # Display default
    Test.@test CTSolvers.__display() isa Bool

    # ADNLPModeler defaults wrapper
    ad_modeler = CTSolvers.ADNLPModeler()
    ad_opts = Dict(ad_modeler.options)
    Test.@test ad_opts[:show_time] == false
    Test.@test ad_opts[:backend] == :optimized

    # ExaModeler defaults wrapper
    exa_modeler = CTSolvers.ExaModeler()
    Test.@test exa_modeler isa CTSolvers.ExaModeler{Float64}
    exa_opts = Dict(exa_modeler.options)
    Test.@test exa_opts[:backend] === nothing

    # ADNLPModeler helper defaults
    Test.@test CTSolvers.__adnlp_model_show_time() isa Bool
    Test.@test CTSolvers.__adnlp_model_show_time() == false
    Test.@test CTSolvers.__adnlp_model_backend() isa Symbol
    Test.@test CTSolvers.__adnlp_model_backend() == :optimized

    # ADNLPModeler wrapper with custom kwargs
    custom_ad = CTSolvers.ADNLPModeler(
        ; show_time=true,
          backend=:manual,
          empty_backends=(
              :hprod_backend, :jtprod_backend, :jprod_backend, :ghjvprod_backend
          ),
          foo=1,
    )
    custom_ad_opts = Dict(custom_ad.options)
    Test.@test custom_ad_opts[:show_time] == true
    Test.@test custom_ad_opts[:backend] == :manual
    Test.@test custom_ad_opts[:empty_backends] == (
        :hprod_backend, :jtprod_backend, :jprod_backend, :ghjvprod_backend
    )
    Test.@test custom_ad_opts[:foo] == 1

    # ExaModeler helper defaults
    Test.@test CTSolvers.__exa_model_base_type() isa DataType
    Test.@test CTSolvers.__exa_model_base_type() === Float64
    Test.@test CTSolvers.__exa_model_backend() === nothing

    # ExaModeler wrapper with custom base_type/backend/kwargs
    custom_exa = CTSolvers.ExaModeler(
        ; base_type=Float32,
          backend=nothing,
          foo=2,
    )
    Test.@test custom_exa isa CTSolvers.ExaModeler{Float32}
    custom_exa_opts = Dict(custom_exa.options)
    Test.@test custom_exa_opts[:backend] === nothing
    Test.@test custom_exa_opts[:foo] == 2

end
