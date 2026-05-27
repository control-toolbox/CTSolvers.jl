# Implémentation Priorité 1 : Options de terminaison MadNLP

## Résumé

✅ **Phase 1 (Priorité 1) complétée avec succès**

### Options ajoutées (4)

| Option | Type | Défaut | Alias | Description |
|--------|------|--------|-------|-------------|
| Option | Type | Défaut | Alias | Description |
|--------|------|--------|-------|-------------|
| `acceptable_tol` | `Real` | `NotProvided` | `acc_tol` | Tolérance acceptable pour solution précoce |
| `acceptable_iter` | `Integer` | `NotProvided` | - | Nombre d'itérations acceptables requises |
| `max_wall_time` | `Real` | `NotProvided` | `max_time` | Limite de temps en secondes |
| `diverging_iterates_tol` | `Real` | `NotProvided` | - | Seuil de divergence |

> **Note**: Les valeurs par défaut ont été changées en `NotProvided` pour éviter les conflits de types avec les modèles Float32 (voir `float_type_investigation.md`).

### Fichiers modifiés

1. **`ext/CTSolversMadNLP.jl`** (lignes 70-124)
   - Ajout des 4 options dans `Strategies.metadata`
   - Descriptions améliorées pour toutes les options (8 au total)
   - Validateurs avec messages d'erreur détaillés

2. **`test/suite/extensions/test_madnlp_extension.jl`** (lignes 54-72, 258-286)
   - Tests de métadonnées étendus (présence, types, défauts)
   - Tests d'alias pour `acc_tol` et `max_time`
   - Tests de validation (valeurs invalides)

### Tests

**Résultats** : 103 tests passés ✅

#### Tests unitaires

- ✅ Présence des 4 nouvelles options dans les métadonnées
- ✅ Types corrects (`Real`, `Integer`)
- ✅ Valeurs par défaut correctes
- ✅ Alias fonctionnels (`acc_tol`, `max_time`)

#### Tests de validation

- ✅ `acceptable_tol=-1.0` → `IncorrectArgument`
- ✅ `acceptable_tol=0.0` → `IncorrectArgument`
- ✅ `acceptable_iter=0` → `IncorrectArgument`
- ✅ `max_wall_time=-1.0` → `IncorrectArgument`
- ✅ `max_wall_time=0.0` → `IncorrectArgument`
- ✅ `diverging_iterates_tol=-1.0` → `IncorrectArgument`
- ✅ `diverging_iterates_tol=0.0` → `IncorrectArgument`
- ✅ Valeurs valides acceptées sans erreur

### Exemples d'utilisation

```julia
using CTSolvers

# Avec les nouvelles options
solver = Solvers.MadNLPSolver(
    max_iter=1000,
    tol=1e-8,
    acceptable_tol=1e-5,      # Nouvelle option
    acceptable_iter=10,        # Nouvelle option
    max_wall_time=60.0,        # Nouvelle option (alias: max_time)
    diverging_iterates_tol=1e15  # Nouvelle option
)

# Utilisation des alias
solver2 = Solvers.MadNLPSolver(
    acc_tol=1e-6,    # Alias pour acceptable_tol
    max_time=120.0   # Alias pour max_wall_time
)
```

### Améliorations des descriptions

Toutes les descriptions ont été enrichies pour être plus informatives :

- **`max_iter`** : Précise qu'on peut mettre 0 pour évaluer le point initial uniquement
- **`tol`** : Explique le critère de convergence
- **`print_level`** : Liste toutes les valeurs valides (TRACE, DEBUG, INFO, etc.)
- **`linear_solver`** : Mentionne les alternatives disponibles
- **`acceptable_tol`** : Explique le mécanisme de terminaison précoce
- **`acceptable_iter`** : Précise "consécutives"
- **`max_wall_time`** : Mentionne le statut de sortie
- **`diverging_iterates_tol`** : Mentionne le statut de sortie

### Prochaines étapes

Pour continuer l'implémentation selon le plan :

**Phase 2 (Priorité 2)** - 4 options NLP :

- `nlp_scaling`
- `nlp_scaling_max_gradient`
- `jacobian_constant`
- `hessian_constant`

**Phase 3 (Priorité 3)** - 5 options d'initialisation :

- `bound_push`
- `bound_fac`
- `constr_mult_init_max`
- `fixed_variable_treatment`
- `equality_treatment`

**Phase 4 (Priorité 4)** - 6 options avancées :

- `kkt_system`
- `hessian_approximation`
- `inertia_correction_method`
- `mu_init`
- `mu_min`
- `tau_min`

---

**Date** : 2026-02-05  
**Statut** : ✅ Priorité 1 complétée et testée
