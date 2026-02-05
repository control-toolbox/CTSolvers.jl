# Spécifications des Messages : Erreurs et Warnings

## 1. Principes de Design des Messages

### 1.1 Clarté

**Objectif** : L'utilisateur doit comprendre immédiatement le problème.

**Éléments requis** :
- Quelle option pose problème
- Pourquoi c'est un problème
- Dans quel contexte (constructeur, routage)

### 1.2 Guidance

**Objectif** : L'utilisateur doit savoir comment résoudre le problème.

**Éléments requis** :
- Solution recommandée
- Exemples concrets
- Alternatives si applicable

### 1.3 Contexte

**Objectif** : L'utilisateur doit avoir toutes les informations nécessaires.

**Éléments requis** :
- Options disponibles
- Suggestions basées sur similarité
- Mode actuel (strict/permissif)

## 2. Messages Constructeur - Mode Strict

### 2.1 Erreur : Option Inconnue

**Contexte** : L'utilisateur passe une option non définie dans les metadata.

**Message** :

```
ERROR: Exceptions.IncorrectArgument: Options inconnues fournies

Options non reconnues : [:unknown_opt, :another_opt]

Ces options ne sont pas définies dans les metadata de IpoptSolver.

Options disponibles :
  :max_iter, :tol, :print_level, :linear_solver, :mu_strategy,
  :dual_inf_tol, :constr_viol_tol, :max_wall_time, :max_cpu_time,
  :timing_statistics, :print_timing_statistics, :print_frequency_iter,
  :print_frequency_time, :sb

Suggestions pour :unknown_opt :
  - :max_iter (distance Levenshtein: 5)
  - :max_wall_time (distance: 7)

Si vous êtes certain que ces options existent pour le backend Ipopt,
utilisez le mode permissif :
  IpoptSolver(...; strict=false)

Context: build_strategy_options - strict validation
```

**Éléments clés** :
- ✅ Liste des options inconnues
- ✅ Options disponibles complètes
- ✅ Suggestions basées sur similarité
- ✅ Solution (mode permissif)
- ✅ Contexte technique

### 2.2 Erreur : Type Incorrect (même en mode permissif)

**Contexte** : L'utilisateur passe une option connue avec un mauvais type.

**Message** :

```
ERROR: Exceptions.IncorrectArgument: Type incorrect pour l'option

Option :max_iter a la valeur "1000" de type String.

Type attendu : Integer

Cette option est validée même en mode permissif car elle est définie
dans les metadata de IpoptSolver.

Suggestion : Utilisez un entier : max_iter=1000

Context: Options.extract_option - type validation
```

**Éléments clés** :
- ✅ Option concernée
- ✅ Valeur et type fournis
- ✅ Type attendu
- ✅ Explication du comportement
- ✅ Solution

### 2.3 Erreur : Validation Échouée

**Contexte** : L'utilisateur passe une valeur qui échoue la validation custom.

**Message** :

```
ERROR: Exceptions.IncorrectArgument: Validation échouée pour l'option

Option :tol a la valeur -0.001

Erreur de validation : tol doit être positif (> 0)

Les validateurs custom sont appliqués même en mode permissif pour
les options définies dans les metadata.

Suggestion : Utilisez une valeur positive, par exemple : tol=1e-6

Context: Options.extract_option - custom validation
```

**Éléments clés** :
- ✅ Option et valeur
- ✅ Message du validateur
- ✅ Explication
- ✅ Suggestion

## 3. Messages Constructeur - Mode Permissif

### 3.1 Warning : Options Non Validées

**Contexte** : L'utilisateur passe des options inconnues en mode permissif.

**Message** :

```
┌ Warning: Options non reconnues transmises au backend
│ 
│ Options non validées : [:unknown_opt, :another_opt]
│ 
│ Ces options seront transmises directement au backend de IpoptSolver
│ sans validation par CTSolvers. Assurez-vous qu'elles sont correctes.
│ 
│ Pour désactiver cet avertissement, définissez ces options dans les metadata.
└ @ CTSolvers.Strategies ~/.julia/dev/CTSolvers/src/Strategies/api/configuration.jl:XX
```

**Éléments clés** :
- ⚠️ Nature du warning (non bloquant)
- ⚠️ Liste des options non validées
- ⚠️ Explication de la transmission
- ⚠️ Comment désactiver (ajouter aux metadata)

### 3.2 Info : Options Validées et Non Validées

**Contexte** : Confirmation que le constructeur a accepté les options.

**Message** (optionnel, via logging) :

```
┌ Info: IpoptSolver créé avec succès
│ 
│ Options validées : [:max_iter, :tol, :print_level]
│ Options non validées : [:unknown_opt] (mode permissif)
│ 
│ Les options non validées seront transmises au backend Ipopt.
└ @ CTSolvers.Solvers ~/.julia/dev/CTSolvers/ext/CTSolversIpopt.jl:XX
```

