# Kanban — Documentation CTSolvers

## Vue d'ensemble

12 tâches pour la reprise complète de la documentation, organisées selon
l'ordre d'implémentation défini dans `reference/02_revised_structure.md` §5.

## Graphe de dépendances

```text
00_setup_docs_infrastructure
├── 01_architecture_md
│   └── 03_implementing_a_strategy_md
│       ├── 04_implementing_a_solver_md
│       ├── 05_implementing_a_modeler_md
│       │   └── 06_implementing_an_optimization_problem_md
│       ├── 07_orchestration_and_routing_md
│       ├── 08_options_system_md
│       │   └── 09_error_messages_md
│       └── 09_error_messages_md
├── 02_api_reference_jl
└── 10_index_md (dépend de toutes les pages)
    └── 11_review_and_cleanup (dépend de tout)
```

## Résumé des tâches

| # | Tâche | Priorité | Dépend de | Page cible | Lignes |
|---|-------|----------|-----------|------------|--------|
| 00 | Setup docs/ infrastructure | 🔴 Critical | — | `docs/` structure, `make.jl` | — |
| 01 | Write `architecture.md` | 🔴 Critical | 00 | `architecture.md` | 200–300 |
| 02 | Write `api_reference.jl` | 🔴 Critical | 00 | ~22 pages API | — |
| 03 | Write `implementing_a_strategy.md` | 🔴 Critical | 01 | `guides/implementing_a_strategy.md` | 400–500 |
| 04 | Write `implementing_a_solver.md` | 🟠 High | 03 | `guides/implementing_a_solver.md` | 300–400 |
| 05 | Write `implementing_a_modeler.md` | 🟠 High | 03 | `guides/implementing_a_modeler.md` | 200–300 |
| 06 | Write `implementing_an_optimization_problem.md` | 🟠 High | 05 | `guides/implementing_an_optimization_problem.md` | 200–300 |
| 07 | Write `orchestration_and_routing.md` | 🟠 High | 03 | `guides/orchestration_and_routing.md` | 200–300 |
| 08 | Write `options_system.md` | 🟡 Medium | 03 | `guides/options_system.md` | 200–250 |
| 09 | Write `error_messages.md` | 🟡 Medium | 03, 08 | `guides/error_messages.md` | ~150 |
| 10 | Write `index.md` | 🟡 Medium | Toutes | `index.md` | 80–120 |
| 11 | Final review and cleanup | 🟢 Low | Toutes | — | — |

**Total estimé** : ~2000–2700 lignes de contenu manuel + ~22 pages API générées.

## Conventions

- **Déplacer** un fichier de `TODO/` vers `IN_PROGRESS/` quand on commence à travailler dessus
- **Déplacer** de `IN_PROGRESS/` vers `DONE/` quand la checklist est complète
- **Déplacer** vers `SKIPPED/` si la tâche est reportée ou abandonnée
- Cocher les items `[ ]` → `[x]` dans la checklist au fur et à mesure

## Documents de référence

Chaque tâche renvoie aux documents de `reference/` :

- `01_critical_review.md` — Constats et problèmes identifiés
- `02_revised_structure.md` — Structure cible et synopsis par page
- `03_tutorial_quality_standards.md` — Standards de qualité (Diátaxis, code exécutable, langue anglaise)
- `04_mermaid_diagrams.md` — Catalogue de 15 diagrammes Mermaid
- `05_display_strategy.md` — Stratégie d'intégration des affichages et erreurs
- `06_discretizer_tutorial.md` — Exemple concret Collocation + DirectShooting
