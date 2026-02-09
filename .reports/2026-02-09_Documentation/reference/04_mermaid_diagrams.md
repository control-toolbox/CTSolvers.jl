# Diagrammes Mermaid pour la Documentation CTSolvers

**Date** : 9 février 2026
**Objet** : Catalogue de diagrammes proposés pour chaque page de documentation

Ce document recense les diagrammes Mermaid à intégrer dans la documentation.
Chaque diagramme est associé à la page où il apparaîtrait et accompagné
d'une justification.

---

## 1. `architecture.md` — Vue d'ensemble

### 1.1 Hiérarchie des types abstraits (class diagram)

Ce diagramme remplace le diagramme ASCII et montre les relations d'héritage
entre tous les types abstraits et concrets de CTSolvers.

```mermaid
classDiagram
    direction TB

    class AbstractStrategy {
        <<abstract>>
        +id(Type) Symbol
        +metadata(Type) StrategyMetadata
        +options(instance) StrategyOptions
    }

    class AbstractOptimizationModeler {
        <<abstract>>
        +(prob, initial_guess) NLPModel
        +(prob, nlp_solution) Solution
    }

    class AbstractOptimizationSolver {
        <<abstract>>
        +(nlp; display) ExecutionStats
    }

    class ADNLPModeler {
        options::StrategyOptions
    }
    class ExaModeler {
        options::StrategyOptions
    }

    class IpoptSolver {
        options::StrategyOptions
    }
    class MadNLPSolver {
        options::StrategyOptions
    }
    class MadNCLSolver {
        options::StrategyOptions
    }
    class KnitroSolver {
        options::StrategyOptions
    }

    AbstractStrategy <|-- AbstractOptimizationModeler
    AbstractStrategy <|-- AbstractOptimizationSolver
    AbstractOptimizationModeler <|-- ADNLPModeler
    AbstractOptimizationModeler <|-- ExaModeler
    AbstractOptimizationSolver <|-- IpoptSolver
    AbstractOptimizationSolver <|-- MadNLPSolver
    AbstractOptimizationSolver <|-- MadNCLSolver
    AbstractOptimizationSolver <|-- KnitroSolver
```

```mermaid
classDiagram
    direction TB

    class AbstractOptimizationProblem {
        <<abstract>>
        +get_adnlp_model_builder() AbstractModelBuilder
        +get_exa_model_builder() AbstractModelBuilder
        +get_adnlp_solution_builder() AbstractSolutionBuilder
        +get_exa_solution_builder() AbstractSolutionBuilder
    }

    class DiscretizedOptimalControlProblem {
        optimal_control_problem::OCP
        adnlp_model_builder::TAMB
        exa_model_builder::TEMB
        adnlp_solution_builder::TASB
        exa_solution_builder::TESB
    }

    class AbstractBuilder {
        <<abstract>>
    }
    class AbstractModelBuilder {
        <<abstract>>
    }
    class AbstractSolutionBuilder {
        <<abstract>>
    }
    class AbstractOCPSolutionBuilder {
        <<abstract>>
    }

    class ADNLPModelBuilder {
        f::Function
    }
    class ExaModelBuilder {
        f::Function
    }
    class ADNLPSolutionBuilder {
        f::Function
    }
    class ExaSolutionBuilder {
        f::Function
    }

    AbstractOptimizationProblem <|-- DiscretizedOptimalControlProblem
    AbstractBuilder <|-- AbstractModelBuilder
    AbstractBuilder <|-- AbstractSolutionBuilder
    AbstractSolutionBuilder <|-- AbstractOCPSolutionBuilder
    AbstractModelBuilder <|-- ADNLPModelBuilder
    AbstractModelBuilder <|-- ExaModelBuilder
    AbstractSolutionBuilder <|-- ADNLPSolutionBuilder
    AbstractSolutionBuilder <|-- ExaSolutionBuilder

    DiscretizedOptimalControlProblem --> ADNLPModelBuilder : contains
    DiscretizedOptimalControlProblem --> ExaModelBuilder : contains
    DiscretizedOptimalControlProblem --> ADNLPSolutionBuilder : contains
    DiscretizedOptimalControlProblem --> ExaSolutionBuilder : contains
```

**Justification** : C'est le diagramme le plus important de toute la documentation.
Il donne la carte mentale complète du système de types. Deux diagrammes séparés
pour éviter la surcharge visuelle : un pour la branche Strategy, un pour la branche
Optimization/Builders.

