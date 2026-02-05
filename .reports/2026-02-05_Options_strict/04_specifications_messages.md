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
ERROR: Exceptions.IncorrectArgument: Unknown options provided

Unrecognized options: [:unknown_opt, :another_opt]

These options are not defined in the metadata of IpoptSolver.

Available options:
  :max_iter, :tol, :print_level, :linear_solver, :mu_strategy,
  :dual_inf_tol, :constr_viol_tol, :max_wall_time, :max_cpu_time,
  :timing_statistics, :print_timing_statistics, :print_frequency_iter,
  :print_frequency_time, :sb

Suggestions for :unknown_opt:
  - :max_iter (Levenshtein distance: 5)
  - :max_wall_time (distance: 7)

If you are certain these options exist for the Ipopt backend,
use permissive mode:
  IpoptSolver(...; mode=:permissive)

Context: build_strategy_options - strict validation
```

**Éléments clés** :
- ✅ List of unknown options
- ✅ Complete available options
- ✅ Similarity-based suggestions
- ✅ Solution (permissive mode)
- ✅ Technical context

### 2.2 Erreur : Type Incorrect (même en mode permissif)

**Contexte** : L'utilisateur passe une option connue avec un mauvais type.

**Message** :

```
ERROR: Exceptions.IncorrectArgument: Incorrect type for option

Option :max_iter has value "1000" of type String.

Expected type: Integer

This option is validated even in permissive mode because it is defined
in the metadata of IpoptSolver.

Suggestion: Use an integer: max_iter=1000

Context: Options.extract_option - type validation
```

**Éléments clés** :
- ✅ Concerned option
- ✅ Provided value and type
- ✅ Expected type
- ✅ Behavior explanation
- ✅ Solution

### 2.3 Erreur : Validation Échouée

**Contexte** : L'utilisateur passe une valeur qui échoue la validation custom.

**Message** :

```
ERROR: Exceptions.IncorrectArgument: Validation failed for option

Option :tol has value -0.001

Validation error: tol must be positive (> 0)

Custom validators are applied even in permissive mode for
options defined in the metadata.

Suggestion: Use a positive value, e.g., : tol=1e-6

Context: Options.extract_option - custom validation
```

**Éléments clés** :
- ✅ Option and value
- ✅ Validator message
- ✅ Explanation
- ✅ Suggestion

## 3. Messages Constructeur - Mode Permissif

### 3.1 Warning : Options Non Validées

**Contexte** : L'utilisateur passe des options inconnues en mode permissif.

**Message** :

```
┌ Warning: Unrecognized options passed to backend
│ 
│ Unvalidated options: [:unknown_opt, :another_opt]
│ 
│ These options will be passed directly to the IpoptSolver backend
│ without validation by CTSolvers. Ensure they are correct.
│ 
│ To disable this warning, define these options in the metadata.
└ @ CTSolvers.Strategies ~/.julia/dev/CTSolvers/src/Strategies/api/configuration.jl:XX
```

**Éléments clés** :
- ⚠️ Warning nature (non-blocking)
- ⚠️ List of unvalidated options
- ⚠️ Transmission explanation
- ⚠️ How to disable (add to metadata)

### 3.2 Info : Options Validées et Non Validées

**Contexte** : Confirmation que le constructeur a accepté les options.

**Message** (optionnel, via logging) :

```
┌ Info: IpoptSolver created successfully
│ 
│ Validated options: [:max_iter, :tol, :print_level]
│ Unvalidated options: [:unknown_opt] (permissive mode)
│ 
│ Unvalidated options will be passed to the Ipopt backend.
└ @ CTSolvers.Solvers ~/.julia/dev/CTSolvers/ext/CTSolversIpopt.jl:XX
```

**Note** : Ce message info est optionnel et peut être activé via un flag de debug.

## 4. Messages Routage - Mode Strict

### 4.1 Erreur : Option Inconnue (0 owners)

**Contexte** : L'utilisateur passe une option qui n'appartient à aucune stratégie.

**Message** :

```
ERROR: Exceptions.IncorrectArgument: Unknown option provided

Option :unknown_opt belongs to no strategy in the method
(:collocation, :adnlp, :ipopt).

Available options:
  discretizer (:collocation):
    :grid_size, :time_grid, :init_type
  modeler (:adnlp):
    :backend, :show_time, :matrix_free, :name
  solver (:ipopt):
    :max_iter, :tol, :print_level, :linear_solver, :mu_strategy

If you are certain this option exists for a specific strategy,
use permissive mode with disambiguation:
  solve(...; unknown_opt=(value, :ipopt), mode=:permissive)

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
ERROR: Exceptions.IncorrectArgument: Ambiguous option requires disambiguation

