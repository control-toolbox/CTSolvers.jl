# ========================================
# Script de Diagnostic : test_validation_permissive.jl Issue
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

println("🔍 Diagnostic du test : test_validation_permissive.jl")
println("=" ^ 50)

# Test 1: Mode permissif avec ADNLPModeler
println("\n📋 Test 1: ADNLPModeler - Mode permissif")
println("-" ^ 30)

try
    # Options valides + option invalide - devrait fonctionner avec warning
    modeler = CTSolvers.Modelers.ADNLPModeler(backend=:default, show_time=true, fake_option=123; mode=:permissive)
    println("✅ ADNLPModeler with mixed options: SUCCESS")
    println("   Type: ", typeof(modeler))
    println("   Mode: ", modeler.options.mode)
    
    # Vérifier les options valides
    println("   backend: ", CTSolvers.Strategies.option_value(modeler, :backend))
    println("   show_time: ", CTSolvers.Strategies.option_value(modeler, :show_time))
    println("   backend source: ", CTSolvers.Strategies.option_source(modeler, :backend))
    println("   show_time source: ", CTSolvers.Strategies.option_source(modeler, :show_time))
    
    # Vérifier l'option invalide
    has_fake = CTSolvers.Strategies.has_option(modeler, :fake_option)
    println("   has fake_option: ", has_fake)
    if has_fake
        println("   fake_option value: ", CTSolvers.Strategies.option_value(modeler, :fake_option))
        println("   fake_option source: ", CTSolvers.Strategies.option_source(modeler, :fake_option))
    end
catch e
    println("❌ ADNLPModeler with mixed options: FAILED")
    println("   Error: ", e)
end

# Test 2: Mode permissif avec ExaModeler
println("\n📋 Test 2: ExaModeler - Mode permissif")
println("-" ^ 30)

try
    modeler = CTSolvers.Modelers.ExaModeler(base_type=Float64, backend=:dense, fake_exa_option="test"; mode=:permissive)
    println("✅ ExaModeler with mixed options: SUCCESS")
    println("   Type: ", typeof(modeler))
    println("   Mode: ", modeler.options.mode)
    
    # Vérifier les options
    println("   base_type: ", CTSolvers.Strategies.option_value(modeler, :base_type))
    println("   backend: ", CTSolvers.Strategies.option_value(modeler, :backend))
    
    has_fake = CTSolvers.Strategies.has_option(modeler, :fake_exa_option)
    println("   has fake_exa_option: ", has_fake)
    if has_fake
        println("   fake_exa_option value: ", CTSolvers.Strategies.option_value(modeler, :fake_exa_option))
        println("   fake_exa_option source: ", CTSolvers.Strategies.option_source(modeler, :fake_exa_option))
    end
catch e
    println("❌ ExaModeler with mixed options: FAILED")
    println("   Error: ", e)
end

# Test 3: Test avec solveurs si disponibles
println("\n📋 Test 3: Solvers - Mode permissif")
println("-" ^ 30)

if isdefined(Main, :NLPModelsIpopt)
    try
        solver = CTSolvers.Solvers.IpoptSolver(max_iter=1000, tol=1e-6, fake_ipopt_opt=789; mode=:permissive)
        println("✅ IpoptSolver with mixed options: SUCCESS")
        println("   Type: ", typeof(solver))
        println("   Mode: ", solver.options.mode)
        
        # Vérifier les options
        println("   max_iter: ", CTSolvers.Strategies.option_value(solver, :max_iter))
        println("   tol: ", CTSolvers.Strategies.option_value(solver, :tol))
        
        has_fake = CTSolvers.Strategies.has_option(solver, :fake_ipopt_opt)
        println("   has fake_ipopt_opt: ", has_fake)
        if has_fake
            println("   fake_ipopt_opt value: ", CTSolvers.Strategies.option_value(solver, :fake_ipopt_opt))
            println("   fake_ipopt_opt source: ", CTSolvers.Strategies.option_source(solver, :fake_ipopt_opt))
        end
    catch e
        println("❌ IpoptSolver with mixed options: FAILED")
        println("   Error: ", e)
    end
else
    println("⏭️  IpoptSolver not available - skipping")
end

# Test 4: build_strategy avec mode permissif
println("\n📋 Test 4: build_strategy() - Mode permissif")
println("-" ^ 30)

