# Implémentation Priorité 3 : Options d'Initialisation MadNLP

## Résumé

✅ **Phase 3 (Priorité 3) complétée avec succès**

### Options ajoutées (5)

| Option | Type | Défaut | Description |
|--------|------|--------|-------------|
| `bound_push` | `Real` | `NotProvided` | Pousse le point initial à l'intérieur des bornes (valeur absolue) |
| `bound_fac` | `Real` | `NotProvided` | Pousse le point initial à l'intérieur des bornes (facteur) |
| `constr_mult_init_max` | `Real` | `NotProvided` | Valeur max pour l'initialisation des multiplicateurs |
| `fixed_variable_treatment` | `Enum` | `NotProvided` | Traitement des variables fixes (ex: `MAKE_PARAMETER`) |
| `equality_treatment` | `Enum` | `NotProvided` | Traitement des contraintes d'égalité (ex: `RELAX_BOUNDS`) |

> **Types Enum** : Les options `fixed_variable_treatment` et `equality_treatment` utilisent les énumérations `MadNLP.FixedVariableTreatments` et `MadNLP.EqualityTreatments` respectivement.

### Fichiers modifiés

1. **`ext/CTSolversMadNLP.jl`**
   - Ajout des 5 options dans `Strategies.metadata`
   - Descriptions et validateurs inclus (pour les types `Real`)

2. **`test/suite/extensions/test_madnlp_extension.jl`**
   - Ajout des tests de métadonnées
   - Ajout du bloc `Initialization Options Validation`
   - Vérification du support des Enums MadNLP

### Tests

Tests ajoutés pour vérifier :
- La présence des métadonnées
- Les types corrects (`Real` et `Enums`)
- Les valeurs par défaut (`NotProvided`)
- La validation des valeurs invalides (ex: `bound_push` négatif)
- Le passage correct des valeurs Enum

### Exemples d'utilisation

```julia
using CTSolvers
using MadNLP

# Configuration de l'initialisation
solver = Solvers.MadNLPSolver(
    bound_push=0.01,
    bound_fac=0.01,
    constr_mult_init_max=1000.0,
    print_level=MadNLP.ERROR
)

# Configuration avancée avec Enums
solver_advanced = Solvers.MadNLPSolver(
    fixed_variable_treatment=MadNLP.MAKE_PARAMETER,
    equality_treatment=MadNLP.RELAX_BOUNDS,
    print_level=MadNLP.ERROR
)
```

---

**Date** : 2026-02-05
**Statut** : ✅ Priorité 3 complétée et testée
