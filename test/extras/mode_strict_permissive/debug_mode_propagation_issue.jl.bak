# ========================================
# Script de Diagnostic : test_mode_propagation Issue
# ========================================

# Configuration de l'environnement
try
    using Revise
catch
    println("🔧 Revise not found - continuing without hot reload")
end

using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))

# Add CTSolvers in development mode
if !haskey(Pkg.project().dependencies, "CTSolvers")
    Pkg.develop(path=joinpath(@__DIR__, "..", "..", ".."))
end

using CTSolvers
using CTSolvers.Strategies
using CTSolvers.Solvers
using CTSolvers.Modelers
using CTSolvers.Options

using Test

# ============================================================================
# TOP-LEVEL: Fake strategy types for testing (copied from test_mode_propagation.jl)
# ============================================================================

"""Fake strategy for testing mode propagation."""
struct FakeStrategy <: Strategies.AbstractStrategy
    options::Strategies.StrategyOptions
end

# Required method for strategy registration
Strategies.id(::Type{FakeStrategy}) = :fake

"""Fake strategy metadata for testing."""
function Strategies.metadata(::Type{FakeStrategy})
    return Strategies.StrategyMetadata(
        Options.OptionDefinition(
            name=:known_option,
            type=Int,
            default=100,
            description="A known option for testing"
        )
    )
end

"""Fake strategy constructor."""
function FakeStrategy(; mode::Symbol = :strict, kwargs...)
    opts = Strategies.build_strategy_options(FakeStrategy; mode=mode, kwargs...)
    return FakeStrategy(opts)
end

# ========================================
# Tests Ciblés pour diagnostiquer le problème
# ========================================

println("🔍 Diagnostic du test : test_mode_propagation")
println("=" ^ 50)

# Test 1: Vérifier FakeStrategy isolation
@testset "FakeStrategy Basic Tests" begin
    println("\n📋 Test 1: FakeStrategy basic functionality")
    
    # Test metadata
    try
        meta = Strategies.metadata(FakeStrategy)
        println("✅ metadata(FakeStrategy) fonctionne")
        @test meta isa Strategies.StrategyMetadata
    catch e
        println("❌ metadata(FakeStrategy) échoue: ", e)
        @test false
    end
    
    # Test id (correct way)
    try
        id = Strategies.id(FakeStrategy)
        println("✅ id(FakeStrategy) fonctionne: ", id)
        @test id == :fake
    catch e
        println("❌ id(FakeStrategy) échoue: ", e)
        @test false
    end
end

# Test 2: Vérifier le registre
@testset "Registry Creation" begin
    println("\n📋 Test 2: Registry creation with FakeStrategy")
    
    try
        registry = Strategies.create_registry(
            Strategies.AbstractStrategy => (FakeStrategy,)
        )
        println("✅ Registry créé avec FakeStrategy")
        @test registry isa Strategies.StrategyRegistry
        
        # Vérifier que FakeStrategy est bien enregistré
        ids = Strategies.strategy_ids(Strategies.AbstractStrategy, registry)
        println("🔍 Stratégies enregistrées: ", ids)
        @test :fake in ids
    catch e
        println("❌ Registry création échoue: ", e)
        @test false
    end
end

# Test 3: Test build_strategy_options directement
@testset "build_strategy_options Direct" begin
    println("\n📋 Test 3: build_strategy_options direct call")
    
    try
        # Test avec mode permissive et option connue
        opts = Strategies.build_strategy_options(FakeStrategy; known_option=500, mode=:permissive)
        println("✅ build_strategy_options fonctionne")
        @test opts isa Strategies.StrategyOptions
        
        # Créer une stratégie pour tester option_value
        strategy = FakeStrategy(opts)
        @test Strategies.option_value(strategy, :known_option) == 500
        @test Strategies.option_source(strategy, :known_option) == :user
        
    catch e
        println("❌ build_strategy_options échoue: ", e)
        println("🔍 Type d'erreur: ", typeof(e))
        @test false
    end
end

# Test 4: Test build_strategy_from_method étape par étape
@testset "build_strategy_from_method Analysis" begin
    println("\n📋 Test 4: build_strategy_from_method step by step")
    
    try
        registry = Strategies.create_registry(
            Strategies.AbstractStrategy => (FakeStrategy,)
        )
        method = (:fake,)
        
        println("🔍 Tentative build_strategy_from_method avec known_option=500, mode=:permissive")
        
        strategy = Strategies.build_strategy_from_method(
            method,
            Strategies.AbstractStrategy, 
            registry; 
            known_option=500,
            mode=:permissive
        )
        
        println("✅ build_strategy_from_method fonctionne")
        @test strategy isa FakeStrategy
        
    catch e
        println("❌ build_strategy_from_method échoue: ", e)
        println("🔍 Type d'erreur: ", typeof(e))
        println("🔍 Stack trace:")
        for (i, frame) in enumerate(stacktrace(catch_backtrace()))
            if i <= 5  # Limiter l'affichage
                println("  $i: $frame")
            end
        end
        @test false
    end
end

# Test 5: Vérifier la propagation du mode
@testset "Mode Propagation Debug" begin
    println("\n📋 Test 5: Mode propagation analysis")
    
    # Test direct avec FakeStrategy constructor
    try
        strategy = FakeStrategy(; known_option=500, mode=:permissive)
        println("✅ FakeStrategy constructor fonctionne")
        @test strategy isa FakeStrategy
    catch e
        println("❌ FakeStrategy constructor échoue: ", e)
        @test false
    end
end

println("\n" * "=" ^ 50)
println("🎯 Diagnostic terminé !")