try
    registry = CTSolvers.Strategies.create_registry(
        CTSolvers.Modelers.AbstractOptimizationModeler => (CTSolvers.Modelers.ADNLPModeler, CTSolvers.Modelers.ExaModeler)
    )
    
    # Options valides + option invalide
    modeler = CTSolvers.Strategies.build_strategy(:adnlp, CTSolvers.Modelers.AbstractOptimizationModeler, registry; backend=:default, fake_build_opt=456, mode=:permissive)
    println("✅ build_strategy with mixed options: SUCCESS")
    println("   Type: ", typeof(modeler))
    println("   Mode: ", modeler.options.mode)
    
    # Vérifier les options
    println("   backend: ", CTSolvers.Strategies.option_value(modeler, :backend))
    
    has_fake = CTSolvers.Strategies.has_option(modeler, :fake_build_opt)
    println("   has fake_build_opt: ", has_fake)
    if has_fake
        println("   fake_build_opt value: ", CTSolvers.Strategies.option_value(modeler, :fake_build_opt))
        println("   fake_build_opt source: ", CTSolvers.Strategies.option_source(modeler, :fake_build_opt))
    end
catch e
    println("❌ build_strategy with mixed options: FAILED")
    println("   Error: ", e)
end

# Test 5: build_strategy_from_method avec mode permissif
println("\n📋 Test 5: build_strategy_from_method() - Mode permissif")
println("-" ^ 30)

try
    registry = CTSolvers.Strategies.create_registry(
        CTSolvers.Modelers.AbstractOptimizationModeler => (CTSolvers.Modelers.ADNLPModeler, CTSolvers.Modelers.ExaModeler)
    )
    
    method = (:collocation, :adnlp, :ipopt)
    modeler = CTSolvers.Strategies.build_strategy_from_method(method, CTSolvers.Modelers.AbstractOptimizationModeler, registry; backend=:default, fake_method_opt="test"; mode=:permissive)
    println("✅ build_strategy_from_method with mixed options: SUCCESS")
    println("   Type: ", typeof(modeler))
    println("   Mode: ", modeler.options.mode)
    
    # Vérifier les options
    println("   backend: ", CTSolvers.Strategies.option_value(modeler, :backend))
    
    has_fake = CTSolvers.Strategies.has_option(modeler, :fake_method_opt)
    println("   has fake_method_opt: ", has_fake)
    if has_fake
        println("   fake_method_opt value: ", CTSolvers.Strategies.option_value(modeler, :fake_method_opt))
        println("   fake_method_opt source: ", CTSolvers.Strategies.option_source(modeler, :fake_method_opt))
    end
catch e
    println("❌ build_strategy_from_method with mixed options: FAILED")
    println("   Error: ", e)
end

# Test 6: Orchestration wrapper avec mode permissif
println("\n📋 Test 6: Orchestration wrapper - Mode permissif")
println("-" ^ 30)

try
    registry = CTSolvers.Strategies.create_registry(
        CTSolvers.Modelers.AbstractOptimizationModeler => (CTSolvers.Modelers.ADNLPModeler, CTSolvers.Modelers.ExaModeler)
    )
    
    method = (:collocation, :adnlp, :ipopt)
    modeler = CTSolvers.Orchestration.build_strategy_from_method(method, CTSolvers.Modelers.AbstractOptimizationModeler, registry; backend=:default, fake_orch_opt=999; mode=:permissive)
    println("✅ Orchestration wrapper with mixed options: SUCCESS")
    println("   Type: ", typeof(modeler))
    println("   Mode: ", modeler.options.mode)
    
    # Vérifier les options
    println("   backend: ", CTSolvers.Strategies.option_value(modeler, :backend))
    
    has_fake = CTSolvers.Strategies.has_option(modeler, :fake_orch_opt)
    println("   has fake_orch_opt: ", has_fake)
    if has_fake
        println("   fake_orch_opt value: ", CTSolvers.Strategies.option_value(modeler, :fake_orch_opt))
        println("   fake_orch_opt source: ", CTSolvers.Strategies.option_source(modeler, :fake_orch_opt))
    end
catch e
    println("❌ Orchestration wrapper with mixed options: FAILED")
    println("   Error: ", e)
end

# Test 7: Options multiples inconnues
println("\n📋 Test 7: Multiple unknown options - Mode permissif")
println("-" ^ 30)

try
    modeler = CTSolvers.Modelers.ADNLPModeler(
        backend=:default, 
        show_time=true,
        fake_option1=123,
        fake_option2="test",
        fake_option3=true;
        mode=:permissive
    )
    println("✅ Multiple unknown options: SUCCESS")
    println("   Type: ", typeof(modeler))
    println("   Mode: ", modeler.options.mode)
    
    # Vérifier toutes les options
    for opt_name in [:backend, :show_time, :fake_option1, :fake_option2, :fake_option3]
        has_opt = CTSolvers.Strategies.has_option(modeler, opt_name)
        println("   has $opt_name: ", has_opt)
        if has_opt
            println("     value: ", CTSolvers.Strategies.option_value(modeler, opt_name))
            println("     source: ", CTSolvers.Strategies.option_source(modeler, opt_name))
        end
    end
catch e
    println("❌ Multiple unknown options: FAILED")
    println("   Error: ", e)
end

println("\n" * "=" ^ 50)
println("🏁 Diagnostic terminé")
println("=" ^ 50)
