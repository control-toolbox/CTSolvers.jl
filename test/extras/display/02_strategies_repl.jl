# ============================================================================
# CTSolvers Strategies Module - REPL Style Display Demonstration
# ============================================================================

try
    using Revise
catch
    println("🔧 Revise not found - continuing without hot reload")
end

using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))

# Add CTSolvers in development mode
if !haskey(Pkg.project().dependencies, "CTSolvers")
    Pkg.develop(path=joinpath(@__DIR__, "..", "..", ".."))
end

using CTSolvers
using CTSolvers.Strategies
using CTSolvers.Solvers
using CTSolvers.Modelers

# Load solver extensions to access all strategies
using NLPModelsIpopt
using MadNLP
using MadNLPMumps
using MadNCL
using NLPModelsKnitro

println()
println("="^60)
println("🎯 CTSOLVERS STRATEGIES MODULE - REPL STYLE DISPLAY DEMO")
println("="^60)
println()

# ============================================================================
# 1. StrategyRegistry Display - Empty and Populated
# ============================================================================

println()
println("="^60)
println("📋 1. STRATEGYREGISTRY DISPLAY - EMPTY AND POPULATED")
println("="^60)
println()

println("🟢 julia> empty_registry = CTSolvers.Strategies.create_registry()")
empty_registry = CTSolvers.Strategies.create_registry()
println("📋 Empty registry created:")
println(empty_registry)
println()

println("🟢 julia> populated_registry = CTSolvers.Strategies.create_registry(")
println("        CTSolvers.Modelers.AbstractOptimizationModeler => (CTSolvers.Modelers.ADNLPModeler, CTSolvers.Modelers.ExaModeler),")
println("        CTSolvers.Solvers.AbstractOptimizationSolver => (CTSolvers.Solvers.IpoptSolver, CTSolvers.Solvers.MadNLPSolver)")
println("    )")
populated_registry = CTSolvers.Strategies.create_registry(
    CTSolvers.Modelers.AbstractOptimizationModeler => (CTSolvers.Modelers.ADNLPModeler, CTSolvers.Modelers.ExaModeler),
    CTSolvers.Solvers.AbstractOptimizationSolver => (CTSolvers.Solvers.IpoptSolver, CTSolvers.Solvers.MadNLPSolver)
)
println("📋 Populated registry created:")
println(populated_registry)
println()

# Show pretty format
println("🟢 julia> display(populated_registry)")
println("📋 Pretty format display:")
display(populated_registry)
println()

# ============================================================================
# 2. StrategyOptions Display - Different Sources and Formats
# ============================================================================

println()
println("="^60)
println("📋 2. STRATEGYOPTIONS DISPLAY - DIFFERENT SOURCES AND FORMATS")
println("="^60)
println()

println("🟢 julia> mixed_options = CTSolvers.Strategies.StrategyOptions(")
println("        max_iter = CTSolvers.Options.OptionValue(500, :user),")
println("        tol = CTSolvers.Options.OptionValue(1e-6, :default),")
println("        backend = CTSolvers.Options.OptionValue(:sparse, :user),")
println("        show_time = CTSolvers.Options.OptionValue(false, :default)")
println("    )")
mixed_options = CTSolvers.Strategies.StrategyOptions(
    max_iter = CTSolvers.Options.OptionValue(500, :user),
    tol = CTSolvers.Options.OptionValue(1e-6, :default),
    backend = CTSolvers.Options.OptionValue(:sparse, :user),
    show_time = CTSolvers.Options.OptionValue(false, :default)
)
println("📋 StrategyOptions with mixed sources:")
println(mixed_options)
println()

println("🟢 julia> display(mixed_options)")
println("📋 Pretty format display:")
display(mixed_options)
println()

# ============================================================================
# 3. Strategy Introspection - Option Names and Types
# ============================================================================

println()
println("="^60)
println("📋 3. STRATEGY INTROSPECTION - OPTION NAMES AND TYPES")
println("="^60)
println()

# Test with ADNLPModeler (which should have metadata implemented)
println("🟢 julia> strategy_type = CTSolvers.Modelers.ADNLPModeler")
strategy_type = CTSolvers.Modelers.ADNLPModeler
println("🟢 julia> CTSolvers.Strategies.id(strategy_type)")
println("📋 Strategy ID:")
println("  :", CTSolvers.Strategies.id(strategy_type))
println()

println("🟢 julia> CTSolvers.Strategies.option_names(strategy_type)")
option_names = CTSolvers.Strategies.option_names(strategy_type)
println("📋 Available option names:")
println("  ", option_names)
println()

