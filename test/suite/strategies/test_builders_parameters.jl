module TestBuildersParameters

using Test
using CTSolvers.Strategies
using Main.TestOptions: VERBOSE, SHOWTIMING

# TOP-LEVEL: Define all structs here
abstract type TestFamily <: AbstractStrategy end

struct TestStratA <: TestFamily 
    options::Strategies.StrategyOptions
end

struct TestStratB{P<:AbstractStrategyParameter} <: TestFamily 
    options::Strategies.StrategyOptions
end

# Implement contracts
Strategies.id(::Type{<:TestStratA}) = :teststrata
Strategies.id(::Type{<:TestStratB}) = :teststratb

# Simple metadata for testing
Strategies.metadata(::Type{T}) where {T<:TestStratA} = CTSolvers.Options.StrategyMetadata(
    CTSolvers.Options.OptionDefinition(name=:opt1, type=Int, default=10)
)

Strategies.metadata(::Type{T}) where {T<:TestStratB} = CTSolvers.Options.StrategyMetadata(
    CTSolvers.Options.OptionDefinition(name=:opt1, type=Int, default=20),
    CTSolvers.Options.OptionDefinition(name=:backend, type=Union{Nothing, String}, default=nothing)
)

# Helper metadata for parameter-specific defaults
function __teststratb_backend(::Type{CPU})
    return nothing
end

function __teststratb_backend(::Type{GPU})
    return "cuda_backend"
end

# Parameter-specific metadata
function Strategies.metadata(::Type{TestStratB{P}}) where {P<:AbstractStrategyParameter}
    return CTSolvers.Options.StrategyMetadata(
        CTSolvers.Options.OptionDefinition(name=:opt1, type=Int, default=20),
        CTSolvers.Options.OptionDefinition(name=:backend, type=Union{Nothing, String}, default=__teststratb_backend(P))
    )
end

# Simple constructors
function TestStratA(; mode::Symbol=:strict, kwargs...)
    opts = Strategies.build_strategy_options(TestStratA; mode=mode, kwargs...)
    return TestStratA(opts)
end

function TestStratB{P}(; mode::Symbol=:strict, kwargs...) where {P<:AbstractStrategyParameter}
    opts = Strategies.build_strategy_options(TestStratB{P}; mode=mode, kwargs...)
    return TestStratB{P}(opts)
end

