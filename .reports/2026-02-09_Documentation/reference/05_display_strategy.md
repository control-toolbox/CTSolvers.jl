# Stratégie d'Intégration des Affichages et Messages d'Erreur

**Date** : 9 février 2026
**Objet** : Comment exploiter la documentation comme banc de validation visuelle

---

## 1. Problématique

CTSolvers investit massivement dans la qualité de ses affichages :

- **`Base.show` compact et pretty** pour chaque type (`OptionValue`, `OptionDefinition`,
  `StrategyMetadata`, `StrategyOptions`, `StrategyRegistry`, builders, solvers, modelers)
- **Messages d'erreur structurés** via `CTBase.Exceptions` (`IncorrectArgument`,
  `NotImplemented`) avec champs `got`, `expected`, `suggestion`, `context`
- **Suggestions Levenshtein** pour les options inconnues en mode strict
- **Warnings** en mode permissif pour les options non reconnues

Aujourd'hui, la validation de ces affichages repose sur **10 scripts manuels**
dans `test/extras/` :

| Répertoire | Fichier | Affichages couverts |
| ---------- | ------- | ------------------- |
| `display/` | `01_options_repl.jl` | OptionValue, OptionDefinition, sentinels, extraction, validation |
| `display/` | `02_strategies_repl.jl` | Registry, StrategyOptions, introspection, metadata, defaults |
| `display/` | `02_strategies_simple.jl` | Variante simplifiée du précédent |
| `display/` | `03_orchestration_repl.jl` | Strategy IDs, family map, ownership map, routing, erreurs |
| `display/` | `04_optimization_repl.jl` | Abstract types, builders, model building |
| `kwarg/` | `01_modeler_display.jl` | ADNLPModeler, ExaModeler, options, construction |
| `kwarg/` | `01_solver_display.jl` | IpoptSolver, MadNLPSolver, options, construction |
| `kwarg/` | `02_solver_display.jl` | Variante étendue avec plus de solveurs |
| `kwarg/` | `03_routing_display.jl` | Routage, désambiguïsation, erreurs d'ambiguïté |
| `kwarg/` | `04_integration_display.jl` | Flux complet modeler + builder + solver |

**Le problème** : Ces scripts sont exécutés manuellement, leur sortie n'est
visible nulle part de façon pérenne, et ils ne sont pas maintenus en synchronisation
avec le code. Si un affichage change, personne ne le voit tant que quelqu'un
ne relance pas le script à la main.

**L'opportunité** : La documentation Documenter.jl exécute du code Julia à chaque
build via les blocs `@example` et `@repl`. Si les affichages sont intégrés dans
la documentation, ils sont :

1. **Validés automatiquement** à chaque build CI
2. **Visibles** dans la documentation publiée
3. **Maintenus** car un changement d'affichage casse le build (ou met à jour le rendu)
4. **Utiles** pour le lecteur qui voit exactement ce que produit chaque fonction

---

## 2. Mécanismes Documenter.jl

### 2.1 `@example` — Code exécuté, erreur = build failure

````markdown
```@example strategy
using CTSolvers
meta = CTSolvers.Strategies.metadata(CTSolvers.Modelers.ADNLPModeler)
```
````

- Le code est exécuté pendant le build
- Le résultat de la dernière expression est affiché
- **Si une exception est levée, le build échoue**
- Idéal pour les affichages normaux (show, display)

### 2.2 `@repl` — Code exécuté avec prompt, erreur = affichée

````markdown
```@repl strategy
using CTSolvers
CTSolvers.Strategies.metadata(CTSolvers.Modelers.ADNLPModeler)
```
````

- Ajoute automatiquement le prompt `julia>` devant chaque expression
- Affiche le résultat de chaque expression (pas seulement la dernière)
- **Les exceptions sont capturées et affichées, sans crasher le build**
- Idéal pour montrer les messages d'erreur

### 2.3 `@setup` — Code invisible, partage le contexte

