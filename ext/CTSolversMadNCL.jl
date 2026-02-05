"""
CTSolversMadNCL Extension

Extension providing MadNCL solver metadata, constructor, and backend interface.
Implements the complete MadNCLSolver functionality with proper option definitions.
"""
module CTSolversMadNCL

using CTSolvers
using CTSolvers.Solvers
using CTSolvers.Strategies
using CTSolvers.Options
using CTBase.Exceptions
using MadNCL
using MadNLP
using MadNLPMumps
using NLPModels
using SolverCore

# ============================================================================
# Helper Functions
# ============================================================================

"""
    base_type(::MadNCL.NCLOptions{BaseType})

Extract the base floating-point type from NCLOptions type parameter.
"""
base_type(::MadNCL.NCLOptions{BaseType}) where {BaseType<:AbstractFloat} = BaseType

# ============================================================================
# Metadata Definition
# ============================================================================

"""
    Strategies.metadata(::Type{<:Solvers.MadNCLSolver})

Return metadata defining MadNCLSolver options and their specifications.
"""
function Strategies.metadata(::Type{<:Solvers.MadNCLSolver})
    return Strategies.StrategyMetadata(
        Strategies.OptionDefinition(;
            name=:max_iter,
            type=Integer,
            default=3000,
            description="Maximum number of augmented Lagrangian iterations",
            aliases=(:maxiter,),
            validator=x -> x >= 0 || throw(Exceptions.IncorrectArgument(
                "Invalid max_iter value",
                got="max_iter=$x",
                expected="non-negative integer (>= 0)",
                suggestion="Provide a non-negative value for maximum iterations",
                context="MadNCLSolver max_iter validation"
            ))
        ),
        Strategies.OptionDefinition(;
            name=:tol,
            type=Real,
            default=1e-8,
            description="Optimality tolerance",
            validator=x -> x > 0 || throw(Exceptions.IncorrectArgument(
                "Invalid tolerance value",
                got="tol=$x",
                expected="positive real number (> 0)",
                suggestion="Provide a positive tolerance value (e.g., 1e-6, 1e-8)",
                context="MadNCLSolver tol validation"
            ))
        ),
        Strategies.OptionDefinition(;
            name=:print_level,
            type=MadNLP.LogLevels,
            default=MadNLP.INFO,
            description="MadNCL/MadNLP logging level"
        ),
        Strategies.OptionDefinition(;
            name=:linear_solver,
            type=Type{<:MadNLP.AbstractLinearSolver},
            default=MadNLPMumps.MumpsSolver,
            description="Linear solver implementation used inside MadNCL"
        ),
        Strategies.OptionDefinition(;
            name=:ncl_options,
            type=MadNCL.NCLOptions,
            default=MadNCL.NCLOptions{Float64}(;
                verbose=true,
                opt_tol=1e-8,
                feas_tol=1e-8
            ),
            description="Low-level NCLOptions structure controlling the augmented Lagrangian algorithm"
        )
    )
end

# ============================================================================
# Constructor Implementation
# ============================================================================

"""
    Solvers.build_madncl_solver(::Solvers.MadNCLTag; kwargs...)

Build a MadNCLSolver with validated options.
"""
function Solvers.build_madncl_solver(::Solvers.MadNCLTag; kwargs...)
    opts = Strategies.build_strategy_options(Solvers.MadNCLSolver; kwargs...)
    return Solvers.MadNCLSolver(opts)
end

# ============================================================================
# Callable Interface with Display Handling
# ============================================================================

"""
    (solver::Solvers.MadNCLSolver)(nlp; display=true)

Solve an NLP problem using MadNCL.

# Arguments
- `nlp::NLPModels.AbstractNLPModel`: The NLP problem to solve
- `display::Bool`: Whether to show solver output (default: true)

# Returns
- `MadNCL.NCLStats`: MadNCL execution statistics
"""
function (solver::Solvers.MadNCLSolver)(
    nlp::NLPModels.AbstractNLPModel;
    display::Bool=true
)::MadNCL.NCLStats
    opts = Strategies.options(solver)
    raw_opts = Options.extract_raw_options(opts.options)
    
    # Handle display flag - convert to Dict for modification
    if !display
        raw_opts_dict = Dict(pairs(raw_opts))
        raw_opts_dict[:print_level] = MadNLP.ERROR
        # Reconstruct ncl_options with verbose=false
        ncl_opts = raw_opts_dict[:ncl_options]
        BaseType = base_type(ncl_opts)
        ncl_opts_dict_inner = Dict(field => getfield(ncl_opts, field) for field in fieldnames(MadNCL.NCLOptions))
        ncl_opts_dict_inner[:verbose] = false
        raw_opts_dict[:ncl_options] = MadNCL.NCLOptions{BaseType}(; ncl_opts_dict_inner...)
        return solve_with_madncl(nlp; raw_opts_dict...)
    end
    
    return solve_with_madncl(nlp; raw_opts...)
end

# ============================================================================
# Backend Solver Interface
# ============================================================================

"""
    solve_with_madncl(nlp; ncl_options, kwargs...)

Backend interface for MadNCL solver.

Calls MadNCL to solve the NLP problem.
"""
function solve_with_madncl(
    nlp::NLPModels.AbstractNLPModel;
    ncl_options::MadNCL.NCLOptions,
    kwargs...
)::MadNCL.NCLStats
    solver = MadNCL.NCLSolver(nlp; ncl_options=ncl_options, kwargs...)
    return MadNCL.solve!(solver)
end

end
