# ========================================
# Test Simple : Validation de Tous les Moyens de Construction
# ========================================

using Pkg
Pkg.activate(@__DIR__)

if !haskey(Pkg.project().dependencies, "CTSolvers")
    Pkg.develop(path=joinpath(@__DIR__, "..", "..", ".."))
end

using CTSolvers
using CTSolvers.Strategies
using CTSolvers.Modelers
using Test

println("🔧 Test Simple : Tous les Moyens de Construction")
println("=" ^ 60)

# Configuration
registry = CTSolvers.Strategies.create_registry(
    CTSolvers.Modelers.AbstractOptimizationModeler => (CTSolvers.Modelers.ADNLPModeler, CTSolvers.Modelers.ExaModeler)
)

known_options = (backend=:default, show_time=true)
unknown_options = (fake_option=123, custom_param="test")
method = (:collocation, :adnlp, :ipopt)

# Test 1: Constructeur direct
println("\n📋 Test 1: Constructeur Direct")
println("-" ^ 40)

# Mode strict - options valides
modeler1 = CTSolvers.Modelers.ADNLPModeler(; known_options...)
println("✅ Direct - Strict - Valid: SUCCESS")
println("   backend: ", CTSolvers.Strategies.option_value(modeler1, :backend))
println("   show_time: ", CTSolvers.Strategies.option_value(modeler1, :show_time))

# Mode strict - options invalides (doit échouer)
try
    CTSolvers.Modelers.ADNLPModeler(; known_options..., unknown_options...)
    println("❌ Direct - Strict - Invalid: UNEXPECTED SUCCESS")
catch e
    println("✅ Direct - Strict - Invalid: CORRECTLY FAILED")
end

# Mode permissif - options mixtes
modeler2 = CTSolvers.Modelers.ADNLPModeler(; known_options..., unknown_options..., mode=:permissive)
println("✅ Direct - Permissive - Mixed: SUCCESS")
println("   backend: ", CTSolvers.Strategies.option_value(modeler2, :backend))
println("   fake_option: ", CTSolvers.Strategies.option_value(modeler2, :fake_option))
println("   custom_param: ", CTSolvers.Strategies.option_value(modeler2, :custom_param))

# Test 2: build_strategy()
println("\n📋 Test 2: build_strategy()")
println("-" ^ 40)

# Mode strict - options valides
modeler3 = CTSolvers.Strategies.build_strategy(:adnlp, CTSolvers.Modelers.AbstractOptimizationModeler, registry; known_options...)
println("✅ build_strategy - Strict - Valid: SUCCESS")
println("   backend: ", CTSolvers.Strategies.option_value(modeler3, :backend))

# Mode strict - options invalides (doit échouer)
try
    CTSolvers.Strategies.build_strategy(:adnlp, CTSolvers.Modelers.AbstractOptimizationModeler, registry; known_options..., unknown_options...)
    println("❌ build_strategy - Strict - Invalid: UNEXPECTED SUCCESS")
catch e
    println("✅ build_strategy - Strict - Invalid: CORRECTLY FAILED")
end

# Mode permissif - options mixtes
modeler4 = CTSolvers.Strategies.build_strategy(:adnlp, CTSolvers.Modelers.AbstractOptimizationModeler, registry; known_options..., unknown_options..., mode=:permissive)
println("✅ build_strategy - Permissive - Mixed: SUCCESS")
println("   backend: ", CTSolvers.Strategies.option_value(modeler4, :backend))
println("   fake_option: ", CTSolvers.Strategies.option_value(modeler4, :fake_option))

# Test 3: build_strategy_from_method()
println("\n📋 Test 3: build_strategy_from_method()")
println("-" ^ 40)

# Mode strict - options valides
modeler5 = CTSolvers.Strategies.build_strategy_from_method(method, CTSolvers.Modelers.AbstractOptimizationModeler, registry; known_options...)
println("✅ build_strategy_from_method - Strict - Valid: SUCCESS")
println("   backend: ", CTSolvers.Strategies.option_value(modeler5, :backend))