println("🟢 julia> CTSolvers.Strategies.option_type(strategy_type, :backend)")
println("📋 Type of backend option:")
println("  ", CTSolvers.Strategies.option_type(strategy_type, :backend))
println()

println("🟢 julia> CTSolvers.Strategies.option_default(strategy_type, :backend)")
println("📋 Default value of backend:")
println("  ", CTSolvers.Strategies.option_default(strategy_type, :backend))
println()

println("🟢 julia> CTSolvers.Strategies.option_description(strategy_type, :backend)")
println("📋 Description of backend:")
println("  ", CTSolvers.Strategies.option_description(strategy_type, :backend))
println()

# Show that some strategies might not have metadata implemented yet
println("🟢 julia> # Note: Some solvers like IpoptSolver may not have metadata implemented yet")
println("📋 This is expected during development - the metadata system is being built incrementally")
println()

# ============================================================================
# 4. Strategy Construction and Options Inspection
# ============================================================================

println()
println("="^60)
println("📋 4. STRATEGY CONSTRUCTION AND OPTIONS INSPECTION")
println("="^60)
println()

println("🟢 julia> ipopt_solver = CTSolvers.Solvers.IpoptSolver(max_iter=100, tol=1e-4)")
ipopt_solver = CTSolvers.Solvers.IpoptSolver(max_iter=100, tol=1e-4)
println("📋 IpoptSolver created:")
println(ipopt_solver)
println()

println("🟢 julia> CTSolvers.Strategies.options(ipopt_solver)")
solver_options = CTSolvers.Strategies.options(ipopt_solver)
println("📋 Solver options (compact):")
println(solver_options)
println()

println("🟢 julia> display(CTSolvers.Strategies.options(ipopt_solver))")
println("📋 Solver options (pretty):")
display(solver_options)
println()

# Test individual option access
println("🟢 julia> CTSolvers.Strategies.option_value(ipopt_solver, :max_iter)")
println("📋 Individual option value:")
println("  ", CTSolvers.Strategies.option_value(ipopt_solver, :max_iter))
println()

println("🟢 julia> CTSolvers.Strategies.option_source(ipopt_solver, :max_iter)")
println("📋 Individual option source:")
println("  ", CTSolvers.Strategies.option_source(ipopt_solver, :max_iter))
println()

println("🟢 julia> CTSolvers.Strategies.is_user(ipopt_solver, :max_iter)")
println("📋 Is user-set option:")
println("  ", CTSolvers.Strategies.is_user(ipopt_solver, :max_iter))
println()

println("🟢 julia> CTSolvers.Strategies.is_default(ipopt_solver, :tol)")
println("📋 Is default option:")
println("  ", CTSolvers.Strategies.is_default(ipopt_solver, :tol))
println()

# ============================================================================
# 5. Multiple Strategies Comparison
# ============================================================================

println()
println("="^60)
println("📋 5. MULTIPLE STRATEGIES COMPARISON")
println("="^60)
println()

# Create multiple strategies
println("🟢 julia> strategies = [")
println("        CTSolvers.Solvers.IpoptSolver(max_iter=100, tol=1e-6),")
println("        CTSolvers.Solvers.MadNLPSolver(max_iter=50, tol=1e-8),")
println("        CTSolvers.Modelers.ADNLPModeler(backend=:optimized, show_time=true)")
println("    ]")
strategies = [
    CTSolvers.Solvers.IpoptSolver(max_iter=100, tol=1e-6),
    CTSolvers.Solvers.MadNLPSolver(max_iter=50, tol=1e-8),
    CTSolvers.Modelers.ADNLPModeler(backend=:optimized, show_time=true)
]

for (i, strategy) in enumerate(strategies)
    println()
    println("📋 Strategy ", i, ": ", typeof(strategy))
    println("🟢 julia> CTSolvers.Strategies.id(typeof(strategy))")
    println("  ID: :", CTSolvers.Strategies.id(typeof(strategy)))
    
    println("🟢 julia> CTSolvers.Strategies.option_names(typeof(strategy))")
    println("  Options: ", CTSolvers.Strategies.option_names(typeof(strategy)))
    
    println("🟢 julia> CTSolvers.Strategies.options(strategy)")
    println("  Options object:")
    println("  ", CTSolvers.Strategies.options(strategy))
end
println()

# ============================================================================
# 6. StrategyOptions Collection Interface
# ============================================================================

println()
println("="^60)
println("📋 6. STRATEGYOPTIONS COLLECTION INTERFACE")
println("="^60)
println()

