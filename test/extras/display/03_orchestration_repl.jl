# ============================================================================
# CTSolvers Orchestration Module - REPL Style Display Demonstration
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
using CTSolvers.Options
using CTSolvers.Strategies
using CTSolvers.Orchestration
using CTSolvers.Modelers

println()
println("="^60)
println("🎯 CTSOLVERS ORCHESTRATION MODULE - REPL STYLE DISPLAY DEMO")
println("="^60)
println()

# ============================================================================
# 1. Strategy Registry Setup
# ============================================================================

println()
println("="^60)
println("📋 1. STRATEGY REGISTRY SETUP")
println("="^60)
println()

println("🟢 julia> registry = CTSolvers.Strategies.create_registry(")
println("        CTSolvers.Modelers.AbstractOptimizationModeler => (CTSolvers.Modelers.ADNLPModeler, CTSolvers.Modelers.ExaModeler)")
println("    )")
registry = CTSolvers.Strategies.create_registry(
    CTSolvers.Modelers.AbstractOptimizationModeler => (CTSolvers.Modelers.ADNLPModeler, CTSolvers.Modelers.ExaModeler)
)
println("📋 Registry created:")
println(registry)
println()

# ============================================================================
# 2. Strategy ID Extraction
# ============================================================================

println()
println("="^60)
println("📋 2. STRATEGY ID EXTRACTION")
println("="^60)
println()

println("🟢 julia> method_tuple = (:adnlp, :exa)")
method_tuple = (:adnlp, :exa)
println("🟢 julia> # Test with disambiguation syntax")
println("🟢 julia> disambiguated_value = (:sparse, :adnlp)")
disambiguated_value = (:sparse, :adnlp)
println("🟢 julia> CTSolvers.Orchestration.extract_strategy_ids(disambiguated_value, method_tuple)")
strategy_ids = CTSolvers.Orchestration.extract_strategy_ids(disambiguated_value, method_tuple)
println("📋 Extracted strategy IDs:")
println("  ", strategy_ids)
println()

println("🟢 julia> # Test with non-disambiguated value")
println("🟢 julia> normal_value = :sparse")
normal_value = :sparse
println("🟢 julia> CTSolvers.Orchestration.extract_strategy_ids(normal_value, method_tuple)")
normal_ids = CTSolvers.Orchestration.extract_strategy_ids(normal_value, method_tuple)
println("📋 Normal value (no disambiguation):")
println("  ", normal_ids)
println()

println("🟢 julia> # Test with multi-strategy disambiguation")
println("🟢 julia> multi_value = ((:sparse, :adnlp), (:cpu, :exa))")
multi_value = ((:sparse, :adnlp), (:cpu, :exa))
println("🟢 julia> CTSolvers.Orchestration.extract_strategy_ids(multi_value, method_tuple)")
multi_ids = CTSolvers.Orchestration.extract_strategy_ids(multi_value, method_tuple)
println("📋 Multi-strategy disambiguation:")
println("  ", multi_ids)
println()

# ============================================================================
# 3. Strategy to Family Map Building
# ============================================================================

println()
println("="^60)
println("📋 3. STRATEGY TO FAMILY MAP BUILDING")
println("="^60)
println()

println("🟢 julia> method = (:adnlp,)")
method = (:adnlp,)
println("🟢 julia> families = (modeler=CTSolvers.Modelers.ADNLPModeler,)")
families = (modeler=CTSolvers.Modelers.ADNLPModeler,)

println("🟢 julia> CTSolvers.Orchestration.build_strategy_to_family_map(method, families, registry)")
try
    strategy_family_map = CTSolvers.Orchestration.build_strategy_to_family_map(method, families, registry)
    println("📋 Strategy to family mapping:")
    for (strategy_id, family) in strategy_family_map
        println("  :", strategy_id, " -> :", family)
    end
catch e
    println("⚠️  Strategy to family map error:")
    println("  ", typeof(e), ": ", e)
end
println()

# ============================================================================
# 4. Option Ownership Map Building
# ============================================================================

println()
println("="^60)
println("📋 4. OPTION OWNERSHIP MAP BUILDING")
println("="^60)
println()

println("🟢 julia> CTSolvers.Orchestration.build_option_ownership_map(method, families, registry)")
try
    ownership_map = CTSolvers.Orchestration.build_option_ownership_map(method, families, registry)
    println("📋 Option ownership mapping:")
    for (option_name, family_set) in ownership_map
        println("  :", option_name, " -> ", family_set)
    end
catch e
    println("⚠️  Option ownership map error:")
    println("  ", typeof(e), ": ", e)
end
println()

# ============================================================================
# 5. Simple Option Routing
# ============================================================================

println()
println("="^60)
println("📋 5. SIMPLE OPTION ROUTING")
println("="^60)
println()

println("🟢 julia> # Define families for routing")
println("🟢 julia> families = (")
println("        CTSolvers.Modelers.AbstractOptimizationModeler => CTSolvers.Modelers.ADNLPModeler")
println("    )")
families = (
    CTSolvers.Modelers.AbstractOptimizationModeler => CTSolvers.Modelers.ADNLPModeler
)