---

### 1.2 Dépendances entre modules (flowchart)

Montre l'ordre de chargement réel tel que défini dans `CTSolvers.jl` (lignes 47-73)
et les dépendances `using` de chaque module.

```mermaid
flowchart LR
    Options["Options\n<i>Configuration &amp;\noption management</i>"]
    Strategies["Strategies\n<i>Contract, registry,\nbuilders, validation</i>"]
    Orchestration["Orchestration\n<i>Option routing &amp;\ndisambiguation</i>"]
    Optimization["Optimization\n<i>Abstract types,\nbuilders, contract</i>"]
    Modelers["Modelers\n<i>ADNLPModeler,\nExaModeler</i>"]
    DOCP["DOCP\n<i>Discretized OCP,\ncontract impl</i>"]
    Solvers["Solvers\n<i>Ipopt, MadNLP,\nMadNCL, Knitro</i>"]

    Options --> Strategies
    Options --> Orchestration
    Strategies --> Orchestration
    Strategies --> Modelers
    Strategies --> Solvers
    Optimization --> Modelers
    Optimization --> DOCP
    Optimization --> Solvers
    Modelers --> Solvers

    style Options fill:#e1f5fe
    style Strategies fill:#fff3e0
    style Orchestration fill:#fce4ec
    style Optimization fill:#e8f5e9
    style Modelers fill:#f3e5f5
    style DOCP fill:#e8f5e9
    style Solvers fill:#fff8e1
```

**Justification** : Montre visuellement pourquoi l'ordre d'inclusion dans
`CTSolvers.jl` est important et quelles dépendances existent entre modules.
Les couleurs regroupent les familles fonctionnelles.

---

### 1.3 Flux de résolution complet (sequence diagram)

Le chemin d'une résolution de bout en bout, montrant les interactions
entre les composants.

```mermaid
sequenceDiagram
    participant User
    participant CommonSolve as CommonSolve.solve
    participant Modeler as ADNLPModeler
    participant DOCP as DiscretizedOCP
    participant Builder as ADNLPModelBuilder
    participant Solver as IpoptSolver
    participant SolBuilder as ADNLPSolutionBuilder

    User ->> CommonSolve: solve(docp, x0, modeler, solver)

    Note over CommonSolve: Step 1: Build NLP Model
    CommonSolve ->> Modeler: build_model(docp, x0, modeler)
    Modeler ->> DOCP: get_adnlp_model_builder(docp)
    DOCP -->> Modeler: ADNLPModelBuilder
    Modeler ->> Builder: builder(x0; options...)
    Builder -->> Modeler: ADNLPModel
    Modeler -->> CommonSolve: nlp::ADNLPModel

    Note over CommonSolve: Step 2: Solve NLP
    CommonSolve ->> Solver: solve(nlp, solver)
    Solver ->> Solver: solver(nlp; display=true)
    Note right of Solver: Delegates to ext/<br/>CTSolversIpopt.jl
    Solver -->> CommonSolve: stats::ExecutionStats

    Note over CommonSolve: Step 3: Build Solution
    CommonSolve ->> Modeler: build_solution(docp, stats, modeler)
    Modeler ->> DOCP: get_adnlp_solution_builder(docp)
    DOCP -->> Modeler: ADNLPSolutionBuilder
    Modeler ->> SolBuilder: builder(stats)
    SolBuilder -->> Modeler: OptimalControlSolution
    Modeler -->> CommonSolve: solution

    CommonSolve -->> User: OptimalControlSolution
```

**Justification** : Ce diagramme de séquence est le plus utile pour un développeur.
Il montre exactement quelles méthodes sont appelées, dans quel ordre, et par qui.
Il rend concret le flux abstrait `OCP → NLP → Solution`.

---

## 2. `guides/implementing_a_strategy.md` — Two-level contract

### 2.1 Le two-level contract (flowchart)

Montre la distinction entre méthodes type-level et instance-level.

