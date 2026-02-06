# ========================================
# Script de Diagnostic : test_route_to_comprehensive.jl Issue
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
using CTSolvers.Strategies: create_registry, StrategyRegistry, route_to, RoutedOption

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

println("🔍 Diagnostic du test : test_route_to_comprehensive.jl")
println("=" ^ 50)

# Test 1: Vérifier les extensions disponibles
println("\n📋 1. Vérification des extensions disponibles:")
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

# Test 2: Vérifier RoutedOption de base
println("\n📋 2. Test RoutedOption de base:")
try
    # Test route_to() sans arguments (devrait échouer)
    try
        Strategies.route_to()
        println("  ❌ ERREUR: route_to() aurait dû échouer!")
    catch e
        if e isa Exceptions.PreconditionError
            println("  ✅ route_to() correctement échoué: $(typeof(e))")
        else
            println("  ⚠️  route_to() échoué avec erreur inattendue: $(typeof(e))")
        end
    end
    
    # Test RoutedOption vide (devrait échouer)
    try
        Strategies.RoutedOption(NamedTuple())
        println("  ❌ ERREUR: RoutedOption(NamedTuple()) aurait dû échouer!")
    catch e
        if e isa Exceptions.PreconditionError
            println("  ✅ RoutedOption(NamedTuple()) correctement échoué: $(typeof(e))")
        else
            println("  ⚠️  RoutedOption(NamedTuple()) échoué avec erreur inattendue: $(typeof(e))")
        end
    end
    
    # Test avec route_to (devrait fonctionner)
    routed = route_to(adnlp=Float64)
    println("  ✅ route_to(adnlp=Float64) créé")
    println("  📍 Type: $(typeof(routed))")
    
catch e
    println("  ❌ Erreur RoutedOption: $e")
    println("  📍 Stack trace:")
    for (i, frame) in enumerate(stacktrace(catch_backtrace()))
        if i <= 3
            println("      $i: $frame")
        end
    end
end

# Test 3: Vérifier les registres
println("\n📋 3. Test création de registres:")
try
    modeler_registry = create_registry(
        AbstractOptimizationModeler => (ADNLPModeler, ExaModeler)
    )
    println("  ✅ Registre de modelers créé")
    
    solver_registry = if isempty(solver_types)
        create_registry(AbstractOptimizationSolver => ())
    else
        create_registry(AbstractOptimizationSolver => tuple(solver_types...))
    end
    println("  ✅ Registre de solveurs créé")
    
catch e
    println("  ❌ Erreur création registres: $e")
end

# Test 4: Test avec stratégies réelles
println("\n📋 4. Test avec stratégies réelles:")
try
    # Test ADNLPModeler
    modeler = ADNLPModeler()
    println("  ✅ ADNLPModeler créé")
    
    # Test avec route_to
    routed_options = route_to(adnlp=Float64, backend=:sparse)
    println("  ✅ route_to avec options multiples créé")
    
    # Test application
    routed_modeler = modeler(routed_options)
    println("  ✅ Application des options routées réussie")
    
catch e
    println("  ❌ Erreur stratégies réelles: $e")
    println("  📍 Stack trace:")
    for (i, frame) in enumerate(stacktrace(catch_backtrace()))
        if i <= 3
            println("      $i: $frame")
        end
    end
end

# Test 5: Test de validation mode
println("\n📋 5. Test de validation mode:")
try
    # Mode strict
    routed_strict = route_to(adnlp=Float64, fake_option=123)
    modeler_strict = ADNLPModeler(routed_strict; mode=:strict)
    println("  ❌ ERREUR: Le test aurait dû échouer en mode strict!")
    
catch e
    if e isa Exceptions.IncorrectArgument
        println("  ✅ Correctement échoué en mode strict: $(typeof(e))")
    else
        println("  ⚠️  Échoué avec une erreur inattendue: $(typeof(e)) - $e")
    end
end

# Test 6: Test mode permissive
println("\n📋 6. Test mode permissive:")
try
    routed_permissive = route_to(adnlp=Float64, fake_option=123)
    modeler_permissive = ADNLPModeler(routed_permissive; mode=:permissive)
    println("  ✅ Mode permissive OK")
    
catch e
    println("  ❌ Erreur mode permissive: $e")
end

println("\n" * "="^50)
println("🏁 Diagnostic terminé")
