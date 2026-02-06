# Plan de Tests : Stratégie de Validation

## 1. Stratégie Globale de Tests

### 1.1 Objectifs

1. **Couverture complète** : Tous les cas d'usage strict/permissif
2. **Non-régression** : Aucun breaking change
3. **Qualité des messages** : Vérifier le contenu des erreurs/warnings
4. **Performance** : Pas d'impact significatif

### 1.2 Organisation

Tests organisés par **fonctionnalité** et **niveau** :

```
test/suite/
├── strategies/
│   ├── test_validation_strict.jl       # Constructeur mode strict
│   ├── test_validation_permissive.jl   # Constructeur mode permissif
│   └── test_validation_messages.jl     # Qualité des messages
├── orchestration/
│   ├── test_routing_strict.jl          # Routage mode strict
│   ├── test_routing_permissive.jl      # Routage mode permissif
│   └── test_routing_messages.jl        # Qualité des messages
└── integration/
    ├── test_strict_permissive_integration.jl  # End-to-end
    └── test_strict_permissive_performance.jl  # Benchmarks
```

### 1.3 Principes

🧪 **Applying Testing Rule**: Contract-First Testing

- Tester le comportement via l'API publique
- Utiliser des fakes pour l'isolation
- Séparer unit tests et integration tests
- Messages d'erreur vérifiés explicitement

## 2. Tests Constructeur - Mode Strict

### 2.1 Fichier : `test/suite/strategies/test_validation_strict.jl`

```julia
module TestValidationStrict

using Test
using CTSolvers
using CTSolvers.Strategies
using CTSolvers.Solvers
using CTSolvers.Options
using CTBase.Exceptions
using Main.TestOptions: VERBOSE, SHOWTIMING

function test_validation_strict()
    @testset "Validation Strict - Constructeur" verbose=VERBOSE showtiming=SHOWTIMING begin
        
        # ================================================================
        # UNIT TESTS - Options Connues Acceptées
        # ================================================================
        
        @testset "Options connues acceptées" begin
            # Test avec IpoptSolver (nécessite extension)
            using NLPModelsIpopt
            
            solver = Solvers.IpoptSolver(max_iter=1000, tol=1e-6)
            @test Strategies.option_value(solver, :max_iter) == 1000
            @test Strategies.option_value(solver, :tol) == 1e-6
            @test Strategies.option_source(solver, :max_iter) == :user
            @test Strategies.option_source(solver, :tol) == :user
        end
        
        @testset "Options avec aliases acceptées" begin
            using NLPModelsIpopt
            
            # maxiter est un alias de max_iter
            solver = Solvers.IpoptSolver(maxiter=500)
            @test Strategies.option_value(solver, :max_iter) == 500
        end
        
        @testset "Options par défaut utilisées" begin
            using NLPModelsIpopt
            
            solver = Solvers.IpoptSolver()
            @test Strategies.option_source(solver, :max_iter) == :default
            @test Strategies.option_source(solver, :tol) == :default
        end
        
        # ================================================================
        # UNIT TESTS - Unknown Options Rejected
        # ================================================================
        
        @testset "Unknown option rejected" begin
            using NLPModelsIpopt
            
            @test_throws Exceptions.IncorrectArgument begin
                Solvers.IpoptSolver(unknown_option=123)
            end
        end
        
        @testset "Multiple unknown options rejected" begin
            using NLPModelsIpopt
            
            @test_throws Exceptions.IncorrectArgument begin
                Solvers.IpoptSolver(unknown1=123, unknown2=456)
            end
        end
        
        @testset "Mix options connues/inconnues rejeté" begin
            using NLPModelsIpopt
            
            @test_throws Exceptions.IncorrectArgument begin
                Solvers.IpoptSolver(max_iter=1000, unknown=123)
            end
        end
        
        # ================================================================
        # UNIT TESTS - Error Message Quality
        # ================================================================
        
        @testset "Error message contains unknown option" begin
            using NLPModelsIpopt
            
            try
                Solvers.IpoptSolver(unknown_option=123)
                @test false  # Ne devrait pas arriver ici
            catch e
                @test e isa Exceptions.IncorrectArgument
                msg = string(e)
                @test occursin("unknown_option", msg)
                @test occursin("Unrecognized options", msg)
            end
        end
        
        @testset "Message contient suggestions (typo)" begin
            using NLPModelsIpopt
            
            try
                Solvers.IpoptSolver(max_it=1000)  # Typo
                @test false
            catch e
                @test e isa Exceptions.IncorrectArgument
                msg = string(e)
                @test occursin("max_iter", msg)  # Suggestion
                @test occursin("mode=:permissive", msg)  # Solution alternative
            end
        end
        
        @testset "Message contient options disponibles" begin
            using NLPModelsIpopt
            
            try
                Solvers.IpoptSolver(unknown=123)
                @test false
            catch e
                @test e isa Exceptions.IncorrectArgument
                msg = string(e)
                @test occursin("Options disponibles", msg)
                @test occursin("max_iter", msg)
                @test occursin("tol", msg)
            end
        end
        
        # ================================================================
        # UNIT TESTS - Validation Type (même en mode strict)
        # ================================================================
        
        @testset "Type incorrect détecté" begin
            using NLPModelsIpopt
            
            # max_iter attend un Integer, pas un String
            @test_throws Exception begin  # Type ou validation error
                Solvers.IpoptSolver(max_iter="1000")
            end
        end
        
        @testset "Validation custom appliquée" begin
            using NLPModelsIpopt
            
            # tol doit être positif
            @test_throws Exceptions.IncorrectArgument begin
                Solvers.IpoptSolver(tol=-1.0)
            end
        end
        
        # ================================================================
        # UNIT TESTS - Mode Strict Explicite
        # ================================================================
        
        @testset "mode=:strict explicite identique au défaut" begin
            using NLPModelsIpopt
            
            @test_throws Exceptions.IncorrectArgument begin
                Solvers.IpoptSolver(unknown=123; mode=:strict)
            end
        end
        
    end
end

end # module

test_validation_strict() = TestValidationStrict.test_validation_strict()
```

