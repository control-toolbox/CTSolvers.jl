# Architecture Technique : Design et Implémentation

## 1. Vue d'Ensemble de l'Architecture

### 1.1 Principes de Design

#### Principe 1 : Rétrocompatibilité Totale

**Décision** : Le mode strict est le comportement par défaut.

**Justification** :
- Aucun breaking change pour le code existant
- Sécurité par défaut maintenue
- Migration progressive possible

**Implémentation** :
```julia
function build_strategy_options(
    strategy_type::Type{<:AbstractStrategy};
    mode::Symbol = :strict,  # ← Défaut strict
    kwargs...
)
```

#### Principe 2 : Propagation Explicite

**Décision** : Le paramètre `mode` se propage explicitement à travers la chaîne d'appels.

**Justification** :
- Traçabilité claire
- Pas d'état global
- Testabilité

**Implémentation** :
```julia
solve(...; mode=:permissive)
    ↓
route_all_options(...; mode=:permissive)
    ↓
build_strategy_from_method(...; mode=:permissive)
    ↓
build_strategy(...; mode=:permissive)
    ↓
build_strategy_options(...; mode=:permissive)
```

#### Principe 3 : Validation Partielle

**Décision** : Les options connues sont toujours validées, même en mode permissif.

**Justification** :
- Maintien de la qualité
- Détection des erreurs de type
- Cohérence

**Implémentation** :
```julia
# Mode permissif
extracted, remaining = Options.extract_options(kwargs, defs)
# extracted : validé (type, validator)
# remaining : non validé mais accepté
```

#### Principe 4 : Messages Pédagogiques

**Décision** : Les messages d'erreur guident vers la solution.

**Justification** :
- Meilleure expérience utilisateur
- Réduction du support
- Auto-documentation

### 1.2 Diagramme d'Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    API Utilisateur                          │
│  solve(ocp, method; options..., mode=:strict/false)         │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│              Orchestration Layer                            │
│  route_all_options(method, families, kwargs; mode)        │
│    ├─ Extract action options                                │
│    ├─ Build option ownership map                            │
│    └─ Route to families                                     │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│              Strategy Builders                              │
│  build_strategy_from_method(method, family, opts; mode)   │
│    └─ build_strategy(id, opts, registry; mode)            │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│              Strategy Configuration                         │
│  build_strategy_options(type; strict, kwargs...)            │
│    ├─ Extract known options (validated)                     │
│    ├─ Handle unknown options (strict vs permissive)         │
│    └─ Build StrategyOptions                                 │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│              Options Extraction                             │
│  Options.extract_options(kwargs, defs)                      │
│    └─ Returns (extracted, remaining)                        │
└─────────────────────────────────────────────────────────────┘
```

## 2. Modifications Détaillées par Composant

### 2.1 Strategies Module

#### Fichier : `src/Strategies/api/configuration.jl`

##### Fonction : `build_strategy_options()`

**Signature actuelle** :
```julia
function build_strategy_options(
    strategy_type::Type{<:AbstractStrategy};
    kwargs...
)
    meta = metadata(strategy_type)
    defs = collect(values(meta.specs))
    
    extracted, _ = Options.extract_options((; kwargs...), defs)
    
    nt = (; (k => v for (k, v) in extracted)...)
    
    return StrategyOptions(nt)