**Note** : Ce message info est optionnel et peut être activé via un flag de debug.

## 4. Messages Routage - Mode Strict

### 4.1 Erreur : Option Inconnue (0 owners)

**Contexte** : L'utilisateur passe une option qui n'appartient à aucune stratégie.

**Message** :

```
ERROR: Exceptions.IncorrectArgument: Option inconnue fournie

Option :unknown_opt n'appartient à aucune stratégie dans la méthode
(:collocation, :adnlp, :ipopt).

Options disponibles :
  discretizer (:collocation):
    :grid_size, :time_grid, :init_type
  modeler (:adnlp):
    :backend, :show_time, :matrix_free, :name
  solver (:ipopt):
    :max_iter, :tol, :print_level, :linear_solver, :mu_strategy

Si vous êtes certain que cette option existe pour une stratégie spécifique,
utilisez le mode permissif avec disambiguation :
  solve(...; unknown_opt=(value, :ipopt), strict=false)

Context: route_options - unknown option validation
```

**Éléments clés** :
- ✅ Option concernée
- ✅ Méthode utilisée
- ✅ Options disponibles par stratégie
- ✅ Solution (mode permissif + disambiguation)

### 4.2 Erreur : Option Ambiguë

**Contexte** : L'utilisateur passe une option qui existe dans plusieurs stratégies.

**Message** :

```
ERROR: Exceptions.IncorrectArgument: Option ambiguë nécessite disambiguation

Option :backend est ambiguë entre les stratégies : :adnlp, :ipopt

Disambiguez en spécifiant l'ID de la stratégie :

  backend = (:sparse, :adnlp)    # Router vers modeler
  backend = (:cpu, :ipopt)       # Router vers solver

Ou définissez pour plusieurs stratégies :
  backend = ((:sparse, :adnlp), (:cpu, :ipopt))

Context: route_options - ambiguous option resolution
```

**Éléments clés** :
- ✅ Option ambiguë
- ✅ Stratégies concernées
- ✅ Syntaxe de disambiguation
- ✅ Exemples concrets
- ✅ Multi-stratégie

### 4.3 Erreur : Routage Invalide

**Contexte** : L'utilisateur essaie de router une option vers la mauvaise stratégie.

**Message** :

```
ERROR: Exceptions.IncorrectArgument: Routage d'option invalide

Option :backend routée vers :ipopt mais cette option n'appartient pas
à cette stratégie.

Stratégies valides pour :backend : [:adnlp]

Utilisez la bonne stratégie :
  backend = (:sparse, :adnlp)

Context: route_options - validating strategy-specific option routing
```

**Éléments clés** :
- ✅ Option et stratégie incorrecte
- ✅ Stratégies valides
- ✅ Correction

## 5. Messages Routage - Mode Permissif

### 5.1 Erreur : Option Inconnue Sans Disambiguation

**Contexte** : En mode permissif, les options inconnues doivent être disambiguées.

**Message** :

```
ERROR: Exceptions.IncorrectArgument: Option inconnue doit être disambiguée

Option :unknown_opt n'est pas reconnue et n'est pas disambiguée.

En mode permissif, les options inconnues doivent utiliser la syntaxe
de disambiguation :
  unknown_opt = (value, :strategy_id)

Exemples pour votre méthode (:collocation, :adnlp, :ipopt) :
  unknown_opt = (123, :collocation)  # Router vers discretizer
  unknown_opt = (123, :adnlp)        # Router vers modeler
  unknown_opt = (123, :ipopt)        # Router vers solver

Options disponibles :
  discretizer (:collocation): :grid_size, :time_grid, :init_type
  modeler (:adnlp): :backend, :show_time, :matrix_free, :name
  solver (:ipopt): :max_iter, :tol, :print_level, :linear_solver

Context: route_options - permissive mode requires disambiguation
```

**Éléments clés** :
- ✅ Option non disambiguée
- ✅ Explication du requirement
- ✅ Syntaxe de disambiguation
- ✅ Exemples pour chaque stratégie
- ✅ Options disponibles pour référence

### 5.2 Warning : Option Inconnue Disambiguée Acceptée

**Contexte** : L'utilisateur a correctement disambigué une option inconnue.

**Message** :

```
┌ Warning: Option non reconnue routée vers la stratégie
│ 
│ Option :unknown_opt n'est pas dans les metadata de :ipopt
│ mais sera transmise au backend.
│ 
│ Assurez-vous que cette option est valide pour Ipopt.
│ 
│ Pour supprimer cet avertissement, ajoutez cette option aux metadata
│ de IpoptSolver.
└ @ CTSolvers.Orchestration ~/.julia/dev/CTSolvers/src/Orchestration/routing.jl:XX
```