````markdown
```@setup strategy
using CTSolvers
using CTSolvers.Strategies
using CTSolvers.Modelers
```
````

- Le code est exécuté mais n'apparaît pas dans le rendu
- Partage le contexte avec les blocs `@example`/`@repl` du même nom
- Idéal pour les imports et le setup qui polluent le discours

### 2.4 Contextes nommés et partagés

Tous les blocs `@setup`, `@example` et `@repl` portant le même nom sur une
même page partagent le même module d'évaluation. Cela permet d'alterner
entre texte explicatif et blocs de code sans perdre le contexte.

````markdown
```@setup mystrategy
using CTSolvers
# ... imports cachés
```

Voici comment créer une stratégie :

```@example mystrategy
struct MyStrategy <: CTSolvers.Strategies.AbstractStrategy
    options::CTSolvers.Strategies.StrategyOptions
end
```

Si on oublie d'implémenter `metadata`, voici l'erreur :

```@repl mystrategy
CTSolvers.Strategies.metadata(MyStrategy)
```
````

---

## 3. Inventaire des Affichages à Intégrer

Après analyse des 10 scripts `test/extras/`, voici l'inventaire complet
des affichages, classés par catégorie et par page de destination.

### 3.1 Affichages normaux (Base.show)

Ces affichages s'intègrent naturellement dans les guides via `@example`.

| Affichage | Type | Page cible |
| --------- | ---- | ---------- |
| `OptionValue(1000, :user)` | compact show | `options_system.md` |
| `OptionDefinition(name=:max_iter, ...)` | pretty show | `options_system.md` |
| `OptionDefinition` avec aliases | pretty show | `options_system.md` |
| `NotProvided`, `NotStored` sentinels | compact show | `options_system.md` |
| `StrategyMetadata(...)` | pretty show | `implementing_a_strategy.md` |
| `StrategyOptions(...)` | compact + pretty | `implementing_a_strategy.md` |
| `StrategyRegistry(...)` | compact + pretty | `implementing_a_strategy.md` |
| `ADNLPModeler(...)` | compact show | `implementing_a_modeler.md` |
| `ExaModeler(...)` | compact show | `implementing_a_modeler.md` |
| `IpoptSolver(...)` | compact show | `implementing_a_solver.md` |
| `MadNLPSolver(...)` | compact show | `implementing_a_solver.md` |
| `ADNLPModelBuilder(f)` | compact + pretty | `implementing_an_optimization_problem.md` |
| `ExaModelBuilder(f)` | compact + pretty | `implementing_an_optimization_problem.md` |
| Introspection : `option_names`, `option_type`, `option_default` | valeurs | `implementing_a_strategy.md` |
| Collection interface : `keys`, `values`, `pairs` sur StrategyOptions | itération | `implementing_a_strategy.md` |
| Provenance : `source`, `is_user`, `is_default` | valeurs | `options_system.md` |
| `route_all_options(...)` résultat | NamedTuple | `orchestration_and_routing.md` |
| `build_option_ownership_map(...)` résultat | Dict | `orchestration_and_routing.md` |

### 3.2 Messages d'erreur (exceptions)

Ces affichages nécessitent `@repl` pour ne pas crasher le build.

