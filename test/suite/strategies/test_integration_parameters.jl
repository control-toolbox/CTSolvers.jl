module TestIntegrationParameters

import Test
import CTBase.Exceptions
import CTSolvers.Strategies
import CTSolvers.Modelers
import CTSolvers.Solvers
import CTSolvers.Options

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
Strategies.metadata(::Type{T}) where {T<:IntegrationStratA} = Strategies.StrategyMetadata(
    Options.OptionDefinition(
        name = :opt1,
        type = Int,
        default = 10,
        description = "Option 1"
    )
)

Strategies.metadata(::Type{T}) where {T<:IntegrationStratB} = Strategies.StrategyMetadata(
    Options.OptionDefinition(
        name = :opt1,
        type = Int,
        default = 20,
        description = "Option 1"
    ),
    Options.OptionDefinition(
        name = :backend,
        type = Union{Nothing, String},
        default = nothing,
        description = "Backend type"
    )
)

# Parameter-specific metadata
function Strategies.metadata(::Type{IntegrationStratB{P}}) where {P<:Strategies.AbstractStrategyParameter}
    backend_default = P == Strategies.CPU ? nothing : "cuda_backend"
    return Strategies.StrategyMetadata(
        Options.OptionDefinition(
            name = :opt1,
            type = Int,
            default = 20,
            description = "Option 1"
        ),
        Options.OptionDefinition(
            name = :backend,
            type = Union{Nothing, String},
            default = backend_default,
            description = "Backend type"
        )
    )
end

# Simple constructors
function IntegrationStratA(; mode=:strict, kwargs...)
    opts = Strategies.build_strategy_options(IntegrationStratA; mode=mode, kwargs...)
    return IntegrationStratA(opts)
end

