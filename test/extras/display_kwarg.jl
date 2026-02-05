# Helper script to test CTSolvers display=false functionality
# This script specifically tests whether display=false suppresses all output

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

# Load solver extensions
using NLPModelsIpopt
using MadNLP
using MadNLPMumps
using MadNCL
using NLPModelsKnitro

using ADNLPModels
using CommonSolve
using SolverCore

# ---------------------------------------------------------------------------
# Utility: capture output
# ---------------------------------------------------------------------------

function capture_output(f::Function)
    original_stdout = stdout
    original_stderr = stderr
    
    stdout_buffer = IOBuffer()
    stderr_buffer = IOBuffer()
    
    try
        redirect_stdout(stdout_buffer)
        redirect_stderr(stderr_buffer)
        
        result = f()
        
        return (
            result = result,
            stdout_output = String(take!(stdout_buffer)),
            stderr_output = String(take!(stderr_buffer))
        )
    finally
        redirect_stdout(original_stdout)
        redirect_stderr(original_stderr)
    end
end

# ---------------------------------------------------------------------------
# Test display functionality with different solver configurations
# ---------------------------------------------------------------------------

function test_display_with_solvers()
    println()
    println("===== TESTING DISPLAY FUNCTIONALITY WITH SOLVERS =====")
    
    # Create a simple test problem
    println("Creating test NLP problem...")
    nlp = ADNLPModel(x -> sum(x.^2), zeros(5))
    println("Test problem created: Rosenbrock-like with 5 variables")
    
    # Test different solvers with display=true and display=false
    solvers_to_test = [
        ("IpoptSolver", () -> CTSolvers.Solvers.IpoptSolver(max_iter=10, print_level=0)),
        ("MadNLPSolver", () -> CTSolvers.Solvers.MadNLPSolver(max_iter=10, print_level=MadNLP.ERROR)),
        ("MadNCLSolver", () -> CTSolvers.Solvers.MadNCLSolver(max_iter=10, print_level=MadNLP.ERROR)),
    ]
    
    for (solver_name, solver_constructor) in solvers_to_test
        println()
        println("--- Testing ", solver_name, " ---")
        
        solver = solver_constructor()
        
        # Test with display=true
        println("Testing display=true...")
        result_with_display = capture_output() do
            return CommonSolve.solve(nlp, solver; display=true)
        end
        
        println("  Stdout length: ", length(result_with_display.stdout_output))
        println("  Stderr length: ", length(result_with_display.stderr_output))
        if length(result_with_display.stdout_output) > 0
            println("  Stdout preview: ", result_with_display.stdout_output[1:min(100, end)])
        end
        
        # Test with display=false
        println("Testing display=false...")
        result_without_display = capture_output() do
            return CommonSolve.solve(nlp, solver; display=false)
        end
        
        println("  Stdout length: ", length(result_without_display.stdout_output))
        println("  Stderr length: ", length(result_without_display.stderr_output))
        
        # Check if display=false actually suppresses output
        stdout_suppressed = length(result_without_display.stdout_output) == 0
        stderr_suppressed = length(result_without_display.stderr_output) == 0
        
        println("  Stdout suppressed: ", stdout_suppressed)
        println("  Stderr suppressed: ", stderr_suppressed)
        
        if !stdout_suppressed || !stderr_suppressed
            println("  WARNING: Display=false did not suppress all output!")
            if !stdout_suppressed
                println("    Unsuppressed stdout: ", result_without_display.stdout_output)
            end
            if !stderr_suppressed
                println("    Unsuppressed stderr: ", result_without_display.stderr_output)
            end
        else
            println("  SUCCESS: Display=false suppressed all output")
        end
        
        # Show solution status
        stats = result_without_display.result
        println("  Solution status: ", stats.status)
        println("  Objective value: ", stats.objective)
    end
end

# ---------------------------------------------------------------------------
# Test display with different modeler options
# ---------------------------------------------------------------------------

