# ========================================
# Script de Diagnostic : test_route_to_comprehensive BoundsError
# ========================================

# Imports de base
using Test
using CTBase: CTBase
const Exceptions = CTBase.Exceptions
using CTSolvers
using CTSolvers.Strategies
using CTSolvers.Orchestration

println("🔍 Diagnostic du BoundsError dans test_route_to_comprehensive.jl")
println("=" ^ 60)

# Créer des types mock simples pour le diagnostic
module TestDiag
    abstract type MockStrategy <: CTSolvers.Strategies.AbstractStrategy end
    
    struct MockCollocation <: MockStrategy
        options::NamedTuple
    end
    
    struct MockADNLP <: MockStrategy
        options::NamedTuple
    end
    
    struct MockIpopt <: MockStrategy
        options::NamedTuple
    end
    
    # Constructeurs simples
    MockCollocation(; kwargs...) = MockCollocation((; kwargs...))
    MockADNLP(; kwargs...) = MockADNLP((; kwargs...))
    MockIpopt(; kwargs...) = MockIpopt((; kwargs...))
    
    # Métadonnées minimales
    function CTSolvers.Strategies.metadata(::Type{MockCollocation})
        CTSolvers.Strategies.StrategyMetadata(
            CTSolvers.Strategies.OptionDefinition(name=:grid_size, type=Int, default=100, description="Grid size")
        )
    end
    
    function CTSolvers.Strategies.metadata(::Type{MockADNLP})
        CTSolvers.Strategies.StrategyMetadata(
            CTSolvers.Strategies.OptionDefinition(name=:backend, type=Symbol, default=:default, description="Backend type")
        )
    end
    
    function CTSolvers.Strategies.metadata(::Type{MockIpopt})
        CTSolvers.Strategies.StrategyMetadata(
            CTSolvers.Strategies.OptionDefinition(name=:max_iter, type=Int, default=1000, description="Max iterations")
        )
    end
    
    # Options helpers
    has_option(strategy, name) = haskey(strategy.options, name)
    option_value(strategy, name) = strategy.options[name]
end

# Créer le registre
registry = CTSolvers.Strategies.create_registry(
    TestDiag.MockCollocation => (TestDiag.MockCollocation,),
    TestDiag.MockADNLP => (TestDiag.MockADNLP,),
    TestDiag.MockIpopt => (TestDiag.MockIpopt,)
)

# Définir les familles
families = (
    discretizer = TestDiag.MockCollocation,
    modeler = TestDiag.MockADNLP,
    solver = TestDiag.MockIpopt
)

method = (:collocation, :adnlp, :ipopt)
kwargs = (grid_size=200, display=false)

println("📍 Method: $method")
println("📍 Families: $families")
println("📍 Kwargs: $kwargs")

# Test du routing
try
    println("\n🔍 Test du routing...")
    routed = Orchestration.route_all_options(
        method, families, CTSolvers.Options.OptionDefinition{Bool}[], kwargs, registry; mode=:strict
    )
    println("✅ Routing réussi")
    
    println("\n📂 Résultat du routing:")
    println("  Action: $(routed.action)")
    println("  Strategies: $(routed.strategies)")
    
    # Analyser la structure qui cause le BoundsError
    println("\n🔍 Analyse des types de familles:")
    for (family_name, family_type) in pairs(families)
        println("  📂 $family_name: $family_type")
        
        # Vérifier family_type.types
        try
            types_field = family_type.types
            println("    📋 types: $types_field")
            println("    📋 types type: $(typeof(types_field))")
            
            # Tenter first()
            try
                first_type = first(types_field)
                println("    ✅ first(): $first_type")
            catch e
                println("    ❌ first() erreur: $e")
                
                # Vérifier si c'est un tuple vide
                if isempty(types_field)
                    println("    💡 Le tuple est vide!")
                end
            end
        catch e
            println("    ❌ Erreur accès types: $e")
        end
    end
    
    # Test de la boucle problématique
    println("\n🔍 Test de la boucle problématique:")
    for (family_name, family_type) in pairs(families)
        if haskey(routed.strategies, family_name) && !isempty(routed.strategies[family_name])
            println("  🔄 Traitement de $family_name")
            
            # Solution: utiliser les types concrets directement
            strategy_type = if family_name == :discretizer
                TestDiag.MockCollocation
            elseif family_name == :modeler
                TestDiag.MockADNLP
            elseif family_name == :solver
                TestDiag.MockIpopt
            else
                println("    ❌ Famille inconnue: $family_name")
                continue
            end
            
            println("    ✅ Type concret: $strategy_type")
            
            # Créer la stratégie
            strategy = strategy_type(; routed.strategies[family_name]...)
            println("    ✅ Stratégie créée: $strategy")
        end
    end
    
catch e
    println("❌ Erreur: $e")
    println("💡 Stacktrace:")
    for (i, frame) in enumerate(stacktrace(catch_backtrace()))
        println("  $i. $frame")
        if i >= 5  # Limiter la sortie
            break
        end
    end
end

println("\n" + "=" ^ 60)
println("🏁 Diagnostic BoundsError terminé")
