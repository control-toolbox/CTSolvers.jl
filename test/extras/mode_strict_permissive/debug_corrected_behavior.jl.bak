# ========================================
# Script de Diagnostic : Comportement Corrigé
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

println("🔧 Diagnostic du comportement corrigé (mode NON stocké dans options)")
println("=" ^ 70)

# Test 1: Vérifier que le mode n'est PAS stocké dans les options
println("\n📋 Test 1: Vérification que mode n'est PAS dans les options")
println("-" ^ 50)

try
    # Mode strict (par défaut)
    modeler1 = CTSolvers.Modelers.ADNLPModeler(backend=:default)
    println("✅ ADNLPModeler (mode strict): SUCCESS")
    
    # Le mode ne doit PAS être dans les options
    try
        mode_value = modeler1.options.mode
        println("❌ ERREUR: Le mode est accessible dans les options: ", mode_value)
        println("   Ceci est un BUG - le mode ne doit pas être stocké dans les options!")
    catch e
        println("✅ CORRECT: Le mode n'est PAS accessible dans les options")
        println("   Erreur attendue: ", typeof(e))
    end
    
    # Mode permissif explicite
    modeler2 = CTSolvers.Modelers.ADNLPModeler(backend=:default; mode=:permissive)
    println("✅ ADNLPModeler (mode permissif): SUCCESS")
    
    # Le mode ne doit PAS être dans les options
    try
        mode_value = modeler2.options.mode
        println("❌ ERREUR: Le mode est accessible dans les options: ", mode_value)
        println("   Ceci est un BUG - le mode ne doit pas être stocké dans les options!")
    catch e
        println("✅ CORRECT: Le mode n'est PAS accessible dans les options")
        println("   Erreur attendue: ", typeof(e))
    end
    
catch e
    println("❌ Création ADNLPModeler échouée: ", e)
end

# Test 2: Vérifier que les options valides fonctionnent
println("\n📋 Test 2: Options valides dans les deux modes")
println("-" ^ 50)

try
    # Mode strict - options valides
    modeler1 = CTSolvers.Modelers.ADNLPModeler(backend=:default, show_time=true)
    println("✅ Mode strict - options valides: SUCCESS")
    println("   backend: ", CTSolvers.Strategies.option_value(modeler1, :backend))
    println("   show_time: ", CTSolvers.Strategies.option_value(modeler1, :show_time))
    
    # Mode permissif - options valides
    modeler2 = CTSolvers.Modelers.ADNLPModeler(backend=:default, show_time=true; mode=:permissive)
    println("✅ Mode permissif - options valides: SUCCESS")
    println("   backend: ", CTSolvers.Strategies.option_value(modeler2, :backend))
    println("   show_time: ", CTSolvers.Strategies.option_value(modeler2, :show_time))
    
catch e
    println("❌ Options valides: FAILED")
    println("   Error: ", e)
end

# Test 3: Vérifier que les options invalides sont gérées correctement
println("\n📋 Test 3: Gestion des options invalides")
println("-" ^ 50)

try
    # Mode strict - option invalide doit échouer
    try
        modeler1 = CTSolvers.Modelers.ADNLPModeler(backend=:default, fake_option=123)
        println("❌ Mode strict - option invalide: UNEXPECTED SUCCESS")
    catch e
        println("✅ Mode strict - option invalide: CORRECTLY FAILED")
        println("   Error type: ", typeof(e))
        println("   Contains 'fake_option': ", occursin("fake_option", string(e)))
    end
    
    # Mode permissif - option invalide doit réussir avec warning
    try
        modeler2 = CTSolvers.Modelers.ADNLPModeler(backend=:default, fake_option=123; mode=:permissive)
        println("✅ Mode permissif - option invalide: SUCCESS")
        
        # Vérifier que l'option invalide est accessible
        has_fake = CTSolvers.Strategies.has_option(modeler2, :fake_option)
        println("   has fake_option: ", has_fake)
        if has_fake
            println("   fake_option value: ", CTSolvers.Strategies.option_value(modeler2, :fake_option))
            println("   fake_option source: ", CTSolvers.Strategies.option_source(modeler2, :fake_option))
        end
    catch e
        println("❌ Mode permissif - option invalide: FAILED")
        println("   Error: ", e)
    end
    
catch e
    println("❌ Test options invalides: FAILED")
    println("   Error: ", e)
end

# Test 4: Vérifier build_strategy
println("\n📋 Test 4: build_strategy avec mode")
println("-" ^ 50)

try
    registry = CTSolvers.Strategies.create_registry(
        CTSolvers.Modelers.AbstractOptimizationModeler => (CTSolvers.Modelers.ADNLPModeler, CTSolvers.Modelers.ExaModeler)
    )
    
    # Mode strict (par défaut)
    modeler1 = CTSolvers.Strategies.build_strategy(:adnlp, CTSolvers.Modelers.AbstractOptimizationModeler, registry; backend=:default)
    println("✅ build_strategy (mode strict): SUCCESS")
    
    # Le mode ne doit PAS être dans les options
    try
        mode_value = modeler1.options.mode
        println("❌ ERREUR: Le mode est accessible dans les options: ", mode_value)
    catch e
        println("✅ CORRECT: Le mode n'est PAS accessible dans les options")
    end
    
    # Mode permissif explicite
    modeler2 = CTSolvers.Strategies.build_strategy(:adnlp, CTSolvers.Modelers.AbstractOptimizationModeler, registry; backend=:default, mode=:permissive)
    println("✅ build_strategy (mode permissif): SUCCESS")
    
    # Le mode ne doit PAS être dans les options
    try
        mode_value = modeler2.options.mode
        println("❌ ERREUR: Le mode est accessible dans les options: ", mode_value)
    catch e
        println("✅ CORRECT: Le mode n'est PAS accessible dans les options")
    end
    
catch e
    println("❌ build_strategy: FAILED")
    println("   Error: ", e)
end

# Test 5: Vérifier build_strategy_options directement
println("\n📋 Test 5: build_strategy_options comportement")
println("-" ^ 50)

try
    # Mode strict
    options1 = CTSolvers.Strategies.build_strategy_options(CTSolvers.Modelers.ADNLPModeler; backend=:default)
    println("✅ build_strategy_options (mode strict): SUCCESS")
    
    # Le mode ne doit PAS être dans les options
    try
        mode_value = options1.mode
        println("❌ ERREUR: Le mode est accessible dans les options: ", mode_value)
    catch e
        println("✅ CORRECT: Le mode n'est PAS accessible dans les options")
    end
    
    # Mode permissif
    options2 = CTSolvers.Strategies.build_strategy_options(CTSolvers.Modelers.ADNLPModeler; backend=:default, mode=:permissive)
    println("✅ build_strategy_options (mode permissif): SUCCESS")
    
    # Le mode ne doit PAS être dans les options
    try
        mode_value = options2.mode
        println("❌ ERREUR: Le mode est accessible dans les options: ", mode_value)
    catch e
        println("✅ CORRECT: Le mode n'est PAS accessible dans les options")
    end
    
catch e
    println("❌ build_strategy_options: FAILED")
    println("   Error: ", e)
end

println("\n" * "=" ^ 70)
println("🏁 Diagnostic terminé")
println("📝 RAPPEL: Le mode est un paramètre de construction, PAS une option de stratégie!")
println("=" ^ 70)
