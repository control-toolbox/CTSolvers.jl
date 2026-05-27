# Revue Critique du Plan de Documentation CTSolvers

**Date** : 9 février 2026
**Objet** : Analyse critique de la proposition `propal/`
**Méthode** : Confrontation systématique du plan au code source réel

---

## 1. Diagnostic Global

La proposition est un bon point de départ mais souffre de trois défauts structurels :

1. **Superficialité** : Les descriptions de contenu restent au niveau des titres de fichiers sans préciser *ce qui sera dit* dans chaque page. Un plan de documentation doit contenir un synopsis par page, pas seulement un nom de fichier.

2. **Redondance entre les 3 documents** : Le README, la proposition (01) et l'analyse technique (02) répètent les mêmes informations (structure de fichiers, phases, métriques) avec des variations mineures. Cela dilue le propos au lieu de le renforcer.

3. **Déconnexion partielle du code** : Certains concepts clés du code source ne sont pas mentionnés dans le plan, tandis que d'autres sont surreprésentés. L'analyse de complexité par module (02) contient des erreurs factuelles (nombre de fichiers, nombre d'exports).

---

## 2. Analyse Structurelle

### 2.1 Ce qui fonctionne bien

- **Séparation User Guide / Dev Guide / API** : C'est le bon découpage pour un public développeur. La distinction entre "utiliser" et "étendre" est pertinente.
- **Génération automatique de l'API** : S'appuyer sur `CTBase.automatic_reference_documentation` est la bonne approche. La ressource `migration_to_ctsolvers/docs/api_reference.jl` fournit un modèle éprouvé avec séparation Public/Internal.
- **Approche par phases** : Commencer par l'API est judicieux car c'est la fondation.

### 2.2 Problèmes de structure

**Le User Guide est mal positionné pour la cible.**
Le plan dit que la cible primaire est "développeurs Julia expérimentés" qui veulent "implémenter des interfaces". Or 4 pages sur 17 sont consacrées à un User Guide (`getting_started`, `working_with_options`, `using_solvers`, `modeling_workflows`). Pour un développeur qui veut *étendre* CTSolvers, `getting_started` et `modeling_workflows` sont peu utiles : ces pages décrivent l'utilisation depuis OptimalControl.jl, pas depuis CTSolvers directement.

**Recommandation** : Réduire le User Guide à 1-2 pages maximum (une page "Overview & Quick Start" et une page "Options System"). Le reste du contenu utilisateur appartient à la documentation d'OptimalControl.jl, pas de CTSolvers.

**La page `architecture.md` arrive trop tard.**
Dans le plan, elle est en Phase 3 (Jours 4-8), après l'API. Or c'est la page la plus importante pour un développeur : elle donne la vision d'ensemble *avant* de plonger dans les contrats. Elle devrait être la première page rédigée manuellement.

**Recommandation** : Faire de `architecture.md` le pivot central de la documentation. Tout le reste en découle.

**Confusion entre "Interface" et "Tutoriel".**
Le plan propose 4 pages d'interfaces ET 4 tutoriels qui couvrent les mêmes sujets. Pour `AbstractStrategy`, il y aurait `interfaces/strategies.md` ET `tutorials/creating_a_strategy.md`. C'est redondant. Un bon document d'interface *inclut* un exemple d'implémentation complet.

**Recommandation** : Fusionner interface + tutoriel en un seul document par contrat, structuré en : Contrat → Implémentation pas à pas → Tests → Patterns avancés.

---

## 3. Couverture des Concepts

### 3.1 Concepts présents dans le code mais absents du plan

Après analyse du code source, les concepts suivants ne sont pas mentionnés :

| Concept | Fichier source | Importance |
|---------|---------------|------------|
| **Two-level contract** (type-level vs instance-level) | `abstract_strategy.jl:6-31` | Critique |
| **Validation modes** (strict/permissive) dans les stratégies | `abstract_strategy.jl:42-64` | Haute |
| **StrategyMetadata** et son interface Collection | `metadata.jl:46-51` | Haute |
| **StrategyOptions** et provenance tracking | `strategy_options.jl:1-87` | Haute |
| **OptionDefinition** avec aliases et validators | `option_definition.jl` | Haute |
| **RoutedOption** et `route_to()` | `disambiguation.jl:20-24` | Haute |
| **Tag dispatch** pour extensions | `Solvers.jl:56-61` | Moyenne |
| **CommonSolve multi-level** (high/mid/low) | `common_solve_api.jl:1-8` | Haute |
| **build_model / build_solution** dispatch | `building.jl` | Moyenne |
| **Concrete builders** (ADNLPModelBuilder, etc.) | `builders.jl:51+` | Moyenne |
| **Strategy registry** et introspection | `api/registry.jl`, `api/introspection.jl` | Haute |
| **Validation helpers** (Levenshtein, suggestions) | `api/validation_helpers.jl` | Basse |

Le concept de **two-level contract** est le cœur architectural de CTSolvers. Il est documenté en détail dans `abstract_strategy.jl` (lignes 1-115) mais n'apparaît nulle part dans le plan de documentation. C'est la lacune la plus critique.

### 3.2 Concepts surreprésentés

- **Options strict/permissive** : Deux pages existantes (`migration_guide.md`, `options_validation.md`) couvrent déjà ce sujet en 843 lignes. Le plan propose d'en créer une troisième (`working_with_options.md`). C'est excessif.
- **Exemples standalone** (`examples/`) : 3 exemples dans un répertoire séparé alors que les exemples devraient être intégrés dans les pages de documentation via les blocs `@example` de Documenter.jl.

### 3.3 Hiérarchie des contrats non explicitée

Le code révèle une hiérarchie d'héritage claire :

```
AbstractStrategy
├── AbstractOptimizationModeler    (Modelers/)
│   ├── ADNLPModeler
│   └── ExaModeler
└── AbstractOptimizationSolver     (Solvers/)
    ├── IpoptSolver
    ├── MadNLPSolver
    ├── MadNCLSolver
    └── KnitroSolver

AbstractOptimizationProblem         (Optimization/)
└── DiscretizedOptimalControlProblem (DOCP/)

AbstractBuilder
├── AbstractModelBuilder
│   ├── ADNLPModelBuilder
│   └── ExaModelBuilder
└── AbstractSolutionBuilder
    ├── AbstractOCPSolutionBuilder
    ├── ADNLPSolutionBuilder
    └── ExaSolutionBuilder
```

Cette hiérarchie est **le** concept central à documenter. Elle n'apparaît pas dans le plan.

---

## 4. Qualité des Tutoriels : Qu'est-ce qu'un bon tutoriel développeur ?

Le plan mentionne "tutoriels pas à pas" mais ne définit pas ce que cela signifie concrètement. Voici les critères d'un bon tutoriel pour développeurs Julia :

### 4.1 Critères d'un bon tutoriel

1. **Objectif clair et mesurable** : "À la fin de ce tutoriel, vous aurez implémenté un solveur fonctionnel enregistré dans le registry."

2. **Prérequis explicites** : Quels concepts Julia faut-il maîtriser ? Quels modules CTSolvers faut-il connaître ?

3. **Code complet et exécutable** : Pas de `# ...` ni de `# TODO`. Chaque bloc de code doit être copiable et fonctionnel. Idéalement, utiliser les blocs `@example` de Documenter.jl pour garantir que le code compile.

4. **Progression incrémentale** : Commencer par le minimum viable (struct + 2 méthodes), puis ajouter des fonctionnalités (options, validation, tests).

5. **Erreurs intentionnelles** : Montrer ce qui se passe quand on oublie d'implémenter une méthode. Les messages d'erreur de CTSolvers (via `NotImplemented`) sont excellents et méritent d'être mis en avant.

6. **Tests intégrés** : Chaque étape du tutoriel inclut un test qui vérifie que l'implémentation est correcte. Utiliser `validate_strategy_contract` comme point de validation.

7. **Lien vers l'API** : Chaque fonction utilisée dans le tutoriel doit avoir un lien `@ref` vers sa documentation API.

### 4.2 Structure recommandée pour un tutoriel

```markdown
# Implémenter un Solveur d'Optimisation

## Objectif
À la fin de ce tutoriel, vous aurez créé un solveur fonctionnel
intégré au système CTSolvers.

## Prérequis
- Connaissance du dispatch multiple Julia
- Lecture de la page Architecture
- Lecture du contrat AbstractStrategy

## Étape 1 : Définir le type
[Code minimal + explication + test]

## Étape 2 : Implémenter le contrat type-level
[Code + explication de id() et metadata() + test]

## Étape 3 : Implémenter le constructeur
[Code + explication de build_strategy_options + test]

## Étape 4 : Implémenter l'interface callable
[Code + explication + test]

## Étape 5 : Enregistrer dans le registry
[Code + explication + test]

## Étape 6 : Créer l'extension
[Code + explication du pattern ext/ + test]

## Résultat final
[Code complet assemblé]

## Pour aller plus loin
- Mode permissif
- Options avec aliases et validators
- Intégration CommonSolve
```

### 4.3 Ce qui manque dans le plan actuel

Le plan ne distingue pas entre :
- **Tutoriel guidé** (pas à pas, pour apprendre)
- **How-to** (recette rapide, pour résoudre un problème précis)
- **Référence d'interface** (spécification formelle du contrat)

Ces trois formats ont des objectifs différents et ne s'adressent pas au même moment du parcours développeur. Le framework [Diátaxis](https://diataxis.fr/) formalise cette distinction.

---

## 5. Analyse de l'API Reference

### 5.1 Le modèle de référence existe déjà

Le fichier `migration_to_ctsolvers/docs/api_reference.jl` (481 lignes) contient une configuration complète et éprouvée avec :
- Séparation **Public / Internal** par module
- Séparation **Contract / API** pour Strategies
- Sous-répertoires par module (`options/`, `strategies/`, `orchestration/`)
- Structure de pages dans `make.jl` (lignes 65-107)

Le plan actuel propose un `api_reference.jl` simplifié (tout en `public=true, private=true` dans un seul fichier par module). C'est un recul par rapport à la ressource existante.

**Recommandation** : Reprendre le modèle de `migration_to_ctsolvers/docs/api_reference.jl` et l'adapter à CTSolvers. La séparation Public/Internal est essentielle pour un public développeur.

### 5.2 Modules manquants dans la ressource de référence

La ressource de référence ne couvre pas les modules ajoutés dans CTSolvers :
- `Optimization/` (abstract_types, builders, contract, building, solver_info)
- `Modelers/` (abstract_modeler, validation, adnlp_modeler, exa_modeler)
- `DOCP/` (types, contract_impl, accessors, building)
- `Solvers/` (abstract_solver, validation, ipopt/madnlp/madncl/knitro, common_solve_api)

Ces modules doivent être ajoutés à la configuration API.

### 5.3 Extensions

Le plan mentionne les extensions mais ne détaille pas la stratégie. La ressource de référence ne les couvre pas non plus (elle n'avait pas d'extensions). Il faut :
1. Charger les extensions dans `make.jl` (via `using NLPModelsIpopt`, etc.)
2. Utiliser `Base.get_extension` pour la documentation conditionnelle
3. Documenter le pattern Tag Dispatch utilisé dans `Solvers.jl`

---

## 6. Erreurs Factuelles dans la Proposition

| Affirmation (propal) | Réalité (code) |
|----------------------|----------------|
| "Options : 4 exports publics" | 5 exports : `NotProvided`, `NotProvidedType`, `OptionValue`, `OptionDefinition`, `extract_option`, `extract_options`, `extract_raw_options` (7 en fait) |
| "Strategies : 12 sous-fichiers" | 11 fichiers (3 contract/ + 8 api/) |
| "Strategies : 13 exports publics" | 28 exports (compter les lignes 40-69 de Strategies.jl) |
| "Optimization : 5 sous-fichiers" | 5 fichiers (correct) mais 6 avec le module lui-même |
| "DOCP : 5 sous-fichiers" | 4 fichiers + le module (types, contract_impl, accessors, building) |
| "Solvers : 7 sous-fichiers" | 8 fichiers (abstract_solver, validation, 4 solvers, common_solve_api) + le module |
| "Couverture actuelle ~20%" | Plus proche de 14% (1/7 modules, et encore partiellement) |

Ces erreurs ne sont pas graves en soi, mais elles montrent que l'analyse n'a pas été suffisamment rigoureuse. Pour un plan de documentation, la précision est importante.

---

## 7. Problèmes de Présentation

### 7.1 Abus d'emojis et de formatage marketing

Les documents utilisent des emojis (📋, 🎯, 🏗️, etc.) et un ton marketing ("transformera CTSolvers en un package avec une documentation professionnelle"). Pour un rapport technique destiné à des développeurs, un ton factuel et sobre est plus approprié.

### 7.2 Redondance entre documents

Le README répète 80% du contenu de 01_project_proposal.md. L'analyse technique (02) répète la structure de fichiers et les phases. La roadmap (03) répète encore les phases avec plus de détail mais aussi plus de boilerplate.

**Recommandation** : Un seul document de proposition suffit, structuré en : Diagnostic → Structure proposée → Synopsis par page → Plan d'implémentation.

### 7.3 Métriques artificielles

"20+ fichiers créés" n'est pas une métrique de qualité. "Build time < 3 minutes" est un détail technique, pas un critère de succès. Les vraies métriques seraient :
- Chaque contrat a un exemple d'implémentation complet et exécutable
- Chaque type abstrait a sa hiérarchie documentée
- Chaque module a sa page API avec séparation public/internal
- La documentation compile sans warnings

---

## 8. Recommandations Concrètes

### 8.1 Structure révisée

```
docs/src/
├── index.md                              # Vue d'ensemble + Quick Start
├── architecture.md                       # Architecture, hiérarchie, dépendances
├── guides/
│   ├── options_system.md                # Système d'options (fusion du contenu existant)
│   ├── implementing_a_strategy.md       # Contrat + Tutoriel fusionnés
│   ├── implementing_a_solver.md         # Contrat + Tutoriel fusionnés
│   ├── implementing_a_modeler.md        # Contrat + Tutoriel fusionnés
│   ├── implementing_an_optimization_problem.md  # Contrat + Tutoriel
│   └── orchestration_and_routing.md     # Système de routage
└── api/                                  # Généré automatiquement
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

**Avantages** :
- 13 pages de contenu (au lieu de 17+) : moins de volume, plus de densité
- Fusion interface/tutoriel : un seul endroit pour chaque contrat
- API séparée Public/Internal : conforme au modèle de référence
- Pas de User Guide superflu : le contenu utilisateur est dans OptimalControl.jl

### 8.2 Ordre d'implémentation révisé

1. **`architecture.md`** : Le pivot. Hiérarchie des types, dépendances entre modules, flux de données.
2. **`api_reference.jl`** : Configuration complète avec séparation Public/Internal.
3. **`implementing_a_strategy.md`** : Le contrat le plus fondamental.
4. **`implementing_a_solver.md`** : Le cas d'usage le plus concret (extensions).
5. **`implementing_a_modeler.md`** et **`implementing_an_optimization_problem.md`**.
6. **`orchestration_and_routing.md`** : Le système de routage.
7. **`options_system.md`** : Fusion et simplification du contenu existant.
8. **`index.md`** : Réécrit en dernier quand on sait ce que contient la doc.

### 8.3 Synopsis par page

Chaque page doit avoir un synopsis clair *avant* d'être rédigée. Voici ce que le plan devrait contenir :

**`architecture.md`** :
- Diagramme de la hiérarchie des types abstraits (texte ASCII ou Mermaid)
- Graphe de dépendances entre modules (Options → Strategies → Orchestration → ...)
- Flux de données : OCP → DOCP → NLP Model → Solution
- Rôle de chaque module en 2-3 phrases
- Conventions (qualified access, no exports, NotImplemented pattern)

**`implementing_a_strategy.md`** :
- Le two-level contract expliqué (type-level vs instance-level)
- Méthodes obligatoires : `id`, `metadata`, constructeur avec `build_strategy_options`
- Méthodes d'instance : `options`
- Types associés : `StrategyMetadata`, `StrategyOptions`, `OptionDefinition`
- Implémentation complète pas à pas (struct → id → metadata → constructeur → tests)
- Validation : `validate_strategy_contract`
- Modes strict/permissif
- Enregistrement dans un `StrategyRegistry`
- Patterns avancés : aliases, validators, introspection

**`implementing_a_solver.md`** :
- Héritage : `AbstractOptimizationSolver <: AbstractStrategy`
- Le contrat Strategy + le contrat callable `(solver)(nlp; display)`
- Le pattern Tag Dispatch pour les extensions
- Création du fichier `ext/CTSolversMyBackend.jl`
- Intégration CommonSolve (3 niveaux : high/mid/low)
- Exemple complet avec tests

**`implementing_a_modeler.md`** :
- Héritage : `AbstractOptimizationModeler <: AbstractStrategy`
- Deux callables : model building et solution building
- Intégration avec `AbstractOptimizationProblem` et ses builders
- Dispatch via `build_model` / `build_solution`
- Exemple complet avec ADNLPModels

**`implementing_an_optimization_problem.md`** :
- Le contrat `AbstractOptimizationProblem`
- Les 4 méthodes de contrat : `get_adnlp_model_builder`, `get_exa_model_builder`, `get_adnlp_solution_builder`, `get_exa_solution_builder`
- Les builders concrets et leur pattern callable
- L'exemple de `DiscretizedOptimalControlProblem` comme implémentation de référence
- Comment les builders sont utilisés par les Modelers

**`orchestration_and_routing.md`** :
- Le concept de "method tuple" `(:discretizer, :modeler, :solver)`
- Le concept de "families" et le mapping strategy → family
- Le routage automatique (unambiguous) vs disambiguation (`route_to`)
- L'ownership map et la détection d'ambiguïté
- Modes strict/permissif au niveau orchestration
- Exemples concrets avec `route_all_options`

---

## 9. Conclusion

Le plan actuel est un bon squelette mais manque de substance. Les principales actions correctives sont :

1. **Fusionner interface + tutoriel** pour éviter la redondance
2. **Réduire le User Guide** au strict nécessaire (la cible est développeur)
3. **Placer `architecture.md` en premier** comme pivot central
4. **Reprendre le modèle API de la ressource de référence** (séparation Public/Internal)
5. **Ajouter les concepts manquants** (two-level contract, hiérarchie des types, CommonSolve multi-level, Tag Dispatch)
6. **Écrire un synopsis par page** avant de commencer la rédaction
7. **Supprimer la redondance** entre les 3 documents de proposition
8. **Adopter un ton technique** plutôt que marketing