```mermaid
flowchart TB
    subgraph TypeLevel["Type-Level Contract (static)"]
        direction LR
        id["id(::Type{&lt;:MyStrategy})\n→ :my_strategy"]
        meta["metadata(::Type{&lt;:MyStrategy})\n→ StrategyMetadata"]
    end

    subgraph InstanceLevel["Instance-Level Contract (configured)"]
        direction LR
        opts["options(strategy)\n→ StrategyOptions"]
    end

    subgraph UsedBy["Utilisé par"]
        direction LR
        Registry["StrategyRegistry\n<i>routing, lookup</i>"]
        Validation["Validation\n<i>avant construction</i>"]
        Introspection["Introspection\n<i>option_names, etc.</i>"]
        Config["Configuration\n<i>provenance tracking</i>"]
    end

    id --> Registry
    id --> Validation
    meta --> Validation
    meta --> Introspection
    opts --> Config

    style TypeLevel fill:#e8f5e9,stroke:#4caf50
    style InstanceLevel fill:#e3f2fd,stroke:#2196f3
    style UsedBy fill:#fff3e0,stroke:#ff9800
```

**Justification** : Le two-level contract est le concept architectural le plus
important de CTSolvers. Ce diagramme le rend immédiatement compréhensible.

---

### 2.2 Cycle de vie d'une stratégie (flowchart)

Du type à l'instance, en passant par la validation.

```mermaid
flowchart LR
    A["Définir struct\n<code>MyStrategy &lt;: AbstractStrategy</code>"] --> B
    B["Implémenter id()\n<code>id(::Type) = :my_strat</code>"] --> C
    C["Implémenter metadata()\n<code>StrategyMetadata(...)</code>"] --> D
    D["Constructeur\n<code>build_strategy_options()</code>"] --> E
    E["Validation\n<code>validate_strategy_contract()</code>"] --> F
    F["Enregistrement\n<code>StrategyRegistry</code>"] --> G
    G["Utilisation\n<code>strategy = MyStrategy(...)</code>"]

    style A fill:#ffebee
    style B fill:#fce4ec
    style C fill:#f3e5f5
    style D fill:#ede7f6
    style E fill:#e8eaf6
    style F fill:#e3f2fd
    style G fill:#e1f5fe
```

**Justification** : Donne une vue d'ensemble du parcours d'implémentation
avant de plonger dans les détails de chaque étape.

---

### 2.3 Composition des types Options (ER diagram)

Montre les relations entre `OptionDefinition`, `StrategyMetadata`,
`StrategyOptions` et `OptionValue`.

```mermaid
erDiagram
    StrategyMetadata ||--|{ OptionDefinition : "contains"
    StrategyOptions ||--|{ OptionValue : "contains"
    OptionDefinition ||--|| OptionValue : "produces via build_strategy_options"

    OptionDefinition {
        Symbol name
        Type type
        Any default
        String description
        Tuple aliases
        Function validator
    }

    StrategyMetadata {
        NamedTuple specs
    }

    OptionValue {
        Any value
        Symbol source
    }

    StrategyOptions {
        NamedTuple options
    }
```

**Justification** : Clarifie comment les types Options s'emboîtent.
Un développeur qui implémente une stratégie doit comprendre cette chaîne :
`OptionDefinition` → `StrategyMetadata` → `build_strategy_options` →
`StrategyOptions` (contenant des `OptionValue`).

---

## 3. `guides/implementing_a_solver.md` — Solveurs et extensions

### 3.1 Architecture Solver + Extension (flowchart)

Montre la séparation entre `src/Solvers/` et `ext/`.

```mermaid
flowchart TB
    subgraph SrcSolvers["src/Solvers/ (toujours chargé)"]
        AbstractSolver["AbstractOptimizationSolver\n<i>&lt;: AbstractStrategy</i>"]
        IpoptType["struct IpoptSolver\n<i>options, id, metadata</i>"]
        AbstractTag["AbstractTag\n<i>tag dispatch</i>"]
        Callable["(solver)(nlp; display)\n<i>default: NotImplemented</i>"]
    end

    subgraph ExtIpopt["ext/CTSolversIpopt.jl (chargé si NLPModelsIpopt)"]
        IpoptImpl["Implémentation callable\n<code>(::IpoptSolver)(nlp)</code>"]
        IpoptBackend["Appel NLPModelsIpopt.ipopt()"]
    end

    AbstractSolver --> IpoptType
    IpoptType --> Callable
    Callable -.->|"extension loaded"| IpoptImpl
    IpoptImpl --> IpoptBackend

    style SrcSolvers fill:#e8f5e9,stroke:#4caf50
    style ExtIpopt fill:#fff3e0,stroke:#ff9800
```