end
```

**Nouvelle signature** :
```julia
function build_strategy_options(
    strategy_type::Type{<:AbstractStrategy};
    mode::Symbol = :strict,
    kwargs...
)
    # Validate mode
    mode ∉ (:strict, :permissive) && throw(ArgumentError(
        "Invalid mode: $mode. Expected :strict or :permissive"
    ))
    
    meta = metadata(strategy_type)
    defs = collect(values(meta.specs))
    
    # Extract known options (always validated)
    extracted, remaining = Options.extract_options((; kwargs...), defs)
    
    # Handle unknown options based on mode
    if !isempty(remaining)
        if mode == :strict
            # STRICT MODE: Error with suggestions
            _error_unknown_options_strict(
                remaining, strategy_type, meta
            )
        else  # mode == :permissive
            # PERMISSIVE MODE: Warning and store
            _warn_unknown_options_permissive(
                remaining, strategy_type
            )
            # Add unvalidated options with special source :user_unvalidated
            # This allows tracking which options were not validated
            for (key, value) in pairs(remaining)
                extracted[key] = Options.OptionValue(value, :user_unvalidated)
            end
        end
    end
    
    # Convert to NamedTuple
    nt = (; (k => v for (k, v) in extracted)...)
    
    return StrategyOptions(nt)
end
```

**Nouvelles fonctions helper** :

```julia
"""
Error handler for unknown options in strict mode.
"""
function _error_unknown_options_strict(
    remaining::NamedTuple,
    strategy_type::Type{<:AbstractStrategy},
    meta::StrategyMetadata
)
    unknown_keys = collect(keys(remaining))
    strategy_name = string(nameof(strategy_type))
    
    # Get available options
    available = collect(keys(meta.specs))
    
    # Generate suggestions using Levenshtein distance
    suggestions = Dict{Symbol, Vector{Symbol}}()
    for key in unknown_keys
        suggestions[key] = suggest_options(key, strategy_type; max_suggestions=3)
    end
    
    # Build error message
    msg = "Options inconnues fournies pour $strategy_name\n\n"
    msg *= "Options non reconnues : $(unknown_keys)\n\n"
    msg *= "Ces options ne sont pas définies dans les metadata de $strategy_name.\n\n"
    msg *= "Options disponibles :\n"
    msg *= "  " * join(available, ", ") * "\n\n"
    
    if !isempty(suggestions)
        msg *= "Suggestions :\n"
        for (key, suggs) in suggestions
            if !isempty(suggs)
                msg *= "  Pour :$key → $(join(suggs, ", "))\n"
            end
        end
        msg *= "\n"
    end
    
    msg *= "Si vous êtes certain que ces options existent pour le backend,\n"
    msg *= "utilisez le mode permissif :\n"
    msg *= "  $strategy_name(...; mode=:permissive)"
    
    throw(Exceptions.IncorrectArgument(
        "Options inconnues fournies",
        got="options $(unknown_keys) pour $strategy_name",
        expected="options définies dans les metadata",
        suggestion=msg,
        context="build_strategy_options - strict validation"
    ))
end

"""
Warning handler for unknown options in permissive mode.
"""
function _warn_unknown_options_permissive(
    remaining::NamedTuple,
    strategy_type::Type{<:AbstractStrategy}
)
    unknown_keys = collect(keys(remaining))
    strategy_name = string(nameof(strategy_type))
    
    @warn """
    Options non reconnues transmises au backend
    
    Options non validées : $(unknown_keys)
    
    Ces options seront transmises directement au backend de $strategy_name
    sans validation par CTSolvers. Assurez-vous qu'elles sont correctes.
    
    Pour désactiver cet avertissement, définissez ces options dans les metadata.
    """
end
```

#### Fichier : `src/Strategies/contract/strategy_options.jl`

**Pas de modification structurelle nécessaire**.

Le type `StrategyOptions` peut rester inchangé :
```julia
struct StrategyOptions
    options::NamedTuple