Option :backend is ambiguous between strategies: :adnlp, :ipopt

Disambiguate by specifying the strategy ID:

  backend = (:sparse, :adnlp)    # Route to modeler
  backend = (:cpu, :ipopt)       # Route to solver

Or define for multiple strategies:
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
ERROR: Exceptions.IncorrectArgument: Invalid option routing

Option :backend routed to :ipopt but this option does not belong
to this strategy.

Valid strategies for :backend: [:adnlp]

Use the correct strategy:
  backend = (:sparse, :adnlp)

Context: route_options - validating strategy-specific option routing
```

**Éléments clés** :
- ✅ Incorrect option and strategy
- ✅ Valid strategies
- ✅ Correction

## 5. Messages Routage - Mode Permissif

### 5.1 Erreur : Option Inconnue Sans Disambiguation

**Contexte** : En mode permissif, les options inconnues doivent être disambiguées.

**Message** :

```
ERROR: Exceptions.IncorrectArgument: Unknown option must be disambiguated

Option :unknown_opt is not recognized and is not disambiguated.

In permissive mode, unknown options must use disambiguation syntax:
  unknown_opt = (value, :strategy_id)

Examples for your method (:collocation, :adnlp, :ipopt):
  unknown_opt = (123, :collocation)  # Route to discretizer
  unknown_opt = (123, :adnlp)        # Route to modeler
  unknown_opt = (123, :ipopt)        # Route to solver

Available options:
  discretizer (:collocation): :grid_size, :time_grid, :init_type
  modeler (:adnlp): :backend, :show_time, :matrix_free, :name
  solver (:ipopt): :max_iter, :tol, :print_level, :linear_solver

Context: route_options - permissive mode requires disambiguation
```

**Éléments clés** :
- ✅ Undisambiguated option
- ✅ Requirement explanation
- ✅ Disambiguation syntax
- ✅ Examples for each strategy
- ✅ Available options for reference

### 5.2 Warning : Option Inconnue Disambiguée Acceptée

**Contexte** : L'utilisateur a correctement disambigué une option inconnue.

**Message** :

```
┌ Warning: Unrecognized option routed to strategy
│ 
│ Option :unknown_opt is not in the metadata of :ipopt
│ but will be passed to the backend.
│ 
│ Ensure this option is valid for Ipopt.
│ 
│ To remove this warning, add this option to the metadata
│ of IpoptSolver.
└ @ CTSolvers.Orchestration ~/.julia/dev/CTSolvers/src/Orchestration/routing.jl:XX
```

**Éléments clés** :
- ⚠️ Option and target strategy
- ⚠️ Transmission confirmation
- ⚠️ User responsibility
- ⚠️ How to remove warning

### 5.3 Erreur : Option Ambiguë (même en mode permissif)

**Contexte** : Les options ambiguës nécessitent disambiguation dans les deux modes.

**Message** : Identique au message 4.2 (mode strict).

**Justification** : L'ambiguïté doit toujours être résolue explicitement.

## 6. Messages d'Aide et Documentation

### 6.1 Message d'Aide : Modes Strict/Permissif

**Contexte** : L'utilisateur demande de l'aide sur les modes.

**Command** : `?strict` or in the documentation

**Message** :

```
Option Validation Modes
======================

CTSolvers provides two option validation modes:

STRICT MODE (default)
---------------------
- Rejects unknown options from metadata
- Detects typo errors
- Recommended for most users

Example:
  solver = IpoptSolver(max_iter=1000)  # OK
  solver = IpoptSolver(unknown=123)    # ❌ Error

PERMISSIVE MODE
----------------
- Accepts unknown options with warning
- Passes options to backend without validation
- For advanced users only

Example:
  solver = IpoptSolver(
      max_iter=1000,
      custom_ipopt_option=123;
      mode=:permissive  # Enable permissive mode
  )  # ⚠️ Warning but accepted

WHEN TO USE PERMISSIVE MODE?
-------------------------------
- Backend options not documented in CTSolvers
- Recent experimental options
- Debugging with backend log options
- Academic research with special options

CAUTION
--------
In permissive mode, CTSolvers does not validate unknown options.
Errors may occur at the backend level.

For more information: https://control-toolbox.org/docs/options
```

### 6.2 Help Message : Disambiguation

**Context** : The user requests help on disambiguation.
**Contexte** : L'utilisateur demande de l'aide sur la disambiguation.

**Message** :

```
Option Disambiguation Syntax
=============================

When an option exists in multiple strategies, you must
explicitly specify which strategy should receive it.

BASIC SYNTAX
------------
  option_name = (value, :strategy_id)

EXAMPLES
--------
# Backend option exists in modeler and solver
solve(ocp, :collocation, :adnlp, :ipopt;
    backend = (:sparse, :adnlp)  # For modeler only
)