**Éléments clés** :
- ⚠️ Option et stratégie cible
- ⚠️ Confirmation de transmission
- ⚠️ Responsabilité utilisateur
- ⚠️ Comment supprimer le warning

### 5.3 Erreur : Option Ambiguë (même en mode permissif)

**Contexte** : Les options ambiguës nécessitent disambiguation dans les deux modes.

**Message** : Identique au message 4.2 (mode strict).

**Justification** : L'ambiguïté doit toujours être résolue explicitement.

## 6. Messages d'Aide et Documentation

### 6.1 Message d'Aide : Modes Strict/Permissif

**Contexte** : L'utilisateur demande de l'aide sur les modes.

**Commande** : `?strict` ou dans la documentation

**Message** :

```
Modes de Validation des Options
================================

CTSolvers propose deux modes de validation des options :

MODE STRICT (par défaut)
------------------------
- Rejette les options inconnues des metadata
- Détecte les erreurs de typo
- Recommandé pour la plupart des utilisateurs

Exemple :
  solver = IpoptSolver(max_iter=1000)  # OK
  solver = IpoptSolver(unknown=123)    # ❌ Erreur

MODE PERMISSIF
--------------
- Accepte les options inconnues avec warning
- Transmet les options au backend sans validation
- Pour utilisateurs avancés uniquement

Exemple :
  solver = IpoptSolver(
      max_iter=1000,
      custom_ipopt_option=123;
      strict=false  # Active le mode permissif
  )  # ⚠️ Warning mais accepté

QUAND UTILISER LE MODE PERMISSIF ?
-----------------------------------
- Options backend non documentées dans CTSolvers
- Options expérimentales récentes
- Debugging avec options de log backend
- Recherche académique avec options spéciales

ATTENTION
---------
En mode permissif, CTSolvers ne valide pas les options inconnues.
Des erreurs peuvent survenir au niveau du backend.

Pour plus d'informations : https://control-toolbox.org/docs/options
```

### 6.2 Message d'Aide : Disambiguation

**Contexte** : L'utilisateur demande de l'aide sur la disambiguation.

**Message** :

```
Syntaxe de Disambiguation des Options
======================================

Quand une option existe dans plusieurs stratégies, vous devez
spécifier explicitement quelle stratégie doit la recevoir.

SYNTAXE DE BASE
---------------
  option_name = (value, :strategy_id)

EXEMPLES
--------
# Option backend existe dans modeler et solver
solve(ocp, :collocation, :adnlp, :ipopt;
    backend = (:sparse, :adnlp)  # Pour le modeler uniquement
)

# Définir pour plusieurs stratégies
solve(ocp, :collocation, :adnlp, :ipopt;
    backend = ((:sparse, :adnlp), (:cpu, :ipopt))
)

MODE PERMISSIF
--------------
En mode permissif, les options inconnues DOIVENT être disambiguées :

solve(ocp, :collocation, :adnlp, :ipopt;
    custom_option = (value, :ipopt);  # Obligatoire
    strict = false
)

Pour plus d'informations : https://control-toolbox.org/docs/disambiguation
```

## 7. Exemples Complets de Scénarios

### 7.1 Scénario : Typo dans le Nom d'Option (Mode Strict)

**Code utilisateur** :

```julia
solver = IpoptSolver(max_it=1000)  # Typo: max_it au lieu de max_iter
```

**Message** :

```
ERROR: Exceptions.IncorrectArgument: Options inconnues fournies

Options non reconnues : [:max_it]

Ces options ne sont pas définies dans les metadata de IpoptSolver.

Options disponibles :
  :max_iter, :tol, :print_level, ...

Suggestions pour :max_it :
  - :max_iter (distance: 2) ← Probablement ce que vous vouliez

Si vous êtes certain que cette option existe pour le backend Ipopt,
utilisez le mode permissif :
  IpoptSolver(...; strict=false)

Context: build_strategy_options - strict validation
```

**Résolution** : Corriger le typo → `max_iter=1000`

### 7.2 Scénario : Option Backend Avancée (Mode Permissif)

**Code utilisateur** :

```julia
solver = IpoptSolver(
    max_iter=1000,
    mehrotra_algorithm="yes";  # Option Ipopt non documentée
    strict=false
)
```

**Messages** :

```
┌ Warning: Options non reconnues transmises au backend
│ 
│ Options non validées : [:mehrotra_algorithm]
│ 
│ Ces options seront transmises directement au backend de IpoptSolver
│ sans validation par CTSolvers. Assurez-vous qu'elles sont correctes.
└ @ CTSolvers.Strategies ...
```