end
```

Les options non validées sont stockées avec source `:user_unvalidated` dans le même `NamedTuple`.

**Justification** :
- Simplicité
- Pas de breaking change
- La distinction se fait via la source de l'`OptionValue`

### 2.2 Orchestration Module

#### Fichier : `src/Orchestration/routing.jl`

##### Fonction : `route_all_options()`

**Modifications** :

1. Ajouter paramètre `mode::Symbol = true`
2. Modifier la gestion des options avec 0 owners
3. Accepter les options disambiguées même si inconnues en mode permissif

**Nouvelle implémentation** :

```julia
function route_all_options(
    method::Tuple{Vararg{Symbol}},
    families::NamedTuple,
    action_defs::Vector{Options.OptionDefinition},
    kwargs::NamedTuple,
    registry::Strategies.StrategyRegistry;
    source_mode::Symbol = :description,
    mode::Symbol = true,  # ← Nouveau paramètre
)
    # Step 1: Extract action options FIRST
    action_options, remaining_kwargs = Options.extract_options(
        kwargs, action_defs
    )

    # Step 2: Build strategy-to-family mapping
    strategy_to_family = build_strategy_to_family_map(
        method, families, registry
    )

    # Step 3: Build option ownership map
    option_owners = build_option_ownership_map(method, families, registry)

    # Step 4: Route each remaining option
    routed = Dict{Symbol, Vector{Pair{Symbol, Any}}}()
    for family_name in keys(families)
        routed[family_name] = Pair{Symbol, Any}[]
    end
    
    for (key, raw_val) in pairs(remaining_kwargs)
        # Try to extract disambiguation
        disambiguations = extract_strategy_ids(raw_val, method)

        if disambiguations !== nothing
            # Explicitly disambiguated (single or multiple strategies)
            for (value, strategy_id) in disambiguations
                family_name = strategy_to_family[strategy_id]
                owners = get(option_owners, key, Set{Symbol}())

                # Check if this family owns this option
                if family_name in owners
                    # Known option - route normally
                    push!(routed[family_name], key => value)
                elseif !strict
                    # PERMISSIVE MODE: Accept unknown but disambiguated option
                    @warn """
                    Option non reconnue routée vers la stratégie
                    
                    Option :$key n'est pas dans les metadata de :$strategy_id
                    mais sera transmise au backend.
                    
                    Assurez-vous que cette option est valide pour $strategy_id.
                    """
                    push!(routed[family_name], key => value)
                else
                    # STRICT MODE: Error - trying to route to wrong strategy
                    valid_strategies = [
                        id for (id, fam) in strategy_to_family if fam in owners
                    ]
                    throw(Exceptions.IncorrectArgument(
                        "Invalid option routing",
                        got="option :$key to strategy :$strategy_id",
                        expected="option to be routed to one of: $valid_strategies",
                        suggestion="Check option ownership or use correct strategy identifier",
                        context="route_options - validating strategy-specific option routing"
                    ))
                end
            end
        else
            # Auto-route based on ownership
            value = raw_val
            owners = get(option_owners, key, Set{Symbol}())

            if isempty(owners)
                # Unknown option
                if strict
                    # STRICT MODE: Error
                    _error_unknown_option(
                        key, method, families, strategy_to_family, registry
                    )
                else
                    # PERMISSIVE MODE: Error - must be disambiguated
                    _error_unknown_option_permissive(
                        key, method, families, strategy_to_family, registry
                    )
                end
            elseif length(owners) == 1
                # Unambiguous - auto-route
                family_name = first(owners)
                push!(routed[family_name], key => value)
            else
                # Ambiguous - need disambiguation (same in both modes)
                _error_ambiguous_option(
                    key, value, owners, strategy_to_family, source_mode
                )
            end
        end
    end

    # Step 5: Convert to NamedTuples
    strategy_options = NamedTuple(
        family_name => NamedTuple(pairs)
        for (family_name, pairs) in routed
    )

    return (action=action_options, strategies=strategy_options)
