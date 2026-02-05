# Helper script to manually exercise CTSolvers display and option functionality
# This script demonstrates the current modular architecture without requiring OCP problems

try
    using Revise
catch
    println("Revise not found")
end

using Pkg
Pkg.activate(@__DIR__)

# ---------------------------------------------------------------------------
# Imports and project setup
# ---------------------------------------------------------------------------

using CTSolvers
using CTSolvers.Options
using CTSolvers.Strategies
using CTSolvers.Orchestration
using CTSolvers.Solvers
using CTSolvers.Modelers

# Load solver extensions to have access to all strategies
using NLPModelsIpopt
using MadNLP
using MadNLPMumps
using MadNCL
using NLPModelsKnitro

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
# Section 1: Strategy options metadata via introspection API
# ---------------------------------------------------------------------------

function demo_strategy_options()
    println()
    println("===== STRATEGY OPTIONS METADATA (Introspection API) =====")

    # Define all available strategy types
    strategy_types = [
        CTSolvers.Solvers.IpoptSolver,
        CTSolvers.Solvers.MadNLPSolver,
        CTSolvers.Solvers.MadNCLSolver,
        CTSolvers.Solvers.KnitroSolver,
        CTSolvers.Modelers.ADNLPModeler,
        CTSolvers.Modelers.ExaModeler,
    ]

    for strategy_type in strategy_types
        println()
        println("---- ", strategy_type, " ----")
        
        # Show basic info
        strategy_id = Strategies.id(strategy_type)
        println("Strategy ID: :", strategy_id)
        
        # Show all option names
        option_names = Strategies.option_names(strategy_type)
        println("Available options: ", option_names)
        
        # Show detailed info for each option
        for option_name in option_names
            option_type = Strategies.option_type(strategy_type, option_name)
            option_default = Strategies.option_default(strategy_type, option_name)
            option_description = Strategies.option_description(strategy_type, option_name)
            
            println("  :", option_name, " (", option_type, ")")
            println("    Default: ", option_default)
            println("    Description: ", option_description)
        end
    end
end

# ---------------------------------------------------------------------------
# Section 2: Option defaults for all strategies
# ---------------------------------------------------------------------------

function demo_option_defaults()
    println()
    println("===== OPTION DEFAULTS FOR ALL STRATEGIES =====")

    strategy_types = [
        CTSolvers.Solvers.IpoptSolver,
        CTSolvers.Solvers.MadNLPSolver,
        CTSolvers.Modelers.ADNLPModeler,
        CTSolvers.Modelers.ExaModeler,
    ]

    for strategy_type in strategy_types
        println()
        println("---- ", strategy_type, " defaults ----")
        defaults = Strategies.option_defaults(strategy_type)
        println(defaults)
    end
end

# ---------------------------------------------------------------------------
# Section 3: Option routing and disambiguation
# ---------------------------------------------------------------------------

function demo_option_routing()
    println()
    println("===== OPTION ROUTING AND DISAMBIGUATION =====")

    # Create a mock method tuple (similar to old description mode)
    method = (:adnlp, :ipopt)
    
    # Create mock families mapping
    families = (
        modeler = CTSolvers.Modelers.AbstractOptimizationModeler,
        solver = CTSolvers.Solvers.AbstractOptimizationSolver,
    )
    
    # Create mock action definitions (display option)
    action_defs = [
        Options.OptionDefinition(
            name=:display,
            type=Bool,
            default=true,
            description="Display progress information"
        )
    ]
    
    # Create strategy registry
    registry = Strategies.create_registry()
    
    println()
    println("--- Method: ", method, " ---")
    println("Families: ", families)
    
    # Test 1: Auto-routing (unambiguous options)
    println()
    println("--- Test 1: Auto-routing unambiguous options ---")
    kwargs1 = (
        display=false,  # Action option
        backend=:sparse,  # Only belongs to ADNLPModeler
        max_iter=1000,   # Only belongs to IpoptSolver
        tol=1e-6,        # Only belongs to IpoptSolver
    )
    
    println("Input kwargs: ", kwargs1)
    
    try
        routed1 = Orchestration.route_all_options(
            method, families, action_defs, kwargs1, registry
        )
        println("Routed result:")
        println("  Action: ", routed1.action)
        println("  Strategies: ", routed1.strategies)
    catch e
        println("Error: ", e)
    end
    
    # Test 2: Disambiguated routing
    println()
    println("--- Test 2: Disambiguated routing ---")
    kwargs2 = (
        display=true,
        backend=(:sparse, :adnlp),  # Explicitly route to ADNLPModeler
        max_iter=500,
        tol=1e-8,
    )
    
    println("Input kwargs: ", kwargs2)
    
    try
        routed2 = Orchestration.route_all_options(
            method, families, action_defs, kwargs2, registry
        )
        println("Routed result:")
        println("  Action: ", routed2.action)
        println("  Strategies: ", routed2.strategies)
    catch e
        println("Error: ", e)
    end
