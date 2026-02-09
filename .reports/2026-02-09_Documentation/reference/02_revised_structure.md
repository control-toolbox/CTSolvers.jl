# Structure Révisée et Synopsis par Page

**Date** : 9 février 2026
**Objet** : Proposition révisée suite à la revue critique

---

## 1. Principes Directeurs

Trois principes guident cette structure révisée :

- **Un seul endroit par concept.** Pas de duplication entre "interface" et "tutoriel". Chaque contrat est documenté une seule fois, avec son implémentation pas à pas intégrée.
- **Architecture d'abord.** Le développeur doit comprendre la vision d'ensemble avant de plonger dans un contrat spécifique.
- **API séparée Public/Internal.** Conforme au modèle éprouvé de `migration_to_ctsolvers/docs/api_reference.jl`.

---

## 2. Structure Finale

```
docs/src/
├── index.md
├── architecture.md
├── guides/
│   ├── options_system.md
│   ├── implementing_a_strategy.md
│   ├── implementing_a_solver.md
│   ├── implementing_a_modeler.md
│   ├── implementing_an_optimization_problem.md
│   └── orchestration_and_routing.md
└── api/                                    [généré par api_reference.jl]
    ├── options/
    │   ├── options_public.md
    │   └── options_internal.md
    ├── strategies/
    │   ├── strategies_contract_public.md
    │   ├── strategies_contract_internal.md
    │   ├── strategies_api_public.md
    │   └── strategies_api_internal.md
    ├── orchestration/
    │   ├── orchestration_public.md
    │   └── orchestration_internal.md
    ├── optimization/
    │   ├── optimization_public.md
    │   └── optimization_internal.md
    ├── modelers/
    │   ├── modelers_public.md
    │   └── modelers_internal.md
    ├── docp/
    │   ├── docp_public.md
    │   └── docp_internal.md
    ├── solvers/
    │   ├── solvers_public.md
    │   └── solvers_internal.md
    └── extensions/
        ├── ipopt.md
        ├── madnlp.md
        ├── madncl.md
        └── knitro.md
```

**Total** : 8 pages rédigées manuellement + ~22 pages API générées automatiquement.

---

## 3. Synopsis par Page

### 3.1 `index.md` — Point d'entrée

**Objectif** : Orienter le développeur en 30 secondes.

**Contenu** :

- Positionnement : CTSolvers = couche de résolution dans l'écosystème control-toolbox. Distinction claire avec CTModels (définition des problèmes) et OptimalControl (interface utilisateur).
- Les 7 modules en une phrase chacun, avec lien vers la page appropriée.
- Convention d'accès qualifié (`CTSolvers.Strategies.id(...)`, pas d'exports directs).
- Quick Start : un bloc de code de 10-15 lignes montrant le flux complet OCP → DOCP → NLP → Solution.
- Table de navigation : "Je veux comprendre l'architecture → `architecture.md`", "Je veux implémenter un solveur → `guides/implementing_a_solver.md`", etc.

