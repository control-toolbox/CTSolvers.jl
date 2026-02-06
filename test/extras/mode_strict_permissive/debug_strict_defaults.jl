# ========================================
# Script de Diagnostic : Strict Defaults Issues
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

println("🔍 Diagnostic du test : Default Values")
println("=" ^ 50)

# Test simple default access
println("\n1. Building options with defaults")
opts = Strategies.build_strategy_options(Solvers.IpoptSolver)
println("Opts keys: ", keys(opts))

println("\n2. Accessing defaults")
try
    # Check max_iter (should be default 1000)
    val = opts[:max_iter]
    println("✅ max_iter = $val")
    
    src = Strategies.option_source(opts, :max_iter)
    println("✅ source(max_iter) = $src")
    
    if src != :default
        println("❌ Source mismatch! Expected :default, got $src")
    end
catch e
    println("❌ Access failed:")
    showerror(stdout, e)
    println()
end

println("\n3. Testing Alias Access")
try
    # Check alias access (should resolve to primary)
    # Note: StrategyOptions might not support direct alias access via getindex
    # The test expects: opts[:maxiter] to fail or work? 
    # Let's check what the test code assumes.
    # The test says: 
    # opts = Strategies.build_strategy_options(Solvers.IpoptSolver; maxiter=300)
    # @test opts[:max_iter] == 300
    
    opts_alias = Strategies.build_strategy_options(Solvers.IpoptSolver; maxiter=300)
    println("✅ Alias build success")
    println("Value via primary key: ", opts_alias[:max_iter])
catch e
    println("❌ Alias test failed:")
    showerror(stdout, e)
    println()
end
