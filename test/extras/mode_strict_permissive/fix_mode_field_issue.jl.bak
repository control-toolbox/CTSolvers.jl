# ========================================
# Script de Correction : Mode Field Issue
# ========================================

# Configuration de l'environnement
using Pkg
Pkg.activate(@__DIR__)

# Add CTSolvers in development mode
if !haskey(Pkg.project().dependencies, "CTSolvers")
    Pkg.develop(path=joinpath(@__DIR__, "..", "..", ".."))
end

using CTSolvers
using CTSolvers.Strategies
using CTSolvers.Modelers

println("🔧 Diagnostic du problème de champ mode")
println("=" ^ 50)

# Test 1: Vérifier si le champ mode existe dans les options
println("\n📋 Test 1: Vérification du champ mode")
println("-" ^ 30)

try
    modeler = CTSolvers.Modelers.ADNLPModeler(backend=:default)
    println("✅ ADNLPModeler créé avec succès")
    
    # Tenter d'accéder au champ mode
    try
        mode_value = modeler.options.mode
        println("✅ Champ mode accessible: ", mode_value)
    catch e
        println("❌ Champ mode inaccessible: ", e)
        println("   Type des options: ", typeof(modeler.options))
        println("   Champs disponibles: ", fieldnames(typeof(modeler.options)))
    end
catch e
    println("❌ Création ADNLPModeler échouée: ", e)
end

# Test 2: Vérifier la structure des options
println("\n📋 Test 2: Structure des options")
println("-" ^ 30)

try
    modeler = CTSolvers.Modelers.ADNLPModeler(backend=:default)
    options = modeler.options
    println("Type des options: ", typeof(options))
    println("Champs: ", fieldnames(typeof(options)))
    
    # Afficher les valeurs des champs
    for field in fieldnames(typeof(options))
        try
            value = getfield(options, field)
            println("  $field: $value")
        catch e
            println("  $field: <erreur accès>")
        end
    end
catch e
    println("❌ Analyse des options échouée: ", e)
end

# Test 3: Vérifier build_strategy_options
println("\n📋 Test 3: Vérification de build_strategy_options")
println("-" ^ 30)

try
    # Test avec mode explicite
    options = CTSolvers.Strategies.build_strategy_options(CTSolvers.Modelers.ADNLPModeler; backend=:default, mode=:permissive)
    println("✅ build_strategy_options avec mode explicite: SUCCESS")
    println("   Type: ", typeof(options))
    println("   Champs: ", fieldnames(typeof(options)))
    
    # Vérifier si le mode est là
    try
        mode_value = options.mode
        println("   Mode: ", mode_value)
    catch e
        println("❌ Mode non accessible dans build_strategy_options: ", e)
    end
catch e
    println("❌ build_strategy_options échoué: ", e)
end

try
    # Test sans mode explicite (devrait être :strict par défaut)
    options = CTSolvers.Strategies.build_strategy_options(CTSolvers.Modelers.ADNLPModeler; backend=:default)
    println("✅ build_strategy_options sans mode explicite: SUCCESS")
    println("   Type: ", typeof(options))
    println("   Champs: ", fieldnames(typeof(options)))
    
    # Vérifier si le mode est là
    try
        mode_value = options.mode
        println("   Mode (défaut): ", mode_value)
    catch e
        println("❌ Mode non accessible dans build_strategy_options (défaut): ", e)
    end
catch e
    println("❌ build_strategy_options (défaut) échoué: ", e)
end

# Test 4: Comparer avec les autres méthodes de construction
println("\n📋 Test 4: Comparaison des méthodes de construction")
println("-" ^ 30)

try
    registry = CTSolvers.Strategies.create_registry(
        CTSolvers.Modelers.AbstractOptimizationModeler => (CTSolvers.Modelers.ADNLPModeler, CTSolvers.Modelers.ExaModeler)
    )
    
    # build_strategy
    modeler1 = CTSolvers.Strategies.build_strategy(:adnlp, CTSolvers.Modelers.AbstractOptimizationModeler, registry; backend=:default)
    println("✅ build_strategy: SUCCESS")
    try
        mode_value = modeler1.options.mode
        println("   Mode: ", mode_value)
    catch e
        println("❌ Mode non accessible dans build_strategy: ", e)
        println("   Champs: ", fieldnames(typeof(modeler1.options)))
    end
    
    # build_strategy_from_method
    method = (:collocation, :adnlp, :ipopt)
    modeler2 = CTSolvers.Strategies.build_strategy_from_method(method, CTSolvers.Modelers.AbstractOptimizationModeler, registry; backend=:default)
    println("✅ build_strategy_from_method: SUCCESS")
    try
        mode_value = modeler2.options.mode
        println("   Mode: ", mode_value)
    catch e
        println("❌ Mode non accessible dans build_strategy_from_method: ", e)
        println("   Champs: ", fieldnames(typeof(modeler2.options)))
    end
    
catch e
    println("❌ Comparaison échouée: ", e)
end

println("\n" * "=" ^ 50)
println("🏁 Diagnostic terminé")
println("=" ^ 50)
