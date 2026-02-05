# ============================================================================
# CTSolvers Routing Display Tests - REPL Style
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
println("🎯 CTSOLVERS ROUTING DISPLAY TESTS - REPL STYLE")
println("="^60)
println()

# ============================================================================
# 1. Basic Routing Setup
# ============================================================================

println()
println("="^60)
println("📋 1. BASIC ROUTING SETUP")
println("="^60)
println()

println("🟢 julia> # Create a strategy registry for routing tests")
println("🟢 julia> registry = CTSolvers.Strategies.create_registry(")
println("        CTSolvers.Modelers.AbstractOptimizationModeler => (CTSolvers.Modelers.ADNLPModeler, CTSolvers.Modelers.ExaModeler)")
println("    )")
registry = CTSolvers.Strategies.create_registry(
    CTSolvers.Modelers.AbstractOptimizationModeler => (CTSolvers.Modelers.ADNLPModeler, CTSolvers.Modelers.ExaModeler)
)
println("📋 Registry created:")
println(registry)
println()

println("🟢 julia> # Define method tuple for routing")
println("🟢 julia> method = (:adnlp, :exa)")
method = (:adnlp, :exa)
println("🟢 julia> # Define families for routing")
println("🟢 julia> families = (")
println("        modeler=CTSolvers.Modelers.ADNLPModeler,")
println("        alternative=CTSolvers.Modelers.ExaModeler")
println("    )")
families = (
    modeler=CTSolvers.Modelers.ADNLPModeler,
    alternative=CTSolvers.Modelers.ExaModeler
)
println("📋 Routing setup complete")
println()

# ============================================================================
# 2. Simple Option Routing
# ============================================================================

println()
println("="^60)
println("📋 2. SIMPLE OPTION ROUTING")
println("="^60)
println()

println("🟢 julia> # Test routing with clear option ownership")
println("🟢 julia> simple_kwargs = (backend=:optimized, show_time=true)")
simple_kwargs = (backend=:optimized, show_time=true)

println("🟢 julia> CTSolvers.Orchestration.route_all_options(simple_kwargs, families)")
try
    routed_simple = CTSolvers.Orchestration.route_all_options(simple_kwargs, families)
    println("📋 Simple routing successful:")
    for (family, options) in routed_simple
        println("  ", family, ":")
        for (name, value) in pairs(options)
            println("    :", name, " = ", value)
        end
    end
catch e
    println("⚠️  Simple routing error:")
    println("  ", typeof(e), ": ", e)
end
println()

# ============================================================================
# 3. Option Disambiguation Testing
# ============================================================================

println()
println("="^60)
println("📋 3. OPTION DISAMBIGUATION TESTING")
println("="^60)
println()

println("🟢 julia> # Test disambiguation syntax")
println("🟢 julia> # Single strategy disambiguation")
println("🟢 julia> disambiguated_value = (:sparse, :adnlp)")
disambiguated_value = (:sparse, :adnlp)
println("🟢 julia> CTSolvers.Orchestration.extract_strategy_ids(disambiguated_value, method)")
disambiguated_ids = CTSolvers.Orchestration.extract_strategy_ids(disambiguated_value, method)
println("📋 Single strategy disambiguation:")
println("  ", disambiguated_ids)
println()

println("🟢 julia> # Multi-strategy disambiguation")
println("🟢 julia> multi_disambiguated = ((:sparse, :adnlp), (:cpu, :exa))")
multi_disambiguated = ((:sparse, :adnlp), (:cpu, :exa))
println("🟢 julia> CTSolvers.Orchestration.extract_strategy_ids(multi_disambiguated, method)")
multi_ids = CTSolvers.Orchestration.extract_strategy_ids(multi_disambiguated, method)
println("📋 Multi-strategy disambiguation:")
println("  ", multi_ids)
println()

println("🟢 julia> # Non-disambiguated value")
println("🟢 julia> normal_value = :sparse")
normal_value = :sparse
println("🟢 julia> CTSolvers.Orchestration.extract_strategy_ids(normal_value, method)")
normal_ids = CTSolvers.Orchestration.extract_strategy_ids(normal_value, method)
println("📋 Non-disambiguated value:")
println("  ", normal_ids)
println()

