# ========================================
# Script de Diagnostic : test_comprehensive_validation.jl Issue
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
using CTSolvers.Strategies: build_strategy, build_strategy_from_method

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

using Test

# ========================================
# Tests Ciblés pour diagnostiquer le problème
# ========================================

println("🔍 Diagnostic du test : test_comprehensive_validation.jl")
println("=" ^ 50)

# Test 1: Vérifier les extensions disponibles
println("\n📋 1. Vérification des extensions disponibles:")
global solver_registry = nothing
try
    solver_types = []
    try
        push!(solver_types, CTSolvers.Solvers.IpoptSolver)
        println("  ✅ IpoptSolver disponible")
    catch
        println("  ❌ IpoptSolver non disponible")
    end
    
    try
        push!(solver_types, CTSolvers.Solvers.MadNLPSolver)
        println("  ✅ MadNLPSolver disponible")
    catch
        println("  ❌ MadNLPSolver non disponible")
    end
    
    try
        push!(solver_types, CTSolvers.Solvers.MadNCLSolver)
        println("  ✅ MadNCLSolver disponible")
    catch
        println("  ❌ MadNCLSolver non disponible")
    end
    
    println("  📊 Solveurs disponibles: $(length(solver_types))")
    
    # Créer le registre
    solver_registry = if isempty(solver_types)
        create_registry(AbstractOptimizationSolver => ())
    else
        create_registry(AbstractOptimizationSolver => tuple(solver_types...))
    end
    
    println("  ✅ Registre de solveurs créé")
    
catch e
    println("  ❌ Erreur lors de la création du registre: $e")
end

# Test 2: Tests de base pour chaque solveur disponible
println("\n📋 2. Tests de base pour chaque solveur:")

# Test Ipopt
println("\n  🔍 Test IpoptSolver:")
try
    # Test constructeur direct
    solver = CTSolvers.Solvers.IpoptSolver(max_iter=100, tol=1e-6)
    println("    ✅ Constructeur direct OK")
    
    # Test mode permissive avec option inconnue
    solver_permissive = CTSolvers.Solvers.IpoptSolver(max_iter=100, tol=1e-6, fake_option=123, mode=:permissive)
    println("    ✅ Mode permissive OK")
    
    # Test build_strategy
    strategy = build_strategy(:ipopt, AbstractOptimizationSolver, solver_registry; max_iter=100, tol=1e-6)
    println("    ✅ build_strategy OK")
    
    # Test build_strategy en mode permissive
    strategy_permissive = build_strategy(:ipopt, AbstractOptimizationSolver, solver_registry; max_iter=100, tol=1e-6, fake_option=123, mode=:permissive)
    println("    ✅ build_strategy permissive OK")
    
catch e
    println("    ❌ Erreur IpoptSolver: $e")
    println("    📍 Stack trace:")
    for (i, frame) in enumerate(stacktrace(catch_backtrace()))
        if i <= 3  # Limiter l'affichage
            println("      $i: $frame")
        end
    end
end

# Test MadNLP
println("\n  🔍 Test MadNLPSolver:")
try
    # Test constructeur direct
    solver = CTSolvers.Solvers.MadNLPSolver(max_iter=500, tol=1e-8)
    println("    ✅ Constructeur direct OK")
    
    # Test mode permissive avec option inconnue
    solver_permissive = CTSolvers.Solvers.MadNLPSolver(max_iter=500, tol=1e-8, fake_option=456, mode=:permissive)
    println("    ✅ Mode permissive OK")
    
    # Test build_strategy
    strategy = build_strategy(:madnlp, AbstractOptimizationSolver, solver_registry; max_iter=500, tol=1e-8)
    println("    ✅ build_strategy OK")
    
    # Test build_strategy en mode permissive
    strategy_permissive = build_strategy(:madnlp, AbstractOptimizationSolver, solver_registry; max_iter=500, tol=1e-8, fake_option=456, mode=:permissive)
    println("    ✅ build_strategy permissive OK")
    
catch e
    println("    ❌ Erreur MadNLPSolver: $e")
    println("    📍 Stack trace:")
    for (i, frame) in enumerate(stacktrace(catch_backtrace()))
        if i <= 3  # Limiter l'affichage
            println("      $i: $frame")
        end
    end
end

# Test MadNCL
println("\n  🔍 Test MadNCLSolver:")
try
    # Test constructeur direct
    solver = CTSolvers.Solvers.MadNCLSolver(max_iter=300, tol=1e-10)
    println("    ✅ Constructeur direct OK")
    
    # Test mode permissive avec option inconnue
    solver_permissive = CTSolvers.Solvers.MadNCLSolver(max_iter=300, tol=1e-10, fake_option=789, mode=:permissive)
    println("    ✅ Mode permissive OK")
    
    # Test build_strategy
    strategy = build_strategy(:madncl, AbstractOptimizationSolver, solver_registry; max_iter=300, tol=1e-10)
    println("    ✅ build_strategy OK")
    
    # Test build_strategy en mode permissive
    strategy_permissive = build_strategy(:madncl, AbstractOptimizationSolver, solver_registry; max_iter=300, tol=1e-10, fake_option=789, mode=:permissive)
    println("    ✅ build_strategy permissive OK")
    
catch e
    println("    ❌ Erreur MadNCLSolver: $e")
    println("    📍 Stack trace:")
    for (i, frame) in enumerate(stacktrace(catch_backtrace()))
        if i <= 3  # Limiter l'affichage
            println("      $i: $frame")
        end
    end
end

# Test 3: Tests de mode strict (devraient échouer)
println("\n📋 3. Tests de mode strict (devraient échouer):")

println("\n  🔍 Test IpoptSolver mode strict avec option inconnue:")
try
    # Ceci devrait échouer
    solver = CTSolvers.Solvers.IpoptSolver(max_iter=100, tol=1e-6, fake_option=123)
    println("    ❌ ERREUR: Le test aurait dû échouer en mode strict!")
catch e
    if e isa Exceptions.IncorrectArgument
        println("    ✅ Correctement échoué en mode strict: $(typeof(e))")
    else
        println("    ⚠️  Échoué avec une erreur inattendue: $(typeof(e)) - $e")
    end
end

println("\n📋 4. Tests de build_strategy_from_method:")
try
    method = (:collocation, :adnlp, :ipopt)
    strategy = build_strategy_from_method(method, AbstractOptimizationSolver, solver_registry; max_iter=100, tol=1e-6)
    println("  ✅ build_strategy_from_method OK")
    
    # Test mode permissive
    strategy_permissive = build_strategy_from_method(method, AbstractOptimizationSolver, solver_registry; max_iter=100, tol=1e-6, fake_option=123, mode=:permissive)
    println("  ✅ build_strategy_from_method permissive OK")
    
catch e
    println("  ❌ Erreur build_strategy_from_method: $e")
end

println("\n📋 5. Tests d'orchestration:")
try
    method = (:collocation, :adnlp, :ipopt)
    strategy = Orchestration.build_strategy_from_method(method, AbstractOptimizationSolver, solver_registry; max_iter=100, tol=1e-6)
    println("  ✅ Orchestration wrapper OK")
    
    # Test mode permissive
    strategy_permissive = Orchestration.build_strategy_from_method(method, AbstractOptimizationSolver, solver_registry; max_iter=100, tol=1e-6, fake_option=123, mode=:permissive)
    println("  ✅ Orchestration wrapper permissive OK")
    
catch e
    println("  ❌ Erreur Orchestration wrapper: $e")
end

println("\n" * "="^50)
println("🏁 Diagnostic terminé")
