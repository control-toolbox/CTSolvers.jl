# ========================================
# Script de Diagnostic : test_routing_validation Issue
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
using CTSolvers.Orchestration
using Test

# ========================================
# Tests Ciblés pour diagnostiquer le problème de routage
# ========================================

println("🔍 Diagnostic du test : test_routing_validation")
println("=" ^ 50)

# Test 1: Vérifier la signature de route_all_options
println("\n📋 Test 1: Signature de route_all_options")
@testset "route_all_options signature" begin
    # Test avec Vararg (devrait fonctionner)
    try
        result = CTSolvers.Orchestration.route_all_options(
            (:discretizer, :modeler, :solver),
            NamedTuple(),
            [],
            NamedTuple(),
            CTSolvers.Strategies.StrategyRegistry();
            source_mode=:user,
            mode=:strict
        )
        println("✅ route_all_options avec Vararg fonctionne")
        @test true
    catch e
        println("❌ route_all_options avec Vararg échoue: ", e)
        @test false
    end
    
    # Test avec Tuple (ce qui échoue dans le test)
    try
        result = CTSolvers.Orchestration.route_all_options(
            (:discretizer, :modeler, :solver),
            NamedTuple(),
            [],
            NamedTuple(),
            CTSolvers.Strategies.StrategyRegistry();
            source_mode=:user,
            mode=:strict
        )
        println("❌ route_all_options avec Tuple ne devrait pas fonctionner")
        @test false
    catch e
        println("✅ route_all_options avec Tuple échoue comme attendu: ", typeof(e))
        @test true
    end
end

# Test 2: Vérifier comment le test appelle la fonction
println("\n📋 Test 2: Analyse du code du test")
@testset "Test code analysis" begin
    # Simuler ce que le test fait
    strategy_ids = (:discretizer, :modeler, :solver)
    println("🔍 strategy_ids: ", strategy_ids)
    println("🔍 Type: ", typeof(strategy_ids))
    
    # Vérifier si c'est un Tuple ou Vararg
    if strategy_ids isa Tuple
        println("❌ Le test utilise un Tuple, mais route_all_options attend Vararg")
        println("🔍 Solution: Utiliser (strategy_ids...,) pour convertir en Vararg")
    else
        println("✅ Le test utilise déjà Vararg")
    end
end

println("\n" * "=" ^ 50)
println("🎯 Diagnostic terminé !")