end

# ---------------------------------------------------------------------------
# Section 4: Error messages demonstrations
# ---------------------------------------------------------------------------

function demo_error_messages()
    println()
    println("===== ERROR MESSAGES (validation, routing, unknown options) =====")

    # Create test setup
    method = (:adnlp, :ipopt)
    families = (
        modeler = CTSolvers.Modelers.AbstractOptimizationModeler,
        solver = CTSolvers.Solvers.AbstractOptimizationSolver,
    )
    action_defs = [
        Options.OptionDefinition(name=:display, type=Bool, default=true)
    ]
    registry = Strategies.create_registry()

    # Error 1: Invalid option value for strategy
    show_captured_error("Invalid IpoptSolver tol value") do
        CTSolvers.Solvers.IpoptSolver(tol=-1.0)  # Negative tolerance
    end

    # Error 2: Unknown option in routing
    show_captured_error("Unknown option in routing") do
        kwargs = (display=true, unknown_option=123, max_iter=1000)
        Orchestration.route_all_options(method, families, action_defs, kwargs, registry)
    end

    # Error 3: Invalid option value for modeler
    show_captured_error("Invalid ADNLPModeler backend") do
        CTSolvers.Modelers.ADNLPModeler(backend=:invalid_backend)
    end

    # Error 4: Strategy validation errors
    show_captured_error("Strategy contract validation") do
        # This would trigger if a strategy doesn't implement required contract
        # For now, show a working validation example
        solver = CTSolvers.Solvers.IpoptSolver(max_iter=-10)  # Negative max_iter
    end
end

# ---------------------------------------------------------------------------
# Section 5: Strategy construction and option inspection
# ---------------------------------------------------------------------------

function demo_strategy_construction()
    println()
    println("===== STRATEGY CONSTRUCTION AND OPTION INSPECTION =====")

    # Create strategies with various options
    println()
    println("--- Creating strategies with custom options ---")
    
    ipopt_solver = CTSolvers.Solvers.IpoptSolver(
        max_iter=1000,
        tol=1e-6,
        mu_strategy="adaptive"
    )
    println("IpoptSolver created")
    
    adnlp_modeler = CTSolvers.Modelers.ADNLPModeler(
        backend=:forward,
        show_time=true,
        matrix_free=false
    )
    println("ADNLPModeler created")
    
    exa_modeler = CTSolvers.Modelers.ExaModeler(
        base_type=Float32,
        backend=nothing
    )
    println("ExaModeler created")

    # Inspect strategy options
    println()
    println("--- Inspecting strategy options ---")
    
    strategies = [
        ("IpoptSolver", ipopt_solver),
        ("ADNLPModeler", adnlp_modeler),
        ("ExaModeler", exa_modeler),
    ]
    
    for (name, strategy) in strategies
        println()
        println("---- ", name, " ----")
        
        # Show all option names
        option_names = Strategies.option_names(typeof(strategy))
        println("Option names: ", option_names)
        
        # Show current values and sources
        for option_name in option_names
            value = Strategies.option_value(strategy, option_name)
            source = Strategies.option_source(strategy, option_name)
            is_user_val = Strategies.is_user(strategy, option_name)
            is_default_val = Strategies.is_default(strategy, option_name)
            
            println("  :", option_name, " = ", value, " (", source, ")")
            println("    User set: ", is_user_val, ", Default: ", is_default_val)
        end
    end
end

# ---------------------------------------------------------------------------
# Section 6: Simple Display Examples (REPL-like output)
# ---------------------------------------------------------------------------

