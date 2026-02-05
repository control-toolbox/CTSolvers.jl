# Plan d'implémentation : Extension des options MadNLPSolver

## Résumé

Ce document décrit le plan pour enrichir les options exposées par `MadNLPSolver` dans `CTSolvers`. L'objectif est de permettre aux utilisateurs de contrôler finement le comportement du solveur MadNLP via l'interface unifiée de CTSolvers.

## Méthodologie

### Principes directeurs

1. **Typage fort** : Utiliser `Type{<:...}` pour les options de type, comme `Type{<:MadNLP.AbstractLinearSolver}`
2. **Défaut = comportement garanti** : Définir un `default` dès qu'on veut garantir un comportement précis. Même si le défaut correspond actuellement à celui de MadNLP, on le spécifie explicitement pour assurer la stabilité de CTSolvers face aux évolutions futures de MadNLP
3. **Validation rigoureuse** : Ajouter des validateurs pour les options numériques avec bornes
4. **Descriptions claires** : Chaque option doit avoir une `description` compréhensible
5. **Tests orthogonaux** : Tests unitaires pour les métadonnées, tests d'intégration pour le comportement

### Structure des métadonnées

```julia
Strategies.OptionDefinition(;
    name=:option_name,
    type=ExpectedType,                    # Obligatoire
    default=default_value,                # Optionnel (utilise NotProvided si absent)
    description="Description claire",     # Obligatoire
    aliases=(:alias1, :alias2),           # Optionnel
    validator=x -> condition || throw(...) # Optionnel
)
```

---

## Options existantes (4)

| Option | Type | Défaut CTSolvers | Description |
|--------|------|------------------|-------------|
| `max_iter` | `Integer` | `3000` | Nombre max d'itérations |
| `tol` | `Real` | `1e-8` | Tolérance de convergence |
| `print_level` | `MadNLP.LogLevels` | `MadNLP.INFO` | Niveau de verbosité |
| `linear_solver` | `Type{<:MadNLP.AbstractLinearSolver}` | `MadNLPMumps.MumpsSolver` | Solveur linéaire |

---

## Options à ajouter par priorité

### Priorité 1 : Options de terminaison (essentielles)

Ces options sont critiques pour contrôler le comportement de convergence.

| Option | Type MadNLP | Défaut MadNLP | CTSolvers Default | Aliases | Validator |
|--------|-------------|---------------|-------------------|---------|-----------|
| `acceptable_tol` | `Float64` | `1e-6` | - | `:acc_tol` | `x > 0` |
| `acceptable_iter` | `Int` | `15` | - | - | `x >= 1` |
| `max_wall_time` | `Float64` | `1e6` | - | `:max_time` | `x > 0` |
| `diverging_iterates_tol` | `Float64` | `1e20` | - | - | `x > 0` |

```julia
# Exemple d'implémentation
Strategies.OptionDefinition(;
    name=:acceptable_tol,
    type=Real,
    description="Tolérance acceptable pour convergence précoce (< tol)",
    aliases=(:acc_tol,),
    validator=x -> x > 0 || throw(Exceptions.IncorrectArgument(
        "Invalid acceptable_tol value",
        got="acceptable_tol=$x",
        expected="positive real number (> 0)",
        suggestion="Provide a positive tolerance (typically 1e-6)",
        context="MadNLPSolver acceptable_tol validation"
    ))
)
```

---

### Priorité 2 : Options NLP (importantes pour contrôle optimal)

Ces options influencent directement la résolution de problèmes de contrôle optimal.

| Option | Type MadNLP | Défaut MadNLP | Notes |
|--------|-------------|---------------|-------|
| `nlp_scaling` | `Bool` | `true` | Mise à l'échelle automatique |
| `nlp_scaling_max_gradient` | `Float64` | `100.0` | Gradient max après scaling |
| `jacobian_constant` | `Bool` | `false` | Jacobienne constante (contraintes linéaires) |
| `hessian_constant` | `Bool` | `false` | Hessien constant (pb linéaire/quadratique) |

```julia
Strategies.OptionDefinition(;
    name=:nlp_scaling,
    type=Bool,
    description="Enable automatic NLP scaling"
)
```

---

### Priorité 3 : Options d'initialisation

| Option | Type MadNLP | Défaut MadNLP | Notes |
|--------|-------------|---------------|-------|
| `bound_push` | `Float64` | `1e-2` | Distance min absolue à la borne |
| `bound_fac` | `Float64` | `1e-2` | Distance min relative à la borne |
| `constr_mult_init_max` | `Float64` | `1e3` | Max multiplicateurs duaux initiaux |

---