println("🟢 julia> # Test options with clear ownership")
println("🟢 julia> kwargs = (backend=:optimized, show_time=true)")
kwargs = (backend=:optimized, show_time=true)

println("🟢 julia> CTSolvers.Orchestration.route_all_options(kwargs, families)")
try
    routed_options = CTSolvers.Orchestration.route_all_options(kwargs, families)
    println("📋 Routed options:")
    for (family, options) in routed_options
        println("  ", family, ":")
        for (name, value) in pairs(options)
            println("    :", name, " = ", value)
        end
    end
catch e
    println("⚠️  Routing error:")
    println("  ", typeof(e), ": ", e)
end
println()

# ============================================================================
# 6. Option Routing with Ambiguity
# ============================================================================

println()
println("="^60)
println("📋 6. OPTION ROUTING WITH AMBIGUITY")
println("="^60)
println()

println("🟢 julia> # Test with options that might cause ambiguity")
println("🟢 julia> ambiguous_kwargs = (backend=:optimized,)")
ambiguous_kwargs = (backend=:optimized,)

println("🟢 julia> CTSolvers.Orchestration.route_all_options(ambiguous_kwargs, families)")
try
    routed_ambiguous = CTSolvers.Orchestration.route_all_options(ambiguous_kwargs, families)
    println("📋 Ambiguous routing succeeded:")
    for (family, options) in routed_ambiguous
        println("  ", family, ":")
        for (name, value) in pairs(options)
            println("    :", name, " = ", value)
        end
    end
catch e
    println("⚠️  Routing error:")
    println("  ", typeof(e), ": ", e)
end
println()

# ============================================================================
# 7. Option Routing with Unknown Options
# ============================================================================

println()
println("="^60)
println("📋 7. OPTION ROUTING WITH UNKNOWN OPTIONS")
println("="^60)
println()

println("🟢 julia> # Test with unknown options")
println("🟢 julia> unknown_kwargs = (backend=:optimized, unknown_option=123)")
unknown_kwargs = (backend=:optimized, unknown_option=123)

println("🟢 julia> CTSolvers.Orchestration.route_all_options(unknown_kwargs, families)")
try
    routed_unknown = CTSolvers.Orchestration.route_all_options(unknown_kwargs, families)
    println("📋 Unknown options routing:")
    for (family, options) in routed_unknown
        println("  ", family, ":")
        for (name, value) in pairs(options)
            println("    :", name, " = ", value)
        end
    end
catch e
    println("⚠️  Unknown options error:")
    println("  ", typeof(e), ": ", e)
end
println()

# ============================================================================
# 8. Complex Routing Scenario
# ============================================================================

println()
println("="^60)
println("📋 8. COMPLEX ROUTING SCENARIO")
println("="^60)
println()

println("🟢 julia> # Complex scenario with multiple options")
println("🟢 julia> complex_kwargs = (")
println("        backend=:optimized, show_time=true,")
println("        matrix_free=false, name=\"MyModel\"")
println("    )")
complex_kwargs = (
    backend=:optimized, show_time=true,
    matrix_free=false, name="MyModel"
)

println("🟢 julia> CTSolvers.Orchestration.route_all_options(complex_kwargs, families)")
try
    routed_complex = CTSolvers.Orchestration.route_all_options(complex_kwargs, families)
    println("📋 Complex routing results:")
    for (family, options) in routed_complex
        println("  ", family, ":")
        for (name, value) in pairs(options)
            println("    :", name, " = ", value)
        end
    end
catch e
    println("⚠️  Complex routing error:")
    println("  ", typeof(e), ": ", e)
end
println()

# ============================================================================
# 9. Helper Functions Display
# ============================================================================

println()
println("="^60)
println("📋 9. HELPER FUNCTIONS DISPLAY")
println("="^60)
println()

println("🟢 julia> # Show available helper functions")
println("📋 Orchestration helper functions:")
println("  ✅ extract_strategy_ids() - Extract strategy IDs from method tuple")
println("  ✅ build_strategy_to_family_map() - Map strategies to their families")
println("  ✅ build_option_ownership_map() - Map options to their owning strategies")
println("  ✅ route_all_options() - Route options to appropriate strategies")
println()

# ============================================================================
# SUMMARY
# ============================================================================

println()
println("="^60)
println("🎯 ORCHESTRATION MODULE DISPLAY DEMO - SUMMARY")
println("="^60)
println()

println("📋 What we demonstrated:")
println("  ✅ Strategy registry setup and display")
println("  ✅ Strategy ID extraction from method tuples")
println("  ✅ Strategy to family mapping")
println("  ✅ Option ownership mapping")
println("  ✅ Simple option routing")
println("  ✅ Option routing with ambiguity handling")
println("  ✅ Option routing with unknown options")
println("  ✅ Complex routing scenarios")
println("  ✅ Helper functions overview")

println()
println("🎨 Key orchestration features shown:")
println("  🟢 Automatic option routing based on ownership")
println("  📋 Strategy family management")
println("  🔹 Error handling for ambiguous/unknown options")
println("  ⚠️  Clear error messages for debugging")
println("  ✅ Flexible routing for complex scenarios")

println()
println("🚀 All Orchestration module display capabilities demonstrated!")
println("   Ready to explore Optimization module next...")