end
```

**Nouvelle fonction helper** :

```julia
"""
Error handler for unknown options in permissive mode (routing level).
"""
function _error_unknown_option_permissive(
    key::Symbol,
    method::Tuple,
    families::NamedTuple,
    strategy_to_family::Dict{Symbol, Symbol},
    registry::Strategies.StrategyRegistry
)
    # Build helpful error message
    all_options = Dict{Symbol, Vector{Symbol}}()
    for (family_name, family_type) in pairs(families)
        id = Strategies.extract_id_from_method(method, family_type, registry)
        option_names = Strategies.option_names_from_method(
            method, family_type, registry
        )
        all_options[id] = collect(option_names)
    end

    msg = "Option :$key inconnue et non disambiguée en mode permissif.\n\n"
    msg *= "En mode permissif, les options inconnues doivent utiliser\n"
    msg *= "la syntaxe de disambiguation :\n"
    msg *= "  $key = (value, :strategy_id)\n\n"
    msg *= "Exemples pour votre méthode $method :\n"
    for (id, _) in all_options
        family = strategy_to_family[id]
        msg *= "  $key = (value, :$id)  # Router vers $family\n"
    end
    msg *= "\nOptions disponibles :\n"
    for (id, option_names) in all_options
        family = strategy_to_family[id]
        msg *= "  $family (:$id): $(join(option_names, ", "))\n"
    end

    throw(Exceptions.IncorrectArgument(
        "Option inconnue doit être disambiguée en mode permissif",
        got="option :$key sans disambiguation",
        expected="syntaxe de disambiguation (value, :strategy_id)",
        suggestion=msg,
        context="route_options - permissive mode requires disambiguation"
    ))
end
```

#### Fichier : `src/Orchestration/method_builders.jl`

##### Fonction : `build_strategy_from_method()`

**Modification** : Ajouter et propager le paramètre `strict`.

```julia
function build_strategy_from_method(
    method::Tuple{Vararg{Symbol}},
    family_type::Type{<:AbstractStrategy},
    options::NamedTuple,
    registry::Strategies.StrategyRegistry;
    mode::Symbol = true  # ← Nouveau paramètre
)
    strategy_id = Strategies.extract_id_from_method(method, family_type, registry)
    return Strategies.build_strategy(strategy_id, options, registry; strict=strict)
end
```

### 2.3 Strategies Builders

#### Fichier : `src/Strategies/api/builders.jl`

##### Fonction : `build_strategy()`

**Modification** : Ajouter et propager le paramètre `strict`.

```julia
function build_strategy(
    strategy_id::Symbol,
    options::NamedTuple,
    registry::Strategies.StrategyRegistry;
    mode::Symbol = true  # ← Nouveau paramètre
)
    strategy_type = registry[strategy_id]
    return build_strategy_options(strategy_type; strict=strict, options...)
end
```

##### Fonction : `build_strategy_from_method()`

**Modification** : Ajouter et propager le paramètre `strict`.

```julia
function build_strategy_from_method(
    method::Tuple{Vararg{Symbol}},
    family_type::Type{<:AbstractStrategy},
    options::NamedTuple,
    registry::Strategies.StrategyRegistry;
    mode::Symbol = true  # ← Nouveau paramètre
)
    strategy_id = Strategies.extract_id_from_method(method, family_type, registry)
    return build_strategy(strategy_id, options, registry; strict=strict)
end
```

### 2.4 Extensions (Solvers)

#### Fichiers : `ext/CTSolversIpopt.jl`, `ext/CTSolversMadNLP.jl`, etc.

##### Fonction : `build_*_solver()`

**Modification** : Propager le paramètre `strict`.

**Exemple pour Ipopt** :

```julia
function Solvers.build_ipopt_solver(::Solvers.IpoptTag; kwargs...)
    # Extract strict parameter if present
    strict = get(kwargs, :strict, true)
    kwargs_without_strict = Base.structdiff(kwargs, (strict=strict,))
    
    opts = Strategies.build_strategy_options(
        Solvers.IpoptSolver; 
        strict=strict,
        kwargs_without_strict...
    )
    return Solvers.IpoptSolver(opts)
end
```

**Alternative plus simple** (recommandée) :

```julia
function Solvers.build_ipopt_solver(::Solvers.IpoptTag; mode::Symbol=true, kwargs...)
    opts = Strategies.build_strategy_options(
        Solvers.IpoptSolver; 
        strict=strict,
        kwargs...
    )
    return Solvers.IpoptSolver(opts)
