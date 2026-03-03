module TestBuildersParameters

import Test
import CTSolvers.Strategies
import CTBase.Exceptions

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

# TOP-LEVEL: Define all structs here
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

# Simple metadata for testing
Strategies.metadata(::Type{T}) where {T<:TestStratA} = Strategies.StrategyMetadata(
    Strategies.OptionDefinition(name=:opt1, type=Int, default=10, description="Test option 1")
)

Strategies.metadata(::Type{T}) where {T<:TestStratB} = Strategies.StrategyMetadata(
    Strategies.OptionDefinition(name=:opt1, type=Int, default=20, description="Test option 1"),
    Strategies.OptionDefinition(name=:backend, type=Union{Nothing, String}, default=nothing, description="Test backend")
)

# Helper metadata for parameter-specific defaults
function __teststratb_backend(::Type{Strategies.CPU})
    return nothing
end

function __teststratb_backend(::Type{Strategies.GPU})
    return "cuda_backend"
end

# Parameter-specific metadata
function Strategies.metadata(::Type{TestStratB{P}}) where {P<:Strategies.AbstractStrategyParameter}
    return Strategies.StrategyMetadata(
        Strategies.OptionDefinition(name=:opt1, type=Int, default=20, description="Test option 1"),
        Strategies.OptionDefinition(name=:backend, type=Union{Nothing, String}, default=__teststratb_backend(P), description="Test backend")
    )
end

# Simple constructors
function TestStratA(; mode::Symbol=:strict, kwargs...)
    opts = Strategies.build_strategy_options(TestStratA; mode=mode, kwargs...)
    return TestStratA(opts)
end

function TestStratB{P}(; mode::Symbol=:strict, kwargs...) where {P<:Strategies.AbstractStrategyParameter}
    opts = Strategies.build_strategy_options(TestStratB{P}; mode=mode, kwargs...)
    return TestStratB{P}(opts)
end

