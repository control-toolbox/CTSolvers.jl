# Plan d'Implémentation : Phases et Timeline

## 1. Vue d'Ensemble

### 1.1 Stratégie d'Implémentation

**Approche** : Implémentation progressive en 4 phases pour minimiser les risques.

**Principes** :
- Chaque phase est indépendante et testable
- Pas de breaking changes
- Validation à chaque étape
- Possibilité de rollback

### 1.2 Timeline Estimée

| Phase | Durée | Effort | Priorité |
|-------|-------|--------|----------|
| Phase 1 : Constructeurs | 3-5 jours | Moyen | Haute |
| Phase 2 : Routage | 3-5 jours | Moyen | Haute |
| Phase 3 : Propagation | 2-3 jours | Faible | Moyenne |
| Phase 4 : Finalisation | 2-3 jours | Faible | Moyenne |
| **Total** | **10-16 jours** | **Moyen** | - |

**Note** : Timeline pour un développeur à temps plein. Peut être parallélisé.

## 2. Phase 1 : Constructeurs de Stratégies

### 2.1 Objectifs

Implémenter le mode strict/permissif au niveau des constructeurs de stratégies.

**Livrables** :
- ✅ `build_strategy_options()` modifié
- ✅ Fonctions helper pour messages
- ✅ Helper optionnel `route_to()` pour disambiguation
- ✅ Tests unitaires complets
- ✅ Documentation inline

### 2.2 Tâches Détaillées

#### Tâche 1.1 : Modifier `build_strategy_options()`

**Fichier** : `src/Strategies/api/configuration.jl`

**Actions** :
1. Ajouter paramètre `mode::Symbol = :strict`
2. Valider le mode (`:strict` ou `:permissive`)
3. Récupérer `remaining` de `Options.extract_options()`
4. Implémenter logique strict/permissif
5. Ajouter docstring

**Estimation** : 2-3 heures

**Code** :
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
    
    if !isempty(remaining)
        if mode == :strict
            _error_unknown_options_strict(remaining, strategy_type, meta)
        else  # mode == :permissive
            _warn_unknown_options_permissive(remaining, strategy_type)
            # Store with special source :user_unvalidated
            for (key, value) in pairs(remaining)
                extracted[key] = Options.OptionValue(value, :user_unvalidated)
            end
        end
    end
    
    nt = (; (k => v for (k, v) in extracted)...)
    return StrategyOptions(nt)