end
```

### 2.5 Modelers

#### Fichiers : `src/Modelers/adnlp_modeler.jl`, `src/Modelers/exa_modeler.jl`

##### Constructeurs

**Modification** : Ajouter paramètre `strict`.

**Exemple pour ADNLPModeler** :

```julia
function ADNLPModeler(; mode::Symbol=true, kwargs...)
    opts = Strategies.build_strategy_options(
        ADNLPModeler; 
        strict=strict,
        kwargs...
    )
    return ADNLPModeler(opts)
end
```

## 3. Gestion de la Source des Options

### 3.1 Sources d'Options

Le système utilise des symboles pour identifier la source des options :

- `:user` : Option fournie par l'utilisateur et validée
- `:default` : Option utilisant la valeur par défaut
- `:user_unvalidated` : Option fournie par l'utilisateur en mode permissif (non validée)

### 3.2 Priorité des Options

En cas de conflit, la priorité est :

1. `:user` (validée) - Priorité maximale
2. `:user_unvalidated` (non validée) - Priorité moyenne
3. `:default` - Priorité minimale

**Implémentation** :

```julia
# Dans Options.extract_options()
# Les options validées sont extraites en premier
extracted, remaining = extract_validated_options(kwargs, defs)

# En mode permissif, les options non validées sont ajoutées
# MAIS ne remplacent pas les options validées
if !strict
    for (key, value) in pairs(remaining)
        if !haskey(extracted, key)  # ← Ne remplace pas si déjà présent
            extracted[key] = OptionValue(value, :user_unvalidated)
        end
    end
end
```

### 3.3 Transmission aux Backends

Les options sont transmises via `options_dict()` qui extrait toutes les options, validées ou non :

```julia
function options_dict(strategy::AbstractStrategy)
    opts = options(strategy)
    raw_opts = Options.extract_raw_options(opts.options)
    return Dict{Symbol, Any}(pairs(raw_opts))
end
```

**Comportement** :
- Toutes les options (validées et non validées) sont incluses
- La source n'est pas transmise au backend
- Le backend reçoit un `Dict{Symbol, Any}` standard

## 4. Flux de Données Complet

### 4.1 Constructeur Direct - Mode Strict

```
IpoptSolver(max_iter=1000, unknown=123)
    ↓
build_ipopt_solver(IpoptTag(); max_iter=1000, unknown=123, mode=:strict)
    ↓
build_strategy_options(IpoptSolver; mode=:strict, max_iter=1000, unknown=123)
    ↓
Options.extract_options((max_iter=1000, unknown=123), defs)
    ↓
(extracted={max_iter: 1000 (user)}, remaining={unknown: 123})
    ↓
!isempty(remaining) && strict
    ↓
_error_unknown_options_strict(remaining, IpoptSolver, meta)
    ↓
❌ ERROR: Options inconnues [unknown]
```

### 4.2 Constructeur Direct - Mode Permissif

```
IpoptSolver(max_iter=1000, unknown=123; mode=:permissive)
    ↓
build_ipopt_solver(IpoptTag(); max_iter=1000, unknown=123, mode=:permissive)
    ↓
build_strategy_options(IpoptSolver; mode=:permissive, max_iter=1000, unknown=123)
    ↓
Options.extract_options((max_iter=1000, unknown=123), defs)
    ↓
(extracted={max_iter: 1000 (user)}, remaining={unknown: 123})
    ↓
!isempty(remaining) && !strict
    ↓
_warn_unknown_options_permissive(remaining, IpoptSolver)
    ↓
⚠️  WARNING: Options non reconnues [unknown]
    ↓
Add to extracted: {unknown: 123 (user_unvalidated)}
    ↓