# Mode strict - options invalides (doit échouer)
try
    CTSolvers.Strategies.build_strategy_from_method(method, CTSolvers.Modelers.AbstractOptimizationModeler, registry; known_options..., unknown_options...)
    println("❌ build_strategy_from_method - Strict - Invalid: UNEXPECTED SUCCESS")
catch e
    println("✅ build_strategy_from_method - Strict - Invalid: CORRECTLY FAILED")
end

# Mode permissif - options mixtes
modeler6 = CTSolvers.Strategies.build_strategy_from_method(method, CTSolvers.Modelers.AbstractOptimizationModeler, registry; known_options..., unknown_options..., mode=:permissive)
println("✅ build_strategy_from_method - Permissive - Mixed: SUCCESS")
println("   backend: ", CTSolvers.Strategies.option_value(modeler6, :backend))
println("   fake_option: ", CTSolvers.Strategies.option_value(modeler6, :fake_option))

# Test 4: Orchestration wrapper
println("\n📋 Test 4: Orchestration Wrapper")
println("-" ^ 40)

# Mode strict - options valides
modeler7 = CTSolvers.Orchestration.build_strategy_from_method(method, CTSolvers.Modelers.AbstractOptimizationModeler, registry; known_options...)
println("✅ Orchestration - Strict - Valid: SUCCESS")
println("   backend: ", CTSolvers.Strategies.option_value(modeler7, :backend))

# Mode strict - options invalides (doit échouer)
try
    CTSolvers.Orchestration.build_strategy_from_method(method, CTSolvers.Modelers.AbstractOptimizationModeler, registry; known_options..., unknown_options...)
    println("❌ Orchestration - Strict - Invalid: UNEXPECTED SUCCESS")
catch e
    println("✅ Orchestration - Strict - Invalid: CORRECTLY FAILED")
end

# Mode permissif - options mixtes
modeler8 = CTSolvers.Orchestration.build_strategy_from_method(method, CTSolvers.Modelers.AbstractOptimizationModeler, registry; known_options..., unknown_options..., mode=:permissive)
println("✅ Orchestration - Permissive - Mixed: SUCCESS")
println("   backend: ", CTSolvers.Strategies.option_value(modeler8, :backend))
println("   fake_option: ", CTSolvers.Strategies.option_value(modeler8, :fake_option))

# Test 5: Vérification que le mode n'est PAS stocké
println("\n📋 Test 5: Mode NON Stocké dans Options")
println("-" ^ 40)

strategies = [modeler2, modeler4, modeler6, modeler8]  # Celles créées en mode permissif

for (i, strategy) in enumerate(strategies)
    try
        mode_value = strategy.options.mode
        println("❌ Strategy $i: ERREUR - mode accessible: ", mode_value)
    catch e
        println("✅ Strategy $i: CORRECT - mode non accessible")
    end
end

# Test 6: Consistance
println("\n📋 Test 6: Consistance Entre Méthodes")
println("-" ^ 40)

permissive_strategies = [modeler2, modeler4, modeler6, modeler8]
all_consistent = true

for (i, strategy) in enumerate(permissive_strategies)
    backend_ok = CTSolvers.Strategies.option_value(strategy, :backend) == :default
    show_time_ok = CTSolvers.Strategies.option_value(strategy, :show_time) == true
    fake_ok = CTSolvers.Strategies.option_value(strategy, :fake_option) == 123
    custom_ok = CTSolvers.Strategies.option_value(strategy, :custom_param) == "test"
    
    if backend_ok && show_time_ok && fake_ok && custom_ok
        println("✅ Strategy $i: Toutes les options correctes")
    else
        println("❌ Strategy $i: Options incorrectes")
        all_consistent = false
    end
end

if all_consistent
    println("✅ Consistance: PARFAITE - toutes les méthodes donnent le même résultat")
else
    println("❌ Consistance: PROBLÈME - résultats incohérents")
end

println("\n" * "=" ^ 60)
println("🏁 Test Simple Terminé")
println("=" ^ 60)
