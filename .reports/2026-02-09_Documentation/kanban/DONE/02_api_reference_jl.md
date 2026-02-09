# 02 — Write `api_reference.jl`

**Priority**: 🔴 Critical
**Depends on**: `00_setup_docs_infrastructure`
**Ref**: `reference/02_revised_structure.md` §2, §4

## Description

Create the script that generates all API reference pages automatically. Follows the Public/Internal separation pattern from `migration_to_ctsolvers/docs/api_reference.jl`.

## Pages to Generate

### Public API (one page per module)

- `api/options/options_public.md`
- `api/strategies/strategies_contract_public.md`
- `api/strategies/strategies_api_public.md`
- `api/orchestration/orchestration_public.md`
- `api/optimization/optimization_public.md`
- `api/modelers/modelers_public.md`
- `api/docp/docp_public.md`
- `api/solvers/solvers_public.md`

### Internal API (one page per module)

- `api/options/options_internal.md`
- `api/strategies/strategies_contract_internal.md`
- `api/strategies/strategies_api_internal.md`
- `api/orchestration/orchestration_internal.md`
- `api/optimization/optimization_internal.md`
- `api/modelers/modelers_internal.md`
- `api/docp/docp_internal.md`
- `api/solvers/solvers_internal.md`

### Extensions

- `api/extensions/ipopt.md`
- `api/extensions/madnlp.md`
- `api/extensions/madncl.md`
- `api/extensions/knitro.md`

## Checklist

- [ ] Identify all exported symbols per module (Public)
- [ ] Identify all non-exported documented symbols per module (Internal)
- [ ] Write `@docs` blocks for each page
- [ ] Separate Strategies into Contract (abstract types, default impls) and API (registry, builders, introspection)
- [ ] Add extension pages with `@docs` for extension-specific methods
- [ ] Verify all `@docs` blocks resolve (no missing docstrings)
- [ ] Verify `makedocs` passes with all API pages

## Acceptance Criteria

- Every exported symbol appears in a Public API page
- Every documented internal symbol appears in an Internal API page
- No `@docs` warnings during build
