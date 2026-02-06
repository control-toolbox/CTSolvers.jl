# ========================================
# Script de Diagnostic : test_strict_permissive_integration Issue
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
# TOP-LEVEL: Fake strategy types for testing (copied from test file)
# ============================================================================

"""Fake solver for testing."""
struct FakeSolver <: Strategies.AbstractStrategy
    options::Strategies.StrategyOptions
end

"""Fake modeler for testing."""
struct FakeModeler <: Strategies.AbstractStrategy
    options::Strategies.StrategyOptions
end

"""Fake discretizer for testing."""
struct FakeDiscretizer <: Strategies.AbstractStrategy
    options::Strategies.StrategyOptions
end

# Strategy IDs
Strategies.id(::Type{FakeSolver}) = :fake_solver
Strategies.id(::Type{FakeModeler}) = :fake_modeler
Strategies.id(::Type{FakeDiscretizer}) = :fake_discretizer

# Metadata for FakeSolver
function Strategies.metadata(::Type{FakeSolver})
    return Strategies.StrategyMetadata(
        Options.OptionDefinition(
            name=:tol,
            type=Float64,
            default=1e-6,
            description="Tolerance"
        )
    )
end

# Metadata for FakeModeler
function Strategies.metadata(::Type{FakeModeler})
    return Strategies.StrategyMetadata(
        Options.OptionDefinition(
            name=:model_type,
            type=Symbol,
            default=:auto,
            description="Model type"
        )
    )
end

# Metadata for FakeDiscretizer
function Strategies.metadata(::Type{FakeDiscretizer})
    return Strategies.StrategyMetadata(
        Options.OptionDefinition(
            name=:grid_size,
            type=Int,
            default=100,
            description="Grid size"
        )
    )
end

# Constructors
function FakeSolver(; mode::Symbol = :strict, kwargs...)
    opts = redirect_stderr(devnull) do
        Strategies.build_strategy_options(FakeSolver; mode=mode, kwargs...)
    end
    return FakeSolver(opts)
end

function FakeModeler(; mode::Symbol = :strict, kwargs...)
    opts = redirect_stderr(devnull) do
        Strategies.build_strategy_options(FakeModeler; mode=mode, kwargs...)
    end
    return FakeModeler(opts)
end

function FakeDiscretizer(; mode::Symbol = :strict, kwargs...)
    opts = redirect_stderr(devnull) do
        Strategies.build_strategy_options(FakeDiscretizer; mode=mode, kwargs...)
    end
    return FakeDiscretizer(opts)
end

# ========================================
# Tests Ciblés pour diagnostiquer le problème
# ========================================

println("🔍 Diagnostic du test : test_strict_permissive_integration")
println("=" ^ 50)

# Test 1: Registry creation
@testset "Registry Creation" begin
    println("\n📋 Test 1: Registry creation with multiple strategies")
    
    try
        registry = Strategies.create_registry(
            Strategies.AbstractStrategy => (FakeSolver, FakeModeler, FakeDiscretizer)
        )
        println("✅ Registry créé avec succès")
        @test registry isa Strategies.StrategyRegistry
        
        # Vérifier que toutes les stratégies sont enregistrées
        ids = Strategies.strategy_ids(Strategies.AbstractStrategy, registry)
        println("🔍 Stratégies enregistrées: ", ids)
        @test :fake_solver in ids
        @test :fake_modeler in ids
        @test :fake_discretizer in ids
    catch e
        println("❌ Registry création échoue: ", e)
        @test false
    end
end

# Test 2: Build from ID
@testset "Build from ID" begin
    println("\n📋 Test 2: Build strategy from ID")
    
    try
        registry = Strategies.create_registry(
            Strategies.AbstractStrategy => (FakeSolver, FakeModeler, FakeDiscretizer)
        )
        
        # Test build from ID
        solver = Strategies.build_strategy(
            :fake_solver,
            Strategies.AbstractStrategy,
            registry;
            tol=1e-8
        )
        println("✅ Build from ID fonctionne")
        @test solver isa FakeSolver
        @test Strategies.option_value(solver, :tol) == 1e-8
        
    catch e
        println("❌ Build from ID échoue: ", e)
        println("🔍 Type d'erreur: ", typeof(e))
        @test false
    end
end

# Test 3: Build from method tuple
@testset "Build from Method Tuple" begin
    println("\n📋 Test 3: Build strategy from method tuple")
    
    try
        registry = Strategies.create_registry(
            Strategies.AbstractStrategy => (FakeSolver, FakeModeler)
        )
        
        method = (:fake_solver,)
        
        # Test build from method tuple (single strategy)
        solver = Strategies.build_strategy_from_method(
            method,
            Strategies.AbstractStrategy,
            registry;
            tol=1e-8  # Only options that belong to FakeSolver
        )
        println("✅ Build from method tuple fonctionne")
        @test solver isa FakeSolver
        
    catch e
        println("❌ Build from method tuple échoue: ", e)
        println("🔍 Type d'erreur: ", typeof(e))
        @test false
    end
end

println("\n" * "=" ^ 50)
println("🎯 Diagnostic terminé !")