println("🟢 julia> opts = CTSolvers.Strategies.options(ipopt_solver)")
opts = CTSolvers.Strategies.options(ipopt_solver)

println("🟢 julia> collect(CTSolvers.Strategies.keys(opts))")
println("📋 Keys collection:")
println("  ", collect(CTSolvers.Strategies.keys(opts)))
println()

println("🟢 julia> collect(CTSolvers.Strategies.values(opts))")
println("📋 Values collection:")
println("  ", collect(CTSolvers.Strategies.values(opts)))
println()

println("🟢 julia> collect(CTSolvers.Strategies.pairs(opts))")
println("📋 Pairs collection:")
println("  ", collect(CTSolvers.Strategies.pairs(opts)))
println()

# Iteration examples
println("🟢 julia> for value in opts")
println("           println(\"  Value: \", value)")
println("       end")
println("📋 Iteration over values:")
for value in opts
    println("  Value: ", value)
end
println()

println("🟢 julia> for (name, value) in CTSolvers.Strategies.pairs(opts)")
println("           println(\"  :\", name, \" = \", value)")
println("       end")
println("📋 Iteration over pairs:")
for (name, value) in CTSolvers.Strategies.pairs(opts)
    println("  :", name, " = ", value)
end
println()

# ============================================================================
# 7. Strategy Metadata Display
# ============================================================================

println()
println("="^60)
println("📋 7. STRATEGY METADATA DISPLAY")
println("="^60)
println()

# Get metadata for ADNLPModeler (which should have metadata implemented)
println("🟢 julia> metadata = CTSolvers.Strategies.metadata(CTSolvers.Modelers.ADNLPModeler)")
metadata = CTSolvers.Strategies.metadata(CTSolvers.Modelers.ADNLPModeler)
println("📋 Strategy metadata:")
println(metadata)
println()

# Show individual option definitions from metadata
println("🟢 julia> for option_name in CTSolvers.Strategies.option_names(CTSolvers.Modelers.ADNLPModeler)")
println("           def = metadata[option_name]")
println("           println(\"  :\", option_name, \" -> \", def)")
println("       end")
println("📋 Individual option definitions:")
for option_name in CTSolvers.Strategies.option_names(CTSolvers.Modelers.ADNLPModeler)
    def = metadata[option_name]
    println("  :", option_name, " -> ", def)
end
println()

# Note about solver metadata
println("🟢 julia> # Note: Solver metadata (IpoptSolver, MadNLPSolver) may not be implemented yet")
println("📋 This is expected during development - solver metadata will be added incrementally")
println()

# ============================================================================
# 8. Strategy Options Defaults
# ============================================================================

println()
println("="^60)
println("📋 8. STRATEGY OPTIONS DEFAULTS")
println("="^60)
println()

# Show defaults for different strategy types
strategy_types = [
    CTSolvers.Solvers.IpoptSolver,
    CTSolvers.Solvers.MadNLPSolver,
    CTSolvers.Modelers.ADNLPModeler,
    CTSolvers.Modelers.ExaModeler
]

for strategy_type in strategy_types
    println("🟢 julia> CTSolvers.Strategies.option_defaults(", strategy_type, ")")
    defaults = CTSolvers.Strategies.option_defaults(strategy_type)
    println("📋 ", strategy_type, " defaults:")
    println("  ", defaults)
    println()
end

# ============================================================================
# SUMMARY
# ============================================================================

println()
println("="^60)
println("🎯 STRATEGIES MODULE DISPLAY DEMO - SUMMARY")
println("="^60)
println()

println("📋 What we demonstrated:")
println("  ✅ StrategyRegistry display (empty and populated)")
println("  ✅ StrategyOptions display (compact and pretty formats)")
println("  ✅ Strategy introspection API (names, types, defaults, descriptions)")
println("  ✅ Strategy construction and options inspection")
println("  ✅ Multiple strategies comparison")
println("  ✅ StrategyOptions collection interface (keys, values, pairs, iteration)")
println("  ✅ Strategy metadata display")
println("  ✅ Strategy options defaults")

println()
println("🎨 Key display features shown:")
println("  🟢 REPL-style prompts with julia>")
println("  📋 Structured output with clear sections")
println("  🔹 Indented details for readability")
println("  ✅ Success confirmations")
println("  📊 Multiple format comparisons (compact vs pretty)")

println()
println("🚀 All Strategies module display capabilities demonstrated!")
println("   Ready to explore Orchestration module next...")