function test_builders_parameters()
    @testset "Builders with Parameters" verbose=VERBOSE showtiming=SHOWTIMING begin
        
        # ====================================================================
        # UNIT TESTS - extract_parameter_from_method
        # ====================================================================
        
        @testset "extract_parameter_from_method" begin
            r = Strategies.create_registry(
                TestFamily => (TestStratA, (TestStratB, [CPU, GPU]))
            )
            
            @test Strategies.extract_parameter_from_method((:teststratb, :cpu), r) == CPU
            @test Strategies.extract_parameter_from_method((:teststratb, :gpu), r) == GPU
            @test Strategies.extract_parameter_from_method((:teststratb,), r) === nothing
            @test Strategies.extract_parameter_from_method((:teststrata, :cpu), r) === nothing  # :teststrata not parameterized
        end
        
        @testset "extract_parameter_from_method no parameters in registry" begin
            r = Strategies.create_registry(
                TestFamily => (TestStratA,)  # No parameterized strategies
            )
            
            @test Strategies.extract_parameter_from_method((:teststrata, :cpu), r) === nothing
            @test Strategies.extract_parameter_from_method((:teststrata, :gpu), r) === nothing
        end
        
        # ====================================================================
        # UNIT TESTS - build_strategy_from_method with parameter
        # ====================================================================
        
        @testset "build_strategy_from_method parameterized" begin
            r = Strategies.create_registry(
                TestFamily => (TestStratA, (TestStratB, [CPU, GPU]))
            )
            
            s_cpu = Strategies.build_strategy_from_method((:teststratb, :cpu), TestFamily, r)
            s_gpu = Strategies.build_strategy_from_method((:teststratb, :gpu), TestFamily, r)
            
            @test s_cpu isa TestStratB{CPU}
            @test s_gpu isa TestStratB{GPU}
        end
        
        @testset "build_strategy_from_method non-parameterized" begin
            r = Strategies.create_registry(
                TestFamily => (TestStratA, (TestStratB, [CPU, GPU]))
            )
            
            s = Strategies.build_strategy_from_method((:teststrata,), TestFamily, r)
            @test s isa TestStratA
        end
        
        @testset "build_strategy_from_method with options" begin
            r = Strategies.create_registry(
                TestFamily => (TestStratA, (TestStratB, [CPU, GPU]))
            )
            
            s = Strategies.build_strategy_from_method((:teststratb, :cpu), TestFamily, r; opt1=100)
            @test s isa TestStratB{CPU}
            @test Strategies.option_value(s, :opt1) == 100
        end
        
        # ====================================================================
        # UNIT TESTS - build_strategy with parameter
        # ====================================================================
        
        @testset "build_strategy parameterized" begin
            r = Strategies.create_registry(
                TestFamily => ((TestStratB, [CPU, GPU]),)
            )
            
            s_cpu = Strategies.build_strategy(:teststratb, CPU, TestFamily, r)
            s_gpu = Strategies.build_strategy(:teststratb, GPU, TestFamily, r)
            
            @test s_cpu isa TestStratB{CPU}
            @test s_gpu isa TestStratB{GPU}
        end
        
        @testset "build_strategy parameterized with options" begin
            r = Strategies.create_registry(
                TestFamily => ((TestStratB, [CPU, GPU]),)
            )
            
            s = Strategies.build_strategy(:teststratb, GPU, TestFamily, r; opt1=50)
            @test s isa TestStratB{GPU}
            @test Strategies.option_value(s, :opt1) == 50
        end
        
        @testset "build_strategy unsupported parameter error" begin
            r = Strategies.create_registry(
                TestFamily => ((TestStratB, [CPU]),)  # Only CPU
            )
            
            @test_throws CTBase.Exceptions.IncorrectArgument Strategies.build_strategy(
                :teststratb, GPU, TestFamily, r
            )
        end
        
        # ====================================================================
        # UNIT TESTS - option_names_from_method with parameter
        # ====================================================================
        
        @testset "option_names_from_method parameterized" begin
            r = Strategies.create_registry(
                TestFamily => (TestStratA, (TestStratB, [CPU, GPU]))
            )
            
            names_cpu = Strategies.option_names_from_method((:teststratb, :cpu), TestFamily, r)
            names_gpu = Strategies.option_names_from_method((:teststratb, :gpu), TestFamily, r)
            
            @test :opt1 in names_cpu
            @test :backend in names_cpu
            @test :opt1 in names_gpu
            @test :backend in names_gpu
        end
        
        @testset "option_names_from_method non-parameterized" begin
            r = Strategies.create_registry(
                TestFamily => (TestStratA, (TestStratB, [CPU, GPU]))
            )
            
            names = Strategies.option_names_from_method((:teststrata,), TestFamily, r)
            @test names == (:opt1,)
        end
        
        # ====================================================================
        # INTEGRATION TESTS
        # ====================================================================
        
        @testset "Parameter-specific default options" begin
            r = Strategies.create_registry(
                TestFamily => ((TestStratB, [CPU, GPU]),)
            )
            
            s_cpu = Strategies.build_strategy_from_method((:teststratb, :cpu), TestFamily, r)
            s_gpu = Strategies.build_strategy_from_method((:teststratb, :gpu), TestFamily, r)
            
            # Check that defaults are different based on parameter
            @test Strategies.option_value(s_cpu, :backend) === nothing
            @test Strategies.option_value(s_gpu, :backend) == "cuda_backend"
        end
        
        @testset "Type stability" begin
            r = Strategies.create_registry(
                TestFamily => ((TestStratB, [CPU, GPU]),)
            )
            
            @test_nowarn @inferred Strategies.extract_parameter_from_method((:teststratb, :cpu), r)
            @test_nowarn @inferred Strategies.build_strategy_from_method((:teststratb, :cpu), TestFamily, r)
            @test_nowarn @inferred Strategies.build_strategy(:teststratb, CPU, TestFamily, r)
        end
    end
end

end # module

# Redefine in outer scope for TestRunner
test_builders_parameters() = TestBuildersParameters.test_builders_parameters()