function test_builders_parameters()
    Test.@testset "Builders with Parameters" verbose=VERBOSE showtiming=SHOWTIMING begin
        
        # ====================================================================
        # UNIT TESTS - extract_parameter_from_method
        # ====================================================================
        
        Test.@testset "extract_parameter_from_method" begin
            r = Strategies.create_registry(
                TestFamily => (TestStratA, (TestStratB, [Strategies.CPU, Strategies.GPU]))
            )
            
            @test Strategies.extract_parameter_from_method((:teststratb, :cpu), r) == Strategies.CPU
            @test Strategies.extract_parameter_from_method((:teststratb, :gpu), r) == Strategies.GPU
            @test Strategies.extract_parameter_from_method((:teststratb,), r) === nothing
            @test Strategies.extract_parameter_from_method((:teststrata, :cpu), r) === nothing  # :teststrata not parameterized
        end
        
        Test.@testset "extract_parameter_from_method no parameters in registry" begin
            r = Strategies.create_registry(
                TestFamily => (TestStratA,)  # No parameterized strategies
            )
            
            @test Strategies.extract_parameter_from_method((:teststrata, :cpu), r) === nothing
            @test Strategies.extract_parameter_from_method((:teststrata, :gpu), r) === nothing
        end
        
        # ====================================================================
        # UNIT TESTS - build_strategy_from_method with parameter
        # ====================================================================
        
        Test.@testset "build_strategy_from_method parameterized" begin
            r = Strategies.create_registry(
                TestFamily => (TestStratA, (TestStratB, [Strategies.CPU, Strategies.GPU]))
            )
            
            s_cpu = Strategies.build_strategy_from_method((:teststratb, :cpu), TestFamily, r)
            s_gpu = Strategies.build_strategy_from_method((:teststratb, :gpu), TestFamily, r)
            
            @test s_cpu isa TestStratB{Strategies.CPU}
            @test s_gpu isa TestStratB{Strategies.GPU}
        end
        
        Test.@testset "build_strategy_from_method non-parameterized" begin
            r = Strategies.create_registry(
                TestFamily => (TestStratA, (TestStratB, [Strategies.CPU, Strategies.GPU]))
            )
            
            s = Strategies.build_strategy_from_method((:teststrata,), TestFamily, r)
            Test.@test s isa TestStratA
        end
        
        Test.@testset "build_strategy_from_method with options" begin
            r = Strategies.create_registry(
                TestFamily => (TestStratA, (TestStratB, [Strategies.CPU, Strategies.GPU]))
            )
            
            s = Strategies.build_strategy_from_method((:teststratb, :cpu), TestFamily, r; opt1=100)
            @test s isa TestStratB{Strategies.CPU}
            @test Strategies.option_value(s, :opt1) == 100
        end
        
        # ====================================================================
        # UNIT TESTS - build_strategy with parameter
        # ====================================================================
        
        Test.@testset "build_strategy parameterized" begin
            r = Strategies.create_registry(
                TestFamily => ((TestStratB, [Strategies.CPU, Strategies.GPU]),)
            )
            
            s_cpu = Strategies.build_strategy(:teststratb, Strategies.CPU, TestFamily, r)
            s_gpu = Strategies.build_strategy(:teststratb, Strategies.GPU, TestFamily, r)
            
            @test s_cpu isa TestStratB{Strategies.CPU}
            @test s_gpu isa TestStratB{Strategies.GPU}
        end
        
        Test.@testset "build_strategy parameterized with options" begin
            r = Strategies.create_registry(
                TestFamily => ((TestStratB, [Strategies.CPU, Strategies.GPU]),)
            )
            
            s = Strategies.build_strategy(:teststratb, Strategies.GPU, TestFamily, r; opt1=50)
            @test s isa TestStratB{Strategies.GPU}
            @test Strategies.option_value(s, :opt1) == 50
        end
        
        Test.@testset "build_strategy unsupported parameter error" begin
            r = Strategies.create_registry(
                TestFamily => ((TestStratB, [Strategies.CPU]),)  # Only CPU
            )
            
            @test_throws Exceptions.IncorrectArgument Strategies.build_strategy(
                :teststratb, Strategies.GPU, TestFamily, r
            )
        end
        
        # ====================================================================
        # UNIT TESTS - option_names_from_method with parameter
        # ====================================================================
        
        Test.@testset "option_names_from_method parameterized" begin
            r = Strategies.create_registry(
                TestFamily => (TestStratA, (TestStratB, [Strategies.CPU, Strategies.GPU]))
            )
            
            names_cpu = Strategies.option_names_from_method((:teststratb, :cpu), TestFamily, r)
            names_gpu = Strategies.option_names_from_method((:teststratb, :gpu), TestFamily, r)
            
            @test :opt1 in names_cpu
            @test :backend in names_cpu
            @test :opt1 in names_gpu
            @test :backend in names_gpu
        end
        
        Test.@testset "option_names_from_method non-parameterized" begin
            r = Strategies.create_registry(
                TestFamily => (TestStratA, (TestStratB, [Strategies.CPU, Strategies.GPU]))
            )
            
            names = Strategies.option_names_from_method((:teststrata,), TestFamily, r)
            @test names == (:opt1,)
        end
        
        # ====================================================================
        # INTEGRATION TESTS
        # ====================================================================
        
        Test.@testset "Parameter-specific default options" begin
            r = Strategies.create_registry(
                TestFamily => ((TestStratB, [Strategies.CPU, Strategies.GPU]),)
            )
            
            s_cpu = Strategies.build_strategy_from_method((:teststratb, :cpu), TestFamily, r)
            s_gpu = Strategies.build_strategy_from_method((:teststratb, :gpu), TestFamily, r)
            
            # Check that defaults are different based on parameter
            @test Strategies.option_value(s_cpu, :backend) === nothing
            @test Strategies.option_value(s_gpu, :backend) == "cuda_backend"
        end
        
        Test.@testset "Correctness verification" begin
            r = Strategies.create_registry(
                TestFamily => ((TestStratB, [Strategies.CPU, Strategies.GPU]),)
            )
            
            # Verify extract_parameter_from_method returns correct types
            result = Strategies.extract_parameter_from_method((:teststratb, :cpu), r)
            @test result === Strategies.CPU
            
            # Verify builder functions return correct types
            s1 = Strategies.build_strategy_from_method((:teststratb, :cpu), TestFamily, r)
            @test s1 isa TestStratB{Strategies.CPU}
            
            s2 = Strategies.build_strategy(:teststratb, Strategies.CPU, TestFamily, r)
            @test s2 isa TestStratB{Strategies.CPU}
        end
    end
end

end # module

# Redefine in outer scope for TestRunner
test_builders_parameters() = TestBuildersParameters.test_builders_parameters()
