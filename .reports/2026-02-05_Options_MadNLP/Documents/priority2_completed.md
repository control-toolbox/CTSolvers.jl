# Implémentation Priorité 2 : Options de Scaling et Structure MadNLP

## Résumé

✅ **Phase 2 (Priorité 2) complétée avec succès**

### Options ajoutées (4)

| Option | Type | Défaut | Alias | Description |
|--------|------|--------|-------|-------------|
| `nlp_scaling` | `Bool` | `NotProvided` | - | Active le scaling automatique du NLP |
| `nlp_scaling_max_gradient` | `Real` | `NotProvided` | - | Valeur maximale du gradient pour le scaling |
| `jacobian_constant` | `Bool` | `NotProvided` | `jacobian_cst` | Jacobien des contraintes constant (linéaire) |
| `hessian_constant` | `Bool` | `NotProvided` | `hessian_cst` | Hessien du Lagrangien constant (quadratique) |

> **Note**: Comme pour la Phase 1, les valeurs par défaut sont `NotProvided` pour laisser MadNLP gérer ses propres défauts et éviter les conflits de types (Float32).

### Fichiers modifiés

1. **`ext/CTSolversMadNLP.jl`**
   - Ajout des 4 options dans `Strategies.metadata`
   - Descriptions et validateurs inclus

2. **`test/suite/extensions/test_madnlp_extension.jl`**
   - Ajout des tests de métadonnées pour les 4 options
   - Ajout d'un nouveau bloc de tests `NLP Scaling Options Validation`
   - Vérification des alias (`jacobian_cst`, `hessian_cst`)

### Tests

Tests ajoutés pour vérifier :
- La présence des métadonnées
- Les types corrects (`Bool`, `Real`)
- Les valeurs par défaut (`NotProvided`)
- Le fonctionnement des alias
- La validation des valeurs invalides (ex: gradient négatif)

### Exemples d'utilisation

```julia
using CTSolvers

# Configuration avec scaling
solver = Solvers.MadNLPSolver(
    nlp_scaling=true,
    nlp_scaling_max_gradient=10.0,
    print_level=MadNLP.ERROR
)

# Configuration pour problème structuré (QP)
solver_qp = Solvers.MadNLPSolver(
    jacobian_cst=true,  # Contraintes linéaires
    hessian_cst=true,   # Objectif quadratique
    print_level=MadNLP.ERROR
)
```

---

**Date** : 2026-02-05
**Statut** : ✅ Priorité 2 complétée et testée
