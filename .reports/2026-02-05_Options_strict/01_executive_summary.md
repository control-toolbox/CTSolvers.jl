# Rapport : Système de Validation Strict/Permissif pour les Options

**Date** : 5 février 2026  
**Auteur** : Équipe CTSolvers  
**Version** : 1.0  
**Statut** : Proposition d'Architecture

---

## Résumé Exécutif

Ce rapport présente une proposition d'architecture pour l'ajout d'un système de validation à deux modes (strict/permissif) dans CTSolvers. Cette fonctionnalité permettra aux utilisateurs avancés de passer des options directement aux backends (Ipopt, MadNLP, etc.) sans que CTSolvers les connaisse explicitement, tout en conservant la sécurité par défaut du mode strict actuel.

**Note importante** : CTSolvers se concentre sur les **constructeurs de stratégies**. L'orchestration complète (fonction `solve()` et routage d'options) sera implémentée dans le package **OptimalControl**. Ce rapport couvre principalement CTSolvers, avec des considérations architecturales pour OptimalControl.

### Objectifs

1. **Sécurité par défaut** : Maintenir le comportement strict actuel qui détecte les erreurs de typo
2. **Flexibilité avancée** : Permettre aux experts de passer des options backend non documentées
3. **Messages clairs** : Fournir une guidance explicite pour l'utilisateur
4. **Rétrocompatibilité** : Aucun breaking change

### Portée

**CTSolvers (ce rapport)** :

1. **Constructeurs de stratégies** (Modelers, Solvers, etc.)
   - Validation des options par rapport aux metadata
   - Stockage et transmission des options non validées en mode permissif
   - Paramètre `mode::Symbol` avec valeurs `:strict` (défaut) et `:permissive`

**OptimalControl (futur)** :

2. **Routage d'options** (Orchestration)
   - Routage des options vers les stratégies appropriées via `solve()`
   - Gestion des options inconnues avec disambiguation obligatoire en mode permissif
   - Propagation du paramètre `mode` à travers la chaîne d'appels

### Impact

- **Utilisateurs standards** : Aucun changement (mode strict par défaut)
- **Utilisateurs avancés** : Nouvelle flexibilité pour options backend
- **Développeurs** : Système extensible et bien testé
- **Performance** : Impact négligeable (overhead minimal en mode permissif)

### Recommandation

**Approuver l'implémentation** selon l'architecture détaillée dans ce rapport, avec une implémentation progressive en 4 phases pour minimiser les risques.

---

## Structure du Rapport

1. **Executive Summary** (ce document)
2. **Analyse Détaillée** - Contexte et motivation
3. **Architecture Technique** - Design et implémentation
4. **Spécifications des Messages** - Erreurs et warnings
5. **Plan de Tests** - Stratégie de validation
6. **Plan d'Implémentation** - Phases et timeline
7. **Annexes** - Exemples de code et références
