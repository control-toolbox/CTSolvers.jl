# Analyse Détaillée : Contexte et Motivation

## 1. Situation Actuelle

### 1.1 Comportement du Système

CTSolvers implémente actuellement une validation **stricte** des options à deux niveaux :

#### Niveau Constructeur de Stratégies

**Fichier** : `src/Strategies/api/configuration.jl`

```julia
function build_strategy_options(
    strategy_type::Type{<:AbstractStrategy};
    kwargs...
)
    meta = metadata(strategy_type)
    defs = collect(values(meta.specs))
    
    # Use Options.extract_options for validation and extraction
    extracted, _ = Options.extract_options((; kwargs...), defs)
    
    # Convert Dict to NamedTuple
    nt = (; (k => v for (k, v) in extracted)...)
    
    return StrategyOptions(nt)
end
```

**Comportement** : La fonction `Options.extract_options()` retourne `(extracted, remaining)` où :
- `extracted` : Options reconnues et validées
- `remaining` : Options non reconnues (actuellement ignorées)

**Problème** : Les options dans `remaining` sont silencieusement ignorées. L'utilisateur ne sait pas si son option a été prise en compte ou non.

#### Niveau Routage (Orchestration)

**Fichier** : `src/Orchestration/routing.jl`

```julia
function route_all_options(...)
    # ...
    for (key, raw_val) in pairs(remaining_kwargs)
        owners = get(option_owners, key, Set{Symbol}())
        
        if isempty(owners)
            # Unknown option - provide helpful error
            _error_unknown_option(key, method, families, ...)
        elseif length(owners) == 1
            # Unambiguous - auto-route
            push!(routed[family_name], key => value)
        else
            # Ambiguous - need disambiguation
            _error_ambiguous_option(key, value, owners, ...)
        end
    end
end
```

**Comportement** : 
- Option avec 0 owners → **Erreur immédiate**
- Option ambiguë sans disambiguation → **Erreur immédiate**

### 1.2 Limitations Identifiées

#### Limitation 1 : Options Backend Non Documentées

**Problème** : Les backends (Ipopt, MadNLP, etc.) ont des centaines d'options. CTSolvers ne peut pas toutes les documenter dans les metadata.

**Exemple concret** : 
```julia
# Ipopt a ~200 options, CTSolvers en documente ~15
solver = IpoptSolver(
    max_iter = 1000,        # ✅ Documenté
    tol = 1e-6,             # ✅ Documenté
    mehrotra_algorithm = "yes"  # ❌ Non documenté → Ignoré silencieusement
)
```

**Impact** : L'utilisateur avancé ne peut pas utiliser toutes les capacités d'Ipopt.

#### Limitation 2 : Options Expérimentales

**Problème** : Les backends ajoutent régulièrement de nouvelles options expérimentales. CTSolvers ne peut pas suivre en temps réel.

**Exemple** :
```julia
# Nouvelle option MadNLP v0.8 non encore dans CTSolvers
solver = MadNLPSolver(
    experimental_feature = true  # ❌ Rejeté
)
```

#### Limitation 3 : Options Spécifiques à une Version

**Problème** : Certaines options n'existent que dans certaines versions des backends.

**Exemple** :
```julia
# Option disponible uniquement dans Ipopt >= 3.14
solver = IpoptSolver(
    nlp_scaling_constr_target_gradient = 0.0  # ❌ Peut être rejeté
)
```

### 1.3 Cas d'Usage Motivants

#### Cas 1 : Recherche Académique

**Contexte** : Un chercheur veut tester une nouvelle option Ipopt pour un article.

**Besoin** : Passer l'option sans attendre une mise à jour de CTSolvers.

**Solution actuelle** : Impossible ou nécessite modification du code source.

**Solution proposée** :
```julia
solver = IpoptSolver(
    max_iter = 1000,
    experimental_option = value;
    strict = false  # Mode permissif
)
```

#### Cas 2 : Tuning Avancé

**Contexte** : Un utilisateur expert veut optimiser finement les performances du solver.

**Besoin** : Accéder à toutes les options du backend, pas seulement celles documentées.

