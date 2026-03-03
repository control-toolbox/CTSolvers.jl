module TestRegistryParameters

using Test
using CTSolvers.Strategies
using Main.TestOptions: VERBOSE, SHOWTIMING

# TOP-LEVEL: Define all structs here
struct FakeFamily <: AbstractStrategy end
struct FakeStratA <: FakeFamily end
struct FakeStratB{P<:AbstractStrategyParameter} <: FakeFamily end

# Implement contracts
Strategies.id(::Type{<:FakeStratA}) = :fakestrata
Strategies.id(::Type{<:FakeStratB}) = :fakestratb

# Fake parameter for testing
struct FakeParam <: AbstractStrategyParameter end
Strategies.id(::Type{FakeParam}) = :fakeparam

function test_registry_parameters()
    @testset "Registry with Parameters" verbose=VERBOSE showtiming=SHOWTIMING begin
        
        # ====================================================================
        # UNIT TESTS - create_registry with parameterized strategies
        # ====================================================================
        
        @testset "create_registry parameterized" begin
            r = Strategies.create_registry(
                FakeFamily => (FakeStratA, (FakeStratB, [CPU, GPU]))
            )
            
            # Check that the registry contains the correct types
            types = r.families[FakeFamily]
            @test FakeStratA in types
            @test FakeStratB{CPU} in types
            @test FakeStratB{GPU} in types
            @test length(types) == 3
        end
        
        @testset "create_registry with multiple parameterized strategies" begin
            r = Strategies.create_registry(
                FakeFamily => ((FakeStratA, [CPU]), (FakeStratB, [CPU, GPU]))
            )
            
            types = r.families[FakeFamily]
            @test FakeStratA{CPU} in types
            @test FakeStratB{CPU} in types
            @test FakeStratB{GPU} in types
            @test length(types) == 3
        end
        
        @testset "create_registry validation - invalid strategy type" begin
            @test_throws CTBase.Exceptions.IncorrectArgument Strategies.create_registry(
                FakeFamily => ((String, [CPU]),)  # String is not a strategy
            )
        end
        
        @testset "create_registry validation - invalid parameter type" begin
            @test_throws CTBase.Exceptions.IncorrectArgument Strategies.create_registry(
                FakeFamily => ((FakeStratB, [String]),)  # String is not a parameter
            )
        end
        
        @testset "create_registry validation - invalid parameter format" begin
            @test_throws CTBase.Exceptions.IncorrectArgument Strategies.create_registry(
                FakeFamily => ((FakeStratB, "not a tuple"),)  # Not a tuple/vector
            )
        end
        
        # ====================================================================
        # UNIT TESTS - Global ID uniqueness
        # ====================================================================
        
        @testset "Global ID uniqueness - strategy vs parameter" begin
            # :cpu cannot be both a strategy ID and a parameter ID
            struct FakeStratWithIdCpu <: FakeFamily end
            Strategies.id(::Type{<:FakeStratWithIdCpu}) = :cpu
            
            @test_throws CTBase.Exceptions.IncorrectArgument Strategies.create_registry(
                FakeFamily => (FakeStratWithIdCpu, (FakeStratB, [CPU]))
            )
        end
        
        @testset "Global ID uniqueness - parameter vs parameter" begin
            # :fakeparam cannot be used by two different parameter types
            struct FakeParam2 <: AbstractStrategyParameter end
            Strategies.id(::Type{FakeParam2}) = :fakeparam
            
            @test_throws CTBase.Exceptions.IncorrectArgument Strategies.create_registry(
                FakeFamily => ((FakeStratB, [FakeParam, FakeParam2]),)
            )
        end
        
        @testset "Global ID uniqueness - strategy vs strategy" begin
            # Same ID for two different strategies should fail
            struct FakeStratC <: FakeFamily end
            Strategies.id(::Type{<:FakeStratC}) = :fakestrata  # Same as FakeStratA
            
            @test_throws CTBase.Exceptions.IncorrectArgument Strategies.create_registry(
                FakeFamily => (FakeStratA, FakeStratC)
            )
        end
        
        # ====================================================================
        # UNIT TESTS - strategy_ids deduplication
        # ====================================================================
        
        @testset "strategy_ids deduplication" begin
            r = Strategies.create_registry(
                FakeFamily => (FakeStratA, (FakeStratB, [CPU, GPU]))
            )
            ids = Strategies.strategy_ids(FakeFamily, r)
            @test length(ids) == length(unique(ids))  # No duplicates
            @test :fakestrata in ids
            @test :fakestratb in ids
            @test length(ids) == 2  # Only 2 unique IDs despite 3 types
        end
        
        @testset "strategy_ids with only parameterized strategies" begin
            r = Strategies.create_registry(
                FakeFamily => ((FakeStratA, [CPU, GPU]), (FakeStratB, [CPU]))
            )
            ids = Strategies.strategy_ids(FakeFamily, r)
            @test length(ids) == 2  # :fakestrata, :fakestratb
        end
        
        # ====================================================================
        # UNIT TESTS - get_parameter_type
        # ====================================================================
        
        @testset "get_parameter_type" begin
            @test Strategies.get_parameter_type(FakeStratB{CPU}) == CPU
            @test Strategies.get_parameter_type(FakeStratB{GPU}) == GPU
            @test Strategies.get_parameter_type(FakeStratA) === nothing
        end
        
        @testset "get_parameter_type type stability" begin
            @test_nowarn @inferred Strategies.get_parameter_type(FakeStratB{CPU})
            @test_nowarn @inferred Strategies.get_parameter_type(FakeStratA)
        end
        
        # ====================================================================
        # UNIT TESTS - type_from_id with parameter
        # ====================================================================
        
        @testset "type_from_id with parameter" begin
            r = Strategies.create_registry(
                FakeFamily => ((FakeStratB, [CPU, GPU]),)
            )
            
            T_cpu = Strategies.type_from_id(:fakestratb, FakeFamily, r; parameter=CPU)
            T_gpu = Strategies.type_from_id(:fakestratb, FakeFamily, r; parameter=GPU)
            
            @test T_cpu == FakeStratB{CPU}
            @test T_gpu == FakeStratB{GPU}
        end
        
        @testset "type_from_id without parameter" begin
            r = Strategies.create_registry(
                FakeFamily => ((FakeStratB, [CPU, GPU]),)
            )
            
            # Should return the first match (implementation-dependent but should work)
            T = Strategies.type_from_id(:fakestratb, FakeFamily, r)
            @test T in (FakeStratB{CPU}, FakeStratB{GPU})
        end
        
        @testset "type_from_id parameter not found" begin
            r = Strategies.create_registry(
                FakeFamily => ((FakeStratB, [CPU]),)  # Only CPU
            )
            
            @test_throws CTBase.Exceptions.IncorrectArgument Strategies.type_from_id(
                :fakestratb, FakeFamily, r; parameter=GPU
            )
        end
        
        @testset "type_from_id strategy not found" begin
            r = Strategies.create_registry(
                FakeFamily => (FakeStratA,)
            )
            
            @test_throws CTBase.Exceptions.IncorrectArgument Strategies.type_from_id(
                :nonexistent, FakeFamily, r
            )
        end
        
        # ====================================================================
        # INTEGRATION TESTS
        # ====================================================================
        
        @testset "Registry display with parameterized strategies" begin
            r = Strategies.create_registry(
                FakeFamily => (FakeStratA, (FakeStratB, [CPU, GPU]))
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
