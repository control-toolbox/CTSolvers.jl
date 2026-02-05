# Tableau récapitulatif des options MadNLP

Ce tableau liste **toutes** les options MadNLP avec leur type, défaut, et recommandation d'ajout dans CTSolvers.

## Légende

| Symbole | Signification |
|---------|---------------|
| ✅ | Déjà implémenté dans CTSolvers |
| 🔴 | Priorité 1 - À ajouter en premier |
| 🟠 | Priorité 2 - Important |
| 🟡 | Priorité 3 - Utile |
| 🟢 | Priorité 4 - Avancé |
| ⚪ | Priorité 5 - Optionnel/Spécialisé |
| ❌ | Ne pas exposer (interne) |

---

## Options primaires

| Option | Type | Défaut MadNLP | Priorité | Notes |
|--------|------|---------------|----------|-------|
| `tol` | `Float64` | `1e-8` | ✅ | Tolérance de convergence |
| `callback` | `Type` | auto | ❌ | Géré automatiquement |
| `kkt_system` | `Type{<:AbstractKKTSystem}` | auto | 🟢 | Système KKT |
| `linear_solver` | `Type{<:AbstractLinearSolver}` | auto | ✅ | Solveur linéaire |

---

## Options générales

| Option | Type | Défaut MadNLP | Priorité | Notes |
|--------|------|---------------|----------|-------|
| `iterator` | `Type` | `RichardsonIterator` | ⚪ | Raffinement itératif |
| `blas_num_threads` | `Int` | `1` | ⚪ | Threads BLAS |
| `disable_garbage_collector` | `Bool` | `false` | ❌ | Interne |
| `rethrow_error` | `Bool` | `true` | ❌ | Interne |

---

## Options de sortie

| Option | Type | Défaut MadNLP | Priorité | Notes |
|--------|------|---------------|----------|-------|
| `print_level` | `LogLevels` | `INFO` | ✅ | Niveau de log |
| `output_file` | `String` | `""` | ⚪ | Fichier de log |
| `file_print_level` | `LogLevels` | `INFO` | ⚪ | Niveau log fichier |

---

## Options de terminaison

| Option | Type | Défaut MadNLP | Priorité | Notes |
|--------|------|---------------|----------|-------|
| `max_iter` | `Int` | `3000` | ✅ | Itérations max |
| `acceptable_tol` | `Float64` | `1e-6` | 🔴 | Tolérance acceptable |
| `acceptable_iter` | `Int` | `15` | 🔴 | Itérations acceptables |
| `diverging_iterates_tol` | `Float64` | `1e20` | 🔴 | Seuil divergence |
| `max_wall_time` | `Float64` | `1e6` | 🔴 | Temps max (secondes) |
| `s_max` | `Float64` | `100.0` | ⚪ | Scaling max KKT |

---

## Options NLP

| Option | Type | Défaut MadNLP | Priorité | Notes |
|--------|------|---------------|----------|-------|
| `kappa_d` | `Float64` | `1e-5` | ⚪ | Poids terme damping |
| `fixed_variable_treatment` | `Type` | `MakeParameter` | 🟡 | Traitement variables fixes |
| `equality_treatment` | `Type` | `EnforceEquality` | 🟡 | Traitement égalités |
| `bound_relax_factor` | `Float64` | `1e-8` | ⚪ | Relaxation bornes |
| `jacobian_constant` | `Bool` | `false` | 🟠 | Jacobienne constante |
| `hessian_constant` | `Bool` | `false` | 🟠 | Hessien constant |
| `hessian_approximation` | `Type{<:AbstractHessian}` | `ExactHessian` | 🟢 | Approximation Hessien |
| `quasi_newton_options` | `QuasiNewtonOptions` | `QuasiNewtonOptions()` | ❌ | Struct complexe |
| `inertia_correction_method` | `Type{<:AbstractInertiaCorrector}` | `InertiaAuto` | 🟢 | Correction inertie |
| `inertia_free_tol` | `Float64` | `0.0` | ⚪ | Tolérance inertia-free |

---

## Options d'initialisation

| Option | Type | Défaut MadNLP | Priorité | Notes |
|--------|------|---------------|----------|-------|
| `dual_initialized` | `Bool` | `false` | ⚪ | Dual initial fourni |
| `dual_initialization_method` | `Type` | auto | ⚪ | Méthode init dual |
| `constr_mult_init_max` | `Float64` | `1e3` | 🟡 | Max mult. duaux init |
| `bound_push` | `Float64` | `1e-2` | 🟡 | Distance abs. borne |
| `bound_fac` | `Float64` | `1e-2` | 🟡 | Distance rel. borne |
| `nlp_scaling` | `Bool` | `true` | 🟠 | Mise à l'échelle NLP |
| `nlp_scaling_max_gradient` | `Float64` | `100.0` | 🟠 | Gradient max scaling |

---

## Perturbation Hessienne