**Justification** : Le pattern Tag Dispatch et la séparation src/ext est
un concept clé pour quiconque veut ajouter un nouveau solveur. Ce diagramme
rend la mécanique visible.

---

### 3.2 CommonSolve multi-level (flowchart)

Les 3 niveaux de l'API CommonSolve.

```mermaid
flowchart TB
    subgraph HighLevel["High-level: solve(problem, x0, modeler, solver)"]
        H1["Build NLP model"] --> H2["Solve NLP"] --> H3["Build solution"]
    end

    subgraph MidLevel["Mid-level: solve(nlp, solver)"]
        M1["solver(nlp; display)"]
    end

    subgraph LowLevel["Low-level: solve(any, solver)"]
        L1["solver(any; display)"]
    end

    HighLevel -->|"appelle"| MidLevel
    MidLevel -->|"appelle"| LowLevel

    User["Utilisateur"] -->|"Flux complet\nOCP → Solution"| HighLevel
    User -->|"NLP direct"| MidLevel
    User -->|"Flexible"| LowLevel

    style HighLevel fill:#e8f5e9
    style MidLevel fill:#e3f2fd
    style LowLevel fill:#fff3e0
```

**Justification** : Montre clairement les 3 points d'entrée de l'API
et quand utiliser chacun.

---

## 4. `guides/implementing_a_modeler.md` — Modelers

### 4.1 Flux Modeler (sequence diagram)

Comment un modeler interagit avec le problème et les builders.

```mermaid
sequenceDiagram
    participant Caller
    participant Modeler as ADNLPModeler
    participant Problem as AbstractOptimizationProblem
    participant ModelBuilder as ADNLPModelBuilder
    participant SolBuilder as ADNLPSolutionBuilder

    Note over Caller,SolBuilder: Phase 1: Model Building
    Caller ->> Modeler: modeler(prob, initial_guess)
    Modeler ->> Problem: get_adnlp_model_builder(prob)
    Problem -->> Modeler: builder::ADNLPModelBuilder
    Modeler ->> Modeler: options_dict(modeler)
    Modeler ->> ModelBuilder: builder(initial_guess; options...)
    ModelBuilder -->> Caller: nlp::ADNLPModel

    Note over Caller,SolBuilder: Phase 2: Solution Building
    Caller ->> Modeler: modeler(prob, nlp_stats)
    Modeler ->> Problem: get_adnlp_solution_builder(prob)
    Problem -->> Modeler: builder::ADNLPSolutionBuilder
    Modeler ->> SolBuilder: builder(nlp_stats)
    SolBuilder -->> Caller: solution::OptimalControlSolution
```

**Justification** : Montre les deux callables du modeler et comment ils
interagissent avec le contrat `AbstractOptimizationProblem`. Essentiel
pour comprendre le rôle de chaque composant.

---

## 5. `guides/implementing_an_optimization_problem.md`

### 5.1 Contrat AbstractOptimizationProblem (ER diagram)

Montre la structure du DOCP et ses relations avec les builders.

```mermaid
erDiagram
    AbstractOptimalControlProblem ||--|| DiscretizedOptimalControlProblem : "wrapped by"
    DiscretizedOptimalControlProblem ||--|| ADNLPModelBuilder : "contains"
    DiscretizedOptimalControlProblem ||--|| ExaModelBuilder : "contains"
    DiscretizedOptimalControlProblem ||--|| ADNLPSolutionBuilder : "contains"
    DiscretizedOptimalControlProblem ||--|| ExaSolutionBuilder : "contains"

    ADNLPModeler ||--|| ADNLPModelBuilder : "uses via get_adnlp_model_builder"
    ADNLPModeler ||--|| ADNLPSolutionBuilder : "uses via get_adnlp_solution_builder"
    ExaModeler ||--|| ExaModelBuilder : "uses via get_exa_model_builder"
    ExaModeler ||--|| ExaSolutionBuilder : "uses via get_exa_solution_builder"

    ADNLPModelBuilder ||--|| ADNLPModel : "produces"
    ExaModelBuilder ||--|| ExaModel : "produces"
    ADNLPSolutionBuilder ||--|| OptimalControlSolution : "produces"
    ExaSolutionBuilder ||--|| OptimalControlSolution : "produces"

    DiscretizedOptimalControlProblem {
        OCP optimal_control_problem
        TAMB adnlp_model_builder
        TEMB exa_model_builder
        TASB adnlp_solution_builder
        TESB exa_solution_builder
    }

    ADNLPModelBuilder {
        Function f
    }
    ExaModelBuilder {
        Function f
    }
```