| Erreur | Déclencheur | Page cible |
| ------ | ----------- | ---------- |
| `NotImplemented` : `metadata` non implémenté | Appel sur type sans implémentation | `implementing_a_strategy.md` |
| `NotImplemented` : `id` non implémenté | Appel sur type sans implémentation | `implementing_a_strategy.md` |
| `NotImplemented` : callable solver non implémenté | Appel sans extension chargée | `implementing_a_solver.md` |
| `NotImplemented` : callable modeler non implémenté | Appel sans implémentation | `implementing_a_modeler.md` |
| `NotImplemented` : `get_adnlp_model_builder` non implémenté | Appel sur type sans implémentation | `implementing_an_optimization_problem.md` |
| `IncorrectArgument` : option inconnue (strict) | `build_strategy_options` avec option inconnue | `options_system.md` |
| `IncorrectArgument` : suggestion Levenshtein | Option proche d'une option connue | `options_system.md` |
| `IncorrectArgument` : type mismatch | Option avec mauvais type | `options_system.md` |
| `IncorrectArgument` : validator failure | Option ne passant pas le validator | `options_system.md` |
| `IncorrectArgument` : option ambiguë (routing) | Option appartenant à 2+ familles | `orchestration_and_routing.md` |
| `IncorrectArgument` : option inconnue (routing) | Option n'appartenant à aucune famille | `orchestration_and_routing.md` |
| `IncorrectArgument` : duplicate option names | `StrategyMetadata` avec noms dupliqués | `options_system.md` |
| Warning : option inconnue (permissif) | `build_strategy_options` mode permissif | `options_system.md` |

---

## 4. Stratégie d'Intégration

### 4.1 Principe : ne pas polluer le discours

Le risque principal est de transformer les guides en catalogue d'affichages.
Pour l'éviter, trois règles :

**Règle 1 — Affichages intégrés au fil du tutoriel.**
Chaque affichage normal apparaît naturellement à l'étape du tutoriel où il
est pertinent. Pas de section "Affichages" séparée.

````markdown
## Étape 3 : Implémenter metadata

```@example mystrategy
function CTSolvers.Strategies.metadata(::Type{<:MyStrategy})
    return CTSolvers.Strategies.StrategyMetadata(
        CTSolvers.Options.OptionDefinition(
            name=:param, type=Int, default=42,
            description="My parameter"
        )
    )
end
```

Vérifions le résultat :

```@repl mystrategy
CTSolvers.Strategies.metadata(MyStrategy)
```
````

L'affichage de `StrategyMetadata` apparaît naturellement après son implémentation.

**Règle 2 — Erreurs montrées comme "ce qui se passe si...".**
Les messages d'erreur sont introduits par une phrase courte expliquant
le scénario d'erreur, puis un bloc `@repl`.

````markdown
Si vous oubliez d'implémenter `metadata`, l'appel lève une erreur explicite :

```@repl mystrategy_error
CTSolvers.Strategies.metadata(IncompleteStrategy)
```

Le message indique la méthode requise et comment l'implémenter.
````

**Règle 3 — Pages dédiées pour le catalogue d'erreurs.**
Les erreurs les plus importantes méritent une page de référence séparée
qui les regroupe toutes. Cette page n'est pas un tutoriel mais une
**référence consultable** quand on rencontre une erreur.

### 4.2 Structure proposée : page dédiée aux erreurs

Ajouter une page `guides/error_messages.md` à la structure révisée :

```text
docs/src/
├── ...
├── guides/
│   ├── ...
│   └── error_messages.md          ← NOUVEAU
└── api/
    └── ...
```

Cette page regroupe tous les messages d'erreur de CTSolvers avec :
- Le message exact (via `@repl`)
- Le scénario qui le déclenche
- La solution recommandée

#### Synopsis de `error_messages.md`

````markdown
# Messages d'Erreur de Référence

Cette page regroupe les messages d'erreur de CTSolvers avec leur
explication et la solution recommandée.

## NotImplemented — Contrat non implémenté

### Strategy contract

```@setup errors
using CTSolvers
struct IncompleteStrategy <: CTSolvers.Strategies.AbstractStrategy end
```

#### `id` non implémenté

```@repl errors
CTSolvers.Strategies.id(IncompleteStrategy)
```

**Cause** : Le type `IncompleteStrategy` n'implémente pas la méthode
`id(::Type)` du contrat `AbstractStrategy`.

**Solution** : Ajouter `CTSolvers.Strategies.id(::Type{<:IncompleteStrategy}) = :my_id`

#### `metadata` non implémenté

```@repl errors
CTSolvers.Strategies.metadata(IncompleteStrategy)
```

**Cause** : ...
**Solution** : ...

## IncorrectArgument — Argument invalide

### Option inconnue (mode strict)

