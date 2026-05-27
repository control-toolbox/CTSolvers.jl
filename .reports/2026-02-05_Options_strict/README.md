# Rapport : Système de Validation Strict/Permissif pour les Options

**Date** : 5 février 2026  
**Version** : 1.0  
**Statut** : Proposition d'Architecture

---

## Vue d'Ensemble

Ce rapport présente une proposition complète pour l'ajout d'un système de validation à deux modes (strict/permissif) dans CTSolvers. Cette fonctionnalité permettra aux utilisateurs avancés de passer des options directement aux backends sans que CTSolvers les connaisse explicitement, tout en conservant la sécurité par défaut.

**Note importante** : CTSolvers se concentre sur les **constructeurs de stratégies** (Solvers, Modelers). L'orchestration complète et la fonction `solve()` seront implémentées dans le package **OptimalControl**, qui utilisera CTSolvers comme dépendance. Ce rapport couvre principalement le niveau constructeur, avec des considérations pour l'orchestration future dans OptimalControl.

## Structure du Rapport

### 1. [Executive Summary](01_executive_summary.md)

Résumé exécutif présentant :
- Objectifs et portée
- Impact sur les utilisateurs
- Recommandation

### 2. [Analyse Détaillée](02_analyse_detaillee.md)

Analyse approfondie incluant :
- Situation actuelle et limitations
- Cas d'usage motivants
- Analyse des besoins (fonctionnels et non-fonctionnels)
- Risques et mitigation
- Alternatives considérées

### 3. [Architecture Technique](03_architecture_technique.md)

Design et implémentation détaillés :
- Principes de design
- Diagramme d'architecture
- Modifications par composant
- Flux de données complets
- Considérations techniques

### 4. [Spécifications des Messages](04_specifications_messages.md)

Définition complète des messages :
- Principes de design des messages
- Messages pour chaque scénario (strict/permissif, constructeur/routage)
- Exemples complets
- Checklist de qualité

### 5. [Plan de Tests](05_plan_tests.md)

Stratégie de validation exhaustive :
- Organisation des tests
- Tests par niveau (unit, integration, performance)
- Checklist de couverture
- Critères d'acceptation

### 6. [Plan d'Implémentation](06_plan_implementation.md)

Roadmap d'implémentation :
- 4 phases progressives
- Timeline et effort estimés
- Tâches détaillées
- Gestion des risques
- Checklist de déploiement

### 7. Décisions de Design (Validées)

Toutes les décisions de design ont été validées le 5 février 2026 :

