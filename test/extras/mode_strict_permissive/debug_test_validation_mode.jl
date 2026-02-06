# ========================================
# Script de Diagnostic : test_validation_mode.jl Issue
# ========================================

# Configuration de l'environnement
try
    using Revise
catch
    println("🔧 Revise not found - continuing without hot reload")
end

using Pkg
Pkg.activate(@__DIR__)

# Add CTSolvers in development mode
if !haskey(Pkg.project().dependencies, "CTSolvers")
    Pkg.develop(path=joinpath(@__DIR__, "..", "..", ".."))
end

using CTSolvers
using CTSolvers.Strategies
using CTSolvers.Solvers
using CTSolvers.Modelers

# Charger les extensions nécessaires
try
    using NLPModelsIpopt
    println("✅ NLPModelsIpopt loaded")
catch
    println("❌ NLPModelsIpopt not available")
end

try
    using MadNLP
    using MadNLPMumps
    println("✅ MadNLP loaded")
catch
    println("❌ MadNLP not available")
end

try
    using MadNCL
    println("✅ MadNCL loaded")
catch
    println("❌ MadNCL not available")
end

try
    using NLPModelsKnitro
    println("✅ NLPModelsKnitro loaded")
catch
    println("❌ NLPModelsKnitro not available")
end

using Test

# ========================================
# Tests Ciblés pour diagnostiquer le problème
# ========================================

println("🔍 Diagnostic du test : test_validation_mode.jl")
println("=" ^ 50)

# Test 1: Mode par défaut (strict)
println("\n📋 Test 1: Mode par défaut (strict)")
println("-" ^ 30)

try
    modeler = CTSolvers.Modelers.ADNLPModeler(backend=:default)
    println("✅ Default mode: SUCCESS")
    println("   Type: ", typeof(modeler))
    println("   Mode: ", modeler.options.mode)
    println("   Mode should be :strict: ", modeler.options.mode == :strict)
catch e
    println("❌ Default mode: FAILED")
    println("   Error: ", e)
end

# Test 2: Mode strict explicite
println("\n📋 Test 2: Mode strict explicite")
println("-" ^ 30)

try
    modeler = CTSolvers.Modelers.ADNLPModeler(backend=:default; mode=:strict)
    println("✅ Explicit strict mode: SUCCESS")
    println("   Type: ", typeof(modeler))
    println("   Mode: ", modeler.options.mode)
    println("   Mode should be :strict: ", modeler.options.mode == :strict)
catch e
    println("❌ Explicit strict mode: FAILED")
    println("   Error: ", e)
end

# Test 3: Mode permissif explicite
println("\n📋 Test 3: Mode permissif explicite")
println("-" ^ 30)

try
    modeler = CTSolvers.Modelers.ADNLPModeler(backend=:default; mode=:permissive)
    println("✅ Explicit permissive mode: SUCCESS")
    println("   Type: ", typeof(modeler))
    println("   Mode: ", modeler.options.mode)
    println("   Mode should be :permissive: ", modeler.options.mode == :permissive)
catch e
    println("❌ Explicit permissive mode: FAILED")
    println("   Error: ", e)
end

# Test 4: Mode invalide
println("\n📋 Test 4: Mode invalide")
println("-" ^ 30)

invalid_modes = [:invalid, :strict_invalid, :permissive_invalid, :STRICT, :PERMISSIVE, "strict", "permissive"]

for mode in invalid_modes
    try
        modeler = CTSolvers.Modelers.ADNLPModeler(backend=:default; mode=mode)
        println("❌ Invalid mode $mode: UNEXPECTED SUCCESS")
    catch e
        println("✅ Invalid mode $mode: CORRECTLY FAILED")
        println("   Error type: ", typeof(e))
        println("   Error is IncorrectArgument: ", e isa CTBase.Exceptions.IncorrectArgument)
    end
end

# Test 5: Mode propagation avec build_strategy
println("\n📋 Test 5: Mode propagation avec build_strategy()")
println("-" ^ 30)

