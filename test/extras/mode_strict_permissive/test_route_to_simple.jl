# ========================================
# Test Simple : route_to() avec Validation Mode
# ========================================

using Pkg
Pkg.activate(@__DIR__)

if !haskey(Pkg.project().dependencies, "CTSolvers")
    Pkg.develop(path=joinpath(@__DIR__, "..", "..", ".."))
end

using CTSolvers
using CTSolvers.Strategies
using CTSolvers.Orchestration
using CTSolvers.Options
using Test

println("🔧 Test Simple : route_to() avec Validation Mode")
println("=" ^ 60)

# ============================================================================
# Mock Strategies Simplifiées
# ============================================================================

abstract type TestModeler <: Strategies.AbstractStrategy end
abstract type TestSolver <: Strategies.AbstractStrategy end

struct TestADNLP <: TestModeler
    options::Strategies.StrategyOptions
end

struct TestIpopt <: TestSolver
    options::Strategies.StrategyOptions
end

# Contracts
Strategies.id(::Type{TestADNLP}) = :adnlp
Strategies.id(::Type{TestIpopt}) = :ipopt

# Constructeurs
function TestADNLP(; mode=:strict, kwargs...)
    options = Strategies.build_strategy_options(TestADNLP; mode=mode, kwargs...)
    return TestADNLP(options)
end

function TestIpopt(; mode=:strict, kwargs...)
    options = Strategies.build_strategy_options(TestIpopt; mode=mode, kwargs...)
    return TestIpopt(options)
end

# Métadonnées avec conflict :backend
Strategies.metadata(::Type{TestADNLP}) = Strategies.StrategyMetadata(
    Options.OptionDefinition(
        name = :backend,
        type = Symbol,
        default = :dense,
        description = "Modeler backend"
    ),
    Options.OptionDefinition(
        name = :show_time,
        type = Bool,
        default = false,
        description = "Show timing"
    )
)

Strategies.metadata(::Type{TestIpopt}) = Strategies.StrategyMetadata(
    Options.OptionDefinition(
        name = :backend,
        type = Symbol,
        default = :cpu,
        description = "Solver backend"
    ),
    Options.OptionDefinition(
        name = :max_iter,
        type = Int,
        default = 1000,
        description = "Maximum iterations"
    )
)

# Registry
const TEST_REGISTRY = Strategies.create_registry(
    TestModeler => (TestADNLP,),
    TestSolver => (TestIpopt,)
)

const TEST_METHOD = (:adnlp, :ipopt)
const TEST_FAMILIES = (
    modeler = TestModeler,
    solver = TestSolver
)

const TEST_ACTION_DEFS = [
    Options.OptionDefinition(
        name = :display,
        type = Bool,
        default = true,
        description = "Display progress"
    )
]

# ============================================================================
# Tests de Base route_to()
# ============================================================================

println("\n📋 Test 1: route_to() Syntax de Base")
println("-" ^ 40)

# Test RoutedOption simple
routed_single = Strategies.route_to(solver=100)
println("✅ route_to(solver=100): ", typeof(routed_single))
println("   Routes: ", routed_single.routes)

# Test RoutedOption multiple
routed_multi = Strategies.route_to(solver=100, modeler=50)
println("✅ route_to(solver=100, modeler=50): ", typeof(routed_multi))
println("   Routes: ", routed_multi.routes)

# ============================================================================
# Tests de Routage Simple
# ============================================================================

println("\n📋 Test 2: Routage Simple (Sans Conflict)")
println("-" ^ 40)

# Options sans conflict
kwargs_simple = (
    show_time = true,    # Seulement dans modeler
    max_iter = 500,     # Seulement dans solver
    display = false     # Action option
)

try
    routed = Orchestration.route_all_options(
        TEST_METHOD, TEST_FAMILIES, TEST_ACTION_DEFS, kwargs_simple, TEST_REGISTRY; mode=:strict
    )
    println("✅ Routage simple réussi")
    println("   Action options: ", routed.action)
    println("   Strategy options: ", routed.strategies)
    
    # Construire stratégies
    modeler = TestADNLP(; routed.strategies.modeler...)
    solver = TestIpopt(; routed.strategies.solver...)
    
    # Vérifier options
    println("   Modeler show_time: ", CTSolvers.Strategies.has_option(modeler, :show_time))
    println("   Solver max_iter: ", CTSolvers.Strategies.has_option(solver, :max_iter))
    