| # | Question | Décision Validée |
|---|----------|------------------|
| 1 | Nom du paramètre | `mode::Symbol` avec `:strict` (défaut) / `:permissive` |
| 2 | Stockage options | Tout dans `options` avec source `:user_unvalidated` |
| 3 | Validation partielle | Valider complètement les options connues même en mode permissif |
| 4 | Propagation | Explicite à chaque niveau (pas d'état global) |
| 5 | Warnings | Warning à chaque fois (désactivable par l'utilisateur) |
| 6 | Disambiguation | Tuple `(value, :strategy_id)` + helper `route_to(strategy, value)` |
| 7 | Priorité | Options validées prioritaires (cas théorique) |
| 8 | Langue | Anglais uniquement pour tous les messages |
| 9 | Config globale | Paramètre local uniquement (v1.0, YAGNI) |
| 10 | Défaut | Mode strict par défaut (sécurité) |

**Helper optionnel** (export optionnel dans CTSolvers ou OptimalControl) :
```julia
route_to(strategy::Symbol, value) = (value, strategy)
```

## Résumé Technique

### Modifications Principales

| Composant | Fichier | Modification | Package |
|-----------|---------|--------------|---------|
| Strategy Configuration | `src/Strategies/api/configuration.jl` | Ajouter `mode`, gérer `remaining` | CTSolvers |
| Extensions (Solvers) | `ext/CTSolvers*.jl` | Ajouter `mode` aux constructeurs | CTSolvers |
| Modelers | `src/Modelers/*.jl` | Ajouter `mode` aux constructeurs | CTSolvers |
| Orchestration Routing | `routing.jl` | Ajouter `mode`, accepter options disambiguées | OptimalControl (futur) |
| Method Builders | `method_builders.jl` | Propager `mode` | OptimalControl (futur) |

### Nouvelles Fonctions (CTSolvers)

- `_error_unknown_options_strict()` : Gestion erreur mode strict (constructeur)
- `_warn_unknown_options_permissive()` : Gestion warning mode permissif (constructeur)
- `route_to(strategy, value)` : Helper optionnel pour disambiguation (export optionnel)

### Fonctions Futures (OptimalControl)

- `_error_unknown_option_permissive()` : Gestion erreur mode permissif (routage)
- Modifications dans `route_all_options()` pour supporter le mode permissif

### Tests

- 5 fichiers de tests principaux
- Couverture > 95%
- Tests de performance
- Tests d'intégration end-to-end

## Timeline

### CTSolvers (Priorité Immédiate)

**Total** : 5-8 jours de développement

- **Phase 1** : Constructeurs de stratégies (3-5 jours)
- **Phase 2** : Tests et documentation (2-3 jours)

### OptimalControl (Futur)

**Total** : 5-8 jours de développement (après CTSolvers)

- **Phase 1** : Routage et orchestration (3-5 jours)
- **Phase 2** : Tests d'intégration (2-3 jours)

## Impact

### Utilisateurs Standards

✅ **Aucun changement** - Mode strict par défaut maintenu

### Utilisateurs Avancés

✅ **Nouvelle flexibilité** - Accès aux options backend non documentées

### Développeurs

✅ **Système extensible** - Architecture claire et testée

## Exemples d'Utilisation Finaux

### CTSolvers - Mode Strict (Défaut)

```julia
using CTSolvers

# OK - options connues
solver = Solvers.IpoptSolver(max_iter=1000, tol=1e-6)

# Erreur - option inconnue
solver = Solvers.IpoptSolver(max_iter=1000, unknown_opt=123)
# IncorrectArgument: Unknown options provided: [:unknown_opt]
# Did you mean: :max_iter, :tol ?
# Use mode=:permissive to pass undocumented backend options.
```

### CTSolvers - Mode Permissif

```julia
using CTSolvers

# OK avec warning
solver = Solvers.IpoptSolver(
    max_iter=1000,
    custom_ipopt_option=123;
    mode=:permissive
)
# Warning: Unrecognized options passed to backend: [:custom_ipopt_option]

# Erreur - type incorrect même en mode permissif
solver = Solvers.IpoptSolver(max_iter="1000"; mode=:permissive)
# IncorrectArgument: max_iter must be Integer, got String
```

### OptimalControl - Avec Disambiguation (Futur)

```julia
using OptimalControl

# Avec tuple
sol = solve(ocp, :collocation, :adnlp, :ipopt;
    max_iter=100,
    backend=(:sparse, :adnlp);
    mode=:permissive
)

# Avec helper (plus lisible)
sol = solve(ocp, :collocation, :adnlp, :ipopt;
    max_iter=100,
    backend=route_to(:adnlp, :sparse);
    mode=:permissive
)
```

## Recommandation

**✅ APPROUVER** l'implémentation selon l'architecture détaillée dans ce rapport.

**Justification** :
- Besoin réel identifié
- Solution équilibrée (sécurité + flexibilité)
- Risques maîtrisés
- Implémentation faisable
- Rétrocompatibilité garantie
- Toutes les décisions de design validées

## Prochaines Étapes

1. Validation du rapport par l'équipe
2. Création des issues GitHub
3. Démarrage Phase 1
4. Suivi du planning

## Contact

Pour questions ou feedback sur ce rapport :
- **GitHub** : https://github.com/control-toolbox/CTSolvers.jl/issues
- **Email** : dev@control-toolbox.org

---

**Auteurs** : Équipe CTSolvers  
**Dernière mise à jour** : 5 février 2026