**Solution actuelle** : Limité aux options documentées dans CTSolvers.

**Solution proposée** :
```julia
solve(ocp, :collocation, :adnlp, :ipopt;
    # Options CTSolvers (validées)
    max_iter = 1000,
    tol = 1e-6,
    
    # Options Ipopt avancées (non validées)
    mu_strategy = ("adaptive", :ipopt),
    alpha_for_y = ("primal", :ipopt);
    
    strict = false
)
```

#### Cas 3 : Debugging Backend

**Contexte** : Un développeur veut activer des options de debug du backend.

**Besoin** : Passer des options de logging/profiling non documentées.

**Solution actuelle** : Modification du code source ou wrapper externe.

**Solution proposée** :
```julia
solver = IpoptSolver(
    print_timing_statistics = "yes",
    timing_statistics = "yes",
    debug_option = true;  # Option de debug non documentée
    strict = false
)
```

## 2. Analyse des Besoins

### 2.1 Exigences Fonctionnelles

#### EF1 : Mode Strict par Défaut

**Description** : Le comportement par défaut doit rester strict pour la sécurité.

**Justification** : 
- Détecte les erreurs de typo (ex: `max_it` au lieu de `max_iter`)
- Protège contre les options obsolètes
- Maintient la rétrocompatibilité

**Critère d'acceptation** :
```julia
# Sans spécifier strict, comportement actuel
solver = IpoptSolver(unknown_opt = 123)  # ❌ Erreur
```

#### EF2 : Mode Permissif Optionnel

**Description** : L'utilisateur peut activer le mode permissif explicitement.

**Justification** : Flexibilité pour utilisateurs avancés.

**Critère d'acceptation** :
```julia
# Avec strict=false, accepte les options inconnues
solver = IpoptSolver(unknown_opt = 123; strict = false)  # ✅ Warning + OK
```

#### EF3 : Validation Partielle en Mode Permissif

**Description** : Les options connues sont toujours validées, même en mode permissif.

**Justification** : Maintenir la qualité des options documentées.

**Critère d'acceptation** :
```julia
# Option connue avec mauvais type → Erreur même en mode permissif
solver = IpoptSolver(max_iter = "1000"; strict = false)  # ❌ Erreur de type
```

#### EF4 : Transmission Automatique

**Description** : Les options non validées sont automatiquement transmises au backend.

**Justification** : Pas de code supplémentaire nécessaire dans les extensions.

**Critère d'acceptation** :
```julia
solver = IpoptSolver(custom_opt = 123; strict = false)
options = Strategies.options_dict(solver)
@test options[:custom_opt] == 123  # ✅ Présent dans le dict
```

#### EF5 : Disambiguation Obligatoire au Routage

**Description** : En mode permissif, les options inconnues doivent être disambiguées.

**Justification** : Éviter les erreurs de routage silencieuses.

**Critère d'acceptation** :
```julia
# Sans disambiguation → Erreur
solve(ocp, method; unknown_opt = 123, strict = false)  # ❌ Erreur

# Avec disambiguation → OK
solve(ocp, method; unknown_opt = (123, :ipopt), strict = false)  # ✅ OK
```

### 2.2 Exigences Non Fonctionnelles

#### ENF1 : Performance

**Exigence** : Impact négligeable sur les performances.

**Mesure** : 
- Mode strict : 0% overhead (comportement actuel)
- Mode permissif : < 1% overhead

**Justification** : La validation d'options n'est pas dans le chemin critique.

#### ENF2 : Rétrocompatibilité

**Exigence** : Aucun breaking change.

**Mesure** : Tous les tests existants passent sans modification.

**Justification** : Le mode strict est le défaut.

#### ENF3 : Maintenabilité

**Exigence** : Code clair et bien testé.

**Mesure** : 
- Couverture de tests > 95%
- Documentation complète
- Architecture modulaire

#### ENF4 : Extensibilité

**Exigence** : Facile d'ajouter de nouveaux modes de validation à l'avenir.

**Mesure** : Architecture permettant l'ajout de modes personnalisés.

