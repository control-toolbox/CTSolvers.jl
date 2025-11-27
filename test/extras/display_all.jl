# Helper script to manually exercise CTSolvers on benchmark problems (not part of
# automated test suite). The goal is to see, as a human, whether the various
# displays and error messages are readable and informative.

try
    using Revise
catch
    println("Revise not found")
end

using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))

# ---------------------------------------------------------------------------
# Imports and project setup (mirrors test/runtests.jl)
# ---------------------------------------------------------------------------

using CTBase: CTBase
using CTDirect: CTDirect
using CTModels: CTModels
using CTParser: CTParser, @def
using CTSolvers: CTSolvers, @init
using ADNLPModels
using ExaModels
using NLPModels
using CommonSolve
using CUDA
using MadNLPGPU
using SolverCore

# Load solver extensions explicitly so that all backends are available.
using NLPModelsIpopt
using MadNLP
using MadNLPMumps
using MadNCL
using NLPModelsKnitro

# ---------------------------------------------------------------------------
# Load benchmark problems (same setup as in test/runtests.jl)
# ---------------------------------------------------------------------------

const TEST_DIR = joinpath(@__DIR__, "..")

include(joinpath(TEST_DIR, "problems", "problems_definition.jl"))
include(joinpath(TEST_DIR, "problems", "rosenbrock.jl"))
include(joinpath(TEST_DIR, "problems", "elec.jl"))
include(joinpath(TEST_DIR, "problems", "beam.jl"))

# ---------------------------------------------------------------------------
# Utility: capture and print error messages
# ---------------------------------------------------------------------------

function show_captured_error(f::Function, label::AbstractString)
    println()
    println("===== ERROR DEMO: ", label, " =====")
    err = nothing
    try
        f()
    catch e
        err = e
    end
    if err === nothing
        println("(no error was thrown)")
    else
        buf = sprint(showerror, err)
        println(buf)
    end
end

# ---------------------------------------------------------------------------
# Section 1: Options metadata via CTSolvers.show_options
# ---------------------------------------------------------------------------

function demo_show_options()
    println()
    println("===== OPTIONS METADATA (CTSolvers.show_options) =====")

    tools = (
        CTSolvers.Collocation,
        CTSolvers.ADNLPModeler,
        CTSolvers.ExaModeler,
        CTSolvers.IpoptSolver,
        CTSolvers.MadNLPSolver,
        CTSolvers.MadNCLSolver,
        CTSolvers.KnitroSolver,
    )

    for T in tools
        println()
        println("---- CTSolvers.show_options(", T, ") ----")
        CTSolvers.show_options(T)
    end
end

# ---------------------------------------------------------------------------
# Section 2: Display helper for OCP methods
# ---------------------------------------------------------------------------

function demo_display_helper()
    println()
    println("===== DISPLAY HELPER (_display_ocp_method) =====")

    method = (:collocation, :adnlp, :ipopt)
    discretizer = CTSolvers.Collocation()
    modeler = CTSolvers.ADNLPModeler()
    solver = CTSolvers.IpoptSolver()

    CTSolvers._display_ocp_method(
        method,
        discretizer,
        modeler,
        solver;
        display=true,
    )
end

# ---------------------------------------------------------------------------
# Section 3: Beam OCP solves (explicit and description modes)
# ---------------------------------------------------------------------------

function demo_beam_solves()
    println()
    println("===== BEAM OCP SOLVES (explicit & description modes) =====")

    beam_data = beam()
    ocp = beam_data.ocp
    init = CTSolvers.initial_guess(ocp; beam_data.init...)
    discretizer = CTSolvers.Collocation()

    ipopt_options = Dict(
        :max_iter => 1000,
        :tol => 1e-6,
        :print_level => 0,
        :mu_strategy => "adaptive",
        :linear_solver => "Mumps",
        :sb => "yes",
    )

    madnlp_options = Dict(
        :max_iter => 1000,
        :tol => 1e-6,
        :print_level => MadNLP.ERROR,
    )

    modeler_ad  = CTSolvers.ADNLPModeler(; backend=:manual)
    modeler_exa = CTSolvers.ExaModeler()

    # Explicit mode: low-level _solve with Ipopt and ADNLPModeler
    println()
    println("--- Explicit mode: Ipopt + ADNLPModeler ---")
    solver_ipopt = CTSolvers.IpoptSolver(; ipopt_options...)
    sol_explicit = CTSolvers._solve(ocp, init, discretizer, modeler_ad, solver_ipopt; display=true)
    println("successful=", CTModels.successful(sol_explicit),
            " objective=", CTModels.objective(sol_explicit))

    # Description mode: (:collocation, :adnlp, :ipopt)
    println()
    println("--- Description mode: (:collocation, :adnlp, :ipopt) ---")
    sol_desc_ad_ipopt = CommonSolve.solve(
        ocp,
        :collocation,
        :adnlp,
        :ipopt;
        initial_guess=init,
        display=true,
        ipopt_options...,
    )
    println("successful=", CTModels.successful(sol_desc_ad_ipopt),
            " objective=", CTModels.objective(sol_desc_ad_ipopt))

    # Description mode: (:collocation, :exa, :madnlp)
    println()
    println("--- Description mode: (:collocation, :exa, :madnlp) ---")
    sol_desc_exa_mad = CommonSolve.solve(
        ocp,
        :collocation,
        :exa,
        :madnlp;
        initial_guess=init,
        display=true,
        madnlp_options...,
    )
    println("successful=", CTModels.successful(sol_desc_exa_mad),
            " objective=", CTModels.objective(sol_desc_exa_mad))
end

# ---------------------------------------------------------------------------
# Section 4: Error messages demonstrations
# ---------------------------------------------------------------------------

function demo_error_messages()
    println()
    println("===== ERROR MESSAGES (schema, routing, solve API) =====")

    # Unknown Ipopt option name with suggestions (options schema)
    show_captured_error("Ipopt unknown option mx_iter (schema validation)") do
        CTSolvers._validate_option_kwargs((mx_iter=10,), CTSolvers.IpoptSolver; strict_keys=true)
    end

    # Unknown ExaModeler option name with suggestions
    show_captured_error("ExaModeler unknown option foo (strict modeler options)") do
        CTSolvers.ExaModeler(; base_type=Float32, foo=2)
    end

    # Description-mode routing ambiguity between discretizer and solver
    show_captured_error("Description routing ambiguity for :foo between discretizer/solver") do
        CTSolvers._route_option_for_description(:foo, 1.0, Symbol[:discretizer, :solver], :description)
    end

    # Description mode: option with no owner in the selected method
    beam_data = beam()
    ocp = beam_data.ocp
    init = beam_data.init
    show_captured_error("CommonSolve.solve description unknown kw :foo") do
        CommonSolve.solve(
            ocp,
            :collocation,
            :adnlp,
            :ipopt;
            initial_guess=init,
            display=false,
            foo=1,
        )
    end

    # Mixing description with explicit components (should be rejected)
    discretizer = CTSolvers.Collocation()
    show_captured_error("CommonSolve.solve mixing description and explicit discretizer") do
        CommonSolve.solve(
            ocp,
            :collocation;
            initial_guess=init,
            discretizer=discretizer,
            display=false,
        )
    end
end

# ---------------------------------------------------------------------------
# Main entry point
# ---------------------------------------------------------------------------

function main()
    println("=== CTSolvers display_all.jl ===")
    println("Project: ", Base.current_project())
    println()

    demo_show_options()
    demo_display_helper()
    demo_beam_solves()
    demo_error_messages()

    println()
    println("=== End of CTSolvers display_all.jl ===")
end

main()