function test_display_with_modelers()
    println()
    println("===== TESTING DISPLAY FUNCTIONALITY WITH MODELERS =====")
    
    # Test modelers that have display-related options
    modelers_to_test = [
        ("ADNLPModeler (show_time=true)", () -> CTSolvers.Modelers.ADNLPModeler(show_time=true)),
        ("ADNLPModeler (show_time=false)", () -> CTSolvers.Modelers.ADNLPModeler(show_time=false)),
        ("ExaModeler (default)", () -> CTSolvers.Modelers.ExaModeler()),
    ]
    
    for (modeler_name, modeler_constructor) in modelers_to_test
        println()
        println("--- Testing ", modeler_name, " ---")
        
        modeler = modeler_constructor()
        
        # Show modeler options
        println("Modeler options:")
        for option_name in Strategies.option_names(typeof(modeler))
            value = Strategies.option_value(modeler, option_name)
            source = Strategies.option_source(modeler, option_name)
            println("  :", option_name, " = ", value, " (", source, ")")
        end
        
        # Test if show_time option actually affects timing output
        # Note: This would require actual problem solving to see timing effects
        println("  Note: Timing effects would be visible during actual model building")
    end
end

# ---------------------------------------------------------------------------
# Test option routing with display option
# ---------------------------------------------------------------------------

function test_display_option_routing()
    println()
    println("===== TESTING DISPLAY OPTION ROUTING =====")
    
    # Create test setup for routing
    method = (:adnlp, :ipopt)
    families = (
        modeler = CTSolvers.Modelers.AbstractOptimizationModeler,
        solver = CTSolvers.Solvers.AbstractOptimizationSolver,
    )
    action_defs = [
        Options.OptionDefinition(
            name=:display,
            type=Bool,
            default=true,
            description="Display progress information"
        )
    ]
    registry = Strategies.create_registry()
    
    # Test routing with display=true
    println()
    println("--- Testing routing with display=true ---")
    kwargs_with_display = (
        display=true,
        max_iter=10,
        tol=1e-6,
        backend=:forward,
    )
    
    try
        routed_with_display = Orchestration.route_all_options(
            method, families, action_defs, kwargs_with_display, registry
        )
        println("Input: ", kwargs_with_display)
        println("Routed:")
        println("  Action: ", routed_with_display.action)
        println("  Strategies: ", routed_with_display.strategies)
        
        # Check that display was routed to action
        display_in_action = haskey(routed_with_display.action, :display)
        display_value = display_in_action ? routed_with_display.action.display.value : "not found"
        println("  Display in action: ", display_in_action, " (value: ", display_value, ")")
    catch e
        println("Routing error: ", e)
    end
    
    # Test routing with display=false
    println()
    println("--- Testing routing with display=false ---")
    kwargs_without_display = (
        display=false,
        max_iter=10,
        tol=1e-6,
        backend=:forward,
    )
    
    try
        routed_without_display = Orchestration.route_all_options(
            method, families, action_defs, kwargs_without_display, registry
        )
        println("Input: ", kwargs_without_display)
        println("Routed:")
        println("  Action: ", routed_without_display.action)
        println("  Strategies: ", routed_without_display.strategies)
        
        # Check that display was routed to action
        display_in_action = haskey(routed_without_display.action, :display)
        display_value = display_in_action ? routed_without_display.action.display.value : "not found"
        println("  Display in action: ", display_in_action, " (value: ", display_value, ")")
    catch e
        println("Routing error: ", e)
    end
end

# ---------------------------------------------------------------------------
# Test display option extraction and validation
# ---------------------------------------------------------------------------

