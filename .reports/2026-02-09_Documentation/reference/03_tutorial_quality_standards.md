# Standards de Qualité pour les Tutoriels Développeur

**Date** : 9 février 2026
**Objet** : Définir ce qu'est un bon tutoriel dans le contexte CTSolvers

---

## 1. Le Framework Diátaxis Appliqué à CTSolvers

La documentation technique se décompose en quatre types de contenu distincts, chacun avec un objectif et un format différent. Le plan initial ne fait pas cette distinction, ce qui mène à de la confusion entre "interface" et "tutoriel".

### Les 4 types de contenu

| Type | Objectif | Moment | Format |
| ---- | -------- | ------ | ------ |
| **Tutoriel** | Apprendre en faisant | Découverte | Pas à pas guidé |
| **How-to** | Résoudre un problème | Besoin ponctuel | Recette ciblée |
| **Référence** | Consulter une spécification | Pendant le développement | Exhaustif, factuel |
| **Explication** | Comprendre un concept | Prise de recul | Narratif, conceptuel |

### Application à CTSolvers

Dans la structure révisée, chaque page `guides/implementing_*.md` combine **tutoriel + référence** :

- Les sections "Contrat" et "Patterns avancés" sont de la **référence**.
- Les sections "Implémentation pas à pas" sont du **tutoriel**.
- La page `architecture.md` est de l'**explication**.
- L'API générée est de la **référence** pure.

Ce qui manque dans le plan : des **how-to** courts pour des problèmes spécifiques. Exemples :
- "Comment ajouter un alias à une option existante ?"
- "Comment déboguer un routage d'option ambiguë ?"
- "Comment tester un solveur sans le backend réel ?"

Ces how-to peuvent être intégrés comme sections finales dans les guides, ou regroupés dans une page FAQ.

---

## 2. Anatomie d'un Bon Tutoriel Julia

### 2.1 Structure obligatoire

Chaque tutoriel doit contenir ces éléments dans cet ordre :

```markdown
# Titre orienté action

## Objectif
Une phrase qui décrit le résultat concret.
"À la fin de ce guide, vous aurez implémenté un solveur fonctionnel
enregistré dans le registry et testable via CommonSolve."

## Prérequis
- Concepts Julia requis (dispatch multiple, modules, extensions)
- Pages de documentation à lire avant
- Packages nécessaires

## Étape 1 : [Action concrète]
[Explication courte]
[Bloc de code complet et copiable]
[Test de validation]

## Étape 2 : [Action concrète]
...

## Résultat complet
[Code assemblé, sans interruption]

## Pour aller plus loin
[Liens vers patterns avancés, API reference]
```

### 2.2 Langue

**Toute la documentation Documenter.jl doit être rédigée en anglais.**
Cela inclut les pages de guides, l'architecture, les messages dans les blocs
`@example`/`@repl`, les titres de sections, et la page `error_messages.md`.

Les rapports internes (ce répertoire `reference/`, les fichiers `propal/`)
restent en français car ce sont des documents de travail.

### 2.3 Règles pour les blocs de code

1. **Chaque bloc doit être copiable et exécutable.** Pas de `# ...`, pas de `# TODO`, pas de code tronqué. Si le code est long, le découper en étapes mais chaque étape doit compiler.

2. **Utiliser les blocs `@example` de Documenter.jl** quand c'est possible. Cela garantit que le code compile lors du build de la documentation.

    ```markdown
    ```@example strategy
    using CTSolvers
    using CTSolvers.Strategies

    struct MyStrategy <: AbstractStrategy
        options::StrategyOptions
    end

    Strategies.id(::Type{<:MyStrategy}) = :my_strategy
    ```
    ```

3. **Montrer les erreurs intentionnellement.** Les messages `NotImplemented` de CTSolvers sont excellents. Les montrer dans le tutoriel aide le développeur à comprendre ce qui se passe quand il oublie une méthode.

    ```markdown
    Si vous essayez d'appeler `metadata` sans l'implémenter :
    ```@repl strategy
    Strategies.metadata(MyStrategy)
    # ERROR: NotImplemented: Strategy metadata method not implemented
    #   required_method: metadata(::Type{<:MyStrategy})
    #   suggestion: Implement metadata(::Type{<:MyStrategy}) to return StrategyMetadata
    ```
    ```

4. **Inclure un test après chaque étape.** Le développeur doit pouvoir vérifier qu'il est sur la bonne voie.

    ```julia
    # Vérification
    @assert Strategies.id(MyStrategy) === :my_strategy
    ```

### 2.3 Règles de rédaction

1. **Ton direct et technique.** Pas de "Nous allons maintenant..." ni de "Comme vous pouvez le voir...". Aller droit au fait.

    - Non : "Nous allons maintenant implémenter la méthode `id` pour notre stratégie."
    - Oui : "Implémentez `id` pour retourner l'identifiant unique :"

2. **Expliquer le *pourquoi*, pas seulement le *comment*.** Chaque étape doit avoir une phrase d'explication qui dit pourquoi cette méthode existe.

    - Non : "Ajoutez cette méthode."
    - Oui : "`id` est utilisé par le registry pour identifier et router les stratégies. Il doit retourner un `Symbol` unique."

3. **Liens `@ref` systématiques.** Chaque type et fonction mentionné doit avoir un lien vers sa page API.

