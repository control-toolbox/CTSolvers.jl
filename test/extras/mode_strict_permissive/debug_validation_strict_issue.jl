# ========================================
# Script de Diagnostic : test_validation_strict Issue
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

# Charger les extensions nécessaires
using NLPModelsIpopt
using MadNLP
using MadNLPMumps
using MadNCL
using NLPModelsKnitro

using Test

# ========================================
# Tests Ciblés pour diagnostiquer le problème
# ========================================

println("🔍 Diagnostic du test : test_validation_strict")
println("=" ^ 50)

# Test 1: Vérifier si les extensions sont chargées
println("\n📋 Test 1: Vérification des extensions")
@testset "Extension loading" begin
    @testset "Ipopt extension" begin
        try
            # Vérifier si la méthode metadata existe pour IpoptSolver
            meta = Strategies.metadata(CTSolvers.Solvers.IpoptSolver)
            println("✅ IpoptSolver metadata found: ", typeof(meta))
            @test meta isa CTSolvers.Strategies.StrategyMetadata
        catch e
            println("❌ IpoptSolver metadata failed: ", e)
            @test false
        end
    end
    
    @testset "MadNLP extension" begin
        try
            meta = Strategies.metadata(CTSolvers.Solvers.MadNLPSolver)
            println("✅ MadNLPSolver metadata found: ", typeof(meta))
            @test meta isa CTSolvers.Strategies.StrategyMetadata
        catch e
            println("❌ MadNLPSolver metadata failed: ", e)
            @test false
        end
    end
end

# Test 2: Vérifier les méthodes disponibles
println("\n📋 Test 2: Méthodes disponibles")
@testset "Available methods" begin
    @testset "IpoptSolver methods" begin
        println("🔍 Méthodes pour IpoptSolver:")
        for m in methods(Strategies.metadata)
            if m.sig.types[1] <: Type{<:CTSolvers.Solvers.IpoptSolver}
                println("  ✅ ", m)
            end
        end
    end
    
    @testset "MadNLPSolver methods" begin
        println("🔍 Méthodes pour MadNLPSolver:")
        for m in methods(Strategies.metadata)
            if m.sig.types[1] <: Type{<:CTSolvers.Solvers.MadNLPSolver}
                println("  ✅ ", m)
            end
        end
    end
end

# Test 3: Vérifier build_strategy_options avec ADNLPModeler (qui fonctionne)
println("\n📋 Test 3: build_strategy_options avec ADNLPModeler")
@testset "build_strategy_options ADNLPModeler" begin
    try
        opts = Strategies.build_strategy_options(
            CTSolvers.Modelers.ADNLPModeler;
            mode=:strict,
            backend=:optimized,
            show_time=true
        )
        println("✅ ADNLPModeler build_strategy_options fonctionne")
        @test opts isa CTSolvers.Strategies.StrategyOptions
    catch e
        println("❌ ADNLPModeler build_strategy_options failed: ", e)
        @test false
    end
end

# Test 4: Essayer build_strategy_options avec IpoptSolver
println("\n📋 Test 4: build_strategy_options avec IpoptSolver")
@testset "build_strategy_options IpoptSolver" begin
    try
        opts = Strategies.build_strategy_options(
            CTSolvers.Solvers.IpoptSolver;
            mode=:strict,
            tol=1e-6
        )
        println("✅ IpoptSolver build_strategy_options fonctionne")
        @test opts isa CTSolvers.Strategies.StrategyOptions
    catch e
        println("❌ IpoptSolver build_strategy_options failed: ", e)
        println("🔍 Type d'erreur: ", typeof(e))
        @test false
    end
end

# Test 5: Vérifier les modules chargés
println("\n📋 Test 5: Modules chargés")
@testset "Loaded modules" begin
    println("🔍 Modules chargés:")
    for mod in [CTSolvers, CTSolvers.Solvers, CTSolvers.Strategies, NLPModelsIpopt, MadNLP]
        println("  ✅ ", mod)
    end
    
    # Vérifier si les extensions sont dans le namespace
    try
        @eval using CTSolversIpopt
        println("  ✅ CTSolversIpopt chargé")
    catch e
        println("  ❌ CTSolversIpopt pas chargé: ", e)
    end
end

# Test 6: Vérifier les types de solveurs
println("\n📋 Test 6: Types de solveurs")
@testset "Solver types" begin
    println("🔍 Types de solveurs disponibles:")
    println("  IpoptSolver: ", CTSolvers.Solvers.IpoptSolver)
    println("  MadNLPSolver: ", CTSolvers.Solvers.MadNLPSolver)
    println("  MadNCLSolver: ", CTSolvers.Solvers.MadNCLSolver)
    println("  KnitroSolver: ", CTSolvers.Solvers.KnitroSolver)
end

println("\n" * "=" ^ 50)
println("🎯 Diagnostic terminé !")