| Option | Type | Défaut MadNLP | Priorité | Notes |
|--------|------|---------------|----------|-------|
| `min_hessian_perturbation` | `Float64` | `1e-20` | ⚪ | Perturbation min |
| `first_hessian_perturbation` | `Float64` | `1e-4` | ⚪ | Première perturbation |
| `max_hessian_perturbation` | `Float64` | `1e20` | ⚪ | Perturbation max |
| `perturb_inc_fact_first` | `Float64` | `100.0` | ⚪ | Facteur incrémentation 1ère |
| `perturb_inc_fact` | `Float64` | `8.0` | ⚪ | Facteur incrémentation |
| `perturb_dec_fact` | `Float64` | `1/3` | ⚪ | Facteur décrémentation |
| `jacobian_regularization_exponent` | `Float64` | `0.25` | ⚪ | Exposant régularisation |
| `jacobian_regularization_value` | `Float64` | `1e-8` | ⚪ | Valeur régularisation |

---

## Restauration

| Option | Type | Défaut MadNLP | Priorité | Notes |
|--------|------|---------------|----------|-------|
| `soft_resto_pderror_reduction_factor` | `Float64` | `0.9999` | ⚪ | Facteur réduction soft |
| `required_infeasibility_reduction` | `Float64` | `0.9` | ⚪ | Réduction requise |

---

## Line Search

| Option | Type | Défaut MadNLP | Priorité | Notes |
|--------|------|---------------|----------|-------|
| `obj_max_inc` | `Float64` | `5.0` | ⚪ | Augmentation max obj. |
| `kappha_soc` | `Float64` | `0.99` | ⚪ | SOC factor |
| `max_soc` | `Int` | `4` | ⚪ | SOC essais max |
| `alpha_min_frac` | `Float64` | `0.05` | ⚪ | Fraction alpha min |
| `s_theta` | `Float64` | `1.1` | ⚪ | Exposant theta |
| `s_phi` | `Float64` | `2.3` | ⚪ | Exposant phi |
| `eta_phi` | `Float64` | `1e-4` | ⚪ | Relaxation Armijo |
| `kappa_soc` | `Float64` | `0.99` | ⚪ | SOC factor (duplicate?) |
| `gamma_theta` | `Float64` | `1e-5` | ⚪ | Marge filtre theta |
| `gamma_phi` | `Float64` | `1e-5` | ⚪ | Marge filtre phi |
| `delta` | `Float64` | `1.0` | ⚪ | Multiplicateur switch |
| `kappa_sigma` | `Float64` | `1e10` | ⚪ | Limite déviation duale |
| `barrier_tol_factor` | `Float64` | `10.0` | ⚪ | Facteur tolérance barrière |
| `rho` | `Float64` | `1000.0` | ⚪ | Paramètre pénalité |

---

## Barrière

| Option | Type | Défaut MadNLP | Priorité | Notes |
|--------|------|---------------|----------|-------|
| `mu_init` | `Float64` | `0.1` | 🟢 | Paramètre barrière initial |
| `mu_min` | `Float64` | `1e-9` | 🟢 | Paramètre barrière min |
| `mu_superlinear_decrease_power` | `Float64` | `1.5` | ⚪ | Puissance décroissance |
| `tau_min` | `Float64` | `0.99` | 🟢 | Fraction-to-boundary min |
| `mu_linear_decrease_factor` | `Float64` | `0.2` | ⚪ | Facteur décroissance linéaire |
| `barrier` | `AbstractBarrierUpdate` | `MonotoneUpdate(...)` | ❌ | Struct complexe |

---

## Résumé par priorité

| Priorité | Nombre | Options |
|----------|--------|---------|
| ✅ Implémenté | 4 | `max_iter`, `tol`, `print_level`, `linear_solver` |
| 🔴 P1 - Critique | 4 | `acceptable_tol`, `acceptable_iter`, `diverging_iterates_tol`, `max_wall_time` |
| 🟠 P2 - Important | 4 | `nlp_scaling`, `nlp_scaling_max_gradient`, `jacobian_constant`, `hessian_constant` |
| 🟡 P3 - Utile | 5 | `bound_push`, `bound_fac`, `constr_mult_init_max`, `fixed_variable_treatment`, `equality_treatment` |
| 🟢 P4 - Avancé | 5 | `kkt_system`, `hessian_approximation`, `inertia_correction_method`, `mu_init`, `mu_min`, `tau_min` |
| ⚪ P5 - Optionnel | ~30 | Line search, perturbation, etc. |
| ❌ Non exposé | ~5 | Internes, structs complexes |

---

## Recommandation d'implémentation

### Phase 1 (4 options)
```
acceptable_tol, acceptable_iter, diverging_iterates_tol, max_wall_time
```

### Phase 2 (4 options)
```
nlp_scaling, nlp_scaling_max_gradient, jacobian_constant, hessian_constant
```

### Phase 3 (5 options)
```
bound_push, bound_fac, constr_mult_init_max, fixed_variable_treatment, equality_treatment
```

### Phase 4 (6 options)
```
kkt_system, hessian_approximation, inertia_correction_method, mu_init, mu_min, tau_min
```

**Total recommandé : 19 nouvelles options** pour une couverture complète des cas d'usage courants.