**Résultat** : ✅ Solver créé, option transmise à Ipopt

### 7.3 Scénario : Option Ambiguë (Mode Strict)

**Code utilisateur** :

```julia
solve(ocp, :collocation, :adnlp, :ipopt;
    backend=:sparse  # Ambiguë entre adnlp et ipopt
)
```

**Message** :

```
ERROR: Exceptions.IncorrectArgument: Option ambiguë nécessite disambiguation

Option :backend est ambiguë entre les stratégies : :adnlp, :ipopt

Disambiguez en spécifiant l'ID de la stratégie :
  backend = (:sparse, :adnlp)    # Router vers modeler
  backend = (:cpu, :ipopt)       # Router vers solver

Context: route_options - ambiguous option resolution
```

**Résolution** : Ajouter disambiguation → `backend=(:sparse, :adnlp)`

### 7.4 Scénario : Option Inconnue avec Disambiguation (Mode Permissif)

**Code utilisateur** :

```julia
solve(ocp, :collocation, :adnlp, :ipopt;
    custom_ipopt_debug=(true, :ipopt);
    strict=false
)
```

**Messages** :

```
┌ Warning: Option non reconnue routée vers la stratégie
│ 
│ Option :custom_ipopt_debug n'est pas dans les metadata de :ipopt
│ mais sera transmise au backend.
│ 
│ Assurez-vous que cette option est valide pour Ipopt.
└ @ CTSolvers.Orchestration ...
```

**Résultat** : ✅ Option routée vers IpoptSolver et transmise

### 7.5 Scénario : Option Inconnue Sans Disambiguation (Mode Permissif)

**Code utilisateur** :

```julia
solve(ocp, :collocation, :adnlp, :ipopt;
    custom_option=123;  # Pas de disambiguation
    strict=false
)
```

**Message** :

```
ERROR: Exceptions.IncorrectArgument: Option inconnue doit être disambiguée

Option :custom_option n'est pas reconnue et n'est pas disambiguée.

En mode permissif, les options inconnues doivent utiliser la syntaxe
de disambiguation :
  custom_option = (value, :strategy_id)

Exemples pour votre méthode (:collocation, :adnlp, :ipopt) :
  custom_option = (123, :ipopt)  # Router vers solver

Context: route_options - permissive mode requires disambiguation
```

**Résolution** : Ajouter disambiguation → `custom_option=(123, :ipopt)`

## 8. Checklist de Qualité des Messages

Avant de finaliser un message d'erreur ou warning, vérifier :

- [ ] Le message identifie clairement le problème
- [ ] Le message explique pourquoi c'est un problème
- [ ] Le message fournit une solution concrète
- [ ] Le message inclut des exemples si pertinent
- [ ] Le message indique le contexte technique
- [ ] Le message utilise un langage clair et précis
- [ ] Le message évite le jargon technique inutile
- [ ] Le message est formaté pour la lisibilité
- [ ] Le message inclut des suggestions basées sur similarité (si applicable)
- [ ] Le message guide vers la documentation si nécessaire

## 9. Implémentation Technique

### 9.1 Utilisation de `Exceptions.IncorrectArgument`

Tous les messages d'erreur utilisent l'exception enrichie :

```julia
throw(Exceptions.IncorrectArgument(
    "Titre court de l'erreur",
    got="ce que l'utilisateur a fourni",
    expected="ce qui était attendu",
    suggestion="message détaillé avec solution",
    context="fonction - contexte technique"
))
```

### 9.2 Utilisation de `@warn`

Les warnings utilisent le système de logging Julia :

```julia
@warn """
Titre du warning

Corps du message
avec plusieurs lignes
si nécessaire.
"""
```

### 9.3 Formatage des Messages

**Conventions** :
- Utiliser des listes à puces pour les énumérations
- Indenter les exemples de code
- Séparer les sections avec des lignes vides
- Utiliser des émojis sparingly (✅, ❌, ⚠️) pour la clarté visuelle
- Limiter la largeur des lignes à ~80 caractères

## 10. Internationalisation (Future)

**Note** : Les messages sont actuellement en français. Pour l'internationalisation future :

- Extraire les messages dans des fichiers de ressources
- Utiliser des clés symboliques
- Supporter anglais et français au minimum
- Détecter la locale de l'utilisateur

**Exemple de structure** :

```julia
const MESSAGES = Dict(
    :fr => Dict(
        :unknown_options_strict => "Options inconnues fournies",
        # ...
    ),
    :en => Dict(
        :unknown_options_strict => "Unknown options provided",
        # ...
    )
)
```

Cette fonctionnalité n'est pas prioritaire pour la v1 mais doit être considérée dans le design.
