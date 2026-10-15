# docs/

Documentation site for CTSolvers.jl, built with
[DocumenterVitepress](https://github.com/LuxDL/DocumenterVitepress.jl).

Build (from the package root):

```bash
julia --project=docs docs/make.jl
```

Preview after build: `npx serve docs/build/1 --listen 5173`

Documentation conventions and build workflow:
[control-toolbox Handbook](https://github.com/control-toolbox/Handbook).

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

Use `NoExt.repl` ([`noext.jl`](noext.jl)) from an `@eval` block instead. It runs the code
in a fresh Julia process where only CTSolvers is loaded, and renders the transcript like
an `@repl` block:

````markdown
```@eval
Main.NoExt.repl("CTSolvers.Solvers.Ipopt()")
```
````

Snippets before the last one are run first and shown as inputs (e.g.
`Main.NoExt.repl("using OrdinaryDiffEqVerner", "CTSolvers.Integrators.SciML()")`). The
build fails if the last snippet does not throw, so an example cannot silently go stale.