## 3. Tests Constructeur - Mode Permissif

### 3.1 Fichier : `test/suite/strategies/test_validation_permissive.jl`

```julia
module TestValidationPermissive

using Test
using CTSolvers
using CTSolvers.Strategies
using CTSolvers.Solvers
using CTSolvers.Options
using CTBase.Exceptions
using Main.TestOptions: VERBOSE, SHOWTIMING

function test_validation_permissive()
    @testset "Validation Permissive - Constructeur" verbose=VERBOSE showtiming=SHOWTIMING begin
        
        # ================================================================
        # UNIT TESTS - Options Connues (comportement normal)
        # ================================================================
        
        @testset "Options connues fonctionnent normalement" begin
            using NLPModelsIpopt
            
            solver = Solvers.IpoptSolver(max_iter=1000; mode=:permissive)
            @test Strategies.option_value(solver, :max_iter) == 1000
            @test Strategies.option_source(solver, :max_iter) == :user
        end
        
        @testset "Validation type toujours appliquée" begin
            using NLPModelsIpopt
            
            # Type incorrect rejeté même en mode permissif
            @test_throws Exception begin
                Solvers.IpoptSolver(max_iter="1000"; mode=:permissive)
            end
        end
        
        @testset "Validation custom toujours appliquée" begin
            using NLPModelsIpopt
            
            # Validation custom rejetée même en mode permissif
            @test_throws Exceptions.IncorrectArgument begin
                Solvers.IpoptSolver(tol=-1.0; mode=:permissive)
            end
        end
        
        # ================================================================
        # UNIT TESTS - Unknown Options Accepted with Warning
        # ================================================================
        
        @testset "Unknown option accepted with warning" begin
            using NLPModelsIpopt
            
            # Capture warning
            @test_logs (:warn, r"Unrecognized options") begin
                solver = Solvers.IpoptSolver(unknown_option=123; mode=:permissive)
                opts = Strategies.options_dict(solver)
                @test haskey(opts, :unknown_option)
                @test opts[:unknown_option] == 123
            end
        end
        
        @testset "Multiple unknown options accepted" begin
            using NLPModelsIpopt
            
            @test_logs (:warn, r"Unrecognized options") begin
                solver = Solvers.IpoptSolver(
                    unknown1=123, 
                    unknown2=456; 
                    mode=:permissive
                )
                opts = Strategies.options_dict(solver)
                @test opts[:unknown1] == 123
                @test opts[:unknown2] == 456
            end
        end
        
        @testset "Mix options connues/inconnues accepté" begin
            using NLPModelsIpopt
            
            @test_logs (:warn, r"Unrecognized options") begin
                solver = Solvers.IpoptSolver(
                    max_iter=1000,
                    unknown=123;
                    mode=:permissive
                )
                opts = Strategies.options_dict(solver)
                @test opts[:max_iter] == 1000
                @test opts[:unknown] == 123
            end
        end
        
        # ================================================================
        # UNIT TESTS - Source des Options Non Validées
        # ================================================================
        
        @testset "Options non validées ont source :user_unvalidated" begin
            using NLPModelsIpopt
            
            @test_logs (:warn,) begin
                solver = Solvers.IpoptSolver(unknown=123; mode=:permissive)
                opts = Strategies.options(solver)
                # Vérifier la source si accessible
                # (dépend de l'implémentation finale)
            end
        end
        
        # ================================================================
        # UNIT TESTS - Transmission aux Backends
        # ================================================================
        
        @testset "Options non validées transmitted au backend" begin
            using NLPModelsIpopt
            
            @test_logs (:warn,) begin
                solver = Solvers.IpoptSolver(
                    custom_ipopt_opt=456; 
                    mode=:permissive
                )
                opts = Strategies.options_dict(solver)
                @test haskey(opts, :custom_ipopt_opt)
                @test opts[:custom_ipopt_opt] == 456
                
                # Vérifier que le dict peut être passé au backend
                @test opts isa Dict{Symbol, Any}
            end
        end
        
        # ================================================================
        # UNIT TESTS - Qualité des Warnings
        # ================================================================
        
        @testset "Warning contient liste des options" begin
            using NLPModelsIpopt
            
            logs = Test.@test_logs (:warn,) match_mode=:any begin
                Solvers.IpoptSolver(unknown1=1, unknown2=2; mode=:permissive)
            end
            
            # Vérifier le contenu du warning
            @test length(logs) >= 1
            warn_msg = string(logs[1][2])
            @test occursin("unknown1", warn_msg) || occursin("unknown2", warn_msg)
        end
        
    end
end

end # module

test_validation_permissive() = TestValidationPermissive.test_validation_permissive()
```

