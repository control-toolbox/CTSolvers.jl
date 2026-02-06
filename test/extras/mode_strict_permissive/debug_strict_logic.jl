# ========================================
# Script de Diagnostic : Strict Logic Issues
# ========================================

using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))

if !haskey(Pkg.project().dependencies, "CTSolvers")
    Pkg.develop(path=joinpath(@__DIR__, "..", "..", ".."))
end

using CTSolvers
using CTSolvers.Strategies
using CTSolvers.Solvers
using NLPModelsIpopt
using Test

println("🔍 Diagnostic du test : Logic Validation")
println("=" ^ 50)

# 1. Alias Resolution
println("\n1. Testing Alias Resolution (maxiter -> max_iter)")
try
    opts = Strategies.build_strategy_options(Solvers.IpoptSolver; maxiter=300)
    println("✅ built options: ", keys(opts))
    if haskey(opts, :max_iter)
        println("✅ max_iter found: ", opts[:max_iter])
    else
        println("❌ max_iter NOT found")
    end
catch e
    println("❌ Alias test failed:")
    showerror(stdout, e)
    println()
end

# 2. Default Values
println("\n2. Testing Default Values")
try
    opts = Strategies.build_strategy_options(Solvers.IpoptSolver)
    println("✅ built options: ", keys(opts))
    if haskey(opts, :max_iter)
        println("✅ max_iter default found: ", opts[:max_iter])
    else
        println("❌ max_iter default NOT found")
    end
catch e
    println("❌ Defaults test failed:")
    showerror(stdout, e)
    println()
end

# 3. Type Validation
println("\n3. Testing Type Validation (max_iter=1.5 should fail)")
try
    Strategies.build_strategy_options(Solvers.IpoptSolver; max_iter=1.5)
    println("❌ Type validation FAILED (no exception thrown)")
catch e
    println("✅ Type validation success (exception thrown):")
    showerror(stdout, e)
    println()
end
