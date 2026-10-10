# docs/

Documentation site for CTSolvers.jl, built with
[DocumenterVitepress](https://github.com/LuxDL/DocumenterVitepress.jl).

Build (from the package root):

```bash
julia --project=. docs/make.jl
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
