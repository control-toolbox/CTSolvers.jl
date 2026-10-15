# docs/

Documentation site for CTSolvers.jl, built with
[DocumenterVitepress](https://github.com/LuxDL/DocumenterVitepress.jl).

Build (from the package root):

```bash
julia --project=docs docs/make.jl
```

Preview after build: `npx serve docs/build/1 --listen 5173`

Documentation conventions and build workflow:
[ct-conventions](https://github.com/control-toolbox/ct-conventions) (rules `SITE1`–`SITE17`, `method.md`).

## `@repl` vs `@example` — ANSI color rule

Before `DocumenterVitepress` **v0.3.5**, ANSI-colored output from `@repl` could be rendered as raw
escape sequences. This was fixed in v0.3.5 ([#373](https://github.com/LuxDL/DocumenterVitepress.jl/pull/373)):
colored `@repl` output is now rendered correctly while the input remains Julia syntax-highlighted.

**Rules for v0.3.5 and later:**

- Use **`@repl`** for interactive examples, including output from custom ANSI-colored `show`
  methods (strategy instances, `StrategyOptions`, `StrategyMetadata`, `StrategyRegistry`, …).
- Use **`@example`** for regular evaluated examples when REPL formatting is not needed.
- Use **`@ansi`** when explicitly demonstrating terminal styling or raw ANSI output.
- Use **`@repl`** with a direct expression that raises an exception to display errors;
  `@repl` captures the exception as output, so no `try/catch` or `showerror` is needed.

## Extensions are always loaded

`make.jl` loads every weak dependency so that the API reference can document the
extensions, and extension methods are global to the process. An `ExtensionError` (or any
error raised *because* an extension is missing) therefore **cannot** be shown with
`@repl`: the constructor succeeds.

Use `CTBase.DevTools.repl_without_extensions` (CTBase's `DocumenterReference` extension,
ct-conventions `SITE15`) from an `@eval` block instead. It runs the code in a fresh Julia
process where only CTSolvers is loaded, and renders the transcript like an `@repl` block:

````markdown
```@eval
Main.CTBase.DevTools.repl_without_extensions(:CTSolvers, "CTSolvers.Solvers.Ipopt()")
```
````

Snippets before the last one are run first and shown as inputs (e.g.
`"using OrdinaryDiffEqVerner", "CTSolvers.Integrators.SciML()"`). The build fails if the
last snippet does not throw, so an example cannot silently go stale.

## Warnings without build-machine paths

In `@example` blocks, log records show their source location
(`└ @ Module /path/on/the/build/machine/file.jl:line`), which leaks local or CI paths.
Wrap the visible lines with `CTBase.DevTools.warnings_without_paths` (ct-conventions
`SITE16`) on hidden lines; use `show = true` when the block should also display its value:

````markdown
```@example page
Main.CTBase.DevTools.warnings_without_paths(; show = true) do # hide
CTSolvers.Solvers.Ipopt(bound_relax_factor = 1e-10; mode = :permissive)
end # hide
```
````

## GPU page

`docs/src/using/gpu.md` runs on every build. Blocks that need a device are guarded by
`CUDA.functional()` or wrapped in `try/catch`, so the page builds on CPU (GitHub-hosted
`build` job, PR previews) and shows real GPU output when rebuilt by the `build-gpu` job
on the `kkt` runner (push to `main` and tags only).
