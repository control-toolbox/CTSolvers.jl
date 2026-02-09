# 10 — Write `index.md`

**Priority**: 🟡 Medium
**Depends on**: All other pages (written last)
**Ref**: `reference/02_revised_structure.md` §3.1

## Description

The entry point page. Written last because it references all other pages and needs stable content to link to. Must orient a developer in 30 seconds.

## Sections to Write

### Positioning

- CTSolvers = resolution layer in the control-toolbox ecosystem
- Clear distinction with CTModels (problem definition) and OptimalControl (user interface)

### Module Overview

- The 7 modules in one sentence each, with link to the appropriate page

### Access Convention

- Qualified access: `CTSolvers.Strategies.id(...)`, no direct exports

### Quick Start

- One `@example` block of 10–15 lines showing the complete flow: OCP → DOCP → NLP → Solution

### Navigation Table

- "I want to understand the architecture → `architecture.md`"
- "I want to implement a solver → `guides/implementing_a_solver.md`"
- etc.

## What This Page is NOT

- Not an installation guide
- Not a project history
- Not an exhaustive feature list

## Checklist

- [ ] Write in English
- [ ] Include Quick Start `@example` block (must be executable)
- [ ] Navigation table with links to all guides
- [ ] Add `@ref` links to all pages
- [ ] Verify `makedocs` passes
- [ ] Target: 80–120 lines

## Acceptance Criteria

- A developer landing on this page knows where to go in 30 seconds
- Quick Start code block runs successfully
