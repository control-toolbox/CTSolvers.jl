# Architecture

```@meta
CurrentModule = CTSolvers
```

!!! warning "Work in Progress"
    This page is under construction. See [kanban task 01](../../.reports/2026-02-09_Documentation/kanban/TODO/01_architecture_md.md) for the planned content.

## Overview

CTSolvers is organized into 7 modules loaded in a specific order:

1. **Options** — Configuration system (OptionDefinition, OptionValue, extraction)
2. **Strategies** — Strategy contract and registry (AbstractStrategy, StrategyMetadata, StrategyOptions)
3. **Orchestration** — Multi-strategy option routing and disambiguation
4. **Optimization** — Abstract optimization types and builders (AbstractOptimizationProblem, AbstractBuilder)
5. **Modelers** — NLP model backends (ADNLPModeler, ExaModeler)
6. **DOCP** — Discretized Optimal Control Problem
7. **Solvers** — Solver integration (IpoptSolver, MadNLPSolver, etc.)

## Type Hierarchies

TODO: Mermaid class diagrams for Strategy and Optimization/Builder branches.

## Module Dependencies

TODO: Mermaid flowchart showing module loading order and dependencies.

## Data Flow

TODO: Mermaid sequence diagram showing the complete resolution pipeline.

## Architectural Patterns

TODO: Two-level contract, NotImplemented pattern, Tag Dispatch, Qualified access.

## Conventions

TODO: Naming, constructor pattern, OptionDefinition pattern.