**Justification** : Montre comment le DOCP encapsule les builders et comment
les modelers les utilisent. C'est le diagramme de référence pour comprendre
le pattern Builder tel qu'implémenté dans CTSolvers.

---

## 6. `guides/orchestration_and_routing.md` — Routage d'options

### 6.1 Flux de routage (flowchart)

Le parcours d'une option depuis les kwargs utilisateur jusqu'à la stratégie cible.

```mermaid
flowchart TB
    Input["kwargs utilisateur\n<code>(grid_size=100, backend=(:sparse, :adnlp), max_iter=1000)</code>"]

    Input --> Extract["Étape 1: Extraire action options\n<code>extract_options(kwargs, action_defs)</code>"]
    Extract --> ActionOpts["Action options\n<code>(display=true)</code>"]
    Extract --> Remaining["Options restantes\n<code>(grid_size, backend, max_iter)</code>"]

    Remaining --> Ownership["Étape 2: Ownership map\n<code>build_option_ownership_map()</code>"]
    Ownership --> Check{Option ambiguë ?}

    Check -->|"Non\n1 seul owner"| AutoRoute["Auto-route\nvers la famille"]
    Check -->|"Oui\n2+ owners"| Disambig{Syntaxe route_to ?}

    Disambig -->|"Oui"| ExtractID["extract_strategy_ids()\nroute vers cible"]
    Disambig -->|"Non"| Error["Erreur: option ambiguë\navec suggestions route_to()"]

    AutoRoute --> Result
    ExtractID --> Result["Résultat\n<code>(action=..., strategies=...)</code>"]

    style Input fill:#fff3e0
    style ActionOpts fill:#e8f5e9
    style Error fill:#ffebee
    style Result fill:#e1f5fe
```

**Justification** : Le routage d'options est le mécanisme le plus complexe
de l'Orchestration. Ce flowchart montre le parcours décisionnel complet,
y compris les cas d'erreur.

---

### 6.2 Désambiguïsation (sequence diagram)

Exemple concret de routage avec 3 stratégies.

```mermaid
sequenceDiagram
    participant User
    participant Router as route_all_options
    participant OwnerMap as OptionOwnershipMap
    participant Disambig as extract_strategy_ids

    User ->> Router: method=(:collocation, :adnlp, :ipopt)<br/>kwargs=(grid_size=100, backend=route_to(adnlp=:sparse), max_iter=1000)

    Note over Router: Étape 1: Séparer action options
    Router ->> Router: extract_options → action=(display=true)

    Note over Router: Étape 2: Construire ownership map
    Router ->> OwnerMap: build_option_ownership_map()
    OwnerMap -->> Router: grid_size→{discretizer}, backend→{modeler,solver}, max_iter→{solver}

    Note over Router: Étape 3: Router chaque option
    Router ->> Router: grid_size → 1 owner → auto-route → discretizer
    Router ->> Disambig: backend=route_to(adnlp=:sparse) → disambiguated?
    Disambig -->> Router: [(sparse, :adnlp)] → route to modeler
    Router ->> Router: max_iter → 1 owner → auto-route → solver

    Router -->> User: (action=(display=true),<br/>strategies=(discretizer=(grid_size=100,),<br/>modeler=(backend=:sparse,),<br/>solver=(max_iter=1000,)))
```

**Justification** : Montre un cas concret avec les 3 types de routage :
auto-route (unambiguous), désambiguïsation explicite, et auto-route simple.
Rend le mécanisme tangible.

---

## 7. `guides/options_system.md` — Système d'options

### 7.1 Chaîne de construction des options (flowchart)

De la définition à l'utilisation.

```mermaid
flowchart LR
    subgraph Definition["Définition (type-level)"]
        OD["OptionDefinition\n<i>name, type, default,\ndescription, aliases,\nvalidator</i>"]
        SM["StrategyMetadata\n<i>collection de\nOptionDefinition</i>"]
        OD --> SM
    end

    subgraph Construction["Construction (build_strategy_options)"]
        UserKW["kwargs utilisateur\n<code>max_iter=200</code>"]
        Merge["Merge defaults\n+ user values"]
        Validate["Validation\n<i>type check, validator,\naliases resolution</i>"]
        UserKW --> Merge
        SM --> Merge
        Merge --> Validate
    end

    subgraph Result["Résultat (instance-level)"]
        SO["StrategyOptions\n<i>NamedTuple of OptionValue</i>"]
        OV1["OptionValue\n<code>max_iter=200 [:user]</code>"]
        OV2["OptionValue\n<code>tol=1e-6 [:default]</code>"]
        Validate --> SO
        SO --- OV1
        SO --- OV2
    end

    style Definition fill:#e8f5e9
    style Construction fill:#fff3e0
    style Result fill:#e3f2fd
```

