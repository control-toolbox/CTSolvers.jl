# GPU Execution

```@meta
CurrentModule = CTSolvers
```

Strategies that can run on a GPU accept the execution parameter
`CTBase.Strategies.GPU`. The parameter selects the GPU defaults (device backend, linear
solver) at construction; nothing else changes in how the strategy is used. GPU support is
for NVIDIA GPUs, through [CUDA.jl](https://github.com/JuliaGPU/CUDA.jl).

!!! note "What you are reading depends on the machine that built this page"
    Every block below is executed when the documentation is built. With a functional CUDA
    device you are reading real GPU output; without one, you are reading what this exact
    code really produces on a machine without a GPU. The first block says which of the two
    it is.

| Strategy | GPU defaults | Packages to load |
| :--------- | :------------- | :----------------- |
| `Modelers.Exa{GPU}` | `backend = CUDA.CUDABackend()` | `ExaModels`, `CUDA` |
| `Solvers.MadNLP{GPU}` | `linear_solver = MadNLPGPU.CUDSSSolver` | `MadNLP`, `MadNLPGPU`, `CUDA`, `CUDSS` |
| `Solvers.MadNCL{GPU}` | `linear_solver = MadNLPGPU.CUDSSSolver` | `MadNCL`, `MadNLP`, `MadNLPGPU`, `CUDA`, `CUDSS` |
| `Integrators.SciML{GPU}` | — (state on device arrays, e.g. `CuArray`) | `OrdinaryDiffEqTsit5`, and `CUDA` for device arrays |

## Prerequisites

```@example gpu
using CTSolvers
using CTBase: CTBase
using ExaModels, MadNLP, MadNLPGPU, CUDA, CUDSS
using CommonSolve: solve

const GPU = CTBase.Strategies.GPU

println("CUDA.functional() = ", CUDA.functional())
```

`MadNLPGPU`, `CUDA` **and** `CUDSS` must all be loaded: `CUDSS` (the sparse linear solver
on the GPU) is not loaded by `using MadNLPGPU`. If one is missing,
`Solvers.MadNLP{GPU}()` throws an `ExtensionError` that names it.

## GPU defaults

Building the strategies does not touch the device, so this block runs anywhere (with a
warning when CUDA is loaded but not functional):

```@example gpu
Main.DocLogs.run() do # hide
global modeler, solver # hide
modeler = CTSolvers.Modelers.Exa{GPU}()
solver = CTSolvers.Solvers.MadNLP{GPU}(print_level = MadNLP.ERROR)
end # hide
nothing # hide
```

```@example gpu
println("Exa{GPU} backend:          ", modeler[:backend])
println("MadNLP{GPU} linear_solver: ", solver[:linear_solver])
```

The CPU defaults, for comparison:

```@example gpu
println("Exa{CPU} backend:          ", CTSolvers.Modelers.Exa()[:backend])
println("MadNLP{CPU} linear_solver: ", CTSolvers.Solvers.MadNLP()[:linear_solver])
```

## Solving an NLP on the GPU

The modeler's `backend` is where the NLP model lives. Here the model is built directly with
ExaModels (CTDirect does the same from a discretized optimal control problem):

```@example gpu
function quadratic_model(backend, N)
    c = ExaModels.ExaCore(; backend)
    c, x = ExaModels.add_var(c, N; start = 0.5)
    c, _ = ExaModels.add_obj(c, (x[i] - i / N)^2 for i in 1:N)
    c, _ = ExaModels.add_con(c, x[i+1] - x[i] for i in 1:(N-1); lcon = -5e-4, ucon = 5e-4)
    return ExaModels.ExaModel(c)
end
nothing # hide
```

Running it is what needs the hardware:

```@example gpu
try
    nlp = quadratic_model(modeler[:backend], 1000)
    stats = solve(nlp, solver; display = false)
    println("status = ", stats.status, ", objective = ", stats.objective)
catch e
    println("Exception: ", first(sprint(showerror, e), 400))
end
```

With OptimalControl.jl this pairing is the `:gpu` shortcut of `solve`. The NLP model, the
linear algebra and the KKT systems all stay on the device.

Only `Solvers.MadNLP{GPU}` and `Solvers.MadNCL{GPU}` accept a device model: `MadNLP{CPU}`,
Ipopt and Uno have no method for it. Use `Float64`: with `base_type = Float32`, MadNCL has
no method for the model and MadNLP may not converge.

!!! note "Objectives may differ slightly from CPU"
    MadNLP relaxes the bounds by about its tolerance. On a problem whose constraints are all
    active and very sensitive, like this one, the GPU and CPU objectives can differ in the
    fourth significant digit while both solves are correct.

## CPU-only strategies

`Solvers.Ipopt`, `Solvers.Knitro`, `Solvers.Uno` and `Modelers.ADNLP` are CPU-only: their
type parameter is bounded by `CPU`, so Julia rejects the `GPU` parameter before any
CTSolvers code runs, on every machine:

```@repl gpu
CTSolvers.Solvers.Ipopt{GPU}()
```

## Consistency checks

Options that contradict the parameter are accepted with a warning, since they may be
intentional. For instance a CUDA backend on a CPU modeler:

```@example gpu
Main.DocLogs.run() do # hide
CTSolvers.Modelers.Exa(backend = CUDA.CUDABackend())
end # hide
nothing # hide
```

The same holds for `Modelers.Exa{GPU}(backend = nothing)`, a CPU linear solver
(`MumpsSolver`, `UmfpackSolver`, `LapackCPUSolver`, …) with `Solvers.MadNLP{GPU}`, or
`CUDSSSolver` with `Solvers.MadNLP{CPU}`.

## GPU integration

`Integrators.SciML{GPU}` integrates states stored on the device:

```@example gpu
using OrdinaryDiffEqTsit5
using SciMLBase: ODEProblem
using CTSolvers: Integrators

if CUDA.functional()
    integ = Integrators.SciML{GPU}()
    prob = ODEProblem((du, u, p, t) -> (du .= .-u), CuArray([1.0, 2.0]), (0.0, 1.0))
    r = solve(prob, integ; options = Integrators.options_point(integ))
    xf = Integrators.final_state(r)
    println(typeof(xf), " ", Array(xf))
else
    println("No functional GPU on the machine that built this page: no device integration.")
end
```

The initial condition must match the parameter: a `CuArray` under `SciML{CPU}`, or a host
`Array` under `SciML{GPU}`, is inconsistent. CTSolvers provides the check
(`Integrators.__consistent_initial_condition`); the consuming package (e.g. CTFlows)
applies it when it builds the ODE problem, since the integrator does not see `u0` at
construction.