function demo_simple_displays()
    println()
    println("===== SIMPLE DISPLAY EXAMPLES (REPL-like output) =====")

    # Example 1: OptionValue display
    println()
    println("--- OptionValue Display ---")
    user_option = Options.OptionValue(1000, :user)
    default_option = Options.OptionValue(1e-6, :default)
    computed_option = Options.OptionValue(42, :computed)
    
    println("User option: ", user_option)      # Shows: 1000 (user)
    println("Default option: ", default_option)  # Shows: 1.0e-6 (default)
    println("Computed option: ", computed_option) # Shows: 42 (computed)

    # Example 2: OptionDefinition display
    println()
    println("--- OptionDefinition Display ---")
    simple_def = Options.OptionDefinition(
        name=:max_iter,
        type=Int,
        default=100,
        description="Maximum number of iterations"
    )
    
    complex_def = Options.OptionDefinition(
        name=:tol,
        type=Float64,
        default=1e-8,
        description="Convergence tolerance",
        aliases=(:tolerance, :epsilon)
    )
    
    println("Simple definition:")
    println(simple_def)
    println("Complex definition with aliases:")
    println(complex_def)

    # Example 3: StrategyOptions display (both formats)
    println()
    println("--- StrategyOptions Display ---")
    
    # Create StrategyOptions with mixed sources
    strategy_opts = Strategies.StrategyOptions(
        max_iter = Options.OptionValue(500, :user),
        tol = Options.OptionValue(1e-6, :default),
        backend = Options.OptionValue(:sparse, :user),
        show_time = Options.OptionValue(false, :default)
    )
    
    println("Compact format:")
    println(strategy_opts)
    println()
    println("Pretty format:")
    display(strategy_opts)

    # Example 4: StrategyRegistry display
    println()
    println("--- StrategyRegistry Display ---")
    
    # Create a sample registry
    registry = Strategies.create_registry(
        CTSolvers.Modelers.AbstractOptimizationModeler => (CTSolvers.Modelers.ADNLPModeler, CTSolvers.Modelers.ExaModeler),
        CTSolvers.Solvers.AbstractOptimizationSolver => (CTSolvers.Solvers.IpoptSolver, CTSolvers.Solvers.MadNLPSolver)
    )
    
    println("Compact format:")
    println(registry)
    println()
    println("Pretty format:")
    display(registry)

    # Example 5: Sentinel types display
    println()
    println("--- Sentinel Types Display ---")
    
    println("NotProvided: ", Options.NotProvided)
    println("NotStored: ", Options.NotStored)
    
    # Example 6: Real strategy objects display
    println()
    println("--- Real Strategy Objects Display ---")
    
    # Create actual strategies and show their display
    ipopt_solver = CTSolvers.Solvers.IpoptSolver(max_iter=100, tol=1e-4)
    adnlp_modeler = CTSolvers.Modelers.ADNLPModeler(backend=:forward, show_time=true)
    
    println("IpoptSolver object:")
    println(ipopt_solver)
    println()
    println("ADNLPModeler object:")
    println(adnlp_modeler)
    println()
    
    # Show their options (StrategyOptions)
    println("IpoptSolver options:")
    display(Strategies.options(ipopt_solver))
    println()
    println("ADNLPModeler options:")
    display(Strategies.options(adnlp_modeler))

    # Example 7: Collections and iteration
    println()
    println("--- Collections and Iteration Display ---")
    
    # Show strategy options collection behavior
    opts = Strategies.options(ipopt_solver)
    
    println("Keys: ", collect(Strategies.keys(opts)))
    println("Values: ", collect(Strategies.values(opts)))
    println("Pairs: ", collect(Strategies.pairs(opts)))
    
    println("Iteration over values:")
    for value in opts
        println("  ", value)
    end
    
    println("Iteration over pairs:")
    for (name, value) in opts
        println("  :", name, " = ", value)
    end
end

# ---------------------------------------------------------------------------
# Main entry point
# ---------------------------------------------------------------------------

function main()
    println("=== CTSolvers display_all.jl (Current Architecture) ===")
    println("Project: ", Base.current_project())
    println("This script demonstrates the current CTSolvers modular architecture")
    println()

    demo_strategy_options()
    demo_option_defaults()
    demo_option_routing()
    demo_error_messages()
    demo_strategy_construction()
    demo_simple_displays()

    println()
    println("=== End of CTSolvers display_all.jl ===")
end

main()
