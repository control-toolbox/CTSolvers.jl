module TestRegistryParameters

import Test
import CTBase.Exceptions
import CTSolvers.Strategies

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

# TOP-LEVEL: Define all structs here
struct FakeFamily <: Strategies.AbstractStrategy end
struct FakeStratA <: FakeFamily end
struct FakeStratB{P<:Strategies.AbstractStrategyParameter} <: FakeFamily end

# Implement contracts
Strategies.id(::Type{<:FakeStratA}) = :fakestrata
Strategies.id(::Type{<:FakeStratB}) = :fakestratb

# Fake parameter for testing
struct FakeParam <: Strategies.AbstractStrategyParameter end
Strategies.id(::Type{FakeParam}) = :fakeparam

# Additional test structs (must be at top level)
struct FakeStratWithIdCpu <: FakeFamily end
Strategies.id(::Type{<:FakeStratWithIdCpu}) = :cpu

struct FakeParam2 <: Strategies.AbstractStrategyParameter end
Strategies.id(::Type{FakeParam2}) = :fakeparam

struct FakeStratC <: FakeFamily end
Strategies.id(::Type{<:FakeStratC}) = :fakestrata  # Same as FakeStratA

function test_registry_parameters()
    Test.@testset "Registry with Parameters" verbose=VERBOSE showtiming=SHOWTIMING begin
        
        # ====================================================================
        # UNIT TESTS - create_registry with parameterized strategies
        # ====================================================================
        
        Test.@testset "create_registry parameterized" begin
            r = Strategies.create_registry(
                FakeFamily => (FakeStratA, (FakeStratB, [Strategies.CPU, Strategies.GPU]))
            )
            
            # Check that the registry contains the correct types
            types = r.families[FakeFamily]
            @test FakeStratA in types
            @test FakeStratB{Strategies.CPU} in types
            @test FakeStratB{Strategies.GPU} in types
            @test length(types) == 3
        end
        
        Test.@testset "create_registry with multiple parameterized strategies" begin
            r = Strategies.create_registry(
                FakeFamily => ((FakeStratA, [Strategies.CPU]), (FakeStratB, [Strategies.CPU, Strategies.GPU]))
            )
            
            types = r.families[FakeFamily]
            @test FakeStratA{Strategies.CPU} in types
            @test FakeStratB{Strategies.CPU} in types
            @test FakeStratB{Strategies.GPU} in types
            @test length(types) == 3
        end
        
        Test.@testset "create_registry validation - invalid strategy type" begin
            Test.@test_throws Exceptions.IncorrectArgument Strategies.create_registry(
                FakeFamily => ((String, [Strategies.CPU]),)  # String is not a strategy
            )
        end
        
        Test.@testset "create_registry validation - invalid parameter type" begin
            Test.@test_throws Exceptions.IncorrectArgument Strategies.create_registry(
                FakeFamily => ((FakeStratB, [String]),)  # String is not a parameter
            )
        end
        
        Test.@testset "create_registry validation - invalid parameter format" begin
            Test.@test_throws Exceptions.IncorrectArgument Strategies.create_registry(
                FakeFamily => ((FakeStratB, "not a tuple"),)  # Not a tuple/vector
            )
        end
        
        # ====================================================================
        # UNIT TESTS - Global ID uniqueness
        # ====================================================================
        
        Test.@testset "Global ID uniqueness - strategy vs parameter" begin
            # :cpu cannot be both a strategy ID and a parameter ID
            Test.@test_throws Exceptions.IncorrectArgument Strategies.create_registry(
                FakeFamily => (FakeStratWithIdCpu, (FakeStratB, [Strategies.CPU]))
            )
        end
        
        Test.@testset "Global ID uniqueness - parameter vs parameter" begin
            # :fakeparam cannot be used by two different parameter types
            Test.@test_throws Exceptions.IncorrectArgument Strategies.create_registry(
                FakeFamily => ((FakeStratB, [FakeParam, FakeParam2]),)
            )
        end
        
        Test.@testset "Global ID uniqueness - strategy vs strategy" begin
            # Same ID for two different strategies should fail
            Test.@test_throws Exceptions.IncorrectArgument Strategies.create_registry(
                FakeFamily => (FakeStratA, FakeStratC)
            )
        end
        
        # ====================================================================
        # UNIT TESTS - strategy_ids deduplication
        # ====================================================================
        
        Test.@testset "strategy_ids deduplication" begin
            r = Strategies.create_registry(
                FakeFamily => (FakeStratA, (FakeStratB, [Strategies.CPU, Strategies.GPU]))
            )
            ids = Strategies.strategy_ids(FakeFamily, r)
            @test length(ids) == length(unique(ids))  # No duplicates
            @test :fakestrata in ids
            @test :fakestratb in ids
            @test length(ids) == 2  # Only 2 unique IDs despite 3 types
        end
        
        Test.@testset "strategy_ids with only parameterized strategies" begin
            r = Strategies.create_registry(
                FakeFamily => ((FakeStratA, [Strategies.CPU, Strategies.GPU]), (FakeStratB, [Strategies.CPU]))
            )
            ids = Strategies.strategy_ids(FakeFamily, r)
            @test length(ids) == 2  # :fakestrata, :fakestratb
        end
        
        # ====================================================================
        # UNIT TESTS - get_parameter_type
        # ====================================================================
        
        Test.@testset "get_parameter_type" begin
            @test Strategies.get_parameter_type(FakeStratB{Strategies.CPU}) == Strategies.CPU
            @test Strategies.get_parameter_type(FakeStratB{Strategies.GPU}) == Strategies.GPU
            @test Strategies.get_parameter_type(FakeStratA) === nothing
        end
        
        Test.@testset "get_parameter_type type stability" begin
            @test_nowarn @inferred Strategies.get_parameter_type(FakeStratB{Strategies.CPU})
            @test_nowarn @inferred Strategies.get_parameter_type(FakeStratA)
        end
        
        # ====================================================================
        # UNIT TESTS - type_from_id with parameter
        # ====================================================================
        
        Test.@testset "type_from_id with parameter" begin
            r = Strategies.create_registry(
                FakeFamily => ((FakeStratB, [Strategies.CPU, Strategies.GPU]),)
            )
            
            T_cpu = Strategies.type_from_id(:fakestratb, FakeFamily, r; parameter=Strategies.CPU)
            T_gpu = Strategies.type_from_id(:fakestratb, FakeFamily, r; parameter=Strategies.GPU)
            
            @test T_cpu == FakeStratB{Strategies.CPU}
            @test T_gpu == FakeStratB{Strategies.GPU}
        end
        
        Test.@testset "type_from_id without parameter" begin
            r = Strategies.create_registry(
                FakeFamily => ((FakeStratB, [Strategies.CPU, Strategies.GPU]),)
            )
            
            # Should return the first match (implementation-dependent but should work)
            T = Strategies.type_from_id(:fakestratb, FakeFamily, r)
            @test T in (FakeStratB{Strategies.CPU}, FakeStratB{Strategies.GPU})
        end
        
        Test.@testset "type_from_id parameter not found" begin
            r = Strategies.create_registry(
                FakeFamily => ((FakeStratB, [Strategies.CPU]),)  # Only CPU
            )
            
            @test_throws Exceptions.IncorrectArgument Strategies.type_from_id(
                :fakestratb, FakeFamily, r; parameter=Strategies.GPU
            )
        end
        
        Test.@testset "type_from_id strategy not found" begin
            r = Strategies.create_registry(
                FakeFamily => (FakeStratA,)
            )
            
            @test_throws Exceptions.IncorrectArgument Strategies.type_from_id(
                :nonexistent, FakeFamily, r
            )
        end
        
        # ====================================================================
        # INTEGRATION TESTS
        # ====================================================================
        
        Test.@testset "Registry display with parameterized strategies" begin
            r = Strategies.create_registry(
                FakeFamily => (FakeStratA, (FakeStratB, [Strategies.CPU, Strategies.GPU]))
            )
            
            # Test that display works without errors
            io = IOBuffer()
            show(io, r)
            output = String(take!(io))
            @test occursin("StrategyRegistry", output)
            
            io = IOBuffer()
            show(io, MIME"text/plain"(), r)
            output = String(take!(io))
            @test occursin("FakeFamily", output)
        end
    end
end

end # module

# Redefine in outer scope for TestRunner
test_registry_parameters() = TestRegistryParameters.test_registry_parameters()