function test_display_option_extraction()
    println()
    println("===== TESTING DISPLAY OPTION EXTRACTION AND VALIDATION =====")
    
    # Define display option
    display_def = Options.OptionDefinition(
        name=:display,
        type=Bool,
        default=true,
        description="Display progress information"
    )
    
    # Test extraction with various inputs
    test_cases = [
        ("display=true", (display=true, other_option=123)),
        ("display=false", (display=false, other_option=456)),
        ("no display", (other_option=789, another_option="test")),
        ("invalid display type", (display="yes", other_option=999)),
    ]
    
    for (case_name, kwargs) in test_cases
        println()
        println("--- Testing case: ", case_name, " ---")
        println("Input: ", kwargs)
        
        try
            extracted, remaining = Options.extract_option(kwargs, display_def)
            println("Extracted: ", extracted)
            println("Remaining: ", remaining)
            
            if extracted isa Options.NotStoredType
                println("  Result: Not stored (no display option provided)")
            else
                println("  Value: ", extracted.value)
                println("  Source: ", extracted.source)
                println("  Type correct: ", isa(extracted.value, Bool))
            end
        catch e
            println("  Error: ", e)
        end
    end
end

# ---------------------------------------------------------------------------
# Test comprehensive display scenarios
# ---------------------------------------------------------------------------

function test_comprehensive_display_scenarios()
    println()
    println("===== COMPREHENSIVE DISPLAY SCENARIOS =====")
    
    # Create test problem
    nlp = ADNLPModel(x -> sum((x[i] - i)^2 for i in 1:3), [0.0, 0.0, 0.0])
    
    # Scenario 1: All display options enabled
    println()
    println("--- Scenario 1: All display enabled ---")
    solver_verbose = CTSolvers.Solvers.IpoptSolver(
        max_iter=5,
        print_level=5,  # Maximum verbosity
        timing_statistics="yes"
    )
    modeler_verbose = CTSolvers.Modelers.ADNLPModeler(show_time=true)
    
    result_verbose = capture_output() do
        return CommonSolve.solve(nlp, solver_verbose; display=true)
    end
    
    println("Output length with verbose settings: ", length(result_verbose.stdout_output))
    
    # Scenario 2: All display options disabled
    println()
    println("--- Scenario 2: All display disabled ---")
    solver_quiet = CTSolvers.Solvers.IpoptSolver(
        max_iter=5,
        print_level=0,  # Minimum verbosity
        timing_statistics="no"
    )
    modeler_quiet = CTSolvers.Modelers.ADNLPModeler(show_time=false)
    
    result_quiet = capture_output() do
        return CommonSolve.solve(nlp, solver_quiet; display=false)
    end
    
    println("Output length with quiet settings: ", length(result_quiet.stdout_output))
    
    # Compare results
    println()
    println("--- Comparison ---")
    println("Verbose output length: ", length(result_verbose.stdout_output))
    println("Quiet output length: ", length(result_quiet.stdout_output))
    println("Difference: ", length(result_verbose.stdout_output) - length(result_quiet.stdout_output))
    
    # Check if both solutions are valid
    println("Verbose solution status: ", result_verbose.result.status)
    println("Quiet solution status: ", result_quiet.result.status)
    println("Verbose objective: ", result_verbose.result.objective)
    println("Quiet objective: ", result_quiet.result.objective)
    
    # Check if objectives are close (should be identical for same problem)
    objectives_match = abs(result_verbose.result.objective - result_quiet.result.objective) < 1e-10
    println("Objectives match: ", objectives_match)
end

# ---------------------------------------------------------------------------
# Section 6: Simple Display Examples (REPL-like output)
# ---------------------------------------------------------------------------