end
```

#### Tâche 1.2 : Implémenter `_error_unknown_options_strict()`

**Fichier** : `src/Strategies/api/configuration.jl`

**Actions** :
1. Créer fonction helper
2. Générer suggestions avec Levenshtein
3. Formater message d'erreur
4. Utiliser `Exceptions.IncorrectArgument`

**Estimation** : 2-3 heures

**Dépendances** :
- `suggest_options()` existe déjà dans `src/Strategies/api/utilities.jl`
- `levenshtein_distance()` existe déjà

#### Tâche 1.3 : Implémenter `_warn_unknown_options_permissive()`

**Fichier** : `src/Strategies/api/configuration.jl`

**Actions** :
1. Créer fonction helper
2. Formater message warning
3. Utiliser `@warn`

**Estimation** : 1 heure

#### Tâche 1.4 : Tests Unitaires

**Fichier** : `test/suite/strategies/test_validation_strict.jl`
**Fichier** : `test/suite/strategies/test_validation_permissive.jl`

**Actions** :
1. Créer fichiers de tests
2. Implémenter tous les cas de test
3. Vérifier couverture > 95%

**Estimation** : 4-6 heures

#### Tâche 1.5 : Documentation

**Actions** :
1. Mettre à jour docstrings
2. Ajouter exemples
3. Documenter le paramètre `strict`

**Estimation** : 1-2 heures

### 2.3 Validation Phase 1

**Critères d'acceptation** :
- [ ] Tous les tests passent
- [ ] Couverture > 95%
- [ ] Pas de breaking changes
- [ ] Documentation complète
- [ ] Code review approuvé

**Commande de validation** :
```bash
julia --project=@. -e 'using Pkg; Pkg.test()'
julia --project=@. test/suite/strategies/test_validation_strict.jl
julia --project=@. test/suite/strategies/test_validation_permissive.jl
```

## 3. Phase 2 : Routage (Orchestration)

### 3.1 Objectifs

Implémenter le mode strict/permissif au niveau du routage d'options.

**Livrables** :
- ✅ `route_all_options()` modifié
- ✅ Fonction helper pour mode permissif
- ✅ Tests unitaires complets
- ✅ Documentation inline

### 3.2 Tâches Détaillées

#### Tâche 2.1 : Modifier `route_all_options()`

**Fichier** : `src/Orchestration/routing.jl`

**Actions** :
1. Ajouter paramètre `mode::Symbol = true`
2. Modifier gestion des options avec 0 owners
3. Accepter options disambiguées en mode permissif
4. Ajouter warnings appropriés

**Estimation** : 3-4 heures

**Points d'attention** :
- Gérer les options disambiguées mais inconnues
- Maintenir le comportement pour options ambiguës
- Vérifier que le routage invalide est toujours détecté

#### Tâche 2.2 : Implémenter `_error_unknown_option_permissive()`

**Fichier** : `src/Orchestration/routing.jl`

**Actions** :
1. Créer fonction helper
2. Formater message expliquant le requirement de disambiguation
3. Fournir exemples pour chaque stratégie

**Estimation** : 2 heures

#### Tâche 2.3 : Modifier `_error_unknown_option()`

**Fichier** : `src/Orchestration/routing.jl`

**Actions** :
1. Adapter le message pour mode strict
2. Mentionner le mode permissif comme alternative

**Estimation** : 1 heure

#### Tâche 2.4 : Tests Unitaires

**Fichier** : `test/suite/orchestration/test_routing_strict.jl`
**Fichier** : `test/suite/orchestration/test_routing_permissive.jl`

**Actions** :
1. Créer fichiers de tests
2. Implémenter tous les cas de test
3. Vérifier couverture > 95%

**Estimation** : 4-6 heures

### 3.3 Validation Phase 2

**Critères d'acceptation** :
- [ ] Tous les tests passent
- [ ] Couverture > 95%
- [ ] Pas de breaking changes
- [ ] Messages clairs et informatifs
- [ ] Code review approuvé

**Commande de validation** :
```bash
julia --project=@. test/suite/orchestration/test_routing_strict.jl
julia --project=@. test/suite/orchestration/test_routing_permissive.jl
```

## 4. Phase 3 : Propagation

### 4.1 Objectifs

Propager le paramètre `strict` à travers toute la chaîne d'appels.

**Livrables** :
- ✅ Modifications dans `method_builders.jl`
- ✅ Modifications dans `builders.jl`
- ✅ Modifications dans les extensions
- ✅ Modifications dans les modelers
- ✅ Tests d'intégration

### 4.2 Tâches Détaillées

#### Tâche 3.1 : Modifier `build_strategy_from_method()`

**Fichier** : `src/Orchestration/method_builders.jl`

**Actions** :
1. Ajouter paramètre `mode::Symbol = true`
2. Propager à `build_strategy()`

**Estimation** : 30 minutes

#### Tâche 3.2 : Modifier `build_strategy()`

**Fichier** : `src/Strategies/api/builders.jl`

**Actions** :
1. Ajouter paramètre `mode::Symbol = true`
2. Propager à `build_strategy_options()`

**Estimation** : 30 minutes

#### Tâche 3.3 : Modifier Extensions (Solvers)

**Fichiers** :
- `ext/CTSolversIpopt.jl`
- `ext/CTSolversMadNLP.jl`
- `ext/CTSolversKnitro.jl`
- `ext/CTSolversMadNCL.jl`

**Actions** :
1. Ajouter paramètre `mode::Symbol = true` aux constructeurs
2. Propager à `build_strategy_options()`

**Estimation** : 1-2 heures (4 fichiers)

#### Tâche 3.4 : Modifier Modelers

**Fichiers** :
- `src/Modelers/adnlp_modeler.jl`
- `src/Modelers/exa_modeler.jl`

**Actions** :
1. Ajouter paramètre `mode::Symbol = true` aux constructeurs
2. Propager à `build_strategy_options()`

**Estimation** : 1 heure (2 fichiers)

#### Tâche 3.5 : Tests d'Intégration

**Fichier** : `test/suite/integration/test_strict_permissive_integration.jl`

**Actions** :
1. Créer fichier de tests
2. Tester propagation end-to-end
3. Vérifier que le mode se propage correctement

**Estimation** : 3-4 heures

### 4.3 Validation Phase 3

**Critères d'acceptation** :
- [ ] Tous les tests passent
- [ ] Propagation fonctionne end-to-end
- [ ] Pas de breaking changes
- [ ] Toutes les extensions mises à jour
- [ ] Code review approuvé

**Commande de validation** :
```bash
julia --project=@. test/suite/integration/test_strict_permissive_integration.jl
julia --project=@. -e 'using Pkg; Pkg.test()'
```

## 5. Phase 4 : Finalisation

### 5.1 Objectifs

Finaliser l'implémentation avec documentation, benchmarks et polish.

**Livrables** :
- ✅ Documentation utilisateur
- ✅ Tests de performance
- ✅ Exemples d'utilisation
- ✅ Guide de migration
- ✅ Release notes

### 5.2 Tâches Détaillées

#### Tâche 4.1 : Documentation Utilisateur

**Fichier** : `docs/src/options_validation.md` (nouveau)

**Actions** :
1. Expliquer les modes strict/permissif
2. Fournir exemples d'utilisation
3. Documenter quand utiliser chaque mode
4. Ajouter FAQ

**Estimation** : 3-4 heures

**Contenu** :
- Introduction aux modes
- Exemples constructeur direct
- Exemples via solve()
- Cas d'usage avancés
- Troubleshooting

#### Tâche 4.2 : Tests de Performance

**Fichier** : `test/suite/integration/test_strict_permissive_performance.jl`

**Actions** :
1. Créer benchmarks
2. Vérifier overhead < 1% mode strict
3. Vérifier overhead < 5% mode permissif
4. Documenter résultats

**Estimation** : 2-3 heures

#### Tâche 4.3 : Exemples d'Utilisation

**Fichier** : `examples/strict_permissive_modes.jl` (nouveau)

**Actions** :
1. Créer exemples complets
2. Couvrir tous les cas d'usage
3. Ajouter commentaires explicatifs

**Estimation** : 2 heures

#### Tâche 4.4 : Guide de Migration

**Fichier** : `docs/src/migration_strict_permissive.md` (nouveau)

**Actions** :
1. Expliquer les changements
2. Montrer comment migrer si nécessaire
3. Rassurer sur la rétrocompatibilité

**Estimation** : 1-2 heures

#### Tâche 4.5 : Release Notes

**Fichier** : `CHANGELOG.md`

**Actions** :
1. Documenter la nouvelle fonctionnalité
2. Lister les changements
3. Mentionner la rétrocompatibilité

**Estimation** : 1 heure

### 5.3 Validation Phase 4

**Critères d'acceptation** :
- [ ] Documentation complète et claire
- [ ] Benchmarks montrent overhead acceptable
- [ ] Exemples fonctionnent
- [ ] Guide de migration disponible
- [ ] Release notes rédigées
- [ ] Revue finale approuvée

## 6. Gestion des Risques

### 6.1 Risques par Phase

#### Phase 1 : Constructeurs

**Risque** : Breaking change dans `build_strategy_options()`

**Mitigation** :
- Paramètre `strict` a une valeur par défaut
- Tests de non-régression complets
- Validation avant merge

**Probabilité** : Faible

#### Phase 2 : Routage

**Risque** : Complexité du routage avec disambiguation

**Mitigation** :
- Tests exhaustifs de tous les cas
- Code review approfondi
- Documentation claire

**Probabilité** : Moyenne

#### Phase 3 : Propagation

**Risque** : Oubli de propager `strict` quelque part

**Mitigation** :
- Checklist de tous les fichiers
- Tests d'intégration end-to-end
- Grep pour vérifier

**Probabilité** : Moyenne

#### Phase 4 : Finalisation

**Risque** : Documentation incomplète ou confuse

**Mitigation** :
- Revue par utilisateurs
- Exemples testés
- Feedback itératif

**Probabilité** : Faible

### 6.2 Plan de Rollback

Si un problème majeur est découvert après merge :

1. **Identification** : Tests CI détectent le problème
2. **Évaluation** : Déterminer la gravité
3. **Décision** :
   - Problème mineur → Fix rapide
   - Problème majeur → Rollback
4. **Rollback** :
   - Revert du commit
   - Notification équipe
   - Post-mortem
5. **Re-implémentation** :
   - Analyse du problème
   - Fix et re-test
   - Nouveau merge

## 7. Checklist de Déploiement

### 7.1 Avant le Merge

- [ ] Toutes les phases complétées
- [ ] Tous les tests passent (local + CI)
- [ ] Couverture de code > 95%
- [ ] Documentation complète
- [ ] Code review approuvé
- [ ] Benchmarks validés
- [ ] Pas de breaking changes
- [ ] Release notes rédigées

### 7.2 Merge

- [ ] Créer PR avec description détaillée
- [ ] Lier aux issues correspondantes
- [ ] Attendre approbation de 2+ reviewers
- [ ] Vérifier CI passe
- [ ] Squash et merge
- [ ] Tag de version

### 7.3 Après le Merge

- [ ] Vérifier CI sur main
- [ ] Mettre à jour documentation en ligne
- [ ] Annoncer la fonctionnalité
- [ ] Monitorer les issues
- [ ] Préparer hotfix si nécessaire

## 8. Ressources Nécessaires

### 8.1 Humaines

**Développeur principal** : 1 personne, 10-16 jours
- Implémentation
- Tests
- Documentation

**Reviewer** : 1-2 personnes, 2-3 jours
- Code review
- Validation tests
- Feedback documentation

**Testeur** : 1 personne, 1-2 jours (optionnel)
- Tests manuels
- Validation exemples
- Feedback utilisateur

### 8.2 Techniques

**Environnement de développement** :
- Julia 1.9+
- Packages de test (Test, BenchmarkTools)
- Extensions (NLPModelsIpopt, MadNLP, etc.)

**CI/CD** :
- GitHub Actions
- Coverage reporting
- Automated tests

### 8.3 Documentation

**Outils** :
- Documenter.jl pour la doc
- Markdown pour les guides
- Exemples exécutables

## 9. Suivi et Métriques

### 9.1 Métriques de Développement

| Métrique | Cible | Actuel |
|----------|-------|--------|
| Couverture de code | > 95% | - |
| Tests passants | 100% | - |
| Overhead performance | < 1% strict, < 5% permissif | - |
| Temps de build | < 5 min | - |

### 9.2 Métriques Post-Déploiement

| Métrique | Cible | Suivi |
|----------|-------|-------|
| Issues liées | < 5 | GitHub Issues |
| Adoption mode permissif | 5-10% utilisateurs | Logs (optionnel) |
| Satisfaction utilisateurs | > 80% | Survey (optionnel) |

### 9.3 Jalons

| Jalon | Date Cible | Statut |
|-------|------------|--------|
| Phase 1 complète | J+5 | ⏳ En attente |
| Phase 2 complète | J+10 | ⏳ En attente |
| Phase 3 complète | J+13 | ⏳ En attente |
| Phase 4 complète | J+16 | ⏳ En attente |
| Merge dans main | J+17 | ⏳ En attente |
| Release | J+20 | ⏳ En attente |

## 10. Communication

### 10.1 Communication Interne

**Pendant le développement** :
- Daily standups (si équipe)
- Updates dans Slack/Discord
- PR comments pour discussions techniques

**Avant le merge** :
- Présentation de la fonctionnalité
- Demo pour l'équipe
- Q&A session

### 10.2 Communication Externe

**Après le merge** :
- Annonce sur forum/Discord
- Blog post (optionnel)
- Tweet/social media
- Mise à jour documentation

**Message type** :
```
🎉 Nouvelle fonctionnalité : Modes Strict/Permissif pour les Options

CTSolvers v0.X.0 introduit un système de validation flexible :

✅ Mode Strict (défaut) : Sécurité maximale, détecte les typos
🔓 Mode Permissif : Flexibilité pour options backend avancées

Exemples et documentation : https://...

#JuliaLang #OptimalControl
```

## 11. Conclusion

### 11.1 Résumé

Cette implémentation en 4 phases permet :
- **Sécurité** : Mode strict par défaut
- **Flexibilité** : Mode permissif pour experts
- **Qualité** : Tests exhaustifs et documentation complète
- **Maintenabilité** : Code clair et bien structuré

### 11.2 Prochaines Étapes

Après validation de ce plan :
1. Créer les issues GitHub pour chaque phase
2. Assigner les ressources
3. Démarrer Phase 1
4. Suivre le planning et ajuster si nécessaire

### 11.3 Contact

Pour questions ou clarifications :
- GitHub Issues : https://github.com/control-toolbox/CTSolvers.jl/issues
- Discord : https://discord.gg/...
- Email : dev@control-toolbox.org
