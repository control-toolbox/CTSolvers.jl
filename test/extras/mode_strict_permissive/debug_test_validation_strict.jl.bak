# ========================================
# Script de Diagnostic : test_validation_strict.jl Issue
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

println("🔍 Diagnostic du test : test_validation_strict.jl")
println("=" ^ 50)

# Test 1: Mode strict avec ADNLPModeler
println("\n📋 Test 1: ADNLPModeler - Mode strict")
println("-" ^ 30)

try
    # Options valides - devrait fonctionner
    modeler = CTSolvers.Modelers.ADNLPModeler(backend=:default, show_time=true)
    println("✅ ADNLPModeler with valid options: SUCCESS")
    println("   Type: ", typeof(modeler))
    println("   Mode: ", modeler.options.mode)
    println("   backend: ", CTSolvers.Strategies.option_value(modeler, :backend))
    println("   show_time: ", CTSolvers.Strategies.option_value(modeler, :show_time))
catch e
    println("❌ ADNLPModeler with valid options: FAILED")
    println("   Error: ", e)
end

try
    # Option invalide - devrait échouer
    modeler = CTSolvers.Modelers.ADNLPModeler(backend=:default, fake_option=123)
    println("❌ ADNLPModeler with invalid option: UNEXPECTED SUCCESS")
catch e
    println("✅ ADNLPModeler with invalid option: CORRECTLY FAILED")
    println("   Error type: ", typeof(e))
    println("   Error message contains 'fake_option': ", occursin("fake_option", string(e)))
end

# Test 2: Mode strict avec ExaModeler
println("\n📋 Test 2: ExaModeler - Mode strict")
println("-" ^ 30)

try
    # Options valides
    modeler = CTSolvers.Modelers.ExaModeler(base_type=Float64, backend=:dense)
    println("✅ ExaModeler with valid options: SUCCESS")
    println("   Type: ", typeof(modeler))
    println("   Mode: ", modeler.options.mode)
catch e
    println("❌ ExaModeler with valid options: FAILED")
    println("   Error: ", e)
end

try
    # Option invalide
    modeler = CTSolvers.Modelers.ExaModeler(base_type=Float64, fake_exa_option="test")
    println("❌ ExaModeler with invalid option: UNEXPECTED SUCCESS")
catch e
    println("✅ ExaModeler with invalid option: CORRECTLY FAILED")
    println("   Error type: ", typeof(e))
    println("   Error message contains 'fake_exa_option': ", occursin("fake_exa_option", string(e)))
end

# Test 3: Test avec solveurs si disponibles
println("\n📋 Test 3: Solvers - Mode strict")
println("-" ^ 30)

# Test IpoptSolver si disponible
if isdefined(Main, :NLPModelsIpopt)
    try
        solver = CTSolvers.Solvers.IpoptSolver(max_iter=1000, tol=1e-6)
        println("✅ IpoptSolver with valid options: SUCCESS")
        println("   Type: ", typeof(solver))
        println("   Mode: ", solver.options.mode)
    catch e
        println("❌ IpoptSolver with valid options: FAILED")
        println("   Error: ", e)
    end
    
    try
        solver = CTSolvers.Solvers.IpoptSolver(max_iter=1000, fake_ipopt_opt=123)
        println("❌ IpoptSolver with invalid option: UNEXPECTED SUCCESS")
    catch e
        println("✅ IpoptSolver with invalid option: CORRECTLY FAILED")
        println("   Error type: ", typeof(e))
        println("   Error message contains 'fake_ipopt_opt': ", occursin("fake_ipopt_opt", string(e)))
    end
else
    println("⏭️  IpoptSolver not available - skipping")
end

# Test 4: build_strategy avec mode strict
println("\n📋 Test 4: build_strategy() - Mode strict")
println("-" ^ 30)

try
    registry = CTSolvers.Strategies.create_registry(
        CTSolvers.Modelers.AbstractOptimizationModeler => (CTSolvers.Modelers.ADNLPModeler, CTSolvers.Modelers.ExaModeler)
    )
    
    # Options valides
    modeler = CTSolvers.Strategies.build_strategy(:adnlp, CTSolvers.Modelers.AbstractOptimizationModeler, registry; backend=:default)
    println("✅ build_strategy with valid options: SUCCESS")
    println("   Type: ", typeof(modeler))
    println("   Mode: ", modeler.options.mode)
catch e
    println("❌ build_strategy with valid options: FAILED")
    println("   Error: ", e)
end

try
    registry = CTSolvers.Strategies.create_registry(
        CTSolvers.Modelers.AbstractOptimizationModeler => (CTSolvers.Modelers.ADNLPModeler, CTSolvers.Modelers.ExaModeler)
    )
    
    # Option invalide
    modeler = CTSolvers.Strategies.build_strategy(:adnlp, CTSolvers.Modelers.AbstractOptimizationModeler, registry; backend=:default, fake_build_opt=456)
    println("❌ build_strategy with invalid option: UNEXPECTED SUCCESS")
catch e
    println("✅ build_strategy with invalid option: CORRECTLY FAILED")
    println("   Error type: ", typeof(e))
    println("   Error message contains 'fake_build_opt': ", occursin("fake_build_opt", string(e)))
end

# Test 5: Mode invalide
println("\n📋 Test 5: Mode invalide")
println("-" ^ 30)

try
    modeler = CTSolvers.Modelers.ADNLPModeler(backend=:default; mode=:invalid)
    println("❌ Invalid mode: UNEXPECTED SUCCESS")
catch e
    println("✅ Invalid mode: CORRECTLY FAILED")
    println("   Error type: ", typeof(e))
    println("   Error message contains 'mode': ", occursin("mode", string(e)))
end

println("\n" * "=" ^ 50)
println("🏁 Diagnostic terminé")
println("=" ^ 50)
