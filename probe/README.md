# Capability probes

Diagnostics, not tests: they measure which strategy combinations actually work against the
current working-tree CTSolvers, and print capability matrices. Nothing asserts; every
experiment is wrapped in `try/catch`, so the run always succeeds and one failure never hides
the others. They are the ground truth for the capability claims of the documentation
(`docs/src/using/strategies.md`, `docs/src/using/gpu.md`) and of the solver docstrings.

| Probe | Runs on | Measures |
| :--- | :--- | :--- |
| [`cpu/`](cpu/probe_cpu.jl) | GitHub-hosted Ubuntu (`CPUProbe.yml`) | NLP modeler × solver on CPU, strategy × execution parameter, `Integrators.SciML` × state type |
| [`gpu/`](gpu/probe_gpu.jl) | self-hosted `kkt` runner, NVIDIA/CUDA (`GPUProbe.yml`) | GPU defaults, NLP modeler × solver on the device, `Integrators.SciML` with `CuArray` states |

Run them on a PR with the `run probe` label, from the Actions tab (`workflow_dispatch`), or
locally:

```bash
julia --project=probe/cpu probe/cpu/probe_cpu.jl
julia --project=probe/gpu probe/gpu/probe_gpu.jl   # meaningful on a machine with a CUDA device
```

Each script activates its own environment and `dev`s the repository root, so it measures
the checked-out source. Manifests are not committed.

Marks: `✓` works and the result is correct; `⚠` runs but the result is wrong, not
converged, or a warning was emitted; `✗` throws (the exception is shown below the matrix).
Shared helpers live in [`common.jl`](common.jl).

## Known results (CPU, 2026-10-15)

- Every modeler works with Ipopt, MadNLP, MadNCL and Uno in `Float64` (Uno with
  `Modelers.Exa{CPU}` included).
- `Modelers.Exa(base_type = Float32)` works with MadNLP only (with a tolerance reachable in
  single precision, e.g. `tol = 1e-5`); Ipopt, MadNCL and Uno have no method for a `Float32`
  model.
- Knitro needs a license; without one, `KN_new` returns `-520`.
- `Ipopt`, `Knitro`, `Uno` and `ADNLP` reject the `GPU` parameter with a `TypeError`;
  `MadNLP{GPU}`, `MadNCL{GPU}` and `Exa{GPU}` raise an `ExtensionError` until the GPU
  packages are loaded; `SciML{GPU}` builds without them.
- `Integrators.SciML` integrates scalar, vector (in-place or not), `Float32` and matrix
  states, with point and trajectory options.