### 2.3 Messages Utilisateur

#### Principe 1 : Clarté

Les messages doivent être **immédiatement compréhensibles** par l'utilisateur.

**Mauvais** :
```
ERROR: KeyError: unknown_opt
```

**Bon** :
```
ERROR: Option inconnue 'unknown_opt'
Cette option n'est pas définie dans les metadata de IpoptSolver.
Suggestions : max_iter, max_wall_time
Pour utiliser une option backend non documentée : strict=false
```

#### Principe 2 : Guidance

Les messages doivent **guider vers la solution**.

**Mauvais** :
```
ERROR: Invalid option
```

**Bon** :
```
ERROR: Option inconnue et non disambiguée en mode permissif
Utilisez la syntaxe : unknown_opt = (value, :ipopt)
```

#### Principe 3 : Contexte

Les messages doivent **fournir le contexte** de l'erreur.

**Inclure** :
- Quelle option pose problème
- Pourquoi c'est un problème
- Comment le résoudre
- Options disponibles (si pertinent)

## 3. Analyse de l'Existant

### 3.1 Flux Actuel des Options

#### Constructeur Direct

```
Utilisateur
    ↓ IpoptSolver(max_iter=1000, unknown=123)
build_ipopt_solver(IpoptTag(); kwargs...)
    ↓
build_strategy_options(IpoptSolver; kwargs...)
    ↓
Options.extract_options(kwargs, defs)
    ↓ (extracted, remaining)
StrategyOptions(extracted)  ← remaining est ignoré ❌
```

#### Via solve()

```
Utilisateur
    ↓ solve(ocp, :collocation, :adnlp, :ipopt; max_iter=1000, unknown=123)
route_all_options(method, families, action_defs, kwargs, registry)
    ↓
Options.extract_options(kwargs, action_defs)  # Extrait action options
    ↓ (action_options, remaining_kwargs)
Pour chaque (key, value) in remaining_kwargs:
    owners = option_owners[key]
    if isempty(owners):
        _error_unknown_option()  ← Erreur immédiate ❌
    elif length(owners) == 1:
        route to family
    else:
        _error_ambiguous_option()  ← Erreur immédiate ❌
```

### 3.2 Points d'Intervention

Pour implémenter le mode strict/permissif, il faut intervenir à :

1. **`build_strategy_options()`** : Gérer `remaining` au lieu de l'ignorer
2. **`route_all_options()`** : Accepter options disambiguées même si inconnues
3. **Propagation** : Transmettre le paramètre `strict` à travers la chaîne

### 3.3 Code Existant à Modifier

#### Fichiers Principaux

1. `src/Strategies/api/configuration.jl`
   - `build_strategy_options()` : Ajouter paramètre `strict`

2. `src/Orchestration/routing.jl`
   - `route_all_options()` : Ajouter paramètre `strict`
   - `_error_unknown_option()` : Adapter le message

3. `src/Orchestration/method_builders.jl`
   - `build_strategy_from_method()` : Propager `strict`

4. `src/Strategies/api/builders.jl`
   - `build_strategy()` : Propager `strict`

5. `src/Strategies/contract/strategy_options.jl`
   - Potentiellement ajouter champ pour options non validées

#### Fichiers à Créer

1. Tests :
   - `test/suite/strategies/test_validation_strict.jl`
   - `test/suite/strategies/test_validation_permissive.jl`
   - `test/suite/orchestration/test_routing_strict.jl`
   - `test/suite/orchestration/test_routing_permissive.jl`
   - `test/suite/integration/test_strict_permissive_integration.jl`

2. Documentation :
   - Guide utilisateur sur les modes
   - Exemples d'utilisation

## 4. Risques et Mitigation

### 4.1 Risques Techniques

#### Risque 1 : Transmission d'Options Invalides au Backend

**Description** : En mode permissif, l'utilisateur peut passer des options invalides qui feront crasher le backend.

**Probabilité** : Moyenne

**Impact** : Moyen (erreur runtime)

**Mitigation** :
- Warning clair en mode permissif
- Documentation des risques
- Message d'erreur du backend sera visible