function IntegrationStratB{P}(; mode=:strict, kwargs...) where {P<:Strategies.AbstractStrategyParameter}
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
                    (IntegrationStratB, [Strategies.CPU, Strategies.GPU])
                )
            )
            
            # Test strategy IDs deduplication
            ids = Strategies.strategy_ids(IntegrationFamily, r)
            Test.@test length(ids) == 2  # :integrationstrata, :integrationstratb
            Test.@test :integrationstrata in ids
            Test.@test :integrationstratb in ids
            
            # Test parameter extraction from method
            Test.@test Strategies.extract_parameter_from_method((:integrationstratb, :cpu), r) == Strategies.CPU
            Test.@test Strategies.extract_parameter_from_method((:integrationstratb, :gpu), r) == Strategies.GPU
            Test.@test Strategies.extract_parameter_from_method((:integrationstratb,), r) === nothing
            
            # Test building strategies from method
            s_cpu = Strategies.build_strategy_from_method((:integrationstratb, :cpu), IntegrationFamily, r)
            s_gpu = Strategies.build_strategy_from_method((:integrationstratb, :gpu), IntegrationFamily, r)
            s_default = Strategies.build_strategy_from_method((:integrationstratb,), IntegrationFamily, r)
            
            Test.@test s_cpu isa IntegrationStratB{Strategies.CPU}
            Test.@test s_gpu isa IntegrationStratB{Strategies.GPU}
            Test.@test s_default isa IntegrationStratB{Strategies.CPU}  # Default to Strategies.CPU
            
            # Test option names from method
            names_cpu = Strategies.option_names_from_method((:integrationstratb, :cpu), IntegrationFamily, r)
            names_gpu = Strategies.option_names_from_method((:integrationstratb, :gpu), IntegrationFamily, r)
            
            Test.@test :opt1 in names_cpu
            Test.@test :backend in names_cpu
            Test.@test :opt1 in names_gpu
            Test.@test :backend in names_gpu
        end
        
        # ====================================================================
        # INTEGRATION TESTS - Parameter-specific defaults
        # ====================================================================
        
        Test.@testset "Parameter-specific default options" begin
            r = Strategies.create_registry(
                IntegrationFamily => ((IntegrationStratB, [Strategies.CPU, Strategies.GPU]),)
            )
            
            s_cpu = Strategies.build_strategy_from_method((:integrationstratb, :cpu), IntegrationFamily, r)
            s_gpu = Strategies.build_strategy_from_method((:integrationstratb, :gpu), IntegrationFamily, r)
            
            # Check that defaults are different based on parameter
            Test.@test Strategies.option_value(s_cpu, :backend) === nothing
            Test.@test Strategies.option_value(s_gpu, :backend) == "cuda_backend"
            
            # Check that common options are the same
            Test.@test Strategies.option_value(s_cpu, :opt1) == 20
            Test.@test Strategies.option_value(s_gpu, :opt1) == 20
        end
        
        # ====================================================================
        # INTEGRATION TESTS - Registry with real strategies
        # ====================================================================
        
        Test.@testset "Registry with real strategies" begin
            # Test that we can create a registry with real parameterized strategies
            r = Strategies.create_registry(
                Modelers.AbstractNLPModeler => (
                    (Modelers.Exa, [Strategies.CPU, Strategies.GPU]),
                ),
                Solvers.AbstractNLPSolver => (
                    (Solvers.MadNLP, [Strategies.CPU, Strategies.GPU]),
                    (Solvers.MadNCL, [Strategies.CPU, Strategies.GPU]),
                )
            )
            
            # Test that all strategies are registered
            modeler_ids = Strategies.strategy_ids(Modelers.AbstractNLPModeler, r)
            solver_ids = Strategies.strategy_ids(Solvers.AbstractNLPSolver, r)
            
            Test.@test :exa in modeler_ids
            Test.@test :madnlp in solver_ids
            Test.@test :madncl in solver_ids
            
            # Test parameter extraction
            Test.@test Strategies.extract_parameter_from_method((:exa, :gpu), r) == Strategies.GPU
            Test.@test Strategies.extract_parameter_from_method((:madnlp, :cpu), r) == Strategies.CPU
            Test.@test Strategies.extract_parameter_from_method((:madncl, :gpu), r) == Strategies.GPU
        end
        
        # ====================================================================
        # INTEGRATION TESTS - Error handling
        # ====================================================================
        
        Test.@testset "Error handling integration" begin
            r = Strategies.create_registry(
                IntegrationFamily => ((IntegrationStratB, [Strategies.CPU]),)  # Only Strategies.CPU
            )
            
            # Test that requesting unsupported parameter fails
            Test.@test_throws Exceptions.IncorrectArgument Strategies.build_strategy(
                :integrationstratb, Strategies.GPU, IntegrationFamily, r
            )
            
            Test.@test_throws Exceptions.IncorrectArgument Strategies.build_strategy_from_method(
                (:integrationstratb, :gpu), IntegrationFamily, r
            )
            
            # Test that unknown strategy ID fails
            Test.@test_throws Exceptions.IncorrectArgument Strategies.build_strategy(
                :nonexistent, Strategies.CPU, IntegrationFamily, r
            )
        end
        
        # ====================================================================
        # INTEGRATION TESTS - Performance
        # ====================================================================
        
        Test.@testset "Performance and type stability" begin
            r = Strategies.create_registry(
                IntegrationFamily => ((IntegrationStratB, [Strategies.CPU, Strategies.GPU]),)
            )
            
            # Test type stability of key functions
            Test.@test_nowarn Test.@inferred Strategies.extract_parameter_from_method((:integrationstratb, :cpu), r)
            Test.@test_nowarn Test.@inferred Strategies.build_strategy_from_method((:integrationstratb, :cpu), IntegrationFamily, r)
            Test.@test_nowarn Test.@inferred Strategies.option_names_from_method((:integrationstratb, :cpu), IntegrationFamily, r)
            
            # Test allocation-free operations where possible
            allocs = @allocated Strategies.extract_parameter_from_method((:integrationstratb, :cpu), r)
            Test.@test allocs == 0  # Should be allocation-free
            
            allocs = @allocated Strategies.strategy_ids(IntegrationFamily, r)
            Test.@test allocs < 100  # Small allocation for tuple creation
        end
    end
end

end # module

# Redefine in outer scope for TestRunner
test_integration_parameters() = TestIntegrationParameters.test_integration_parameters()
