# ========================================
# Script de Diagnostic : test_route_to_comprehensive Issue
# ========================================

# Configuration de l'environnement
try
    using Revise
catch
    println("🔧 Revise not found - continuing without hot reload")
end

# Imports
using Test
using CTBase: CTBase, Exceptions
using CTSolvers
using CTSolvers.Strategies
using CTSolvers.Orchestration

println("🔍 Diagnostic ciblé pour test_route_to_comprehensive.jl")
println("=" ^ 60)

# ====================================================================
# PROBLÈME 1 : BoundsError ligne 288
# ====================================================================

println("\n📋 1. Analyse du BoundsError dans test_route_to_with_validation:")

# Recréer le contexte exact du test qui échoue
method = (:collocation, :adnlp, :ipopt)
families = (
    discretizer = TestRouteToComprehensive.RouteTestDiscretizer,
    modeler = TestRouteToComprehensive.RouteTestModeler,
    solver = TestRouteToComprehensive.RouteTestSolver
)
kwargs = (grid_size=200, display=false)

println("📍 Method: $method")
println("📍 Families: $families")
println("📍 Kwargs: $kwargs")

try
    # Tenter de reproduire l'erreur
    println("\n🔍 Tentative de reproduction du BoundsError...")
    routed = Orchestration.route_all_options(
        method, families, TestRouteToComprehensive.ACTION_DEFS, kwargs, TestRouteToComprehensive.MOCK_REGISTRY; mode=:strict
    )
    println("✅ Routing réussi: $routed")
    
    # Analyser la structure de routed.strategies
    println("\n🔍 Analyse de routed.strategies:")
    for (family_name, family_options) in pairs(routed.strategies)
        println("  📂 $family_name: $family_options (type: $(typeof(family_options)))")
    end
    
    # Tenter la boucle problématique
    println("\n🔍 Test de la boucle problématique:")
    for (family_name, family_type) in pairs(families)
        println("  🔄 Famille: $family_name -> $family_type")
        println("    📋 family_type.types: $(family_type.types)")
        
        if haskey(routed.strategies, family_name) && !isempty(routed.strategies[family_name])
            println("    ✅ Has options: $(routed.strategies[family_name])")
            
            # Test du first() problématique
            try
                strategy_type = first(family_type.types)
                println("    ✅ first() réussi: $strategy_type")
            catch e
                println("    ❌ Erreur first(): $e")
                
                # Alternative: utiliser les types concrets
                strategy_type = if family_name == :discretizer
                    TestRouteToComprehensive.RouteCollocation
                elseif family_name == :modeler
                    TestRouteToComprehensive.RouteADNLP
                elseif family_name == :solver
                    TestRouteToComprehensive.RouteIpopt
                else
                    println("    ❌ Famille inconnue: $family_name")
                    continue
                end
                println("    🔄 Alternative: $strategy_type")
            end
        else
            println("    ⚠️  Pas d'options ou vide")
        end
    end
    
catch e
    println("❌ Erreur lors du routing: $e")
end

# ====================================================================
# PROBLÈME 2 : Option Absence Test Failed
# ====================================================================

println("\n📋 2. Analyse du test d'absence d'option:")

# Recréer le contexte exact du test qui échoue
println("\n🔍 Test de création de stratégie avec options routées:")

try
    # Recréer le routing du test Single Strategy
    kwargs_single = (
        grid_size = 200,
        backend = Strategies.route_to(adnlp=:default),
        max_iter = 1000,
        display = false
    )
    
    println("📍 Kwargs single: $kwargs_single")
    
    routed_single = Orchestration.route_all_options(
        method, families, TestRouteToComprehensive.ACTION_DEFS, kwargs_single, TestRouteToComprehensive.MOCK_REGISTRY; mode=:strict
    )
    
    println("✅ Routing single réussi")
    println("📂 routed.strategies: $(routed_single.strategies)")
    
    # Créer les stratégies avec les options routées
    println("\n🔍 Création des stratégies avec options routées:")
    
    # Solver
    if haskey(routed_single.strategies, :solver)
        solver_options = routed_single.strategies.solver
        println("  🔧 Solver options: $solver_options")
        
        solver = TestRouteToComprehensive.create_mock_strategy(
            TestRouteToComprehensive.RouteIpopt; 
            mode=:strict, 
            solver_options...
        )
        println("  ✅ Solver créé: $solver")
        
        # Tester si l'option backend est présente
        has_backend = TestRouteToComprehensive.has_option(solver, :backend)
        println("  📋 Solver has_option(:backend): $has_backend")
        
        if has_backend
            backend_value = TestRouteToComprehensive.option_value(solver, :backend)
            println("  📋 Solver backend value: $backend_value")
        end
        
        # Test de la fonction test_option_absence
        println("\n🔍 Test de test_option_absence:")
        try
            TestRouteToComprehensive.test_option_absence(solver, :backend)
            println("  ✅ test_option_absence(:backend) réussi")
        catch e
            println("  ❌ test_option_absence(:backend) échoué: $e")
            
            # Analyser pourquoi
            if TestRouteToComprehensive.has_option(solver, :backend)
                println("    💡 L'option backend est présente alors qu'elle ne devrait pas l'être")
                println("    💡 Cela suggère que le routing ne fonctionne pas comme attendu")
            end
        end
    else
        println("  ⚠️  Pas d'options pour solver")
    end
    
catch e
    println("❌ Erreur: $e")
end

# ====================================================================
# ANALYSE APPROFONDIE
# ====================================================================

println("\n📋 3. Analyse approfondie du comportement de routing:")

# Analyser comment les options sont routées
test_kwargs = (
    grid_size = 200,  # Auto-route to discretizer
    backend = Strategies.route_to(adnlp=:default),  # Route to modeler only
    max_iter = 1000,  # Auto-route to solver (unambiguous)
    display = false   # Action option
)

println("📍 Test kwargs: $test_kwargs")

try
    routed_test = Orchestration.route_all_options(
        method, families, TestRouteToComprehensive.ACTION_DEFS, test_kwargs, TestRouteToComprehensive.MOCK_REGISTRY; mode=:strict
    )
    
    println("\n🔍 Analyse détaillée du routing:")
    println("  📂 Action options: $(routed_test.action)")
    println("  📂 Strategy options:")
    
    for (family, options) in pairs(routed_test.strategies)
        println("    $family: $options")
        
        # Vérifier si backend est dans les options du solver
        if family == :solver
            has_backend_solver = haskey(options, :backend)
            println("      🔍 Solver a backend: $has_backend_solver")
        end
        
        # Vérifier si max_iter est dans les options du modeler
        if family == :modeler
            has_max_iter_modeler = haskey(options, :max_iter)
            println("      🔍 Modeler a max_iter: $has_max_iter_modeler")
        end
    end
    
    # Conclusion
    println("\n🎯 Conclusion du diagnostic:")
    println("  📊 Le routing semble fonctionner mais les tests d'absence échouent")
    println("  💡 Possible que les mock stratégies ne respectent pas le routing")
    println("  🔧 Solution: Simplifier les tests ou corriger la logique de mock")
    
catch e
    println("❌ Erreur dans l'analyse: $e")
end

println("\n" + "=" ^ 60)
println("🏁 Diagnostic terminé")