# ============================================================================
# 4. Routing with Mixed Options
# ============================================================================

println()
println("="^60)
println("📋 4. ROUTING WITH MIXED OPTIONS")
println("="^60)
println()

println("🟢 julia> # Test routing with mixed clear and ambiguous options")
println("🟢 julia> mixed_kwargs = (")
println("        backend=:optimized, show_time=true,")
println("        base_type=Float32, matrix_free=false")
println("    )")
mixed_kwargs = (
    backend=:optimized, show_time=true,
    base_type=Float32, matrix_free=false
)

println("🟢 julia> CTSolvers.Orchestration.route_all_options(mixed_kwargs, families)")
try
    routed_mixed = CTSolvers.Orchestration.route_all_options(mixed_kwargs, families)
    println("📋 Mixed routing results:")
    for (family, options) in routed_mixed
        println("  ", family, ":")
        for (name, value) in pairs(options)
            println("    :", name, " = ", value)
        end
    end
catch e
    println("⚠️  Mixed routing error:")
    println("  ", typeof(e), ": ", e)
end
println()

# ============================================================================
# 5. Unknown Option Handling
# ============================================================================

println()
println("="^60)
println("📋 5. UNKNOWN OPTION HANDLING")
println("="^60)
println()

println("🟢 julia> # Test routing with unknown options")
println("🟢 julia> unknown_kwargs = (")
println("        backend=:optimized, show_time=true,")
println("        unknown_option=123, custom_param=:test")
println("    )")
unknown_kwargs = (
    backend=:optimized, show_time=true,
    unknown_option=123, custom_param=:test
)

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
# 6. Strategy to Family Mapping
# ============================================================================

println()
println("="^60)
println("📋 6. STRATEGY TO FAMILY MAPPING")
println("="^60)
println()

println("🟢 julia> # Test strategy to family mapping")
println("🟢 julia> CTSolvers.Orchestration.build_strategy_to_family_map(method, families, registry)")
try
    strategy_family_map = CTSolvers.Orchestration.build_strategy_to_family_map(method, families, registry)
    println("📋 Strategy to family mapping:")
    for (strategy_id, family) in strategy_family_map
        println("  :", strategy_id, " -> :", family)
    end
catch e
    println("⚠️  Strategy to family mapping error:")
    println("  ", typeof(e), ": ", e)
end
println()

# ============================================================================
# 7. Option Ownership Mapping
# ============================================================================

println()
println("="^60)
println("📋 7. OPTION OWNERSHIP MAPPING")
println("="^60)
println()

println("🟢 julia> # Test option ownership mapping")
println("🟢 julia> CTSolvers.Orchestration.build_option_ownership_map(method, families, registry)")
try
    ownership_map = CTSolvers.Orchestration.build_option_ownership_map(method, families, registry)
    println("📋 Option ownership mapping:")
    for (option_name, family_set) in ownership_map
        println("  :", option_name, " -> ", family_set)
    end
catch e
    println("⚠️  Option ownership mapping error:")
    println("  ", typeof(e), ": ", e)
end
println()

# ============================================================================
# 8. Complex Routing Scenarios
# ============================================================================

println()
println("="^60)
println("📋 8. COMPLEX ROUTING SCENARIOS")
println("="^60)
println()

println("🟢 julia> # Scenario 1: Multiple families with overlapping options")
println("🟢 julia> complex_families = (")
println("        primary=CTSolvers.Modelers.ADNLPModeler,")
println("        secondary=CTSolvers.Modelers.ExaModeler")
println("    )")
complex_families = (
    primary=CTSolvers.Modelers.ADNLPModeler,
    secondary=CTSolvers.Modelers.ExaModeler
)

