module TestModelers

using Test
using CTBase
using CTSolvers
using CTSolvers.Modelers
using CTSolvers.Strategies
using ADNLPModels
using ExaModels
using SolverCore
const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

"""
    test_modelers_basic()

Test basic functionality and module structure.
"""
function test_modelers_basic()
    Test.@testset "Modelers Basic Tests" begin
        # Test module exports
        Test.@test isdefined(CTSolvers, :AbstractNLPModeler)
        Test.@test isdefined(CTSolvers, :ADNLPModeler)
        Test.@test isdefined(CTSolvers, :ExaModeler)
        
        # Test type hierarchy
        Test.@test Modelers.AbstractNLPModeler <: Strategies.AbstractStrategy
        Test.@test Modelers.ADNLPModeler <: Modelers.AbstractNLPModeler
        Test.@test Modelers.ExaModeler <: Modelers.AbstractNLPModeler
        
        # Test strategy identification
        Test.@test Strategies.id(Modelers.ADNLPModeler) == :adnlp
        Test.@test Strategies.id(Modelers.ExaModeler) == :exa
        
        # Test strategy metadata structure
        adnlp_meta = Strategies.metadata(Modelers.ADNLPModeler)
        Test.@test adnlp_meta isa Strategies.StrategyMetadata
        Test.@test haskey(adnlp_meta, :show_time)
        Test.@test haskey(adnlp_meta, :backend)
        
        exa_meta = Strategies.metadata(Modelers.ExaModeler)
        Test.@test exa_meta isa Strategies.StrategyMetadata
        Test.@test haskey(exa_meta, :base_type)
        Test.@test haskey(exa_meta, :backend)
    end
end

"""
    test_adnlp_modeler()

Test ADNLPModeler implementation.
"""
function test_adnlp_modeler()
    Test.@testset "ADNLPModeler Tests" begin
        # Test default constructor
        modeler = Modelers.ADNLPModeler()
        Test.@test modeler isa Modelers.AbstractNLPModeler
        Test.@test modeler isa Strategies.AbstractStrategy
        
        # Test constructor with options
        modeler_opts = Modelers.ADNLPModeler(show_time=true, backend=:default)
        opts = Strategies.options(modeler_opts)
        Test.@test opts[:show_time] == true
        Test.@test opts[:backend] == :default
        
        # Test option defaults
        modeler_default = Modelers.ADNLPModeler()
        opts_default = Strategies.options(modeler_default)
        Test.@test opts_default[:backend] == :optimized
        
        # Test options are passed generically
        opts_nt = Strategies.options(modeler_opts).options
        Test.@test opts_nt isa NamedTuple
        Test.@test haskey(opts_nt, :show_time)
        Test.@test haskey(opts_nt, :backend)
    end
end

"""
    test_exa_modeler()

Test ExaModeler implementation.
"""
function test_exa_modeler()
    Test.@testset "ExaModeler Tests" begin
        # Test default constructor
        modeler = Modelers.ExaModeler()
        Test.@test modeler isa Modelers.AbstractNLPModeler
        Test.@test modeler isa Strategies.AbstractStrategy
        Test.@test typeof(modeler) == Modelers.ExaModeler
        
        # Test constructor with options
        modeler_opts = Modelers.ExaModeler(backend=nothing)
        opts = Strategies.options(modeler_opts)
        Test.@test opts[:backend] === nothing
        
        # Test type parameter (removed - ExaModeler is no longer parameterized)
        modeler_f32 = Modelers.ExaModeler(base_type=Float32)
        Test.@test typeof(modeler_f32) == Modelers.ExaModeler
        
        # Test base_type option handling
        modeler_type = Modelers.ExaModeler(base_type=Float32)
        Test.@test typeof(modeler_type) == Modelers.ExaModeler
        Test.@test Strategies.options(modeler_type)[:base_type] == Float32
        
        # Test base_type is stored in options (not filtered anymore)
        opts_nt = Strategies.options(modeler_type).options
        Test.@test haskey(opts_nt, :base_type)  # base_type is now stored as regular option
        Test.@test haskey(opts_nt, :backend)  # backend has nothing default, always stored
    end
end

"""
    test_modelers_integration()

Test integration with Optimization and Strategies modules.
"""
function test_modelers_integration()
    Test.@testset "Modelers Integration Tests" begin
        # Test strategy registry compatibility
        Test.@test Modelers.ADNLPModeler <: Strategies.AbstractStrategy
        Test.@test Modelers.ExaModeler <: Strategies.AbstractStrategy
        
        # Test option extraction
        modeler = Modelers.ADNLPModeler(show_time=true)
        opts = Strategies.options(modeler)
        Test.@test haskey(opts, :show_time)
        Test.@test haskey(opts, :backend)
    end
end

"""
    test_modelers_error_handling()

Test error handling and edge cases.
"""
function test_modelers_error_handling()
    Test.@testset "Modelers Error Handling" begin
        # Test that abstract methods throw NotImplemented
        # Note: Cannot instantiate abstract type, so we test the interface exists
        Test.@test hasmethod(
            (m::Modelers.AbstractNLPModeler, prob, ig) -> m(prob, ig),
            Tuple{Modelers.AbstractNLPModeler, Modelers.AbstractOptimizationProblem, Any}
        )
    end
end

"""
    test_modelers_options_api()

Test generic options API.
"""
function test_modelers_options_api()
    Test.@testset "Modelers Options API" begin
        # Test that options are passed generically (not extracted by name)
        modeler = Modelers.ADNLPModeler(show_time=true, backend=:default)
        opts = Strategies.options(modeler)
        
        # Options should be accessible as NamedTuple for generic passing
        opts_nt = opts.options
        Test.@test opts_nt isa NamedTuple
        Test.@test length(opts_nt) >= 2  # show_time and backend (plus advanced options)
        
        # Test that we can iterate over options
        for (key, value) in pairs(opts_nt)
            Test.@test key isa Symbol
        end
    end
end

function test_modelers()
    Test.@testset "Modelers Module Tests" verbose = VERBOSE showtiming = SHOWTIMING begin
        test_modelers_basic()
        test_adnlp_modeler()
        test_exa_modeler()
        test_modelers_integration()
        test_modelers_error_handling()
        test_modelers_options_api()
    end
end

end # module

test_modelers() = TestModelers.test_modelers()
