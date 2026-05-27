# Rapport : Backend Override — Acceptation des Types et Instances ADBackend

**Date** : 14 février 2026
**Scope** : Options de surcharge de backend pour `ADNLPModeler`

## Contexte

Les options de surcharge de backend (`gradient_backend`, `hprod_backend`, etc.) dans `ADNLPModeler` étaient déclarées avec le type `Union{Nothing, ADNLPModels.ADBackend}`, ce qui n'acceptait que les **instances** de `ADBackend`. Or, l'API de ADNLPModels.jl accepte aussi des **types** (`Type{<:ADBackend}`) qu'elle construit en interne.

Dans le code source d'ADNLPModels (`ad.jl`), le pattern est :

```julia
gradient_backend = if gradient_backend isa Union{AbstractNLPModel, ADBackend}
    gradient_backend  # Déjà une instance → utilisée directement
else
    GB(nvar, f, ncon, c!; kwargs...)  # C'est un Type → construit par ADNLPModels
end
```

De plus, le validateur `validate_backend_override` n'acceptait que `nothing` ou `Type` (pas les instances), ce qui était incohérent avec la déclaration de type.

## Fichiers modifiés

### 1. `src/Modelers/adnlp_modeler.jl`

#### Déclarations de type des options (L176-L225)

Pour les 7 options de backend actives, le champ `type` a été changé de :

```julia
type=Union{Nothing, ADNLPModels.ADBackend},
```

à :

```julia
type=Union{Nothing, Type{<:ADNLPModels.ADBackend}, ADNLPModels.ADBackend},
```

**Options concernées** :

- `gradient_backend`
- `hprod_backend`
- `jprod_backend`
- `jtprod_backend`
- `jacobian_backend`
- `hessian_backend`
- `ghjvprod_backend`

Les 5 options NLS résidus commentées ont également été mises à jour par l'utilisateur pour cohérence :

- `hprod_residual_backend`
- `jprod_residual_backend`
- `jtprod_residual_backend`
- `jacobian_residual_backend`
- `hessian_residual_backend`

#### Docstring du struct `ADNLPModeler` (L49-L93)

La section "Advanced Backend Overrides" a été réécrite :

- **Avant** : Listait les options avec `Union{Nothing, Type}` et incluait une section NLS séparée avec les 6 options résidus.
- **Après** : Explique clairement les 3 formes acceptées (`nothing`, `Type{<:ADBackend}`, instance `ADBackend`), liste les 7 options actives, et supprime la section NLS (commentée dans le code).

Les exemples ont été enrichis avec 3 cas d'usage :

```julia
# Override with nothing (use default)
modeler = ADNLPModeler(gradient_backend=nothing, hessian_backend=nothing)

# Override with a Type (ADNLPModels constructs it)
modeler = ADNLPModeler(gradient_backend=ADNLPModels.ForwardDiffADGradient)

# Override with an instance (used directly)
modeler = ADNLPModeler(gradient_backend=ADNLPModels.ForwardDiffADGradient())
```

### 2. `src/Modelers/validation.jl`

#### Fonction `validate_backend_override` (L310-L351)

**Avant** : Acceptait uniquement `nothing` ou `Type` (via `!isa(backend, Type)`).

**Après** : Accepte 3 formes avec des vérifications explicites :

```julia
function validate_backend_override(backend)
    backend === nothing && return backend
    isa(backend, Type) && backend <: ADNLPModels.ADBackend && return backend
    isa(backend, ADNLPModels.ADBackend) && return backend
    throw(Exceptions.IncorrectArgument(
        "Backend override must be nothing, a Type{<:ADBackend}, or an ADBackend instance",
        got=string(typeof(backend)),
        expected="nothing, Type{<:ADBackend}, or ADBackend instance",
        suggestion="Use nothing for default backend, a Type like ForwardDiffADGradient, or an instance like ForwardDiffADGradient()"
    ))
end
```

La docstring a été mise à jour avec des exemples pour les 3 cas (Type et instance).

### 3. `test/suite/modelers/test_enhanced_options.jl`

#### Ajouts au module

- Import de `ADNLPModels` : `using ADNLPModels: ADNLPModels`
- Définition d'un fake backend au top-level du module (conformément aux règles de test) :

```julia
struct FakeTestBackend <: ADNLPModels.ADBackend end
```

#### Restructuration du testset "Advanced Backend Overrides"

**Avant** : Un seul testset `Backend Override Validation` testant uniquement `nothing` et incluant des références aux 5 options NLS résidus commentées.

**Après** : 4 testsets distincts :

1. **`Backend Override with nothing`** — Teste les 7 options actives avec `nothing`, vérifie l'accessibilité des valeurs.

2. **`Backend Override with Type{<:ADBackend}`** — Teste le passage d'un `Type` (`FakeTestBackend`) pour `gradient_backend`, `hprod_backend`, `jacobian_backend`, `ghjvprod_backend`. Vérifie que la valeur stockée est bien le type.

3. **`Backend Override with ADBackend instance`** — Teste le passage d'une instance (`FakeTestBackend()`) pour les mêmes options. Vérifie que la valeur stockée est bien une instance de `ADBackend`.

4. **`Backend Override Type Validation`** — Inchangé : vérifie le rejet des valeurs invalides (`String`, `Int`, `Symbol`).

5. **`Combined Advanced Options`** — Mis à jour pour mixer Type et instance dans un même modeler :

```julia
modeler = ADNLPModeler(
    backend=:optimized,
    matrix_free=true,
    name="AdvancedTest",
    gradient_backend=FakeTestBackend,       # Type
    hprod_backend=instance,                 # Instance
    jacobian_backend=nothing,               # nothing
    ghjvprod_backend=nothing                # nothing
)
```

Les références aux 5 options NLS résidus (`hprod_residual_backend`, etc.) ont été supprimées des tests.

## Résultats des tests

- **`test_modelers`** : 40/40 ✅
- **`test_enhanced_options`** : 76/76 ✅

## Note sur le champ `type` dans `OptionDefinition`

Le champ `type` dans `OptionDefinition` est validé contre la valeur `default` via `!isa(default, type)` dans le constructeur (`option_definition.jl:139-149`). Cependant, cette vérification est ignorée quand `default=Options.NotProvided` (notre cas pour toutes les options backend). La validation runtime des valeurs fournies par l'utilisateur est assurée par la fonction `validator`. Le `type` correct reste important pour la documentation et la cohérence future si un default concret est ajouté.