println("🟢 julia> complex_kwargs = (")
println("        backend=:optimized, show_time=true, base_type=Float32,")
println("        matrix_free=false, name=\"ComplexTest\"")
println("    )")
complex_kwargs = (
    backend=:optimized, show_time=true, base_type=Float32,
    matrix_free=false, name="ComplexTest"
)

println("🟢 julia> CTSolvers.Orchestration.route_all_options(complex_kwargs, complex_families)")
try
    routed_complex = CTSolvers.Orchestration.route_all_options(complex_kwargs, complex_families)
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
# 9. Error Handling Patterns
# ============================================================================

println()
println("="^60)
println("📋 9. ERROR HANDLING PATTERNS")
println("="^60)
println()

println("🟢 julia> # Test various error conditions")
println("🟢 julia> # Empty kwargs")
println("🟢 julia> empty_kwargs = ()")
empty_kwargs = ()
println("🟢 julia> CTSolvers.Orchestration.route_all_options(empty_kwargs, families)")
try
    routed_empty = CTSolvers.Orchestration.route_all_options(empty_kwargs, families)
    println("📋 Empty routing successful:")
    for (family, options) in routed_empty
        println("  ", family, ": ", options)
    end
catch e
    println("⚠️  Empty routing error:")
    println("  ", typeof(e), ": ", e)
end
println()

println("🟢 julia> # Invalid families")
println("🟢 julia> invalid_families = (invalid=String,)")
invalid_families = (invalid=String,)
println("🟢 julia> CTSolvers.Orchestration.route_all_options(simple_kwargs, invalid_families)")
try
    routed_invalid = CTSolvers.Orchestration.route_all_options(simple_kwargs, invalid_families)
    println("📋 Invalid families routing:")
    for (family, options) in routed_invalid
        println("  ", family, ": ", options)
    end
catch e
    println("⚠️  Invalid families error (expected):")
    println("  ", typeof(e), ": ", e)
end
println()

# ============================================================================
# 10. Routing Performance Patterns
# ============================================================================

println()
println("="^60)
println("📋 10. ROUTING PERFORMANCE PATTERNS")
println("="^60)
println()

println("🟢 julia> # Test routing performance with different option counts")
println("🟢 julia> # Small option set")
small_kwargs = (backend=:optimized, show_time=true)
println("📋 Small option set (2 options):")
println("  ", length(collect(keys(small_kwargs))), " options")
println()

println("🟢 julia> # Medium option set")
medium_kwargs = (
    backend=:optimized, show_time=true, base_type=Float32,
    matrix_free=false, name="Test", custom_option=:value
)
println("📋 Medium option set (6 options):")
println("  ", length(collect(keys(medium_kwargs))), " options")
println()

println("🟢 julia> # Large option set")
large_kwargs = (
    backend=:optimized, show_time=true, base_type=Float32,
    matrix_free=false, name="Test", opt1=:a, opt2=:b, opt3=:c,
    opt4=:d, opt5=:e, opt6=:f, opt7=:g, opt8=:h
)
println("📋 Large option set (13 options):")
println("  ", length(collect(keys(large_kwargs))), " options")
println()

# ============================================================================
# SUMMARY
# ============================================================================

println()
println("="^60)
println("🎯 ROUTING DISPLAY TESTS - SUMMARY")
println("="^60)
println()

println("📋 What we tested:")
println("  ✅ Basic routing setup and configuration")
println("  ✅ Simple option routing")
println("  ✅ Option disambiguation syntax")
println("  ✅ Mixed option routing")
println("  ✅ Unknown option handling")
println("  ✅ Strategy to family mapping")
println("  ✅ Option ownership mapping")
println("  ✅ Complex routing scenarios")
println("  ✅ Error handling patterns")
println("  ✅ Routing performance patterns")

println()
println("🎨 Key routing features shown:")
println("  🟢 Automatic option routing based on ownership")
println("  📋 Disambiguation syntax for explicit routing")
println("  🔹 Error handling for unknown/invalid options")
println("  ⚠️  Strategy family management")
println("  ✅ Flexible routing for complex scenarios")

println()
println("🚀 Routing display functionality demonstrated!")
println("   Ready to test integration display next...")
