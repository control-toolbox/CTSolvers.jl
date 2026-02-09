# Revue Critique et Recommandations

**Date** : 9 février 2026
**Objet** : Analyse critique du plan de documentation proposé dans `propal/`

---

## Contenu de ce répertoire

### [01 — Revue Critique](./01_critical_review.md)

Analyse systématique du plan initial confronté au code source réel.

Principaux constats :

- **Superficialité** : Le plan liste des fichiers sans préciser leur contenu. Il manque un synopsis par page.
- **Redondance** : Les 3 documents de la proposition répètent les mêmes informations. Interface et tutoriel sont séparés alors qu'ils couvrent les mêmes sujets.
- **Concepts manquants** : Le two-level contract, la hiérarchie des types, CommonSolve multi-level, Tag Dispatch, StrategyMetadata, StrategyOptions et provenance tracking ne sont pas mentionnés.
- **User Guide surdimensionné** : 4 pages pour un public qui est développeur, pas utilisateur final.
- **Erreurs factuelles** : Nombre d'exports, de fichiers et de couverture incorrects.
- **Architecture en retard** : `architecture.md` arrive en Phase 3 alors que c'est le pivot central.

### [02 — Structure Révisée et Synopsis](./02_revised_structure.md)

Proposition révisée avec :

- **8 pages manuelles** (au lieu de 17+) : moins de volume, plus de densité
- **Fusion interface + tutoriel** : un seul document par contrat
- **API séparée Public/Internal** : conforme au modèle de référence existant
- **Synopsis détaillé** pour chaque page (contenu section par section)
- **Ordre d'implémentation** révisé : architecture d'abord, index en dernier
- **Configuration `make.jl`** complète avec structure de navigation

### [03 — Standards de Qualité pour les Tutoriels](./03_tutorial_quality_standards.md)

Définition rigoureuse de ce qu'est un bon tutoriel développeur :

- **Framework Diátaxis** appliqué à CTSolvers (tutoriel vs how-to vs référence vs explication)
- **Anatomie d'un bon tutoriel** : structure obligatoire, règles pour les blocs de code, règles de rédaction
- **Checklists de validation** par type de page
- **Anti-patterns** à éviter (code incomplet, explication sans code, redondance avec l'API)
- **Métriques de qualité** pertinentes (pas "20+ fichiers" mais "chaque contrat a un exemple exécutable")

### [04 — Diagrammes Mermaid](./04_mermaid_diagrams.md)

Catalogue de 15 diagrammes Mermaid proposés pour la documentation :

- **Hiérarchies de types** (classDiagram) : branches Strategy et Optimization/Builders
- **Dépendances entre modules** (flowchart) : ordre de chargement et dépendances `using`
- **Flux de résolution** (sequenceDiagram) : parcours complet OCP → NLP → Solution avec appels de méthodes
- **Two-level contract** (flowchart) : distinction type-level vs instance-level
- **Cycle de vie d'une stratégie** (flowchart) : du type à l'instance
- **Architecture Solver + Extension** (flowchart) : séparation src/ext et Tag Dispatch
- **CommonSolve multi-level** (flowchart) : les 3 niveaux d'API
- **Flux Modeler** (sequenceDiagram) : interaction modeler/problem/builders
- **DOCP + Builders** (erDiagram) : structure et relations
- **Routage d'options** (flowchart + sequenceDiagram) : parcours décisionnel et désambiguïsation
- **Chaîne de construction des options** (flowchart) : OptionDefinition → StrategyOptions
- **Modes de validation** (flowchart) : strict vs permissif

### [05 — Stratégie d'Intégration des Affichages](./05_display_strategy.md)

Comment exploiter la documentation comme banc de validation visuelle des affichages et messages d'erreur :

- **Problématique** : 10 scripts manuels dans `test/extras/` valident les affichages mais ne sont ni automatisés ni pérennes
- **Mécanismes Documenter.jl** : `@example` (affichages normaux), `@repl` (erreurs sans crash), `@setup` (imports cachés)
- **Inventaire complet** : 18 affichages normaux + 13 messages d'erreur classés par page cible
- **3 règles d'intégration** : au fil du tutoriel (pas en bloc), erreurs comme "ce qui se passe si...", page dédiée pour le catalogue
- **Page `error_messages.md`** : nouvelle page de référence regroupant tous les messages d'erreur avec cause/solution
- **Bénéfices** : validation CI continue, documentation vivante, pédagogie par l'erreur, incitation à améliorer les messages

---

## Synthèse des Recommandations

Les 10 actions correctives prioritaires :

1. **Fusionner interface + tutoriel** en un seul document par contrat
2. **Supprimer le User Guide dédié** (la cible est développeur, pas utilisateur)
3. **Placer `architecture.md` en premier** comme pivot central de la documentation
4. **Reprendre le modèle API** de `migration_to_ctsolvers/docs/api_reference.jl` (séparation Public/Internal)
5. **Documenter les concepts manquants** : two-level contract, hiérarchie des types, CommonSolve multi-level, Tag Dispatch
6. **Écrire un synopsis par page** avant de commencer la rédaction
7. **Appliquer les standards de qualité** : code exécutable, tests à chaque étape, liens `@ref`
8. **Adopter un ton technique** sobre, sans emojis ni formulations marketing
9. **Intégrer des diagrammes Mermaid** : 15 diagrammes répartis sur 8 pages (cf. catalogue 04)
10. **Intégrer les affichages et erreurs** dans la doc via `@example`/`@repl` + page `error_messages.md` (cf. stratégie 05)
