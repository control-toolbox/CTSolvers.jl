# ========================================
# Test Systématique : Tous les Moyens de Construction
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
using Test

println("🔧 Test Systématique : Tous les Moyens de Construction")
println("=" ^ 60)

# Créer le registre pour les tests
registry = CTSolvers.Strategies.create_registry(
    CTSolvers.Modelers.AbstractOptimizationModeler => (CTSolvers.Modelers.ADNLPModeler, CTSolvers.Modelers.ExaModeler)
)

# Options de test
known_options = (backend=:default, show_time=true)
unknown_options = (fake_option=123, custom_param="test")

# Test 1: Constructeur direct
println("\n📋 Test 1: Constructeur Direct")
println("-" ^ 40)

@testset "Direct Constructor" begin
    @testset "Mode Strict" begin
        # Options valides - devrait fonctionner
        @test_nowarn CTSolvers.Modelers.ADNLPModeler(; known_options...)
        modeler = CTSolvers.Modelers.ADNLPModeler(; known_options...)
        @test modeler isa CTSolvers.Modelers.ADNLPModeler
        @test CTSolvers.Strategies.option_value(modeler, :backend) == :default
        @test CTSolvers.Strategies.option_value(modeler, :show_time) == true
        @test_throws Exception modeler.options.mode  # Mode NOT stored
        
        # Option invalide - devrait échouer
        @test_throws CTSolvers.Exceptions.IncorrectArgument CTSolvers.Modelers.ADNLPModeler(; known_options..., unknown_options...)
    end
    
    @testset "Mode Permissif" begin
        # Options valides + invalides - devrait fonctionner (avec warning)
        modeler = CTSolvers.Modelers.ADNLPModeler(; known_options..., unknown_options..., mode=:permissive)
        @test modeler isa CTSolvers.Modelers.ADNLPModeler
        @test CTSolvers.Strategies.option_value(modeler, :backend) == :default
        @test CTSolvers.Strategies.option_value(modeler, :show_time) == true
        @test CTSolvers.Strategies.has_option(modeler, :fake_option)
        @test CTSolvers.Strategies.option_value(modeler, :fake_option) == 123
        @test_throws Exception modeler.options.mode  # Mode NOT stored
    end
end

# Test 2: build_strategy()
println("\n📋 Test 2: build_strategy()")
println("-" ^ 40)

@testset "build_strategy()" begin
    @testset "Mode Strict" begin
        # Options valides - devrait fonctionner
        @test_nowarn CTSolvers.Strategies.build_strategy(:adnlp, CTSolvers.Modelers.AbstractOptimizationModeler, registry; known_options...)
        modeler = CTSolvers.Strategies.build_strategy(:adnlp, CTSolvers.Modelers.AbstractOptimizationModeler, registry; known_options...)
        @test modeler isa CTSolvers.Modelers.ADNLPModeler
        @test CTSolvers.Strategies.option_value(modeler, :backend) == :default
        @test CTSolvers.Strategies.option_value(modeler, :show_time) == true
        @test_throws Exception modeler.options.mode  # Mode NOT stored
        
        # Option invalide - devrait échouer
        @test_throws CTSolvers.Exceptions.IncorrectArgument CTSolvers.Strategies.build_strategy(:adnlp, CTSolvers.Modelers.AbstractOptimizationModeler, registry; known_options..., unknown_options...)
    end
    
    @testset "Mode Permissif" begin
        # Options valides + invalides - devrait fonctionner
        @test_nowarn begin
            modeler = CTSolvers.Strategies.build_strategy(:adnlp, CTSolvers.Modelers.AbstractOptimizationModeler, registry; known_options..., unknown_options..., mode=:permissive)
            @test modeler isa CTSolvers.Modelers.ADNLPModeler
            @test CTSolvers.Strategies.option_value(modeler, :backend) == :default
            @test CTSolvers.Strategies.option_value(modeler, :show_time) == true
            @test CTSolvers.Strategies.has_option(modeler, :fake_option)
            @test CTSolvers.Strategies.option_value(modeler, :fake_option) == 123
            @test_throws Exception modeler.options.mode  # Mode NOT stored
        end
        @test_throws Exception modeler.options.mode  # Mode NOT stored
    end
end

# Test 3: build_strategy_from_method()
println("\n📋 Test 3: build_strategy_from_method()")
println("-" ^ 40)

method = (:collocation, :adnlp, :ipopt)

