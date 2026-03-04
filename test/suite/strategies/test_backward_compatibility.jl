module TestBackwardCompatibility

import Test
import CTBase.Exceptions
import CTSolvers.Strategies
import CTSolvers.Modelers
import CTSolvers.Solvers

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

# TOP-LEVEL: Define test types for backward compatibility tests
abstract type TestFamily <: Strategies.AbstractStrategy end

struct TestStratA <: TestFamily 
    options::Strategies.StrategyOptions
end

struct TestStratB{P<:Strategies.AbstractStrategyParameter} <: TestFamily 
    options::Strategies.StrategyOptions
end

# Implement contracts
Strategies.id(::Type{<:TestStratA}) = :teststrata
Strategies.id(::Type{<:TestStratB}) = :teststratb

# Simple metadata
Strategies.metadata(::Type{T}) where {T<:TestStratA} = Strategies.StrategyMetadata()
Strategies.metadata(::Type{T}) where {T<:TestStratB} = Strategies.StrategyMetadata()

# Simple constructors
function TestStratA(; mode=:strict, kwargs...)
    opts = Strategies.build_strategy_options(TestStratA; mode=mode, kwargs...)
    return TestStratA(opts)
end

function TestStratB{P}(; mode=:strict, kwargs...) where {P<:Strategies.AbstractStrategyParameter}
    opts = Strategies.build_strategy_options(TestStratB{P}; mode=mode, kwargs...)
    return TestStratB{P}(opts)
end

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
            
            Test.@test length(Strategies.strategy_ids(Modelers.AbstractNLPModeler, r)) == 1
            Test.@test :exa in Strategies.strategy_ids(Modelers.AbstractNLPModeler, r)
        end
        
        # ====================================================================
        # UNIT TESTS - Parameterized strategies have CPU defaults
        # ====================================================================
        
        Test.@testset "Parameterized strategies default to CPU" begin
            # Test that default constructors create CPU parameterized versions
            Test.@test Modelers.Exa() isa Modelers.Exa{Strategies.CPU}
            
            # Test that default constructors use CPU parameter
            Test.@test Strategies.get_parameter_type(typeof(Modelers.Exa())) == Strategies.CPU
        end
        
        # ====================================================================
        # UNIT TESTS - Parameter tokens must be explicit
        # ====================================================================
        
        Test.@testset "Parameterized strategies require explicit parameter token" begin
            # Test registry
            r = Strategies.create_registry(
                TestFamily => (TestStratA, (TestStratB, [Strategies.CPU, Strategies.GPU]))
            )
            
            # Parameterized strategies now require explicit parameter in method (no implicit defaults)
            Test.@test_throws Exceptions.IncorrectArgument Strategies.extract_global_parameter_from_method((:teststratb,), r)
        end
        
        # ====================================================================
        # UNIT TESTS - Registry compatibility
        # ====================================================================
        
        Test.@testset "Registry compatibility" begin
            # Test that parameterized strategies work in registries
            r = Strategies.create_registry(
                Modelers.AbstractNLPModeler => (
                    (Modelers.Exa, [Strategies.CPU, Strategies.GPU]),
                )
            )
            
            # Should have only one unique ID (:exa)
            ids = Strategies.strategy_ids(Modelers.AbstractNLPModeler, r)
            Test.@test length(ids) == 1
            Test.@test :exa in ids
        end
        
        # ====================================================================
        # UNIT TESTS - ID uniqueness maintained
        # ====================================================================
        
        Test.@testset "ID uniqueness maintained" begin
            # Test that parameterized strategies maintain unique IDs
            Test.@test Strategies.id(Modelers.Exa{Strategies.CPU}) == Strategies.id(Modelers.Exa{Strategies.GPU}) == :exa
            Test.@test Strategies.id(Solvers.MadNLP{Strategies.CPU}) == Strategies.id(Solvers.MadNLP{Strategies.GPU}) == :madnlp
            Test.@test Strategies.id(Solvers.MadNCL{Strategies.CPU}) == Strategies.id(Solvers.MadNCL{Strategies.GPU}) == :madncl
        end
        
        # ====================================================================
        # INTEGRATION TESTS
        # ====================================================================
        
        Test.@testset "Integration with existing code" begin
            exa = Modelers.Exa()
            Test.@test exa isa Modelers.Exa{Strategies.CPU}
            Test.@test Strategies.options(exa) isa Strategies.StrategyOptions
        end
        
        # Test.@testset "Type stability" begin
        #     # Test that parameter extraction is type stable
        #     Test.@test_nowarn Test.@inferred Strategies.get_parameter_type(Modelers.Exa{Strategies.CPU})
        #     Test.@test_nowarn Test.@inferred Strategies.get_parameter_type(Modelers.Exa{Strategies.GPU})
        #     Test.@test_nowarn Test.@inferred Strategies.get_parameter_type(Solvers.MadNLP{Strategies.CPU})
        #     Test.@test_nowarn Test.@inferred Strategies.get_parameter_type(Solvers.MadNLP{Strategies.GPU})
        # end
    end
end

end # module

# Redefine in outer scope for TestRunner
test_backward_compatibility() = TestBackwardCompatibility.test_backward_compatibility()
