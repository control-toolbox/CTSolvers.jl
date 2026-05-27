# 11 — Final Review and Cleanup

**Priority**: 🟢 Low
**Depends on**: All other tasks
**Ref**: `reference/03_tutorial_quality_standards.md`, `reference/05_display_strategy.md` §7

## Description

Final pass over the complete documentation before release. Verify quality standards, cross-references, and consistency.

## Checklist

- [ ] **Language**: All documentation pages are in English (ref: `03_tutorial_quality_standards.md` §2.2)
- [ ] **Code blocks**: Every `@example`/`@repl` block executes without error during `makedocs`
- [ ] **Cross-references**: All `@ref` links resolve correctly
- [ ] **Mermaid diagrams**: All diagrams render correctly in the HTML output
- [ ] **Consistency**: Terminology is consistent across all pages (e.g., "strategy" not "tool", "options" not "kwargs")
- [ ] **No duplicates**: No concept is explained in two different places
- [ ] **Navigation**: Every page is reachable from `index.md` within 2 clicks
- [ ] **API coverage**: Every exported symbol appears in a Public API page
- [ ] **Error messages**: All key error messages appear in `error_messages.md`
- [ ] **Tone**: Technical, sober, no emojis, no marketing language (ref: `03_tutorial_quality_standards.md`)
- [ ] **CI**: Documentation builds and deploys successfully in CI
- [ ] **Retire `test/extras/`**: Once displays are integrated in docs, archive or remove the manual display scripts

## Acceptance Criteria

- `makedocs` completes with zero warnings
- Documentation deploys successfully
- A new developer can navigate the docs and implement a strategy without external help