```@repl errors
CTSolvers.Modelers.ADNLPModeler(unknown_option=123)
```

**Cause** : L'option `unknown_option` n'est pas définie dans les
metadata de `ADNLPModeler`.

**Solution** : Vérifier le nom de l'option avec
`CTSolvers.Strategies.option_names(ADNLPModeler)`.

### Option avec suggestion Levenshtein

```@repl errors
CTSolvers.Modelers.ADNLPModeler(backnd=:optimized)
```

**Cause** : L'option `backnd` n'existe pas, mais `backend` est proche.

**Solution** : Corriger le nom de l'option.

### Option inconnue (mode permissif)

```@repl errors
CTSolvers.Modelers.ADNLPModeler(unknown_option=123; mode=:permissive)
```

**Comportement** : L'option est acceptée avec un warning.

...
````

### 4.3 Répartition des affichages par page

| Page | Affichages normaux (`@example`) | Erreurs (`@repl`) | Volume estimé |
| ---- | ------------------------------- | ------------------ | ------------- |
| `implementing_a_strategy.md` | metadata, StrategyOptions, registry, introspection, collection | NotImplemented (id, metadata, options) | +50 lignes |
| `implementing_a_solver.md` | IpoptSolver show, options | NotImplemented (callable sans ext) | +30 lignes |
| `implementing_a_modeler.md` | ADNLPModeler show, options | NotImplemented (callable) | +30 lignes |
| `implementing_an_optimization_problem.md` | builders show, DOCP show | NotImplemented (getters) | +20 lignes |
| `options_system.md` | OptionValue, OptionDefinition, sentinels, extraction, provenance | IncorrectArgument (type, validator, unknown), warning permissif | +60 lignes |
| `orchestration_and_routing.md` | route_all_options, ownership map | IncorrectArgument (ambiguïté, unknown) | +40 lignes |
| `error_messages.md` | aucun | Tous les messages regroupés | ~150 lignes |

**Impact total** : ~230 lignes d'affichages réparties sur 6 guides + 1 page dédiée.
C'est gérable si les affichages sont intégrés au fil du discours (règle 1).

---

## 5. Implémentation Technique

### 5.1 Pattern `@setup` + `@example` + `@repl`

Chaque page utilise un contexte nommé pour partager l'état :

````markdown
```@setup strategy_guide
using CTSolvers
using CTSolvers.Strategies
using CTSolvers.Options
using CTSolvers.Modelers
```

## Étape 1 : Définir le type

```@example strategy_guide
struct MyStrategy <: CTSolvers.Strategies.AbstractStrategy
    options::CTSolvers.Strategies.StrategyOptions
end
nothing # hide
```

## Étape 2 : Implémenter id

```@example strategy_guide
CTSolvers.Strategies.id(::Type{<:MyStrategy}) = :my_strategy
nothing # hide
```

Vérifions :

```@repl strategy_guide
CTSolvers.Strategies.id(MyStrategy)
```

## Que se passe-t-il si on oublie metadata ?

```@repl strategy_guide
CTSolvers.Strategies.metadata(MyStrategy)
```

Le message indique exactement quelle méthode implémenter.

## Étape 3 : Implémenter metadata

```@example strategy_guide
function CTSolvers.Strategies.metadata(::Type{<:MyStrategy})
    return CTSolvers.Strategies.StrategyMetadata(
        CTSolvers.Options.OptionDefinition(
            name=:param, type=Int, default=42,
            description="My parameter"
        )
    )
end
nothing # hide
```

Vérifions l'affichage :

```@repl strategy_guide
CTSolvers.Strategies.metadata(MyStrategy)
```
````

### 5.2 Gestion du `nothing # hide`

Les blocs `@example` affichent le résultat de la dernière expression.
Pour les définitions de fonctions/structs, ajouter `nothing # hide` pour
éviter d'afficher le retour (qui serait `nothing` ou le nom de la fonction).

