# Helper script to manually exercise CTSolvers on benchmark problems (not part of automated test suite).
try
    using Revise
catch
    println("Revise not found")
end
using Pkg
Pkg.activate(joinpath(@__DIR__, "..", ".."))