### Priorité 4 : Options barrière (avancées)

| Option | Type MadNLP | Défaut MadNLP | Validator |
|--------|-------------|---------------|-----------|
| `mu_init` | `Float64` | `0.1` | `x > 0` |
| `mu_min` | `Float64` | `1e-9` | `x > 0` |
| `tau_min` | `Float64` | `0.99` | `0 < x < 1` |

```julia
Strategies.OptionDefinition(;
    name=:mu_init,
    type=Real,
    description="Initial barrier parameter value",
    validator=x -> x > 0 || throw(Exceptions.IncorrectArgument(
        "Invalid mu_init value",
        got="mu_init=$x",
        expected="positive real number (> 0)",
        suggestion="Provide a positive value (typically 0.1)",
        context="MadNLPSolver mu_init validation"
    ))
)
```

---

### Priorité 5 : Options avancées (optionnelles)

#### Approximation Hessienne

| Option | Type | Description |
|--------|------|-------------|
| `hessian_approximation` | `Type{<:MadNLP.AbstractHessian}` | Méthode d'approximation Hessien |

Valeurs valides :

- `MadNLP.ExactHessian` (défaut)
- `MadNLP.BFGS`
- `MadNLP.DampedBFGS`
- `MadNLP.CompactLBFGS`

```julia
Strategies.OptionDefinition(;
    name=:hessian_approximation,
    type=Type{<:MadNLP.AbstractHessian},
    description="Hessian approximation method (ExactHessian, BFGS, DampedBFGS, CompactLBFGS)"
)
```

#### Correction d'inertie

| Option | Type | Description |
|--------|------|-------------|
| `inertia_correction_method` | `Type{<:MadNLP.AbstractInertiaCorrector}` | Méthode de correction d'inertie |

Valeurs valides :

- `MadNLP.InertiaAuto` (défaut)
- `MadNLP.InertiaBased`
- `MadNLP.InertiaFree`
- `MadNLP.InertiaIgnore`

#### Système KKT

| Option | Type | Description |
|--------|------|-------------|
| `kkt_system` | `Type{<:MadNLP.AbstractKKTSystem}` | Type de système KKT |

Valeurs valides :

- `MadNLP.SparseKKTSystem` (défaut pour problèmes creux)
- `MadNLP.SparseCondensedKKTSystem`
- `MadNLP.SparseUnreducedKKTSystem`
- `MadNLP.DenseKKTSystem`
- `MadNLP.DenseCondensedKKTSystem`

---

## Plan d'action détaillé

### Phase 1 : Priorité 1 - Options de terminaison

**Fichiers à modifier :**

- `ext/CTSolversMadNLP.jl` : Ajouter les 4 options dans `Strategies.metadata`

**Tests à ajouter :**

- `test/suite/extensions/test_madnlp_extension.jl` :
  - Test des métadonnées (présence, types)
  - Test de construction avec nouvelles options
  - Test d'intégration avec `acceptable_tol` et `max_wall_time`
  - Test des validateurs (valeurs invalides)

```julia
# Exemple de test unitaire
Test.@testset "Termination Options Metadata" begin
    meta = Strategies.metadata(Solvers.MadNLPSolver)
    
    Test.@test :acceptable_tol in keys(meta)
    Test.@test :acceptable_iter in keys(meta)
    Test.@test :max_wall_time in keys(meta)
    Test.@test :diverging_iterates_tol in keys(meta)
    
    Test.@test meta[:acceptable_tol].type == Real
    Test.@test meta[:acceptable_iter].type == Integer
end

# Test de validation
Test.@testset "Termination Options Validation" begin
    Test.@test_throws Exceptions.IncorrectArgument Solvers.MadNLPSolver(acceptable_tol=-1.0)
    Test.@test_throws Exceptions.IncorrectArgument Solvers.MadNLPSolver(acceptable_iter=0)
    Test.@test_nowarn Solvers.MadNLPSolver(acceptable_tol=1e-5, acceptable_iter=10)
end
```

---

### Phase 2 : Priorité 2 - Options NLP

**Fichiers à modifier :**

- `ext/CTSolversMadNLP.jl`

**Tests à ajouter :**

- Test avec `nlp_scaling=false`
- Test avec `jacobian_constant=true` sur problème linéaire

---

### Phase 3 : Priorité 3 - Options d'initialisation

**Tests à ajouter :**

- Test avec `bound_push` personnalisé
- Vérifier comportement sur problèmes avec bornes serrées

---

### Phase 4 : Priorité 4 - Options barrière

**Tests à ajouter :**

- Test avec `mu_init` différent
- Vérifier convergence avec `mu_min` ajusté