catch e
    println("❌ Routage simple échoué: ", e)
end

# ============================================================================
# Tests de Conflict de Noms
# ============================================================================

println("\n📋 Test 3: Conflict de Noms (:backend)")
println("-" ^ 40)

# Options avec conflict
kwargs_conflict = (
    backend = Strategies.route_to(adnlp=:sparse),  # Résolution de conflict avec IDs corrects
    show_time = true,    # Auto-route vers modeler
    max_iter = 1000,     # Auto-route vers solver
    display = false     # Action option
)

try
    routed = Orchestration.route_all_options(
        TEST_METHOD, TEST_FAMILIES, TEST_ACTION_DEFS, kwargs_conflict, TEST_REGISTRY; mode=:strict
    )
    println("✅ Routage avec conflict réussi")
    println("   Modeler options: ", routed.strategies.modeler)
    println("   Solver options: ", routed.strategies.solver)
    
    # Construire stratégies
    modeler = TestADNLP(; routed.strategies.modeler...)
    solver = TestIpopt(; routed.strategies.solver...)
    
    # Vérifier routage correct
    modeler_backend = CTSolvers.Strategies.has_option(modeler, :backend) ? CTSolvers.Strategies.option_value(modeler, :backend) : "N/A"
    solver_backend = CTSolvers.Strategies.has_option(solver, :backend) ? CTSolvers.Strategies.option_value(solver, :backend) : "N/A"
    
    println("   Modeler backend: ", modeler_backend)
    println("   Solver backend: ", solver_backend)
    
    # Vérifier que le conflict est résolu correctement
    if modeler_backend == :sparse && solver_backend == :cpu
        println("✅ Conflict résolu correctement")
    else
        println("❌ Conflict mal résolu")
    end
    
catch e
    println("❌ Routage avec conflict échoué: ", e)
end

# ============================================================================
# Tests Multi-Stratégies
# ============================================================================

println("\n📋 Test 4: Multi-Stratégies")
println("-" ^ 40)

# Options multi-stratégies
kwargs_multi = (
    backend = Strategies.route_to(adnlp=:sparse, ipopt=:cpu),  # Multi-stratégies avec IDs corrects
    max_iter = Strategies.route_to(ipopt=1000),  # Single vers solver
    display = false
)

try
    routed = Orchestration.route_all_options(
        TEST_METHOD, TEST_FAMILIES, TEST_ACTION_DEFS, kwargs_multi, TEST_REGISTRY; mode=:strict
    )
    println("✅ Routage multi-stratégies réussi")
    println("   Modeler options: ", routed.strategies.modeler)
    println("   Solver options: ", routed.strategies.solver)
    
    # Construire stratégies
    modeler = TestADNLP(; routed.strategies.modeler...)
    solver = TestIpopt(; routed.strategies.solver...)
    
    # Vérifier options multi-stratégies
    modeler_backend = CTSolvers.Strategies.has_option(modeler, :backend) ? CTSolvers.Strategies.option_value(modeler, :backend) : "N/A"
    solver_backend = CTSolvers.Strategies.has_option(solver, :backend) ? CTSolvers.Strategies.option_value(solver, :backend) : "N/A"
    solver_max_iter = CTSolvers.Strategies.has_option(solver, :max_iter) ? CTSolvers.Strategies.option_value(solver, :max_iter) : "N/A"
    
    println("   Modeler backend: ", modeler_backend)
    println("   Solver backend: ", solver_backend)
    println("   Solver max_iter: ", solver_max_iter)
    
    # Vérifier que tout est correct
    if modeler_backend == :sparse && solver_backend == :cpu && solver_max_iter == 1000
        println("✅ Multi-stratégies correct")
    else
        println("❌ Multi-stratégies incorrect")
    end
    
catch e
    println("❌ Routage multi-stratégies échoué: ", e)
