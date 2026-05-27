# Implémentation Priorité 4 : Options Avancées MadNLP

## Résumé

✅ **Phase 4 (Priorité 4) complétée avec succès**

### Options ajoutées (6)

| Option | Type | Défaut | Description |
|--------|------|--------|-------------|
| `kkt_system` | `Type{<:MadNLP.AbstractKKTSystem}` | `NotProvided` | Type de système KKT (ex: `MadNLP.SparseKKTSystem`) |
| `hessian_approximation` | `Type{<:MadNLP.AbstractHessian}` | `NotProvided` | Approximation hessienne (ex: `MadNLP.ExactHessian`, `MadNLP.BFGS`) |
| `inertia_correction_method` | `Type{<:MadNLP.AbstractInertiaCorrector}` | `NotProvided` | Méthode de correction d'inertie (ex: `MadNLP.InertiaAuto`) |
| `mu_init` | `Real` | `NotProvided` | Valeur initiale paramètre barrière (> 0) |
| `mu_min` | `Real` | `NotProvided` | Valeur minimale paramètre barrière (> 0) |
| `tau_min` | `Real` | `NotProvided` | Borne inférieure pour tau (0 < tau < 1) |

> **Note sur les types** : Les options `kkt_system`, `hessian_approximation` et `inertia_correction_method` attendent des types Julia (pas des instances), qualifiés par le module `MadNLP`.
> Dans les métadonnées techniques (`Strategies.metadata`), ces options sont typées comme `Union{Type{...}, UnionAll}` pour accepter les types génériques (comme `MadNLP.SparseKKTSystem`) sans avertissement de l'infrastructure `CTSolvers.Options`, tout en garantissant une validation stricte via des validateurs personnalisés.

### Fichiers modifiés

1. **`ext/CTSolversMadNLP.jl`**
   - Ajout des 6 options dans `Strategies.metadata`
   - Utilisation de validateurs `isa Type && <: MadNLP.Abstract...` pour la robustesse.

2. **`test/suite/extensions/test_madnlp_extension.jl`**
   - Ajout des tests de métadonnées (`Any` type attendu).
   - Ajout du bloc `Advanced Options Validation`.
   - Tests de valeurs valides (ex: `MadNLP.SparseKKTSystem`) et invalides.

### Exemple d'utilisation

```julia
using CTSolvers
using MadNLP

solver = Solvers.MadNLPSolver(
    # Options avancées
    kkt_system = MadNLP.SparseKKTSystem,
    hessian_approximation = MadNLP.BFGS,
    mu_init = 1e-3,
    print_level = MadNLP.ERROR
)
```

---

**Date** : 2026-02-05
**Statut** : ✅ Priorité 4 complétée et testée. Projet MadNLP Options terminé.
