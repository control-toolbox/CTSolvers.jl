# Docstrings Review Project

**Date**: 2026-02-09  
**Objective**: Complete review and update of all docstrings in CTSolvers.jl

## Context

After significant refactoring (structure access, iteration interfaces), we need to ensure all docstrings are:
- **Accurate**: Reflect current implementation
- **Complete**: Cover all public and key internal APIs
- **Clear**: Easy to understand for users and developers
- **Consistent**: Follow project standards without superfluity

## Documentation Philosophy

### What to Include
- **Purpose**: What the function/type does
- **Exceptions**: What errors can be thrown and when
- **Preconditions**: Required state or argument constraints
- **Examples**: When they add value (not systematically)
- **Cross-references**: Related functions/types with `[@ref]`
- **Contracts**: For abstract types (interface requirements, available API)

### What to Avoid
- ❌ Performance claims without evidence ("fast", "optimized")
- ❌ Marketing language ("powerful", "flexible")
- ❌ Redundant examples for trivial getters/setters
- ❌ Aspirational features not yet implemented
- ❌ Overly verbose descriptions of obvious behavior

### Example Policy

**Include examples for**:
- Public API functions (exported)
- Complex behavior or non-obvious usage
- Abstract types (show interface implementation)
- Main constructors and entry points

**Skip examples for**:
- Trivial getters: `get_value(x) = x.value`
- Standard Base methods: `Base.length`, `Base.keys` (unless special behavior)
- Internal helpers with obvious purpose

## Scope

**In scope**: `src/` and `ext/` directories  
**Out of scope**: `test/` directory (tests are context, not documentation targets)

## References

- Primary guide: `.windsurf/rules/docstrings.md`
- Workflow: `@[/doc-julia]`
- DocStringExtensions macros: `$(TYPEDSIGNATURES)`, `$(TYPEDEF)`

## Organization

See `Kanban/` subdirectory for task tracking:
- `TODO/` - Files awaiting review
- `IN_PROGRESS/` - Currently being worked on  
- `DONE/` - Completed and verified
- `SKIPPED/` - Intentionally not documented (with reason)

## Quality Checklist

For each docstring:
- [ ] Directly above declaration (no blank lines)
- [ ] Uses `$(TYPEDSIGNATURES)` or `$(TYPEDEF)`
- [ ] Clear one-sentence summary
- [ ] All arguments/fields documented with types
- [ ] Return value documented (if applicable)
- [ ] Exceptions documented
- [ ] Example is safe and adds value (if included)
- [ ] Cross-references use `[@ref]` syntax
- [ ] No code changes (docstrings only)
- [ ] Consistent terminology

## Progress Tracking

Total files: TBD  
- TODO: TBD
- IN_PROGRESS: 0
- DONE: 0
- SKIPPED: 0

## Notes

- Focus on accuracy over completeness initially
- When uncertain about behavior, add conservative description and mark for clarification
- Keep language technical and precise
