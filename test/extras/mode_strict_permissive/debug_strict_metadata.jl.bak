# ========================================
# Script de Diagnostic : Strict Validation Issue
# ========================================

using Pkg
Pkg.activate(joinpath(@__DIR__, "..")) # Activate test/extras environment

# Add CTSolvers in development mode
if !haskey(Pkg.project().dependencies, "CTSolvers")
    Pkg.develop(path=joinpath(@__DIR__, "..", "..", ".."))
end

using CTSolvers
using CTSolvers.Strategies
using CTSolvers.Solvers
using NLPModelsIpopt # Required to trigger the extension
using Test

println("🔍 Diagnostic du test : Metadata Implementation")
println("="^50)

# Check if IpoptSolver is defined
println("Checking IpoptSolver definition:")
println(Solvers.IpoptSolver)

# Check metadata method availability
println("\nChecking metadata method for IpoptSolver:")
try
    meta = Strategies.metadata(Solvers.IpoptSolver)
    println("✅ Metadata found: ", meta)
catch e
    println("❌ Metadata check failed:")
    showerror(stdout, e)
    println()
end

# Check if we can build options
println("\nChecking build_strategy_options:")
try
    opts = Strategies.build_strategy_options(Solvers.IpoptSolver; max_iter=100)
    println("✅ Options built: ", opts)
catch e
    println("❌ build_strategy_options failed:")
    showerror(stdout, e)
    println()
end