---

### Phase 5 : Priorité 5 - Options avancées

**Tests à ajouter :**

- Test avec `hessian_approximation=MadNLP.BFGS`
- Test avec différents `kkt_system`
- Test avec `inertia_correction_method=MadNLP.InertiaFree`

> [!WARNING]
> Ces options avancées nécessitent une compatibilité entre elles (ex: BFGS nécessite un système KKT dense).

---

## Amélioration des options existantes

### `print_level`

Ajouter un alias `:verbosity` :

```julia
Strategies.OptionDefinition(;
    name=:print_level,
    type=MadNLP.LogLevels,
    default=MadNLP.INFO,
    description="MadNLP logging level (TRACE, DEBUG, INFO, NOTICE, WARN, ERROR)",
    aliases=(:verbosity,)
)
```

### `linear_solver`

Ajouter une description plus détaillée :

```julia
description="Linear solver backend. Requires appropriate extension loaded. " *
            "Options: MadNLPMumps.MumpsSolver (default), MadNLP.UmfpackSolver, " *
            "MadNLP.LDLSolver, MadNLP.CHOLMODSolver, etc."
```

---

## Structure des tests (suivant `.windsurf/rules/testing.md`)

```julia
# test/suite/extensions/test_madnlp_extension.jl

module TestMadNLPExtension

# ... imports ...

function test_madnlp_extension()
    @testset "MadNLP Extension" verbose=VERBOSE showtiming=SHOWTIMING begin
        
        # ====================================================================
        # UNIT TESTS - Metadata
        # ====================================================================
        
        @testset "Metadata - Termination Options" begin
            # Test presence and types
        end
        
        @testset "Metadata - NLP Options" begin
            # Test presence and types
        end
        
        @testset "Metadata - Barrier Options" begin
            # Test presence and types
        end
        
        # ====================================================================
        # UNIT TESTS - Option Validation
        # ====================================================================
        
        @testset "Validation - Termination Options" begin
            # Test invalid values throw IncorrectArgument
        end
        
        @testset "Validation - Barrier Options" begin
            # Test invalid values throw IncorrectArgument
        end
        
        # ====================================================================
        # INTEGRATION TESTS - Options Passing
        # ====================================================================
        
        @testset "Options Passing to MadNLP" begin
            # Verify options are correctly passed to backend
        end
        
        # ====================================================================
        # INTEGRATION TESTS - Solving with Custom Options
        # ====================================================================
        
        @testset "Solve with Custom Termination" begin
            # Test with acceptable_tol, max_wall_time
        end
        
        @testset "Solve with NLP Scaling Disabled" begin
            # Test nlp_scaling=false
        end
        
    end
end

end # module

test_madnlp_extension() = TestMadNLPExtension.test_madnlp_extension()
```

---

## Références

| Source | Chemin |
|--------|--------|
| Options MadNLP | `.reports/2026-02-05_Options_MadNLP/MadNLP.jl-master/src/IPM/options.jl` |
| Types énumérés | `.reports/2026-02-05_Options_MadNLP/MadNLP.jl-master/src/enums.jl` |
| Hessien approx. | `.reports/2026-02-05_Options_MadNLP/MadNLP.jl-master/src/quasi_newton.jl` |
| Inertia correction | `.reports/2026-02-05_Options_MadNLP/MadNLP.jl-master/src/IPM/inertiacorrector.jl` |
| Extension actuelle | `ext/CTSolversMadNLP.jl` |
| Tests existants | `test/suite/extensions/test_madnlp_extension.jl` |
| Règles de testing | `.windsurf/rules/testing.md` |
| Documentation MadNLP | <https://madsuite.org/MadNLP.jl/stable/options/> |

---

## Résumé des livrables par phase

| Phase | Options ajoutées | Fichiers modifiés | Tests ajoutés | Statut |
|-------|-----------------|-------------------|---------------|--------|
| 1 | 4 (terminaison) | `CTSolversMadNLP.jl` | Metadata + Validation + Integration | ✅ Complété |
| 2 | 4 (NLP) | `CTSolversMadNLP.jl` | Metadata + Integration | ✅ Complété |
| 3 | 3 (initialisation) | `CTSolversMadNLP.jl` | Metadata + Integration | ✅ Complété |
| 4 | 3 (barrière) | `CTSolversMadNLP.jl` | Metadata + Validation + Integration | ✅ Complété |
| 5 | 3 (avancées) | `CTSolversMadNLP.jl` | Metadata + Compatibility + Integration | ✅ Complété |

**Total : 17 nouvelles options** (+ amélioration de 2 existantes) - **PROJET TERMINÉ**