end

# ============================================================================
# Tests Mode Permissif
# ============================================================================

println("\n📋 Test 5: Mode Permissif avec Options Inconnues")
println("-" ^ 40)

# Options avec option inconnue
kwargs_permissive = (
    backend = Strategies.route_to(adnlp=:sparse),
    fake_option = Strategies.route_to(ipopt=123),  # Option inconnue avec ID correct
    display = false
)

try
    routed = Orchestration.route_all_options(
        TEST_METHOD, TEST_FAMILIES, TEST_ACTION_DEFS, kwargs_permissive, TEST_REGISTRY; mode=:permissive
    )
    println("✅ Mode permissif réussi (avec warning attendu)")
    
    # Construire stratégie et vérifier option inconnue
    solver = TestIpopt(; routed.strategies.solver...)
    
    if CTSolvers.Strategies.has_option(solver, :fake_option)
        fake_value = CTSolvers.Strategies.option_value(solver, :fake_option)
        println("   Option inconnue acceptée: fake_option = ", fake_value)
        println("✅ Mode permissif functionne correctement")
    else
        println("❌ Option inconnue non trouvée")
    end
    
catch e
    println("❌ Mode permissif échoué: ", e)
end

# ============================================================================
# Tests Mode Strict (Options Inconnues)
# ============================================================================

println("\n📋 Test 6: Mode Strict avec Options Inconnues")
println("-" ^ 40)

try
    routed = Orchestration.route_all_options(
        TEST_METHOD, TEST_FAMILIES, TEST_ACTION_DEFS, kwargs_permissive, TEST_REGISTRY; mode=:strict
    )
    println("❌ Mode strict aurait dû échouer!")
catch e
    println("✅ Mode strict correctement rejeté: ", typeof(e))
end

# ============================================================================
# Tests d'Inspection Complète
# ============================================================================

println("\n📋 Test 7: Inspection Complète des Stratégies")
println("-" ^ 40)

# Test complete avec toutes les functionnalités
kwargs_completee = (
    backend = Strategies.route_to(adnlp=:sparse, ipopt=:cpu),
    show_time = true,
    max_iter = Strategies.route_to(ipopt=1000),
    display = false
)

try
    routed = Orchestration.route_all_options(
        TEST_METHOD, TEST_FAMILIES, TEST_ACTION_DEFS, kwargs_completee, TEST_REGISTRY; mode=:strict
    )
    
    # Construire stratégies
    modeler = TestADNLP(; routed.strategies.modeler...)
    solver = TestIpopt(; routed.strategies.solver...)
    
    println("✅ Stratégies construites avec succès")
    
    # Inspection complète du modeler
    println("\n   Modeler Inspection:")
    for opt_name in [:backend, :show_time]
        if CTSolvers.Strategies.has_option(modeler, opt_name)
            value = CTSolvers.Strategies.option_value(modeler, opt_name)
            source = CTSolvers.Strategies.option_source(modeler, opt_name)
            println("     $opt_name: $value (source: $source)")
        else
            println("     $opt_name: ABSENT")
        end
    end
    
    # Inspection complète du solver
    println("\n   Solver Inspection:")
    for opt_name in [:backend, :max_iter]
        if CTSolvers.Strategies.has_option(solver, opt_name)
            value = CTSolvers.Strategies.option_value(solver, opt_name)
            source = CTSolvers.Strategies.option_source(solver, opt_name)
            println("     $opt_name: $value (source: $source)")
        else
            println("     $opt_name: ABSENT")
        end
    end
    
    # Vérifier les absences attendues
    modeler_missing = CTSolvers.Strategies.has_option(modeler, :max_iter) ? "❌" : "✅"
    solver_missing = CTSolvers.Strategies.has_option(solver, :show_time) ? "❌" : "✅"
    
    println("\n   Absences correctes:")
    println("     Modeler sans max_iter: $modeler_missing")
    println("     Solver sans show_time: $solver_missing")
    
catch e
    println("❌ Inspection complète échouée: ", e)
end

println("\n" * "=" ^ 60)
println("🏁 Test Simple route_to() Terminé")
println("=" ^ 60)