# Define for multiple strategies
solve(ocp, :collocation, :adnlp, :ipopt;
    backend = ((:sparse, :adnlp), (:cpu, :ipopt))
)

PERMISSIVE MODE
---------------
In permissive mode, unknown options MUST be disambiguated:

solve(ocp, :collocation, :adnlp, :ipopt;
    custom_option = (value, :ipopt);  # Mandatory
    mode = :permissive
)

For more information: https://control-toolbox.org/docs/disambiguation
```

## 7. Exemples Complets de Scénarios

### 7.1 Scénario : Typo dans le Nom d'Option (Mode Strict)

**Code utilisateur** :

```julia
solver = IpoptSolver(max_it=1000)  # Typo: max_it au lieu de max_iter
```

**Message** :

```
ERROR: Exceptions.IncorrectArgument: Unknown options provided

Unrecognized options: [:max_it]

These options are not defined in the metadata of IpoptSolver.

Available options:
  :max_iter, :tol, :print_level, ...

Suggestions for :max_it:
  - :max_iter (distance: 2) ← Probably what you wanted

If you are certain this option exists for the Ipopt backend,
use permissive mode:
  IpoptSolver(...; mode=:permissive)

Context: build_strategy_options - strict validation
```

**Résolution** : Fix typo → `max_iter=1000`

### 7.2 Scénario : Option Backend Avancée (Mode Permissif)

**Code utilisateur** :

```julia
solver = IpoptSolver(
    max_iter=1000,
    mehrotra_algorithm="yes";  # Option Ipopt non documentée
    mode=:permissive
)
```

**Messages** :

```
┌ Warning: Unrecognized options passed to backend
│ 
│ Unvalidated options: [:mehrotra_algorithm]
│ 
│ These options will be passed directly to the IpoptSolver backend
│ without validation by CTSolvers. Ensure they are correct.
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
ERROR: Exceptions.IncorrectArgument: Ambiguous option requires disambiguation

Option :backend is ambiguous between strategies: :adnlp, :ipopt

Disambiguate by specifying the strategy ID:
  backend = (:sparse, :adnlp)    # Route to modeler
  backend = (:cpu, :ipopt)       # Route to solver

Context: route_options - ambiguous option resolution
```

**Résolution** : Add disambiguation → `backend=(:sparse, :adnlp)`

### 7.4 Scénario : Option Inconnue avec Disambiguation (Mode Permissif)

**Code utilisateur** :

```julia
solve(ocp, :collocation, :adnlp, :ipopt;
    custom_ipopt_debug=(true, :ipopt);
    mode=:permissive
)
```

**Messages** :

```
┌ Warning: Unrecognized option routed to strategy
│ 
│ Option :custom_ipopt_debug is not in the metadata of :ipopt
│ but will be passed to the backend.
│ 
│ Ensure this option is valid for Ipopt.
└ @ CTSolvers.Orchestration ...
```

**Résultat** : ✅ Option routée vers IpoptSolver et transmise

### 7.5 Scénario : Option Inconnue Sans Disambiguation (Mode Permissif)

**Code utilisateur** :

```julia
solve(ocp, :collocation, :adnlp, :ipopt;
    custom_option=123;  # Pas de disambiguation
    mode=:permissive
)
```

**Message** :

```
ERROR: Exceptions.IncorrectArgument: Unknown option must be disambiguated

Option :custom_option is not recognized and is not disambiguated.

In permissive mode, unknown options must use disambiguation syntax:
  custom_option = (value, :strategy_id)

Examples for your method (:collocation, :adnlp, :ipopt):
  custom_option = (123, :ipopt)  # Route to solver

Context: route_options - permissive mode requires disambiguation
```

**Résolution** : Add disambiguation → `custom_option=(123, :ipopt)`

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
    "Short error title",
    got="what the user provided",
    expected="what was expected",
    suggestion="detailed message with solution",
    context="function - technical context"
))
```

### 9.2 Utilisation de `@warn`

Les warnings utilisent le système de logging Julia :

```julia
@warn """
Warning title

Message body
with multiple lines
if necessary.
"""
```

### 9.3 Formatage des Messages

**Conventions**:
- Use bullet points for enumerations
- Indent code examples
- Separate sections with blank lines
- Use emojis sparingly (✅, ❌, ⚠️) for visual clarity
- Limit line width to ~80 characters

## 10. Internationalisation (Future)

**Note**: Messages are currently in English. For future internationalization:

- Extract messages to resource files
- Use symbolic keys
- Support English and French at minimum
- Detect user locale

**Example structure**:

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

This feature is not a priority for v1 but should be considered in the design.