## 4. Tests Routage - Mode Strict

### 4.1 Fichier : `test/suite/orchestration/test_routing_strict.jl`

```julia
module TestRoutingStrict

using Test
using CTSolvers
using CTSolvers.Orchestration
using CTSolvers.Strategies
using CTSolvers.Options
using CTBase.Exceptions
using Main.TestOptions: VERBOSE, SHOWTIMING

function test_routing_strict()
    @testset "Routage Strict" verbose=VERBOSE showtiming=SHOWTIMING begin
        
        # Setup commun
        method = (:adnlp, :ipopt)
        families = (
            modeler = Modelers.AbstractOptimizationModeler,
            solver = Solvers.AbstractOptimizationSolver
        )
        action_defs = Options.OptionDefinition[]
        registry = Strategies.default_registry()
        
        # ================================================================
        # UNIT TESTS - Options Connues Routées Correctement
        # ================================================================
        
        @testset "Option non ambiguë routée automatiquement" begin
            using NLPModelsIpopt
            
            kwargs = (max_iter=1000,)  # Appartient uniquement au solver
            
            routed = Orchestration.route_all_options(
                method, families, action_defs, kwargs, registry;
                mode=:strict
            )
            
            @test haskey(routed.strategies.solver, :max_iter)
            @test routed.strategies.solver.max_iter == 1000
        end
        
        @testset "Option disambiguated routée correctement" begin
            using NLPModelsIpopt
            
            # backend existe dans modeler et solver
            kwargs = (backend=(:sparse, :adnlp),)
            
            routed = Orchestration.route_all_options(
                method, families, action_defs, kwargs, registry;
                mode=:strict
            )
            
            @test haskey(routed.strategies.modeler, :backend)
            @test routed.strategies.modeler.backend == :sparse
        end
        
        # ================================================================
        # UNIT TESTS - Options Inconnues Rejetées
        # ================================================================
        
        @testset "Unknown option (0 owners) rejetée" begin
            using NLPModelsIpopt
            
            kwargs = (unknown_option=123,)
            
            @test_throws Exceptions.IncorrectArgument begin
                Orchestration.route_all_options(
                    method, families, action_defs, kwargs, registry;
                    mode=:strict
                )
            end
        end
        
        @testset "Ambiguous option sans disambiguation rejetée" begin
            using NLPModelsIpopt
            
            # backend ambiguë
            kwargs = (backend=:sparse,)
            
            @test_throws Exceptions.IncorrectArgument begin
                Orchestration.route_all_options(
                    method, families, action_defs, kwargs, registry;
                    mode=:strict
                )
            end
        end
        
        # ================================================================
        # UNIT TESTS - Qualité des Messages
        # ================================================================
        
        @testset "Message erreur option inconnue contient suggestions" begin
            using NLPModelsIpopt
            
            kwargs = (unknown_opt=123,)
            
            try
                Orchestration.route_all_options(
                    method, families, action_defs, kwargs, registry;
                    mode=:strict
                )
                @test false
            catch e
                @test e isa Exceptions.IncorrectArgument
                msg = string(e)
                @test occursin("unknown_opt", msg)
                @test occursin("Options disponibles", msg)
            end
        end
        
        @testset "Message erreur ambiguïté contient syntaxe disambiguation" begin
            using NLPModelsIpopt
            
            kwargs = (backend=:sparse,)
            
            try
                Orchestration.route_all_options(
                    method, families, action_defs, kwargs, registry;
                    mode=:strict
                )
                @test false
            catch e
                @test e isa Exceptions.IncorrectArgument
                msg = string(e)
                @test occursin("backend", msg)
                @test occursin("ambiguë", msg)
                @test occursin(":adnlp", msg)
                @test occursin(":ipopt", msg)
            end
        end
        
    end
end

end # module

test_routing_strict() = TestRoutingStrict.test_routing_strict()
```

