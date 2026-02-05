# ============================================================================
# Quick Test: Strict/Permissive Validation System
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

# Load solver extensions to trigger all extensions
using NLPModelsIpopt

println()
println("="^70)
println("🧪 QUICK TEST: Strict/Permissive Validation System")
println("="^70)
println()

# ============================================================================
# Test 1: Strict Mode (Default) - Unknown Option Rejected
# ============================================================================

println("="^70)
println("📋 TEST 1: Strict Mode (Default) - Unknown Option Rejected")
println("="^70)
println()

println("🟢 julia> solver = Solvers.IpoptSolver(unknown_option=123)")
println()

try
    solver = Solvers.IpoptSolver(unknown_option=123)
    println("❌ FAILED: Should have thrown an error")
    exit(1)
catch e
    if occursin("Unknown options", string(e))
        println("✅ PASSED: Unknown option rejected in strict mode")
        println()
        println("📋 Error message:")
        println(e)
        println()
    else
        println("❌ FAILED: Unexpected error: ", typeof(e))
        rethrow(e)
    end
end

# ============================================================================
# Test 2: Strict Mode (Explicit) - Unknown Option Rejected
# ============================================================================

println("="^70)
println("📋 TEST 2: Strict Mode (Explicit) - Unknown Option Rejected")
println("="^70)
println()

println("🟢 julia> solver = Solvers.IpoptSolver(unknown_option=123; mode=:strict)")
println()

try
    solver = Solvers.IpoptSolver(unknown_option=123; mode=:strict)
    println("❌ FAILED: Should have thrown an error")
    exit(1)
catch e
    if occursin("Unknown options", string(e))
        println("✅ PASSED: Unknown option rejected in explicit strict mode")
        println()
    else
        println("❌ FAILED: Unexpected error: ", typeof(e))
        rethrow(e)
    end
end

# ============================================================================
# Test 3: Permissive Mode - Unknown Option Accepted with Warning
# ============================================================================

println("="^70)
println("📋 TEST 3: Permissive Mode - Unknown Option Accepted with Warning")
println("="^70)
println()

println("🟢 julia> solver = Solvers.IpoptSolver(max_iter=10, custom_option=123; mode=:permissive)")
println()

solver = Solvers.IpoptSolver(max_iter=10, custom_option=123; mode=:permissive)
opts = Strategies.options_dict(solver)

if haskey(opts, :custom_option) && opts[:custom_option] == 123
    println("✅ PASSED: Unknown option accepted in permissive mode")
    println("📋 custom_option value: ", opts[:custom_option])
    println()
else
    println("❌ FAILED: Unknown option not found in options")
    exit(1)
end

# ============================================================================
# Test 4: Known Option in Strict Mode
# ============================================================================

println("="^70)
println("📋 TEST 4: Known Option in Strict Mode")
println("="^70)
println()

println("🟢 julia> solver = Solvers.IpoptSolver(max_iter=100)")
println()

solver_strict = Solvers.IpoptSolver(max_iter=100)
opts_strict = Strategies.options_dict(solver_strict)

if opts_strict[:max_iter] == 100
    println("✅ PASSED: Known option works in strict mode")
    println("📋 max_iter value: ", opts_strict[:max_iter])
    println()
else
    println("❌ FAILED: Known option not set correctly")
    exit(1)
end

# ============================================================================
# Test 5: Known Option in Permissive Mode
# ============================================================================

println("="^70)
println("📋 TEST 5: Known Option in Permissive Mode")
println("="^70)
println()

println("🟢 julia> solver = Solvers.IpoptSolver(max_iter=200; mode=:permissive)")
println()

solver_perm = Solvers.IpoptSolver(max_iter=200; mode=:permissive)
opts_perm = Strategies.options_dict(solver_perm)

if opts_perm[:max_iter] == 200
    println("✅ PASSED: Known option works in permissive mode")
    println("📋 max_iter value: ", opts_perm[:max_iter])
    println()
else
    println("❌ FAILED: Known option not set correctly")
    exit(1)
end

# ============================================================================
# Test 6: Invalid Mode Parameter
# ============================================================================

println("="^70)
println("📋 TEST 6: Invalid Mode Parameter")
println("="^70)
println()

println("🟢 julia> solver = Solvers.IpoptSolver(max_iter=10; mode=:invalid)")
println()

try
    solver = Solvers.IpoptSolver(max_iter=10; mode=:invalid)
    println("❌ FAILED: Should have thrown ArgumentError")
    exit(1)
catch e
    if occursin("Invalid mode", string(e))
        println("✅ PASSED: Invalid mode rejected with ArgumentError")
        println("📋 Error: ", string(e))
        println()
    else
        println("❌ FAILED: Unexpected error: ", typeof(e))
        rethrow(e)
    end
end

# ============================================================================
# Test 7: Multiple Unknown Options in Permissive Mode
# ============================================================================

println("="^70)
println("📋 TEST 7: Multiple Unknown Options in Permissive Mode")
println("="^70)
println()

println("🟢 julia> solver = Solvers.IpoptSolver(")
println("              max_iter=50,")
println("              custom_opt1=123,")
println("              custom_opt2=\"test\";")
println("              mode=:permissive")
println("          )")
println()

solver_multi = Solvers.IpoptSolver(
    max_iter=50,
    custom_opt1=123,
    custom_opt2="test";
    mode=:permissive
)
opts_multi = Strategies.options_dict(solver_multi)

if haskey(opts_multi, :custom_opt1) && haskey(opts_multi, :custom_opt2)
    println("✅ PASSED: Multiple unknown options accepted in permissive mode")
    println("📋 custom_opt1: ", opts_multi[:custom_opt1])
    println("📋 custom_opt2: ", opts_multi[:custom_opt2])
    println()
else
    println("❌ FAILED: Not all unknown options found")
    exit(1)
end

# ============================================================================
# Summary
# ============================================================================

println()
println("="^70)
println("✅ ALL QUICK TESTS PASSED!")
println("="^70)
println()
println("📋 Summary:")
println("  • Strict mode (default) rejects unknown options ✓")
println("  • Strict mode (explicit) rejects unknown options ✓")
println("  • Permissive mode accepts unknown options with warning ✓")
println("  • Known options work in both modes ✓")
println("  • Invalid mode parameter is rejected ✓")
println("  • Multiple unknown options work in permissive mode ✓")
println()
println("🎉 Strict/Permissive validation system is working correctly!")
println()