Pour les blocs `@repl`, ce n'est pas nécessaire car chaque expression
est affichée individuellement.

### 5.3 Gestion des extensions (solveurs)

Les solveurs nécessitent le chargement d'extensions. Utiliser `@setup` :

````markdown
```@setup solver_guide
using CTSolvers
using NLPModelsIpopt  # Charge l'extension CTSolversIpopt
```
````

Si l'extension n'est pas disponible dans l'environnement de build,
utiliser `try/catch` dans le `@setup` et conditionner les blocs suivants.

### 5.4 Configuration `make.jl`

Ajouter les dépendances nécessaires dans `docs/Project.toml` :

```toml
[deps]
CTSolvers = "..."
Documenter = "..."
NLPModelsIpopt = "..."
# ... autres extensions si nécessaire pour les exemples
```

---

## 6. Bénéfices

### 6.1 Validation continue

Chaque build CI exécute tous les blocs `@example` et `@repl`. Si un
affichage change (modification de `Base.show`), le build détecte la
différence. Cela remplace les 10 scripts manuels de `test/extras/`.

### 6.2 Documentation vivante

Les affichages dans la documentation sont toujours à jour car ils sont
générés à partir du code réel. Pas de captures d'écran obsolètes ni
de copier-coller périmés.

### 6.3 Pédagogie par l'erreur

Montrer les messages d'erreur dans la documentation est une pratique
pédagogique reconnue. Le développeur qui rencontre une erreur peut :

1. Chercher le message dans `error_messages.md`
2. Trouver la cause et la solution immédiatement
3. Voir le contexte dans lequel l'erreur se produit

### 6.4 Qualité des messages

Si un message d'erreur est mal formulé, il sera visible dans la
documentation publiée. Cela crée une incitation naturelle à améliorer
la qualité des messages.

---

## 7. Risques et Mitigations

| Risque | Mitigation |
| ------ | ---------- |
| Pollution du discours par trop d'affichages | Règle 1 : intégrer au fil du tutoriel, pas en bloc |
| Build time augmenté par l'exécution du code | Limiter les exemples lourds, utiliser `@setup` pour le setup commun |
| Fragilité : changement d'affichage = build cassé | C'est un feature, pas un bug. Utiliser `warnonly` si nécessaire pendant le développement |
| Extensions non disponibles en CI | Ajouter les dépendances dans `docs/Project.toml`, ou conditionner avec `try/catch` |
| Messages d'erreur trop longs dans le rendu | Sélectionner les erreurs les plus représentatives, pas toutes |

---

## 8. Plan d'Action

### Étape 1 : Créer `error_messages.md`

Page de référence regroupant tous les messages d'erreur. C'est la page
la plus facile à créer car elle ne nécessite pas de discours élaboré :
juste des blocs `@repl` avec cause/solution.

### Étape 2 : Intégrer les affichages dans les guides existants

Pour chaque guide, ajouter les blocs `@example`/`@repl` aux étapes
appropriées du tutoriel. Commencer par `implementing_a_strategy.md`
qui a le plus d'affichages.

### Étape 3 : Configurer le build

Ajouter les dépendances dans `docs/Project.toml` et vérifier que
le build CI exécute correctement tous les blocs.

### Étape 4 : Retirer progressivement les scripts manuels

Une fois les affichages intégrés dans la documentation, les scripts
de `test/extras/display/` et `test/extras/kwarg/` deviennent redondants.
Ils peuvent être archivés ou supprimés.

---

## 9. Mise à Jour de la Structure Révisée

La page `error_messages.md` s'ajoute à la structure proposée dans
`02_revised_structure.md` :

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
│   ├── orchestration_and_routing.md
│   └── error_messages.md                        ← NOUVEAU
└── api/
    └── ...
```

Et dans `make.jl` :

```julia
"Developer Guides" => [
    # ... guides existants ...
    "Error Messages Reference" => "guides/error_messages.md",
],
```

**Total révisé** : 9 pages manuelles (au lieu de 8) + ~22 pages API.