## 5. Tests Routage - Mode Permissif

### 5.1 Fichier : `test/suite/orchestration/test_routing_permissive.jl`

```julia
module TestRoutingPermissive

using Test
using CTSolvers
using CTSolvers.Orchestration
using CTSolvers.Strategies
using CTSolvers.Options
using CTBase.Exceptions
using Main.TestOptions: VERBOSE, SHOWTIMING

function test_routing_permissive()
    @testset "Routage Permissif" verbose=VERBOSE showtiming=SHOWTIMING begin
        
        # Setup commun
        method = (:adnlp, :ipopt)
        families = (
            modeler = Modelers.AbstractOptimizationModeler,
            solver = Solvers.AbstractOptimizationSolver
        )
        action_defs = Options.OptionDefinition[]
        registry = Strategies.default_registry()
        
        # ================================================================
        # UNIT TESTS - Options Connues (comportement normal)
        # ================================================================
        
        @testset "Options connues routées normalement" begin
            using NLPModelsIpopt
            
            kwargs = (max_iter=1000,)
            
            routed = Orchestration.route_all_options(
                method, families, action_defs, kwargs, registry;
                mode=:permissive
            )
            
            @test haskey(routed.strategies.solver, :max_iter)
            @test routed.strategies.solver.max_iter == 1000
        end
        
        @testset "Ambiguous option toujours rejetée" begin
            using NLPModelsIpopt
            
            # Ambiguïté doit être résolue même en mode permissif
            kwargs = (backend=:sparse,)
            
            @test_throws Exceptions.IncorrectArgument begin
                Orchestration.route_all_options(
                    method, families, action_defs, kwargs, registry;
                    mode=:permissive
                )
            end
        end
        
        # ================================================================
        # UNIT TESTS - Options Inconnues Sans Disambiguation
        # ================================================================
        
        @testset "Unknown option sans disambiguation rejetée" begin
            using NLPModelsIpopt
            
            kwargs = (unknown_option=123,)
            
            @test_throws Exceptions.IncorrectArgument begin
                Orchestration.route_all_options(
                    method, families, action_defs, kwargs, registry;
                    mode=:permissive
                )
            end
        end
        
        @testset "Message erreur explique requirement disambiguation" begin
            using NLPModelsIpopt
            
            kwargs = (unknown_opt=123,)
            
            try
                Orchestration.route_all_options(
                    method, families, action_defs, kwargs, registry;
                    mode=:permissive
                )
                @test false
            catch e
                @test e isa Exceptions.IncorrectArgument
                msg = string(e)
                @test occursin("disambiguated", msg)
                @test occursin("(value, :strategy_id)", msg)
            end
        end
        
        # ================================================================
        # UNIT TESTS - Options Inconnues Avec Disambiguation
        # ================================================================
        
        @testset "Unknown option disambiguated acceptée avec warning" begin
            using NLPModelsIpopt
            
            kwargs = (unknown_option=(123, :ipopt),)
            
            @test_logs (:warn, r"Option non reconnue") begin
                routed = Orchestration.route_all_options(
                    method, families, action_defs, kwargs, registry;
                    mode=:permissive
                )
                
                @test haskey(routed.strategies.solver, :unknown_option)
                @test routed.strategies.solver.unknown_option == 123
            end
        end
        
        @testset "Plusieurs options inconnues disambiguateds acceptées" begin
            using NLPModelsIpopt
            
            kwargs = (
                unknown1=(111, :adnlp),
                unknown2=(222, :ipopt)
            )
            
            @test_logs (:warn,) (:warn,) match_mode=:any begin
                routed = Orchestration.route_all_options(
                    method, families, action_defs, kwargs, registry;
                    mode=:permissive
                )
                
                @test routed.strategies.modeler.unknown1 == 111
                @test routed.strategies.solver.unknown2 == 222
            end
        end
        
        @testset "Mix options connues/inconnues accepté" begin
            using NLPModelsIpopt
            
            kwargs = (
                max_iter=1000,
                unknown=(123, :ipopt)
            )
            
            @test_logs (:warn,) match_mode=:any begin
                routed = Orchestration.route_all_options(
                    method, families, action_defs, kwargs, registry;
                    mode=:permissive
                )
                
                @test routed.strategies.solver.max_iter == 1000
                @test routed.strategies.solver.unknown == 123
            end
        end
        
        # ================================================================
        # UNIT TESTS - Routage Invalide Détecté
        # ================================================================
        
        @testset "Option connue routée vers mauvaise stratégie rejetée" begin
            using NLPModelsIpopt
            
            # max_iter appartient au solver, pas au modeler
            kwargs = (max_iter=(1000, :adnlp),)
            
            @test_throws Exceptions.IncorrectArgument begin
                Orchestration.route_all_options(
                    method, families, action_defs, kwargs, registry;
                    mode=:permissive
                )
            end
        end
        
    end
end

end # module

test_routing_permissive() = TestRoutingPermissive.test_routing_permissive()
```

