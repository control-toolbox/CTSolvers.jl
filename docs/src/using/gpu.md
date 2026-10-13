# GPU Execution

```@meta
CurrentModule = CTSolvers
```

Strategies that can run on a GPU accept the execution parameter
`CTBase.Strategies.GPU`. The parameter selects the GPU defaults (device backend, linear
solver) at construction; nothing else changes in how the strategy is used.

| Strategy | GPU defaults | Packages to load |
|:---------|:-------------|:-----------------|
| `Modelers.Exa{GPU}` | `backend = CUDA.CUDABackend()` | `ExaModels`, `CUDA` |
| `Solvers.MadNLP{GPU}` | `linear_solver = MadNLPGPU.CUDSSSolver` | `MadNLP`, `MadNLPGPU`, `CUDA`, `CUDSS` |
| `Solvers.MadNCL{GPU}` | `linear_solver = MadNLPGPU.CUDSSSolver` | `MadNCL`, `MadNLP`, `MadNLPGPU`, `CUDA`, `CUDSS` |
| `Integrators.SciML{GPU}` | — (state on device arrays, e.g. `CuArray`) | `OrdinaryDiffEqTsit5`, and `CUDA` for device arrays |

`Solvers.Ipopt`, `Solvers.Knitro`, `Solvers.Uno` and `Modelers.ADNLP` are CPU-only:
their type parameter is bounded by `CPU`, so `Solvers.Ipopt{GPU}` is a `TypeError`.

## A GPU NLP pipeline

The GPU pipeline pairs an ExaModels model with MadNLP (or MadNCL), both on the GPU:

```julia
using CTSolvers
using CTBase: CTBase
using ExaModels, MadNLP, MadNLPGPU, CUDA, CUDSS

const GPU = CTBase.Strategies.GPU

modeler = CTSolvers.Modelers.Exa{GPU}()
solver  = CTSolvers.Solvers.MadNLP{GPU}(max_iter = 1000)
```

With OptimalControl.jl this is the `:gpu` shortcut of `solve`. The NLP model, the
linear algebra and the KKT systems all stay on the device.

If one of `MadNLPGPU`, `CUDA` or `CUDSS` is missing, `Solvers.MadNLP{GPU}()` throws an
`ExtensionError` that names the missing packages.

## Consistency checks

Options that contradict the parameter are accepted with a warning, since they may be
intentional:

- `Modelers.Exa{CPU}(backend = CUDA.CUDABackend())`, or `Modelers.Exa{GPU}(backend = nothing)`;
- a CPU linear solver (`MumpsSolver`, `UmfpackSolver`, `LapackCPUSolver`) with
  `Solvers.MadNLP{GPU}`, or `CUDSSSolver` with `Solvers.MadNLP{CPU}`.

If CUDA is loaded but not functional (no device, driver issue), building `Modelers.Exa{GPU}`
warns once.

## GPU integration

`Integrators.SciML{GPU}` integrates states stored on the device. The initial condition
must match the parameter: a `CuArray` under `SciML{CPU}`, or a host `Array` under
`SciML{GPU}`, is inconsistent. CTSolvers provides the check
(`Integrators.__consistent_initial_condition`); the consuming package (e.g. CTFlows)
applies it when it builds the ODE problem, since the integrator does not see `u0` at
construction.
