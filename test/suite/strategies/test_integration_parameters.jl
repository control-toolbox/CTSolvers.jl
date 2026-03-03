module TestIntegrationParameters

import Test
import CTBase.Exceptions
import CTSolvers.Strategies
import CTSolvers.Modelers
import CTSolvers.Solvers

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

# TOP-LEVEL: Define all structs here
abstract type IntegrationFamily <: Strategies.AbstractStrategy end

struct IntegrationStratA <: IntegrationFamily 
    options::Strategies.StrategyOptions
end

struct IntegrationStratB{P<:Strategies.AbstractStrategyParameter} <: IntegrationFamily 
    options::Strategies.StrategyOptions
end

# Implement contracts
Strategies.id(::Type{<:IntegrationStratA}) = :integrationstrata
Strategies.id(::Type{<:IntegrationStratB}) = :integrationstratb

# Simple metadata
Strategies.metadata(::Type{T}) where {T<:IntegrationStratA} = Options.StrategyMetadata(
    Options.OptionDefinition(name=:opt1, type=Int, default=10)
)

Strategies.metadata(::Type{T}) where {T<:IntegrationStratB} = Options.StrategyMetadata(
    Options.OptionDefinition(name=:opt1, type=Int, default=20),
    Options.OptionDefinition(name=:backend, type=Union{Nothing, String}, default=nothing)
)

# Parameter-specific metadata
function Strategies.metadata(::Type{IntegrationStratB{P}}) where {P<:AbstractStrategyParameter}
    backend_default = P == CPU ? nothing : "cuda_backend"
    return Options.StrategyMetadata(
        Options.OptionDefinition(name=:opt1, type=Int, default=20),
        Options.OptionDefinition(name=:backend, type=Union{Nothing, String}, default=backend_default)
    )
end

# Simple constructors
function IntegrationStratA(; mode=:strict, kwargs...)
    opts = Strategies.build_strategy_options(IntegrationStratA; mode=mode, kwargs...)
    return IntegrationStratA(opts)
end

function IntegrationStratB{P}(; mode=:strict, kwargs...) where {P<:AbstractStrategyParameter}
    opts = Strategies.build_strategy_options(IntegrationStratB{P}; mode=mode, kwargs...)
    return IntegrationStratB{P}(opts)
end

