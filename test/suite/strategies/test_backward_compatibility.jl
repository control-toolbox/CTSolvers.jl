module TestBackwardCompatibility

import Test
import CTBase.Exceptions
import CTSolvers.Strategies
import CTSolvers.Modelers
import CTSolvers.Solvers

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

function test_backward_compatibility()
    Test.@testset "Backward Compatibility" verbose=VERBOSE showtiming=SHOWTIMING begin
        
        # ====================================================================
        # UNIT TESTS - Non-parameterized strategies still work
        # ====================================================================
        
        Test.@testset "Non-parameterized strategies work" begin
            # Test that existing non-parameterized strategies still work
            # Note: MadNLP and MadNCL require extensions, so we test types only
            
            # Test that strategies can be used in registry without parameters
            r = Strategies.create_registry(
                Modelers.AbstractNLPModeler => (Modelers.Exa,)
            )
            
            @test length(Strategies.strategy_ids(Modelers.AbstractNLPModeler, r)) == 1
            @test :exa in Strategies.strategy_ids(Modelers.AbstractNLPModeler, r)
        end
        
        # ====================================================================
        # UNIT TESTS - Parameterized strategies have CPU defaults
        # ====================================================================
        
        Test.@testset "Parameterized strategies default to CPU" begin
            # Test that default constructors create CPU parameterized versions
            @test Modelers.Exa() isa Modelers.Exa{CPU}
            
            # Test that default constructors use CPU parameter
            @test Strategies.get_parameter_type(typeof(Modelers.Exa())) == CPU
        end
        
        # ====================================================================
        # UNIT TESTS - build_strategy_from_method defaults to CPU
        # ====================================================================
        
        Test.@testset "build_strategy_from_method defaults to CPU" begin
            # Define test abstract family
            abstract type TestFamily <: AbstractStrategy end
            
            # Define test strategies
            struct TestStratA <: TestFamily 
                options::Strategies.StrategyOptions
            end
            
            struct TestStratB{P<:AbstractStrategyParameter} <: TestFamily 
                options::Strategies.StrategyOptions
            end
            
            # Implement contracts
            Strategies.id(::Type{<:TestStratA}) = :teststrata
            Strategies.id(::Type{<:TestStratB}) = :teststratb
            
            # Simple metadata
            Strategies.metadata(::Type{T}) where {T<:TestStratA} = Options.StrategyMetadata()
            Strategies.metadata(::Type{T}) where {T<:TestStratB} = Options.StrategyMetadata()
            
            # Simple constructors
            function TestStratA(; mode=:strict, kwargs...)
                opts = Strategies.build_strategy_options(TestStratA; mode=mode, kwargs...)
                return TestStratA(opts)
            end
            
            function TestStratB{P}(; mode=:strict, kwargs...) where {P<:AbstractStrategyParameter}
                opts = Strategies.build_strategy_options(TestStratB{P}; mode=mode, kwargs...)
                return TestStratB{P}(opts)
            end
            
            # Test registry
            r = Strategies.create_registry(
                TestFamily => (TestStratA, (TestStratB, [CPU, GPU]))
            )
            
            # Test that build_strategy_from_method without parameter defaults to CPU
            s = Strategies.build_strategy_from_method((:teststratb,), TestFamily, r)
            @test s isa TestStratB{CPU}
        end
        
        # ====================================================================
        # UNIT TESTS - Registry compatibility
        # ====================================================================
        
        Test.@testset "Registry compatibility" begin
            # Test that registries can mix parameterized and non-parameterized strategies
            r = Strategies.create_registry(
                Modelers.AbstractNLPModeler => (
                    Modelers.Exa,  # Non-parameterized (actually parameterized with default CPU)
                    (Modelers.Exa, [CPU, GPU])  # Explicit parameterized
                )
            )
            
            # Should have only one unique ID (:exa)
            ids = Strategies.strategy_ids(Modelers.AbstractNLPModeler, r)
            @test length(ids) == 1
            @test :exa in ids
        end
        
        # ====================================================================
        # UNIT TESTS - ID uniqueness maintained
        # ====================================================================
        
        Test.@testset "ID uniqueness maintained" begin
            # Test that parameterized strategies maintain unique IDs
            @test Strategies.id(Modelers.Exa{CPU}) == Strategies.id(Modelers.Exa{GPU}) == :exa
            @test Strategies.id(Solvers.MadNLP{CPU}) == Strategies.id(Solvers.MadNLP{GPU}) == :madnlp
            @test Strategies.id(Solvers.MadNCL{CPU}) == Strategies.id(Solvers.MadNCL{GPU}) == :madncl
        end
        
        # ====================================================================
        # INTEGRATION TESTS
        # ====================================================================
        
        Test.@testset "Integration with existing code" begin
            # Test that existing patterns still work
            @test_throws Exceptions.ExtensionError Solvers.MadNLP()  # Extension not loaded
            @test_throws Exceptions.ExtensionError Solvers.MadNCL()  # Extension not loaded
            
            # But Exa should work (no extension required)
            exa = Modelers.Exa()
            @test exa isa Modelers.Exa{CPU}
            @test Strategies.options(exa) isa Strategies.StrategyOptions
        end
        
        Test.@testset "Type stability" begin
            # Test that parameter extraction is type stable
            @test_nowarn @inferred Strategies.get_parameter_type(Modelers.Exa{CPU})
            @test_nowarn @inferred Strategies.get_parameter_type(Modelers.Exa{GPU})
            @test_nowarn @inferred Strategies.get_parameter_type(Solvers.MadNLP{CPU})
            @test_nowarn @inferred Strategies.get_parameter_type(Solvers.MadNLP{GPU})
        end
    end
end

end # module

# Redefine in outer scope for TestRunner
test_backward_compatibility() = TestBackwardCompatibility.test_backward_compatibility()