@testset "build_strategy_from_method()" begin
    @testset "Mode Strict" begin
        # Options valides - devrait fonctionner
        @test_nowarn CTSolvers.Strategies.build_strategy_from_method(method, CTSolvers.Modelers.AbstractOptimizationModeler, registry; known_options...)
        modeler = CTSolvers.Strategies.build_strategy_from_method(method, CTSolvers.Modelers.AbstractOptimizationModeler, registry; known_options...)
        @test modeler isa CTSolvers.Modelers.ADNLPModeler
        @test CTSolvers.Strategies.option_value(modeler, :backend) == :default
        @test CTSolvers.Strategies.option_value(modeler, :show_time) == true
        @test_throws Exception modeler.options.mode  # Mode NOT stored
        
        # Option invalide - devrait échouer
        @test_throws CTSolvers.Exceptions.IncorrectArgument CTSolvers.Strategies.build_strategy_from_method(method, CTSolvers.Modelers.AbstractOptimizationModeler, registry; known_options..., unknown_options...)
    end
    
    @testset "Mode Permissif" begin
        # Options valides + invalides - devrait fonctionner
        @test_nowarn CTSolvers.Strategies.build_strategy_from_method(method, CTSolvers.Modelers.AbstractOptimizationModeler, registry; known_options..., unknown_options..., mode=:permissive)
        modeler = CTSolvers.Strategies.build_strategy_from_method(method, CTSolvers.Modelers.AbstractOptimizationModeler, registry; known_options..., unknown_options..., mode=:permissive)
        @test modeler isa CTSolvers.Modelers.ADNLPModeler
        @test CTSolvers.Strategies.option_value(modeler, :backend) == :default
        @test CTSolvers.Strategies.option_value(modeler, :show_time) == true
        @test CTSolvers.Strategies.has_option(modeler, :fake_option)
        @test CTSolvers.Strategies.option_value(modeler, :fake_option) == 123
        @test_throws Exception modeler.options.mode  # Mode NOT stored
    end
end

# Test 4: Orchestration wrapper
println("\n📋 Test 4: Orchestration Wrapper")
println("-" ^ 40)

@testset "Orchestration Wrapper" begin
    @testset "Mode Strict" begin
        # Options valides - devrait fonctionner
        @test_nowarn CTSolvers.Orchestration.build_strategy_from_method(method, CTSolvers.Modelers.AbstractOptimizationModeler, registry; known_options...)
        modeler = CTSolvers.Orchestration.build_strategy_from_method(method, CTSolvers.Modelers.AbstractOptimizationModeler, registry; known_options...)
        @test modeler isa CTSolvers.Modelers.ADNLPModeler
        @test CTSolvers.Strategies.option_value(modeler, :backend) == :default
        @test CTSolvers.Strategies.option_value(modeler, :show_time) == true
        @test_throws Exception modeler.options.mode  # Mode NOT stored
        
        # Option invalide - devrait échouer
        @test_throws CTSolvers.Exceptions.IncorrectArgument CTSolvers.Orchestration.build_strategy_from_method(method, CTSolvers.Modelers.AbstractOptimizationModeler, registry; known_options..., unknown_options...)
    end
    
    @testset "Mode Permissif" begin
        # Options valides + invalides - devrait fonctionner
        @test_nowarn CTSolvers.Orchestration.build_strategy_from_method(method, CTSolvers.Modelers.AbstractOptimizationModeler, registry; known_options..., unknown_options..., mode=:permissive)
        modeler = CTSolvers.Orchestration.build_strategy_from_method(method, CTSolvers.Modelers.AbstractOptimizationModeler, registry; known_options..., unknown_options..., mode=:permissive)
        @test modeler isa CTSolvers.Modelers.ADNLPModeler
        @test CTSolvers.Strategies.option_value(modeler, :backend) == :default
        @test CTSolvers.Strategies.option_value(modeler, :show_time) == true
        @test CTSolvers.Strategies.has_option(modeler, :fake_option)
        @test CTSolvers.Strategies.option_value(modeler, :fake_option) == 123
        @test_throws Exception modeler.options.mode  # Mode NOT stored
    end
end

# Test 5: Consistance entre toutes les méthodes
println("\n📋 Test 5: Consistance Entre Toutes les Méthodes")
println("-" ^ 40)

@testset "Consistency Test" begin
    # Créer des stratégies avec différentes méthodes mais mêmes options
    modeler1 = CTSolvers.Modelers.ADNLPModeler(; known_options..., unknown_options..., mode=:permissive)
    modeler2 = CTSolvers.Strategies.build_strategy(:adnlp, CTSolvers.Modelers.AbstractOptimizationModeler, registry; known_options..., unknown_options..., mode=:permissive)
    modeler3 = CTSolvers.Strategies.build_strategy_from_method(method, CTSolvers.Modelers.AbstractOptimizationModeler, registry; known_options..., unknown_options..., mode=:permissive)
    modeler4 = CTSolvers.Orchestration.build_strategy_from_method(method, CTSolvers.Modelers.AbstractOptimizationModeler, registry; known_options..., unknown_options..., mode=:permissive)
    
    strategies = [modeler1, modeler2, modeler3, modeler4]
    
    for (i, strategy) in enumerate(strategies)
        @test strategy isa CTSolvers.Modelers.ADNLPModeler
        @test CTSolvers.Strategies.option_value(strategy, :backend) == :default
        @test CTSolvers.Strategies.option_value(strategy, :show_time) == true
        @test CTSolvers.Strategies.has_option(strategy, :fake_option)
        @test CTSolvers.Strategies.option_value(strategy, :fake_option) == 123
        @test CTSolvers.Strategies.has_option(strategy, :custom_param)
        @test CTSolvers.Strategies.option_value(strategy, :custom_param) == "test"
        @test_throws Exception strategy.options.mode  # Mode NOT stored
        println("   Strategy $i: ✅ All checks passed")
    end
end

println("\n" * "=" ^ 60)
println("🏁 Test Systématique Terminé")
println("✅ Tous les moyens de construction fonctionnent correctement!")
println("=" ^ 60)
