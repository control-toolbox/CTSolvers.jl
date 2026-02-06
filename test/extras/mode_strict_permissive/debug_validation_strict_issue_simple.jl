# ========================================
# Script de Diagnostic : test_validation_strict Issue (Simple)
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

using Test

# ========================================
# Tests Ciblés pour diagnostiquer le problème
# ========================================

println("🔍 Diagnostic du test : test_validation_strict (Simple)")
println("=" ^ 50)

# Test 1: Vérifier si les extensions sont chargées SANS les charger explicitement
println("\n📋 Test 1: Vérification SANS charger les extensions")
@testset "Extension loading (sans chargement explicite)" begin
    @testset "IpoptSolver metadata sans extension" begin
        try
            meta = Strategies.metadata(CTSolvers.Solvers.IpoptSolver)
            println("✅ IpoptSolver metadata trouvé SANS extension: ", typeof(meta))
            @test meta isa CTSolvers.Strategies.StrategyMetadata
        catch e
            println("❌ IpoptSolver metadata échoué SANS extension: ", e)
            println("🔍 Type d'erreur: ", typeof(e))
            @test false
        end
    end
end

# Test 2: Maintenant charger les extensions et vérifier
println("\n📋 Test 2: Vérification APRÈS chargement des extensions")
@testset "Extension loading (après chargement)" begin
    # Charger les extensions
    try
        using NLPModelsIpopt
        using MadNLP
        using MadNLPMumps
        using MadNCL
        using NLPModelsKnitro
        println("✅ Extensions chargées")
    catch e
        println("❌ Erreur chargement extensions: ", e)
    end
    
    @testset "IpoptSolver metadata avec extension" begin
        try
            meta = Strategies.metadata(CTSolvers.Solvers.IpoptSolver)
            println("✅ IpoptSolver metadata trouvé AVEC extension: ", typeof(meta))
            @test meta isa CTSolvers.Strategies.StrategyMetadata
        catch e
            println("❌ IpoptSolver metadata échoué AVEC extension: ", e)
            @test false
        end
    end
end

# Test 3: build_strategy_options avec IpoptSolver
println("\n📋 Test 3: build_strategy_options avec IpoptSolver")
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

println("\n" * "=" ^ 50)
println("🎯 Diagnostic terminé !")