try
    registry = CTSolvers.Strategies.create_registry(
        CTSolvers.Modelers.AbstractOptimizationModeler => (CTSolvers.Modelers.ADNLPModeler, CTSolvers.Modelers.ExaModeler)
    )
    
    # Mode par défaut
    modeler1 = CTSolvers.Strategies.build_strategy(:adnlp, CTSolvers.Modelers.AbstractOptimizationModeler, registry; backend=:default)
    println("✅ build_strategy default mode: SUCCESS")
    println("   Mode: ", modeler1.options.mode)
    println("   Mode should be :strict: ", modeler1.options.mode == :strict)
    
    # Mode strict explicite
    modeler2 = CTSolvers.Strategies.build_strategy(:adnlp, CTSolvers.Modelers.AbstractOptimizationModeler, registry; backend=:default; mode=:strict)
    println("✅ build_strategy strict mode: SUCCESS")
    println("   Mode: ", modeler2.options.mode)
    println("   Mode should be :strict: ", modeler2.options.mode == :strict)
    
    # Mode permissif explicite
    modeler3 = CTSolvers.Strategies.build_strategy(:adnlp, CTSolvers.Modelers.AbstractOptimizationModeler, registry; backend=:default; mode=:permissive)
    println("✅ build_strategy permissive mode: SUCCESS")
    println("   Mode: ", modeler3.options.mode)
    println("   Mode should be :permissive: ", modeler3.options.mode == :permissive)
    
catch e
    println("❌ build_strategy mode propagation: FAILED")
    println("   Error: ", e)
end

# Test 6: Mode propagation avec build_strategy_from_method
println("\n📋 Test 6: Mode propagation avec build_strategy_from_method()")
println("-" ^ 30)

try
    registry = CTSolvers.Strategies.create_registry(
        CTSolvers.Modelers.AbstractOptimizationModeler => (CTSolvers.Modelers.ADNLPModeler, CTSolvers.Modelers.ExaModeler)
    )
    
    method = (:collocation, :adnlp, :ipopt)
    
    # Mode par défaut
    modeler1 = CTSolvers.Strategies.build_strategy_from_method(method, CTSolvers.Modelers.AbstractOptimizationModeler, registry; backend=:default)
    println("✅ build_strategy_from_method default mode: SUCCESS")
    println("   Mode: ", modeler1.options.mode)
    println("   Mode should be :strict: ", modeler1.options.mode == :strict)
    
    # Mode strict explicite
    modeler2 = CTSolvers.Strategies.build_strategy_from_method(method, CTSolvers.Modelers.AbstractOptimizationModeler, registry; backend=:default; mode=:strict)
    println("✅ build_strategy_from_method strict mode: SUCCESS")
    println("   Mode: ", modeler2.options.mode)
    println("   Mode should be :strict: ", modeler2.options.mode == :strict)
    
    # Mode permissif explicite
    modeler3 = CTSolvers.Strategies.build_strategy_from_method(method, CTSolvers.Modelers.AbstractOptimizationModeler, registry; backend=:default; mode=:permissive)
    println("✅ build_strategy_from_method permissive mode: SUCCESS")
    println("   Mode: ", modeler3.options.mode)
    println("   Mode should be :permissive: ", modeler3.options.mode == :permissive)
    
catch e
    println("❌ build_strategy_from_method mode propagation: FAILED")
    println("   Error: ", e)
end

# Test 7: Mode propagation avec Orchestration wrapper
println("\n📋 Test 7: Mode propagation avec Orchestration wrapper")
println("-" ^ 30)