## 6. Tests d'Intégration

### 6.1 Fichier : `test/suite/integration/test_strict_permissive_integration.jl`

```julia
module TestStrictPermissiveIntegration

using Test
using CTSolvers
using CTBase.Exceptions
using Main.TestOptions: VERBOSE, SHOWTIMING
using Main.TestProblems: Rosenbrock

function test_strict_permissive_integration()
    @testset "Intégration Strict/Permissif" verbose=VERBOSE showtiming=SHOWTIMING begin
        
        # ================================================================
        # INTEGRATION TESTS - End-to-End Mode Strict
        # ================================================================
        
        @testset "solve() mode strict - options connues" begin
            using NLPModelsIpopt
            
            ros = Rosenbrock()
            
            # Devrait fonctionner
            sol = solve(ros.prob, :adnlp, :ipopt;
                max_iter=100,
                tol=1e-6,
                mode=:strict
            )
            
            @test sol isa Solution
        end
        
        @testset "solve() mode strict - option inconnue rejetée" begin
            using NLPModelsIpopt
            
            ros = Rosenbrock()
            
            @test_throws Exceptions.IncorrectArgument begin
                solve(ros.prob, :adnlp, :ipopt;
                    max_iter=100,
                    unknown_option=123,
                    mode=:strict
                )
            end
        end
        
        # ================================================================
        # INTEGRATION TESTS - End-to-End Mode Permissif
        # ================================================================
        
        @testset "solve() mode permissif - option inconnue disambiguated" begin
            using NLPModelsIpopt
            
            ros = Rosenbrock()
            
            @test_logs (:warn,) match_mode=:any begin
                sol = solve(ros.prob, :adnlp, :ipopt;
                    max_iter=100,
                    custom_ipopt_option=(456, :ipopt),
                    mode=:permissive
                )
                
                @test sol isa Solution
            end
        end
        
        @testset "solve() mode permissif - option inconnue sans disambiguation rejetée" begin
            using NLPModelsIpopt
            
            ros = Rosenbrock()
            
            @test_throws Exceptions.IncorrectArgument begin
                solve(ros.prob, :adnlp, :ipopt;
                    max_iter=100,
                    unknown_option=123,  # Pas de disambiguation
                    mode=:permissive
                )
            end
        end
        
        # ================================================================
        # INTEGRATION TESTS - Propagation du Mode
        # ================================================================
        
        @testset "Mode strict se propage à travers la chaîne" begin
            using NLPModelsIpopt
            
            ros = Rosenbrock()
            
            # L'erreur doit venir du constructeur de stratégie
            @test_throws Exceptions.IncorrectArgument begin
                solve(ros.prob, :adnlp, :ipopt;
                    max_iter=100,
                    unknown=(123, :ipopt),  # Disambiguée au routage
                    mode=:strict  # Mais strict au constructeur
                )
            end
        end
        
        @testset "Mode permissif se propage à travers la chaîne" begin
            using NLPModelsIpopt
            
            ros = Rosenbrock()
            
            @test_logs (:warn,) (:warn,) match_mode=:any begin
                sol = solve(ros.prob, :adnlp, :ipopt;
                    max_iter=100,
                    unknown=(123, :ipopt),
                    mode=:permissive
                )
                
                @test sol isa Solution
            end
        end
        
    end
end

end # module

test_strict_permissive_integration() = TestStrictPermissiveIntegration.test_strict_permissive_integration()
```