StrategyOptions({max_iter: 1000 (user), unknown: 123 (user_unvalidated)})
    ↓
✅ IpoptSolver créé avec options validées et non validées
```

### 4.3 Via solve() - Mode Strict

```
solve(ocp, :collocation, :adnlp, :ipopt; max_iter=1000, unknown=123, mode=:strict)
    ↓
route_all_options(method, families, action_defs, kwargs, registry; mode=:strict)
    ↓
Options.extract_options(kwargs, action_defs)  # Extract action options
    ↓
(action_options={}, remaining={max_iter: 1000, unknown: 123})
    ↓
Build option_owners map
    ↓
For unknown:
    owners = option_owners[unknown] = {}  # Empty set
    ↓
isempty(owners) && strict
    ↓
_error_unknown_option(unknown, method, families, ...)
    ↓
❌ ERROR: Option unknown n'appartient à aucune stratégie
```

### 4.4 Via solve() - Mode Permissif avec Disambiguation

```
solve(ocp, :collocation, :adnlp, :ipopt; 
    max_iter=1000, 
    unknown=(123, :ipopt), 
    mode=:permissive
)
    ↓
route_all_options(method, families, action_defs, kwargs, registry; mode=:permissive)
    ↓
Options.extract_options(kwargs, action_defs)
    ↓
(action_options={}, remaining={max_iter: 1000, unknown: (123, :ipopt)})
    ↓
For unknown:
    disambiguations = extract_strategy_ids((123, :ipopt), method)
    ↓
    disambiguations = [(123, :ipopt)]  # Extracted
    ↓
    family_name = strategy_to_family[:ipopt] = :solver
    owners = option_owners[unknown] = {}  # Empty set
    ↓
    family_name not in owners && !strict
    ↓
    ⚠️  WARNING: Option unknown non reconnue pour :ipopt
    ↓
    push!(routed[:solver], unknown => 123)
    ↓
strategy_options = (solver=(max_iter=1000, unknown=123), ...)
    ↓
build_strategy_from_method(:ipopt, solver_options; mode=:permissive)
    ↓
build_strategy_options(IpoptSolver; mode=:permissive, max_iter=1000, unknown=123)
    ↓
[Même flux que 4.2]
    ↓
✅ IpoptSolver créé avec options validées et non validées
```

## 5. Considérations d'Implémentation

### 5.1 Type Stability

**Question** : Le paramètre `mode::Symbol` affecte-t-il la stabilité de type ?

**Réponse** : Non, car :
- `mode` est un paramètre de fonction, pas un champ de type
- La valeur est connue à la compilation dans la plupart des cas
- Le type de retour (`StrategyOptions`) est le même dans les deux modes

**Vérification** :
```julia
@inferred build_strategy_options(IpoptSolver; mode=:strict, max_iter=1000)
@inferred build_strategy_options(IpoptSolver; mode=:permissive, max_iter=1000)
# Les deux doivent passer
```

### 5.2 Performance

**Impact attendu** :

- **Mode strict** : 0% overhead (comportement actuel)
- **Mode permissif** : < 1% overhead
  - Warning : ~0.1ms (une fois)
  - Stockage options supplémentaires : négligeable
  - Transmission : négligeable (déjà un Dict)

**Benchmark** :
```julia
using BenchmarkTools

# Mode strict
@benchmark IpoptSolver(max_iter=1000)

# Mode permissif
@benchmark IpoptSolver(max_iter=1000, custom=123; mode=:permissive)