**Justification** : Montre la chaîne complète de construction des options,
depuis la définition jusqu'à l'instance avec provenance tracking. Essentiel
pour comprendre comment les options sont validées et assemblées.

---

### 7.2 Modes de validation (flowchart)

Strict vs permissif.

```mermaid
flowchart TB
    Input["Option inconnue\n<code>custom_opt=123</code>"]

    Input --> Mode{mode ?}

    Mode -->|":strict"| StrictPath
    Mode -->|":permissive"| PermissivePath

    subgraph StrictPath["Mode Strict (défaut)"]
        Reject["Rejet immédiat"]
        Levenshtein["Suggestions Levenshtein\n<i>Did you mean :custom_option?</i>"]
        StrictError["IncorrectArgument\navec message détaillé"]
        Reject --> Levenshtein --> StrictError
    end

    subgraph PermissivePath["Mode Permissif"]
        Warn["Warning émis"]
        Store["Stocké avec source :user"]
        Accept["Option acceptée\ndans StrategyOptions"]
        Warn --> Store --> Accept
    end

    style StrictPath fill:#ffebee
    style PermissivePath fill:#fff8e1
```

**Justification** : Les deux modes de validation sont un concept clé
que le développeur doit comprendre pour choisir le bon mode dans son
constructeur.

---

## 8. Récapitulatif : Diagrammes par page

| Page | Diagramme | Type Mermaid | Section |
| ---- | --------- | ------------ | ------- |
| `architecture.md` | Hiérarchie types Strategy | classDiagram | 1.1 |
| `architecture.md` | Hiérarchie types Optimization | classDiagram | 1.1 |
| `architecture.md` | Dépendances modules | flowchart | 1.2 |
| `architecture.md` | Flux de résolution | sequenceDiagram | 1.3 |
| `implementing_a_strategy.md` | Two-level contract | flowchart | 2.1 |
| `implementing_a_strategy.md` | Cycle de vie | flowchart | 2.2 |
| `implementing_a_strategy.md` | Types Options | erDiagram | 2.3 |
| `implementing_a_solver.md` | Solver + Extension | flowchart | 3.1 |
| `implementing_a_solver.md` | CommonSolve levels | flowchart | 3.2 |
| `implementing_a_modeler.md` | Flux Modeler | sequenceDiagram | 4.1 |
| `implementing_an_optimization_problem.md` | DOCP + Builders | erDiagram | 5.1 |
| `orchestration_and_routing.md` | Flux de routage | flowchart | 6.1 |
| `orchestration_and_routing.md` | Désambiguïsation | sequenceDiagram | 6.2 |
| `options_system.md` | Chaîne de construction | flowchart | 7.1 |
| `options_system.md` | Modes de validation | flowchart | 7.2 |

**Total** : 15 diagrammes répartis sur 8 pages.

---

## 9. Notes techniques

### Compatibilité Documenter.jl + Mermaid

Documenter.jl supporte nativement les blocs Mermaid via la syntaxe :

````markdown
```mermaid
flowchart LR
    A --> B
```
````

Aucune configuration supplémentaire n'est nécessaire avec les versions
récentes de Documenter.jl (v1.0+). Le rendu est fait côté client via
la bibliothèque JavaScript Mermaid.

### Conventions de style

- **Couleurs** : Utiliser des teintes pastel pour les groupes fonctionnels.
  Pas de couleurs vives qui fatiguent la lecture.
- **Direction** : `TB` (top-bottom) pour les hiérarchies, `LR` (left-right)
  pour les flux séquentiels.
- **Taille** : Limiter à 10-15 nœuds par diagramme. Au-delà, découper
  en sous-diagrammes.
- **Texte** : Garder les labels courts. Utiliser `<i>...</i>` pour les
  descriptions secondaires.
- **Subgraphs** : Utiliser pour regrouper les composants par responsabilité
  ou par phase.