4. **Pas d'emojis.** Ton professionnel et sobre.

---

## 3. Critères de Qualité par Page

### 3.1 Checklist pour chaque guide

Avant de considérer une page comme terminée, vérifier :

- [ ] L'objectif est énoncé en une phrase
- [ ] Les prérequis sont listés
- [ ] Chaque étape a : explication + code + test
- [ ] Le code complet assemblé est présent en fin de page
- [ ] Les messages d'erreur sont montrés pour les cas d'oubli
- [ ] `validate_strategy_contract` est utilisé comme point de validation
- [ ] Tous les types et fonctions ont des liens `@ref`
- [ ] Le code compile dans un bloc `@example` Documenter
- [ ] Les patterns avancés sont mentionnés avec liens
- [ ] La longueur est dans la cible (200-400 lignes)

### 3.2 Checklist pour `architecture.md`

- [ ] La hiérarchie des types abstraits est un diagramme lisible
- [ ] Le graphe de dépendances entre modules est présent
- [ ] Le flux de données OCP → Solution est décrit
- [ ] Le two-level contract est expliqué
- [ ] Le pattern NotImplemented est expliqué
- [ ] Le pattern Tag Dispatch est expliqué
- [ ] Les conventions de nommage sont listées
- [ ] Chaque module est décrit en 2-3 phrases

### 3.3 Checklist pour `api_reference.jl`

- [ ] Chaque module a une page Public et une page Internal
- [ ] Les extensions sont documentées conditionnellement
- [ ] `EXCLUDE_SYMBOLS` est correctement configuré
- [ ] Les sous-répertoires sont utilisés (`options/`, `strategies/`, etc.)
- [ ] Le build compile sans warnings
- [ ] Les cross-references fonctionnent

---

## 4. Anti-patterns à Éviter

### 4.1 Le tutoriel "Hello World" inutile

Un tutoriel qui montre `using CTSolvers; println("Hello")` n'apporte rien. Le premier exemple doit être un cas d'usage réel, même simplifié.

### 4.2 Le code incomplet

```julia
# ❌ Anti-pattern : code tronqué
struct MyStrategy <: AbstractStrategy
    # ... fields
end

# Implement methods...
```

```julia
# ✅ Correct : code complet
struct MyStrategy <: AbstractStrategy
    options::StrategyOptions
end

Strategies.id(::Type{<:MyStrategy}) = :my_strategy
```

### 4.3 L'explication sans code

```markdown
❌ "Le contrat AbstractStrategy requiert l'implémentation de trois méthodes :
id, metadata et options. La méthode id retourne un Symbol unique..."
[500 mots sans un seul bloc de code]
```

```markdown
✅ "Le contrat AbstractStrategy requiert trois méthodes :"

| Méthode | Niveau | Signature | Retour |
| ------- | ------ | --------- | ------ |
| `id` | Type | `id(::Type{<:T})` | `Symbol` |
| `metadata` | Type | `metadata(::Type{<:T})` | `StrategyMetadata` |
| `options` | Instance | `options(::T)` | `StrategyOptions` |

[Suivi immédiatement par l'implémentation]
```

### 4.4 La redondance avec l'API

Ne pas recopier les docstrings dans les guides. Les guides expliquent *comment utiliser* les fonctions ensemble ; l'API documente *chaque fonction individuellement*. Utiliser des liens `@ref` pour renvoyer vers l'API.

### 4.5 Le guide qui suppose trop

Ne pas supposer que le lecteur connaît les conventions internes. Chaque guide doit être lisible indépendamment, avec des liens vers `architecture.md` pour le contexte global.

---

## 5. Exemples de Référence dans l'Écosystème Julia

### Bonnes documentations à étudier

- **Makie.jl** : Excellents tutoriels avec code exécutable et résultats visuels.
- **Flux.jl** : Progression claire du simple au complexe.
- **DifferentialEquations.jl** : Séparation nette tutoriels / API / exemples.
- **Documenter.jl lui-même** : Guide développeur bien structuré.

### Ce qu'ils ont en commun

1. Code exécutable et testé automatiquement
2. Progression incrémentale
3. Résultats visibles à chaque étape
4. Séparation claire des types de contenu
5. Liens systématiques vers l'API

---

## 6. Métriques de Qualité Révisées

Les métriques du plan initial ("20+ fichiers", "build time < 3min") ne mesurent pas la qualité. Voici des métriques pertinentes :

### Métriques de complétude

- Chaque type abstrait a sa hiérarchie documentée
- Chaque contrat a un exemple d'implémentation complet et exécutable
- Chaque module a sa page API Public et Internal
- La documentation compile sans warnings (`warnonly=false` idéalement)

### Métriques de qualité

- Chaque bloc de code dans les guides compile dans un `@example`
- Chaque guide passe la checklist de la section 3.1
- Aucune duplication de contenu entre guides et API
- Chaque concept du code source est couvert (cf. tableau section 3.1 de la revue critique)

### Métriques d'utilisabilité

- Un développeur Julia expérimenté peut implémenter une stratégie en suivant uniquement le guide, sans lire le code source
- La table de navigation dans `index.md` couvre tous les cas d'usage développeur
- Les messages d'erreur CTSolvers renvoient vers la documentation appropriée