function demo_simple_displays()
    println()
    println("===== SIMPLE DISPLAY EXAMPLES (REPL-like output) =====")

    # Example 1: OptionValue display with different sources
    println()
    println("--- OptionValue Display ---")
    user_option = Options.OptionValue(true, :user)
    default_option = Options.OptionValue(false, :default)
    
    println("Display=true (user): ", user_option)      # Shows: true (user)
    println("Display=false (default): ", default_option)  # Shows: false (default)

    # Example 2: StrategyOptions from actual solvers
    println()
    println("--- StrategyOptions from Solvers ---")
    
    # Create solver with display options
    verbose_solver = CTSolvers.Solvers.IpoptSolver(
        max_iter=100,
        tol=1e-6,
        print_level=5  # Verbose
    )
    
    quiet_solver = CTSolvers.Solvers.IpoptSolver(
        max_iter=100,
        tol=1e-6,
        print_level=0  # Quiet
    )
    
    println("Verbose solver options:")
    display(Strategies.options(verbose_solver))
    println()
    println("Quiet solver options:")
    display(Strategies.options(quiet_solver))

    # Example 3: Modeler display options
    println()
    println("--- Modeler Display Options ---")
    
    verbose_modeler = CTSolvers.Modelers.ADNLPModeler(show_time=true)
    quiet_modeler = CTSolvers.Modelers.ADNLPModeler(show_time=false)
    
    println("Verbose modeler:")
    println(verbose_modeler)
    println("Options:")
    display(Strategies.options(verbose_modeler))
    println()
    
    println("Quiet modeler:")
    println(quiet_modeler)
    println("Options:")
    display(Strategies.options(quiet_modeler))

    # Example 4: Display option in routing context
    println()
    println("--- Display Option in Routing Context ---")
    
    # Create routing setup
    method = (:adnlp, :ipopt)
    families = (
        modeler = CTSolvers.Modelers.AbstractOptimizationModeler,
        solver = CTSolvers.Solvers.AbstractOptimizationSolver,
    )
    action_defs = [
        Options.OptionDefinition(
            name=:display,
            type=Bool,
            default=true,
            description="Display progress information"
        )
    ]
    registry = Strategies.create_registry()
    
    # Test with display=true
    kwargs_display_true = (
        display=true,
        max_iter=50,
        backend=:sparse,
    )
    
    routed_true = Orchestration.route_all_options(
        method, families, action_defs, kwargs_display_true, registry
    )
    
    println("Routed with display=true:")
    println("Action options: ", routed_true.action)
    
    # Test with display=false
    kwargs_display_false = (
        display=false,
        max_iter=50,
        backend=:sparse,
    )
    
    routed_false = Orchestration.route_all_options(
        method, families, action_defs, kwargs_display_false, registry
    )
    
    println("Routed with display=false:")
    println("Action options: ", routed_false.action)

    # Example 5: Collection displays
    println()
    println("--- Collection Displays ---")
    
    # Show different ways to display strategy options
    opts = Strategies.options(verbose_solver)
    
    println("Direct print:")
    println(opts)
    println()
    
    println("Display (pretty):")
    display(opts)
    println()
    
    println("Keys collection:")
    println(collect(Strategies.keys(opts)))
    println()
    
    println("Values collection:")
    println(collect(Strategies.values(opts)))
    println()
    
    println("Pairs collection:")
    println(collect(Strategies.pairs(opts)))

    # Example 6: Option definition display
    println()
    println("--- Option Definition Display ---")
    
    display_def = Options.OptionDefinition(
        name=:display,
        type=Bool,
        default=true,
        description="Display progress information"
    )
    
    println("Display option definition:")
    println(display_def)
end

# ---------------------------------------------------------------------------
# Main entry point
# ---------------------------------------------------------------------------

function main()
    println("=== CTSolvers display_kwarg.jl (Display Testing) ===")
    println("Project: ", Base.current_project())
    println("This script specifically tests display=false functionality")
    println()

    test_display_with_solvers()
    test_display_with_modelers()
    test_display_option_routing()
    test_display_option_extraction()
    test_comprehensive_display_scenarios()
    demo_simple_displays()

    println()
    println("=== End of CTSolvers display_kwarg.jl ===")
    println()
    println("SUMMARY:")
    println("- Test various solver configurations with display=true/false")
    println("- Verify that display=false suppresses all output")
    println("- Test option routing with display parameter")
    println("- Check option extraction and validation")
    println("- Compare verbose vs quiet solver settings")
    println("- Show all display formats like in REPL")
end

main()