#### Risque 2 : Conflits de Noms

**Description** : Une option non validée pourrait avoir le même nom qu'une option interne.

**Probabilité** : Faible

**Impact** : Élevé (comportement imprévisible)

**Mitigation** :
- Les options validées ont priorité
- Documentation claire de la priorité
- Tests de non-régression

#### Risque 3 : Overhead de Performance

**Description** : Le stockage et la transmission d'options supplémentaires pourrait ralentir le système.

**Probabilité** : Très faible

**Impact** : Faible

**Mitigation** :
- Benchmarks avant/après
- Mode strict (défaut) non impacté

### 4.2 Risques Utilisateur

#### Risque 4 : Confusion sur les Modes

**Description** : L'utilisateur ne comprend pas quand utiliser strict vs permissif.

**Probabilité** : Moyenne

**Impact** : Moyen (mauvaise utilisation)

**Mitigation** :
- Documentation claire avec exemples
- Messages d'erreur pédagogiques
- Mode strict par défaut (safe)

#### Risque 5 : Abus du Mode Permissif

**Description** : L'utilisateur utilise systématiquement le mode permissif par facilité.

**Probabilité** : Faible

**Impact** : Moyen (perte de validation)

**Mitigation** :
- Warning à chaque utilisation
- Documentation des bonnes pratiques
- Exemples montrant quand utiliser chaque mode

### 4.3 Risques Projet

#### Risque 6 : Complexité Accrue

**Description** : Le code devient plus complexe avec deux modes.

**Probabilité** : Certaine

**Impact** : Moyen

**Mitigation** :
- Architecture claire et modulaire
- Tests exhaustifs
- Documentation du design

#### Risque 7 : Maintenance

**Description** : Plus de code à maintenir et tester.

**Probabilité** : Certaine

**Impact** : Faible

**Mitigation** :
- Tests automatisés
- CI/CD
- Documentation technique

## 5. Alternatives Considérées

### Alternative 1 : Toujours Permissif

**Description** : Accepter toutes les options sans validation.

**Avantages** :
- Simple à implémenter
- Maximum de flexibilité

**Inconvénients** :
- Perte de sécurité
- Pas de détection de typo
- Breaking change majeur

**Décision** : ❌ Rejeté (perte de sécurité)

### Alternative 2 : Whitelist Utilisateur

**Description** : L'utilisateur fournit une liste d'options à accepter sans validation.

```julia
solver = IpoptSolver(
    unknown_opt = 123;
    allow_options = [:unknown_opt]
)
```

**Avantages** :
- Contrôle fin
- Explicite

**Inconvénients** :
- Verbeux
- Complexe pour l'utilisateur

**Décision** : ❌ Rejeté (trop complexe)

### Alternative 3 : Préfixe pour Options Non Validées

**Description** : Utiliser un préfixe pour marquer les options non validées.

```julia
solver = IpoptSolver(
    max_iter = 1000,
    raw_unknown_opt = 123  # Préfixe "raw_"
)
```

**Avantages** :
- Explicite
- Pas de paramètre supplémentaire

**Inconvénients** :
- Syntaxe non naturelle
- Incompatible avec noms d'options backend

**Décision** : ❌ Rejeté (syntaxe non naturelle)

### Alternative 4 : Mode Strict/Permissif (Retenu)

**Description** : Paramètre `strict::Bool` pour contrôler le mode.

**Avantages** :
- Simple et clair
- Rétrocompatible
- Flexible

**Inconvénients** :
- Paramètre à propager

**Décision** : ✅ **Retenu**

## 6. Conclusion de l'Analyse

### Points Clés

1. **Besoin réel** : Les utilisateurs avancés ont besoin d'accéder aux options backend non documentées
2. **Solution équilibrée** : Mode strict par défaut + mode permissif optionnel
3. **Risques maîtrisés** : Mitigation claire pour chaque risque identifié
4. **Implémentation faisable** : Architecture claire, modifications localisées

### Recommandation

**Procéder à l'implémentation** selon l'architecture détaillée dans les documents suivants.
