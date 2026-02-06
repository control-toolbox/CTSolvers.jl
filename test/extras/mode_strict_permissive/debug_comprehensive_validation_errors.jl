# ========================================
# Script de Diagnostic : test_comprehensive_validation.jl - Erreurs Spécifiques
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
using CTSolvers.Orchestration
using CTBase: Exceptions
using Test

# Charger les extensions nécessaires
try
    using NLPModelsIpopt
    println("✅ Ipopt extension loaded")
catch
    println("❌ Ipopt extension not available")
end

try
    using MadNLP
    using MadNLPMumps
    println("✅ MadNLP extension loaded")
catch
    println("❌ MadNLP extension not available")
end

try
    using MadNCL
    println("✅ MadNCL extension loaded")
catch
    println("❌ MadNCL extension not available")
end

# ========================================
# Diagnostic des Erreurs Spécifiques
# ========================================

println("🔍 Diagnostic des Erreurs Spécifiques : test_comprehensive_validation.jl")
println("=" ^ 60)

# Test 1: Erreur de message d'exception (strict mode)
println("\n📋 1. Test message d'exception - Strict Mode:")
try
    strategy = ADNLPModeler(; fake_option=123)
    println("  ❌ ERREUR: Le test aurait dû échouer!")
catch e
    println("  ✅ Exception levée: $(typeof(e))")
    println("  📍 Message: $(string(e))")
    println("  🔍 Contient 'unknown': $(occursin("unknown", string(e)))")
    println("  🔍 Contient 'unrecognized': $(occursin("unrecognized", string(e)))")
end

# Test 2: Erreur de build_strategy_from_method (ambiguïté)
println("\n📋 2. Test build_strategy_from_method - Ambiguïté:")
try
    # Test avec qualification explicite
    method = (:collocation, :adnlp, :ipopt)
    registry = CTSolvers.Strategies.create_registry(
        AbstractOptimizationModeler => (ADNLPModeler,),
        AbstractOptimizationSolver => ()
    )
    
    strategy = CTSolvers.Strategies.build_strategy_from_method(
        method, AbstractOptimizationModeler, registry; backend=:sparse
    )
    println("  ✅ build_strategy_from_method qualifié fonctionne")
    
catch e
    println("  ❌ Erreur build_strategy_from_method qualifié: $e")
end

# Test 3: Erreur test_option_recovery (type mismatch)
println("\n📋 3. Test test_option_recovery - Type mismatch:")
try
    # Créer une fonction test_option_recovery simple
    function test_option_recovery_simple(strategy, known_options, unknown_options, mode)
        println("  ✅ test_option_recovery_simple appelé avec:")
        println("     strategy: $(typeof(strategy))")
        println("     known_options: $(typeof(known_options))")
        println("     unknown_options: $(typeof(unknown_options))")
        println("     mode: $mode")
        return true
    end
    
    strategy = ADNLPModeler(; backend=:sparse)
    test_option_recovery_simple(strategy, (backend=:sparse,), (), :strict)
    
catch e
    println("  ❌ Erreur test_option_recovery: $e")
end

# Test 4: Erreur merge (BoundsError)
println("\n📋 4. Test merge - BoundsError:")
try
    # Reproduire l'erreur
    known_options = (backend=:sparse, show_time=true)
    invalid_value = 123  # Ceci cause l'erreur
    
    try
        merged = merge(known_options, invalid_value)
        println("  ❌ ERREUR: Le merge aurait dû échouer!")
    catch e
        println("  ✅ Erreur de merge correctement capturée: $(typeof(e))")
        println("  📍 Message: $e")
    end
    
catch e
    println("  ❌ Erreur inattendue dans le test de merge: $e")
end

# Test 5: Erreur warning capture (@test_nowarn)
println("\n📋 5. Test warning capture - @test_nowarn:")
try
    # Test si les warnings sont capturés correctement
    using Test: @test_nowarn
    
    # Créer un fichier temporaire pour tester
    temp_file = tempname()
    open(temp_file, "w") do io
        println(io, "Test warning content")
    end
    
    # Lire le fichier
    content = read(temp_file, String)
    println("  ✅ Lecture de fichier temporaire: $(length(content)) caractères")
    
    # Nettoyer
    rm(temp_file)
    
catch e
    println("  ❌ Erreur dans test warning capture: $e")
end

# Test 6: Vérification des imports
println("\n📋 6. Vérification des imports et qualifications:")
println("  ✅ CTSolvers.Strategies.build_strategy_from_method disponible: $(isdefined(CTSolvers.Strategies, :build_strategy_from_method))")
println("  ✅ CTSolvers.Orchestration.build_strategy_from_method disponible: $(isdefined(CTSolvers.Orchestration, :build_strategy_from_method))")

# Test 7: Création de registre
println("\n📋 7. Test création de registre:")
try
    modeler_registry = CTSolvers.Strategies.create_registry(
        AbstractOptimizationModeler => (ADNLPModeler, ExaModeler)
    )
    println("  ✅ Registre de modelers créé: $(typeof(modeler_registry))")
    
    solver_registry = CTSolvers.Strategies.create_registry(
        AbstractOptimizationSolver => ()
    )
    println("  ✅ Registre de solveurs vide créé: $(typeof(solver_registry))")
    
catch e
    println("  ❌ Erreur création registre: $e")
end

println("\n" * "="^60)
println("🏁 Diagnostic des erreurs spécifiques terminé")