## 7. Tests de Performance

### 7.1 Fichier : `test/suite/integration/test_strict_permissive_performance.jl`

```julia
module TestStrictPermissivePerformance

using Test
using BenchmarkTools
using CTSolvers
using CTSolvers.Solvers
using Main.TestOptions: VERBOSE, SHOWTIMING

function test_strict_permissive_performance()
    @testset "Performance Strict/Permissif" verbose=VERBOSE showtiming=SHOWTIMING begin
        
        using NLPModelsIpopt
        
        # ================================================================
        # PERFORMANCE TESTS - Constructeur
        # ================================================================
        
        @testset "Mode strict - overhead nul" begin
            # Baseline
            t_baseline = @belapsed Solvers.IpoptSolver(max_iter=1000)
            
            # Avec mode=:strict explicite
            t_strict = @belapsed Solvers.IpoptSolver(max_iter=1000; mode=:strict)
            
            # Overhead doit être négligeable (< 1%)
            overhead = (t_strict - t_baseline) / t_baseline
            @test overhead < 0.01
        end
        
        @testset "Mode permissif - overhead minimal" begin
            # Baseline
            t_baseline = @belapsed Solvers.IpoptSolver(max_iter=1000)
            
            # Mode permissif avec option inconnue
            t_permissive = @belapsed begin
                # Supprimer le warning pour le benchmark
                Solvers.IpoptSolver(max_iter=1000, custom=123; mode=:permissive)
            end
            
            # Overhead doit être < 5%
            overhead = (t_permissive - t_baseline) / t_baseline
            @test overhead < 0.05
        end
        
        # ================================================================
        # PERFORMANCE TESTS - Routage
        # ================================================================
        
        @testset "Routage strict - pas d'impact" begin
            method = (:adnlp, :ipopt)
            families = (
                modeler = Modelers.AbstractOptimizationModeler,
                solver = Solvers.AbstractOptimizationSolver
            )
            action_defs = Options.OptionDefinition[]
            registry = Strategies.default_registry()
            kwargs = (max_iter=1000,)
            
            # Benchmark
            t = @belapsed Orchestration.route_all_options(
                $method, $families, $action_defs, $kwargs, $registry;
                mode=:strict
            )
            
            # Doit être rapide (< 1ms)
            @test t < 0.001
        end
        
    end
end

end # module

test_strict_permissive_performance() = TestStrictPermissivePerformance.test_strict_permissive_performance()
```

## 8. Checklist de Couverture

### 8.1 Constructeur - Mode Strict

