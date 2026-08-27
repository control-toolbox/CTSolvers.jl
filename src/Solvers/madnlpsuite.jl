"""
MadNLP/MadNCL Suite Common Functions

This module contains common functions shared between MadNLP and MadNCL solvers
for GPU/CPU linear solver defaults and consistency validation.
"""

"""
Weak dependencies required to activate the MadNLP/MadNCL GPU solver extension.

The extension is loaded only when all three packages are available and loaded:
`MadNLPGPU`, `CUDA`, and `CUDSS`.
"""
const __MADNLP_GPU_DEPENDENCIES = (:MadNLPGPU, :CUDA, :CUDSS)

"""
$(TYPEDSIGNATURES)

Build the diagnostic error for an unavailable MadNLP/MadNCL GPU extension.

# Arguments
- `loaded_modules`: Iterable of loaded package identifiers, each exposing a `String`
  `name` field (as `Base.PkgId` does). Defaults to `keys(Base.loaded_modules)`. A
  dependency counts as present when its name appears among these.

# Returns
- `Exceptions.ExtensionError`: Error naming the missing dependencies, or all three
  extension triggers when none is reported missing.

See also: [`CTSolvers.Solvers.__madnlp_suite_default_linear_solver`](@ref)
"""
function __madnlp_gpu_extension_error(loaded_modules=keys(Base.loaded_modules))
    loaded_names = Set(pkgid.name for pkgid in loaded_modules)
    absent = filter(
        dependency -> String(dependency) ∉ loaded_names, __MADNLP_GPU_DEPENDENCIES
    )
    weakdeps = isempty(absent) ? __MADNLP_GPU_DEPENDENCIES : absent
    return Exceptions.ExtensionError(
        weakdeps...;
        message="to use GPU linear solver with MadNLP/MadNCL",
        feature="GPU computation with MadNLP/MadNCL",
        context="the CTSolversMadNLPGPU extension needs all three of MadNLPGPU, CUDA, and CUDSS",
    )
end

"""
$(TYPEDSIGNATURES)

Return the default linear solver for the given parameter type.

# Arguments
- `parameter_type::Type{<:Strategies.AbstractStrategyParameter}`: CPU or GPU parameter

# Returns
- `Type{<:MadNLP.AbstractLinearSolver}`: Default linear solver type

# Throws
- `Exceptions.ExtensionError`: If GPU parameter used but MadNLPGPU not loaded

# Notes
- Default implementation throws ExtensionError for GPU
- CPU implementation provided by CTSolversMadNLP extension
- GPU implementation provided by CTSolversMadNLPGPU extension
"""
function __madnlp_suite_default_linear_solver(::Type{<:Strategies.GPU})
    return throw(__madnlp_gpu_extension_error())
end

"""
$(TYPEDSIGNATURES)

Check if linear solver is consistent with parameter type.

# Arguments
- `parameter_type::Type{<:Strategies.AbstractStrategyParameter}`: CPU or GPU parameter
- `linear_solver::Type`: Linear solver type

# Returns
- `Bool`: true if consistent, false otherwise

# Notes
- Default implementation returns true (all combinations allowed)
- Specific implementations in extensions provide actual consistency checks
"""
function __madnlp_suite_consistent_linear_solver(
    ::Type{<:Strategies.AbstractStrategyParameter}, linear_solver::Type
)
    return true
end

"""
$(TYPEDSIGNATURES)

Consistency check when the linear solver is unavailable (`nothing`).

Some MadNLPGPU versions bind `MadNLPGPU.CUDSSSolver` (and hence the GPU default linear
solver) to `nothing` when CUDA is not functional. In that case there is no concrete solver
type to validate against, so the pair is treated as consistent (no warning). This keeps
metadata construction and `describe` robust on machines without a functional GPU.
"""
function __madnlp_suite_consistent_linear_solver(
    ::Type{<:Strategies.AbstractStrategyParameter}, ::Nothing
)
    return true
end