# Différence attendue : < 1%
```

### 5.3 Thread Safety

**Question** : Le système est-il thread-safe ?

**Réponse** : Oui, car :
- Pas d'état global mutable
- Chaque appel crée ses propres structures
- Les warnings Julia sont thread-safe

### 5.4 Compatibilité avec Extensions

**Question** : Les extensions existantes fonctionnent-elles sans modification ?

**Réponse** : Oui, car :
- Le paramètre `mode` a une valeur par défaut (`:strict`)
- Les extensions peuvent ignorer `mode` si elles ne l'utilisent pas
- La transmission d'options reste identique

**Migration progressive** :
1. Phase 1 : Core implémenté
2. Phase 2 : Extensions mises à jour (optionnel)
3. Phase 3 : Documentation et exemples

## 6. Résumé Technique

### Modifications Requises

| Fichier | Fonction | Modification |
|---------|----------|--------------|
| `src/Strategies/api/configuration.jl` | `build_strategy_options()` | Ajouter `mode`, gérer `remaining` |
| `src/Strategies/api/configuration.jl` | `_error_unknown_options_strict()` | Nouvelle fonction |
| `src/Strategies/api/configuration.jl` | `_warn_unknown_options_permissive()` | Nouvelle fonction |
| `src/Orchestration/routing.jl` | `route_all_options()` | Ajouter `mode`, gérer options disambiguées |
| `src/Orchestration/routing.jl` | `_error_unknown_option_permissive()` | Nouvelle fonction |
| `src/Orchestration/method_builders.jl` | `build_strategy_from_method()` | Propager `mode` |
| `src/Strategies/api/builders.jl` | `build_strategy()` | Propager `mode` |
| `src/Strategies/api/builders.jl` | `build_strategy_from_method()` | Propager `mode` |
| `ext/CTSolversIpopt.jl` | `build_ipopt_solver()` | Propager `mode` |
| `ext/CTSolversMadNLP.jl` | `build_madnlp_solver()` | Propager `mode` |
| `ext/CTSolversKnitro.jl` | `build_knitro_solver()` | Propager `mode` |
| `ext/CTSolversMadNCL.jl` | `build_madncl_solver()` | Propager `mode` |
| `src/Modelers/adnlp_modeler.jl` | `ADNLPModeler()` | Ajouter `mode` |
| `src/Modelers/exa_modeler.jl` | `ExaModeler()` | Ajouter `mode` |
| `src/Strategies/api/utilities.jl` | `route_to()` | Nouvelle fonction helper (optionnel) |

### Nouvelles Fonctions

- `_error_unknown_options_strict()` : Gestion d'erreur mode strict (constructeur)
- `_warn_unknown_options_permissive()` : Gestion warning mode permissif (constructeur)
- `_error_unknown_option_permissive()` : Gestion d'erreur mode permissif (routage)
- `route_to(strategy::Symbol, value)` : Helper optionnel pour disambiguation (export optionnel)

### Helper Optionnel : `route_to()`

**Fichier** : `src/Strategies/api/utilities.jl` (ou nouveau fichier)

**Signature** :
```julia
"""
    route_to(strategy::Symbol, value) -> Tuple{Any, Symbol}

Helper function for disambiguating options in permissive mode.

Returns a tuple `(value, strategy)` that can be used to explicitly
route an option to a specific strategy.

# Examples
```julia
# Instead of tuple syntax
solve(ocp, method; backend=(:sparse, :adnlp), mode=:permissive)

# Use helper for clarity
solve(ocp, method; backend=route_to(:adnlp, :sparse), mode=:permissive)
```

# See Also
- Disambiguation syntax in OptimalControl package
"""
route_to(strategy::Symbol, value) = (value, strategy)
```

**Export** : Optionnel (à décider lors de l'implémentation)

**Avantages** :
- Syntaxe plus lisible que les tuples bruts
- Auto-documentation via le nom de la fonction
- Facilite la découverte de la fonctionnalité

**Inconvénients** :
- Nécessite un import/using supplémentaire
- Peut être considéré comme redondant

**Recommandation** : Implémenter mais ne pas exporter par défaut. Documenter dans les exemples.

### Aucune Modification

- `Options.extract_options()` : Fonctionne déjà correctement
- `StrategyOptions` : Structure inchangée
- `options_dict()` : Transmission automatique
- API backend : Aucun changement