try
    registry = CTSolvers.Strategies.create_registry(
        CTSolvers.Modelers.AbstractOptimizationModeler => (CTSolvers.Modelers.ADNLPModeler, CTSolvers.Modelers.ExaModeler)
    )
    
    method = (:collocation, :adnlp, :ipopt)
    
    # Mode par défaut
    modeler1 = CTSolvers.Orchestration.build_strategy_from_method(method, CTSolvers.Modelers.AbstractOptimizationModeler, registry; backend=:default)
    println("✅ Orchestration default mode: SUCCESS")
    println("   Mode: ", modeler1.options.mode)
    println("   Mode should be :strict: ", modeler1.options.mode == :strict)
    
    # Mode strict explicite
    modeler2 = CTSolvers.Orchestration.build_strategy_from_method(method, CTSolvers.Modelers.AbstractOptimizationModeler, registry; backend=:default; mode=:strict)
    println("✅ Orchestration strict mode: SUCCESS")
    println("   Mode: ", modeler2.options.mode)
    println("   Mode should be :strict: ", modeler2.options.mode == :strict)
    
    # Mode permissif explicite
    modeler3 = CTSolvers.Orchestration.build_strategy_from_method(method, CTSolvers.Modelers.AbstractOptimizationModeler, registry; backend=:default; mode=:permissive)
    println("✅ Orchestration permissive mode: SUCCESS")
    println("   Mode: ", modeler3.options.mode)
    println("   Mode should be :permissive: ", modeler3.options.mode == :permissive)
    
catch e
    println("❌ Orchestration mode propagation: FAILED")
    println("   Error: ", e)
end

# Test 8: Mode avec solveurs si disponibles
println("\n📋 Test 8: Mode avec solveurs")
println("-" ^ 30)

if isdefined(Main, :NLPModelsIpopt)
    try
        # Mode par défaut
        solver1 = CTSolvers.Solvers.IpoptSolver(max_iter=1000)
        println("✅ IpoptSolver default mode: SUCCESS")
        println("   Mode: ", solver1.options.mode)
        println("   Mode should be :strict: ", solver1.options.mode == :strict)
        
        # Mode strict explicite
        solver2 = CTSolvers.Solvers.IpoptSolver(max_iter=1000; mode=:strict)
        println("✅ IpoptSolver strict mode: SUCCESS")
        println("   Mode: ", solver2.options.mode)
        println("   Mode should be :strict: ", solver2.options.mode == :strict)
        
        # Mode permissif explicite
        solver3 = CTSolvers.Solvers.IpoptSolver(max_iter=1000; mode=:permissive)
        println("✅ IpoptSolver permissive mode: SUCCESS")
        println("   Mode: ", solver3.options.mode)
        println("   Mode should be :permissive: ", solver3.options.mode == :permissive)
        
    catch e
        println("❌ IpoptSolver mode: FAILED")
        println("   Error: ", e)
    end
else
    println("⏭️  IpoptSolver not available - skipping")
end

# Test 9: Mode consistency across different construction methods
println("\n📋 Test 9: Mode consistency across construction methods")
println("-" ^ 30)

try
    registry = CTSolvers.Strategies.create_registry(
        CTSolvers.Modelers.AbstractOptimizationModeler => (CTSolvers.Modelers.ADNLPModeler, CTSolvers.Modelers.ExaModeler)
    )
    
    method = (:collocation, :adnlp, :ipopt)
    
    # Créer des stratégies avec différentes méthodes mais même mode
    modeler1 = CTSolvers.Modelers.ADNLPModeler(backend=:default; mode=:permissive)
    modeler2 = CTSolvers.Strategies.build_strategy(:adnlp, CTSolvers.Modelers.AbstractOptimizationModeler, registry; backend=:default; mode=:permissive)
    modeler3 = CTSolvers.Strategies.build_strategy_from_method(method, CTSolvers.Modelers.AbstractOptimizationModeler, registry; backend=:default; mode=:permissive)
    modeler4 = CTSolvers.Orchestration.build_strategy_from_method(method, CTSolvers.Modelers.AbstractOptimizationModeler, registry; backend=:default; mode=:permissive)
    
    strategies = [modeler1, modeler2, modeler3, modeler4]
    
    all_permissive = all(s -> s.options.mode == :permissive, strategies)
    println("✅ All strategies have permissive mode: ", all_permissive)
    
    for (i, strategy) in enumerate(strategies)
        println("   Strategy $i mode: ", strategy.options.mode)
    end
    
catch e
    println("❌ Mode consistency: FAILED")
    println("   Error: ", e)
end

println("\n" * "=" ^ 50)
println("🏁 Diagnostic terminé")
println("=" ^ 50)