function test_integration_parameters()
    Test.@testset "Integration Tests - Parameterized Strategies" verbose=VERBOSE showtiming=SHOWTIMING begin
        
        # ====================================================================
        # INTEGRATION TESTS - Complete workflow
        # ====================================================================
        
        Test.@testset "Complete parameterized workflow" begin
            # Create registry with mixed strategies
            r = Strategies.create_registry(
                IntegrationFamily => (
                    IntegrationStratA, 
                    (IntegrationStratB, [CPU, GPU])
                )
            )
            
            # Test strategy IDs deduplication
            ids = Strategies.strategy_ids(IntegrationFamily, r)
            @test length(ids) == 2  # :integrationstrata, :integrationstratb
            @test :integrationstrata in ids
            @test :integrationstratb in ids
            
            # Test parameter extraction from method
            @test Strategies.extract_parameter_from_method((:integrationstratb, :cpu), r) == CPU
            @test Strategies.extract_parameter_from_method((:integrationstratb, :gpu), r) == GPU
            @test Strategies.extract_parameter_from_method((:integrationstratb,), r) === nothing
            
            # Test building strategies from method
            s_cpu = Strategies.build_strategy_from_method((:integrationstratb, :cpu), IntegrationFamily, r)
            s_gpu = Strategies.build_strategy_from_method((:integrationstratb, :gpu), IntegrationFamily, r)
            s_default = Strategies.build_strategy_from_method((:integrationstratb,), IntegrationFamily, r)
            
            @test s_cpu isa IntegrationStratB{CPU}
            @test s_gpu isa IntegrationStratB{GPU}
            @test s_default isa IntegrationStratB{CPU}  # Default to CPU
            
            # Test option names from method
            names_cpu = Strategies.option_names_from_method((:integrationstratb, :cpu), IntegrationFamily, r)
            names_gpu = Strategies.option_names_from_method((:integrationstratb, :gpu), IntegrationFamily, r)
            
            @test :opt1 in names_cpu
            @test :backend in names_cpu
            @test :opt1 in names_gpu
            @test :backend in names_gpu
        end
        
        # ====================================================================
        # INTEGRATION TESTS - Parameter-specific defaults
        # ====================================================================
        
        Test.@testset "Parameter-specific default options" begin
            r = Strategies.create_registry(
                IntegrationFamily => ((IntegrationStratB, [CPU, GPU]),)
            )
            
            s_cpu = Strategies.build_strategy_from_method((:integrationstratb, :cpu), IntegrationFamily, r)
            s_gpu = Strategies.build_strategy_from_method((:integrationstratb, :gpu), IntegrationFamily, r)
            
            # Check that defaults are different based on parameter
            @test Strategies.option_value(s_cpu, :backend) === nothing
            @test Strategies.option_value(s_gpu, :backend) == "cuda_backend"
            
            # Check that common options are the same
            @test Strategies.option_value(s_cpu, :opt1) == 20
            @test Strategies.option_value(s_gpu, :opt1) == 20
        end
        
        # ====================================================================
        # INTEGRATION TESTS - Registry with real strategies
        # ====================================================================
        
        Test.@testset "Registry with real strategies" begin
            # Test that we can create a registry with real parameterized strategies
            r = Strategies.create_registry(
                Modelers.AbstractNLPModeler => (
                    (Modelers.Exa, [CPU, GPU]),
                ),
                Solvers.AbstractNLPSolver => (
                    (Solvers.MadNLP, [CPU, GPU]),
                    (Solvers.MadNCL, [CPU, GPU]),
                )
            )
            
            # Test that all strategies are registered
            modeler_ids = Strategies.strategy_ids(Modelers.AbstractNLPModeler, r)
            solver_ids = Strategies.strategy_ids(Solvers.AbstractNLPSolver, r)
            
            @test :exa in modeler_ids
            @test :madnlp in solver_ids
            @test :madncl in solver_ids
            
            # Test parameter extraction
            @test Strategies.extract_parameter_from_method((:exa, :gpu), r) == GPU
            @test Strategies.extract_parameter_from_method((:madnlp, :cpu), r) == CPU
            @test Strategies.extract_parameter_from_method((:madncl, :gpu), r) == GPU
        end
        
        # ====================================================================
        # INTEGRATION TESTS - Error handling
        # ====================================================================
        
        Test.@testset "Error handling integration" begin
            r = Strategies.create_registry(
                IntegrationFamily => ((IntegrationStratB, [CPU]),)  # Only CPU
            )
            
            # Test that requesting unsupported parameter fails
            @test_throws Exceptions.IncorrectArgument Strategies.build_strategy(
                :integrationstratb, GPU, IntegrationFamily, r
            )
            
            @test_throws Exceptions.IncorrectArgument Strategies.build_strategy_from_method(
                (:integrationstratb, :gpu), IntegrationFamily, r
            )
            
            # Test that unknown strategy ID fails
            @test_throws Exceptions.IncorrectArgument Strategies.build_strategy(
                :nonexistent, CPU, IntegrationFamily, r
            )
        end
        
        # ====================================================================
        # INTEGRATION TESTS - Performance
        # ====================================================================
        
        Test.@testset "Performance and type stability" begin
            r = Strategies.create_registry(
                IntegrationFamily => ((IntegrationStratB, [CPU, GPU]),)
            )
            
            # Test type stability of key functions
            @test_nowarn @inferred Strategies.extract_parameter_from_method((:integrationstratb, :cpu), r)
            @test_nowarn @inferred Strategies.build_strategy_from_method((:integrationstratb, :cpu), IntegrationFamily, r)
            @test_nowarn @inferred Strategies.option_names_from_method((:integrationstratb, :cpu), IntegrationFamily, r)
            
            # Test allocation-free operations where possible
            allocs = @allocated Strategies.extract_parameter_from_method((:integrationstratb, :cpu), r)
            @test allocs == 0  # Should be allocation-free
            
            allocs = @allocated Strategies.strategy_ids(IntegrationFamily, r)
            @test allocs < 100  # Small allocation for tuple creation
        end
    end
end

end # module

# Redefine in outer scope for TestRunner
test_integration_parameters() = TestIntegrationParameters.test_integration_parameters()