**Ce que cette page n'est PAS** : Un guide d'installation (c'est trivial en Julia), un historique du projet, une liste exhaustive de fonctionnalités.

**Longueur cible** : 80-120 lignes.

---

### 3.2 `architecture.md` — Le pivot central

**Objectif** : Donner au développeur la carte mentale complète de CTSolvers.

**Contenu** :

**Section 1 — Hiérarchie des types abstraits**

Diagramme ASCII de la hiérarchie complète :

```
AbstractStrategy
├── AbstractOptimizationModeler
│   ├── ADNLPModeler
│   └── ExaModeler
└── AbstractOptimizationSolver
    ├── IpoptSolver
    ├── MadNLPSolver
    ├── MadNCLSolver
    └── KnitroSolver

AbstractOptimizationProblem
└── DiscretizedOptimalControlProblem

AbstractBuilder
├── AbstractModelBuilder
│   ├── ADNLPModelBuilder
│   └── ExaModelBuilder
└── AbstractSolutionBuilder
    ├── AbstractOCPSolutionBuilder
    ├── ADNLPSolutionBuilder
    └── ExaSolutionBuilder
```

Explication du rôle de chaque branche et de la relation entre elles.

**Section 2 — Graphe de dépendances entre modules**

```
Options ──→ Strategies ──→ Orchestration
                │
                ├──→ Optimization
                │         │
                ├──→ Modelers ←── Optimization
                │
                ├──→ DOCP ←── Optimization
                │
                └──→ Solvers ←── Optimization, Modelers
```

Explication de l'ordre de chargement dans `CTSolvers.jl` et pourquoi il est important.

**Section 3 — Flux de données**

Le chemin d'une résolution complète :

```
OptimalControlProblem (CTModels)
    → DiscretizedOptimalControlProblem (DOCP)
        → AbstractModelBuilder.build_model() → NLP Model (ADNLPModel/ExaModel)
            → AbstractOptimizationSolver(nlp) → ExecutionStats
                → AbstractSolutionBuilder.build_solution() → OCP Solution
```

**Section 4 — Patterns architecturaux**

- **Two-level contract** : Méthodes sur le type (introspection) vs méthodes sur l'instance (exécution). Pourquoi cette séparation existe.
- **NotImplemented pattern** : Les méthodes de contrat lèvent `NotImplemented` par défaut avec des messages d'aide.
- **Tag Dispatch** : Comment les extensions utilisent des types tags pour le dispatch.
- **Qualified access** : Pourquoi CTSolvers n'exporte rien au niveau top-level.

**Section 5 — Conventions**

- Nommage des types, modules, fonctions.
- Pattern constructeur avec `build_strategy_options`.
- Pattern `OptionDefinition` avec aliases et validators.

**Longueur cible** : 200-300 lignes.

---

### 3.3 `guides/options_system.md` — Système d'options

**Objectif** : Documenter le système d'options pour ceux qui implémentent des stratégies.

**Contenu** :

**Section 1 — OptionDefinition**

- Création d'une définition d'option : nom, type, default, description, aliases, validator.
- Exemples concrets avec différents types et validators.

**Section 2 — OptionValue et provenance**

- Les 3 sources : `:user`, `:default`, `:computed`.
- Comment la provenance est trackée et pourquoi c'est utile.

**Section 3 — StrategyMetadata**

- Comment assembler des `OptionDefinition` en `StrategyMetadata`.
- L'interface Collection (keys, values, pairs, getindex).

**Section 4 — StrategyOptions**

- Construction via `build_strategy_options`.
- Accès aux valeurs : `opts[:key]` (valeur), `opts.key` (OptionValue), `get(opts, Val(:key))` (type-stable).
- Introspection : `source`, `is_user`, `is_default`, `is_computed`.

**Section 5 — Modes de validation**

- Mode strict : rejet des options inconnues, suggestions Levenshtein.
- Mode permissif : acceptation avec warning.
- Quand utiliser chaque mode.

**Section 6 — extract_options et extract_raw_options**

- Extraction d'options depuis des kwargs.
- Différence entre les deux fonctions.

**Ce que cette page remplace** : `options_validation.md` et `migration_guide.md` actuels, fusionnés et restructurés.

**Longueur cible** : 200-250 lignes.

---

### 3.4 `guides/implementing_a_strategy.md` — Le contrat fondamental

**Objectif** : Permettre à un développeur d'implémenter une stratégie complète et fonctionnelle.

**Contenu** :

**Section 1 — Le two-level contract**

Explication détaillée avec diagramme :
- Type-level : `id(::Type)`, `metadata(::Type)` — introspection sans instanciation.
- Instance-level : `options(strategy)` — configuration de l'instance.
- Pourquoi cette séparation (routing, validation avant construction, introspection).

**Section 2 — Implémentation minimale (pas à pas)**

Étape 1 : Définir le struct avec champ `options::StrategyOptions`.

```julia
struct MyStrategy <: AbstractStrategy
    options::StrategyOptions
end
```

Étape 2 : Implémenter `id` (type-level).

```julia
Strategies.id(::Type{<:MyStrategy}) = :my_strategy
```

Étape 3 : Implémenter `metadata` avec `OptionDefinition`.

```julia
Strategies.metadata(::Type{<:MyStrategy}) = StrategyMetadata(
    OptionDefinition(name=:param, type=Int, default=42, description="...")
)
```

Étape 4 : Implémenter le constructeur avec `build_strategy_options`.

```julia
function MyStrategy(; mode::Symbol=:strict, kwargs...)
    options = build_strategy_options(MyStrategy; mode=mode, kwargs...)
    return MyStrategy(options)
end
```

Étape 5 : Implémenter `options` (instance-level).

```julia
Strategies.options(s::MyStrategy) = s.options
```

**Section 3 — Validation**

- Utiliser `validate_strategy_contract(MyStrategy)`.
- Montrer les messages d'erreur quand une méthode manque.
- Tests unitaires pour chaque méthode du contrat.

**Section 4 — Enregistrement dans un Registry**

- `create_registry` et `strategy_ids`.
- `build_strategy` et `build_strategy_from_method`.
- Introspection : `option_names`, `option_type`, `option_description`.

**Section 5 — Patterns avancés**

- Aliases d'options.
- Validators personnalisés.
- Strategy families (types abstraits intermédiaires).
- Mode permissif pour options backend.

**Longueur cible** : 300-400 lignes.

---

### 3.5 `guides/implementing_a_solver.md` — Solveurs et extensions

**Objectif** : Implémenter un solveur complet avec extension conditionnelle.

**Contenu** :

**Section 1 — Le contrat AbstractOptimizationSolver**

- Héritage : `AbstractOptimizationSolver <: AbstractStrategy`.
- Le contrat Strategy (hérité) + le contrat callable : `(solver)(nlp; display)`.
- Retour attendu : `SolverCore.AbstractExecutionStats`.

**Section 2 — Implémentation du type solveur**

Pas à pas dans `src/Solvers/` :
- Struct avec `options::StrategyOptions`.
- `id`, `metadata`, constructeur.
- Le callable qui délègue au backend.

**Section 3 — Le pattern Tag Dispatch**

- Pourquoi : séparer la logique (dans `src/`) de l'implémentation backend (dans `ext/`).
- Comment : `AbstractTag` et dispatch sur le type tag.
- Exemple concret avec un solveur existant.

**Section 4 — Créer l'extension**

- Structure du fichier `ext/CTSolversMyBackend.jl`.
- Déclaration dans `Project.toml` (weakdeps, extensions).
- Implémentation de la méthode callable dans l'extension.

**Section 5 — Intégration CommonSolve**

Les 3 niveaux de `CommonSolve.solve` :
- High-level : `solve(problem, x0, modeler, solver)` — flux complet.
- Mid-level : `solve(nlp, solver)` — NLP direct.
- Low-level : `solve(any, solver)` — flexible.

**Section 6 — Tests**

- Test du contrat Strategy.
- Test du callable (avec mock NLP).
- Test de l'extension (si le backend est disponible).
- Test CommonSolve.

**Longueur cible** : 300-400 lignes.

---

### 3.6 `guides/implementing_a_modeler.md` — Modelers

**Objectif** : Implémenter un modeler qui convertit un problème d'optimisation en modèle NLP.

**Contenu** :

**Section 1 — Le contrat AbstractOptimizationModeler**

- Héritage : `AbstractOptimizationModeler <: AbstractStrategy`.
- Deux callables obligatoires :
  - `(modeler)(prob, initial_guess)` → NLP model.
  - `(modeler)(prob, nlp_solution)` → Solution.
- Interaction avec `AbstractOptimizationProblem` et ses builders.

**Section 2 — Implémentation pas à pas**

- Struct, id, metadata, constructeur.
- Callable model building : récupérer le builder via `get_adnlp_model_builder(prob)` ou `get_exa_model_builder(prob)`, puis appeler le builder.
- Callable solution building : idem avec `get_adnlp_solution_builder(prob)`.

**Section 3 — Validation**

- `validate_strategy_contract`.
- Tests avec un `FakeOptimizationProblem`.

**Section 4 — Intégration avec build_model / build_solution**

- Comment `Optimization.build_model` dispatch vers le bon modeler.
- Le flux complet : problem → modeler → NLP → solver → solution.

**Longueur cible** : 200-300 lignes.

---

### 3.7 `guides/implementing_an_optimization_problem.md` — Problèmes d'optimisation

**Objectif** : Implémenter un type de problème d'optimisation compatible avec les modelers.

**Contenu** :

**Section 1 — Le contrat AbstractOptimizationProblem**

- Les 4 méthodes de contrat (getters de builders).
- Le pattern : chaque problème fournit des builders, les modelers les utilisent.

**Section 2 — Les Builders**

- `AbstractModelBuilder` : callable qui construit un NLP model.
- `AbstractSolutionBuilder` : callable qui construit une solution.
- Les types concrets : `ADNLPModelBuilder`, `ExaModelBuilder`, `ADNLPSolutionBuilder`, `ExaSolutionBuilder`.
- Le pattern callable avec signatures spécifiques.

**Section 3 — Implémentation pas à pas**

- Définir le struct du problème.
- Créer les builders concrets (callables).
- Implémenter les 4 getters.
- Exemple : `DiscretizedOptimalControlProblem` comme référence.

**Section 4 — Tests**

- Test des getters.
- Test des builders.
- Test d'intégration avec un modeler.

**Longueur cible** : 200-300 lignes.

---

### 3.8 `guides/orchestration_and_routing.md` — Orchestration

**Objectif** : Comprendre et utiliser le système de routage d'options multi-stratégies.

**Contenu** :

**Section 1 — Le concept de method tuple**

- `(:collocation, :adnlp, :ipopt)` : chaque symbole identifie une stratégie.
- Les "families" : mapping entre rôles (discretizer, modeler, solver) et types abstraits.

**Section 2 — Routage automatique**

- `route_all_options` : le point d'entrée.
- L'ownership map : quelle famille possède quelle option.
- Auto-routing pour les options non ambiguës.

**Section 3 — Désambiguïsation**

- Quand une option appartient à plusieurs familles.
- `route_to()` et `RoutedOption` : syntaxe de désambiguïsation.
- Single strategy vs multi-strategy routing.

**Section 4 — Modes strict/permissif**

- Au niveau orchestration (différent du niveau stratégie).
- Comportement avec options inconnues.

**Section 5 — Helpers**

- `extract_strategy_ids` : détection de la syntaxe de désambiguïsation.
- `build_strategy_to_family_map` : mapping inverse.
- `build_option_ownership_map` : détection d'ambiguïté.

**Section 6 — Exemple complet**

Un exemple de bout en bout montrant le routage avec 3 stratégies, options auto-routées et disambiguées.

**Longueur cible** : 200-300 lignes.

---

## 4. Configuration `make.jl` Révisée

```julia
pages=[
    "Introduction" => "index.md",
    "Architecture" => "architecture.md",
    "Developer Guides" => [
        "Options System" => "guides/options_system.md",
        "Implementing a Strategy" => "guides/implementing_a_strategy.md",
        "Implementing a Solver" => "guides/implementing_a_solver.md",
        "Implementing a Modeler" => "guides/implementing_a_modeler.md",
        "Implementing an Optimization Problem" => "guides/implementing_an_optimization_problem.md",
        "Orchestration & Routing" => "guides/orchestration_and_routing.md",
    ],
    "API Reference" => [
        "Public API" => [
            "Options" => "api/options/options_public.md",
            "Strategies (Contract)" => "api/strategies/strategies_contract_public.md",
            "Strategies (API)" => "api/strategies/strategies_api_public.md",
            "Orchestration" => "api/orchestration/orchestration_public.md",
            "Optimization" => "api/optimization/optimization_public.md",
            "Modelers" => "api/modelers/modelers_public.md",
            "DOCP" => "api/docp/docp_public.md",
            "Solvers" => "api/solvers/solvers_public.md",
        ],
        "Internal API" => [
            "Options" => "api/options/options_internal.md",
            "Strategies (Contract)" => "api/strategies/strategies_contract_internal.md",
            "Strategies (API)" => "api/strategies/strategies_api_internal.md",
            "Orchestration" => "api/orchestration/orchestration_internal.md",
            "Optimization" => "api/optimization/optimization_internal.md",
            "Modelers" => "api/modelers/modelers_internal.md",
            "DOCP" => "api/docp/docp_internal.md",
            "Solvers" => "api/solvers/solvers_internal.md",
        ],
        "Extensions" => [
            "Ipopt" => "api/extensions/ipopt.md",
            "MadNLP" => "api/extensions/madnlp.md",
            "MadNCL" => "api/extensions/madncl.md",
            "Knitro" => "api/extensions/knitro.md",
        ],
    ],
],
```

---

## 5. Ordre d'Implémentation Révisé

| Étape | Page | Justification |
| ----- | ---- | ------------- |
| 1 | `architecture.md` | Pivot central, donne la vision d'ensemble |
| 2 | `api_reference.jl` | Fondation technique, génération automatique |
| 3 | `implementing_a_strategy.md` | Contrat le plus fondamental |
| 4 | `implementing_a_solver.md` | Cas d'usage le plus concret (extensions) |
| 5 | `implementing_a_modeler.md` | Dépend de Strategy + Optimization |
| 6 | `implementing_an_optimization_problem.md` | Dépend de Builders |
| 7 | `orchestration_and_routing.md` | Système transversal |
| 8 | `options_system.md` | Fusion du contenu existant |
| 9 | `index.md` | Réécrit en dernier, quand le contenu est stabilisé |

---

## 6. Comparaison Avant / Après

| Critère | Plan initial (propal/) | Plan révisé (reference/) |
| ------- | ---------------------- | ------------------------ |
| Pages manuelles | 17+ | 8 |
| Pages API | ~7 (tout mélangé) | ~22 (Public/Internal séparés) |
| Redondance | Interface + Tutoriel séparés | Fusionnés en un document |
| User Guide | 4 pages (hors cible) | 0 page dédiée (contenu dans index) |
| Architecture | Phase 3, jour 8 | Étape 1, premier document |
| Two-level contract | Non mentionné | Section dédiée |
| Hiérarchie des types | Non mentionnée | Diagramme central |
| CommonSolve multi-level | Non mentionné | Section dans solver guide |
| Tag Dispatch | Non mentionné | Section dans solver guide |
| Synopsis par page | Absent | Détaillé pour chaque page |
| Modèle API | Simplifié | Conforme à la ressource de référence |