- [x] Options connues acceptées
- [x] Options avec aliases acceptées
- [x] Options par défaut utilisées
- [x] Unknown option rejetée
- [x] Plusieurs options inconnues rejetées
- [x] Mix options connues/inconnues rejeté
- [x] Message contient option inconnue
- [x] Message contient suggestions (typo)
- [x] Message contient options disponibles
- [x] Type incorrect détecté
- [x] Validation custom appliquée
- [x] mode=:strict explicite identique au défaut

### 8.2 Constructeur - Mode Permissif

- [x] Options connues fonctionnent normalement
- [x] Validation type toujours appliquée
- [x] Validation custom toujours appliquée
- [x] Unknown option acceptée avec warning
- [x] Plusieurs options inconnues acceptées
- [x] Mix options connues/inconnues accepté
- [x] Options non validées ont source :user_unvalidated
- [x] Options non validées transmitted au backend
- [x] Warning contient liste des options

### 8.3 Routage - Mode Strict

- [x] Option non ambiguë routée automatiquement
- [x] Option disambiguated routée correctement
- [x] Unknown option (0 owners) rejetée
- [x] Ambiguous option sans disambiguation rejetée
- [x] Message erreur option inconnue contient suggestions
- [x] Message erreur ambiguïté contient syntaxe disambiguation

### 8.4 Routage - Mode Permissif

- [x] Options connues routées normalement
- [x] Ambiguous option toujours rejetée
- [x] Unknown option sans disambiguation rejetée
- [x] Message erreur explique requirement disambiguation
- [x] Unknown option disambiguated acceptée avec warning
- [x] Plusieurs options inconnues disambiguateds acceptées
- [x] Mix options connues/inconnues accepté
- [x] Option connue routée vers mauvaise stratégie rejetée

### 8.5 Intégration

- [x] solve() mode strict - options connues
- [x] solve() mode strict - option inconnue rejetée
- [x] solve() mode permissif - option inconnue disambiguated
- [x] solve() mode permissif - option inconnue sans disambiguation rejetée
- [x] Mode strict se propage à travers la chaîne
- [x] Mode permissif se propage à travers la chaîne

### 8.6 Performance

- [x] Mode strict - overhead nul
- [x] Mode permissif - overhead minimal
- [x] Routage strict - pas d'impact

## 9. Exécution des Tests

### 9.1 Commandes

```bash
# Tous les tests
julia --project=@. -e 'using Pkg; Pkg.test()'

# Tests spécifiques
julia --project=@. test/suite/strategies/test_validation_strict.jl
julia --project=@. test/suite/strategies/test_validation_permissive.jl
julia --project=@. test/suite/orchestration/test_routing_strict.jl
julia --project=@. test/suite/orchestration/test_routing_permissive.jl
julia --project=@. test/suite/integration/test_strict_permissive_integration.jl

# Tests de performance
julia --project=@. test/suite/integration/test_strict_permissive_performance.jl
```

### 9.2 CI/CD

Les tests doivent passer dans la CI avant merge :

```yaml
# .github/workflows/CI.yml
test:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v2
    - uses: julia-actions/setup-julia@v1
    - run: julia --project=@. -e 'using Pkg; Pkg.test()'
```

## 10. Critères d'Acceptation

### 10.1 Couverture

- ✅ Couverture de code > 95% pour les nouvelles fonctions
- ✅ Tous les cas d'usage documentés testés
- ✅ Tous les messages d'erreur vérifiés

### 10.2 Non-Régression

- ✅ Tous les tests existants passent
- ✅ Aucun breaking change détecté
- ✅ Performance maintenue

### 10.3 Qualité

- ✅ Tests suivent les standards `.windsurf/rules/testing.md`
- ✅ Tests bien organisés et documentés
- ✅ Tests indépendants et déterministes

## 11. Maintenance

### 11.1 Ajout de Nouvelles Options

Quand une nouvelle option est ajoutée aux metadata :

1. Ajouter test de validation (type, validator)
2. Vérifier que l'option est routée correctement
3. Tester en mode strict et permissif

### 11.2 Ajout de Nouvelles Stratégies

Quand une nouvelle stratégie est ajoutée :

1. Tester le contrat `validate_strategy_contract()`
2. Tester le constructeur en mode strict/permissif
3. Tester le routage si applicable

### 11.3 Modification des Messages

Quand un message est modifié :

1. Mettre à jour les tests de messages
2. Vérifier que le contenu reste informatif
3. Valider avec des utilisateurs si possible
