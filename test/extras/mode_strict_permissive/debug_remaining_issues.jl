# ========================================
# Script de Diagnostic : test_validation_strict Remaining Issues
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
using CTSolvers.Options
using NLPModelsIpopt

using Test

# ========================================
# Tests Ciblés pour diagnostiquer les problèmes restants
# ========================================

println("🔍 Diagnostic des problèmes restants dans test_validation_strict")
println("=" ^ 60)

# Test 1: Type validation - tol négatif
println("\n📋 Test 1: Type validation avec tol négatif")
@testset "Type validation - negative tol" begin
    try
        # Ce test devrait échouer avec une exception
        result = Strategies.build_strategy_options(Solvers.IpoptSolver; tol=-1.0)
        println("❌ Le test n'a pas échoué comme attendu")
        println("🔍 Résultat: ", result)
        @test false  # Le test devrait échouer
    catch e
        println("✅ Le test a correctement échoué: ", typeof(e))
        println("🔍 Message: ", e)
        @test true  # C'est le comportement attendu
    end
end

# Test 2: Vérifier le validateur de tol
println("\n📋 Test 2: Vérification du validateur tol")
@testset "Tol validator check" begin
    # Test avec valeur positive (devrait fonctionner)
    try
        opts = Strategies.build_strategy_options(Solvers.IpoptSolver; tol=1e-6)
        println("✅ tol positif fonctionne: ", opts[:tol])
        @test opts[:tol] == 1e-6
    catch e
        println("❌ tol positif échoue: ", e)
        @test false
    end
    
    # Test avec valeur nulle (devrait échouer)
    try
        opts = Strategies.build_strategy_options(Solvers.IpoptSolver; tol=0.0)
        println("❌ tol=0.0 n'a pas échoué comme attendu")
        @test false
    catch e
        println("✅ tol=0.0 correctement rejeté: ", typeof(e))
        @test true
    end
end

# Test 3: Vérifier les messages d'erreur
println("\n📋 Test 3: Messages d'erreur détaillés")
@testset "Error messages" begin
    try
        # Test avec option inconnue pour voir le message d'erreur
        opts = Strategies.build_strategy_options(Solvers.IpoptSolver; unknown_option=123)
        println("❌ Option inconnue acceptée (devrait échouer)")
        @test false
    catch e
        println("✅ Option inconnue rejetée")
        println("🔍 Type d'erreur: ", typeof(e))
        println("🔍 Message: ", e)
        @test e isa CTSolvers.Exceptions.IncorrectArgument
    end
end

println("\n" * "=" ^ 60)
println("🎯 Diagnostic terminé !")
