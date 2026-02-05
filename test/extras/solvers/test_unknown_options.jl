# Test unknown options for Ipopt, MadNLP, and MadNCL backends directly

using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))

using NLPModelsIpopt
using MadNLP
using MadNLPMumps
using MadNCL
using ADNLPModels

println("\n" * "="^60)
println("Testing backend behavior with unknown options")
println("="^60)

# Define a simple problem with constraints: 
# min x^2 + y^2 s.t. x + y = 1
nlp = ADNLPModel(
    x -> x[1]^2 + x[2]^2,
    [1.0, 1.0],
    x -> [x[1] + x[2]],
    [1.0], [1.0]
)

# 1. Ipopt
println("\n>>> 1. NLPModelsIpopt.solve! with 'fake_option=true'")
try
    solver = NLPModelsIpopt.IpoptSolver(nlp)
    stats = NLPModelsIpopt.solve!(solver, nlp; fake_option=true, print_level=0)
    println("Ipopt finished (stats.status = $(stats.status))")
catch e
    println("Ipopt caught error: $e")
end

# 2. MadNLP
println("\n>>> 2. MadNLP.MadNLPSolver constructor with 'fake_option=true'")
try
    # MadNLP takes options in the constructor
    solver = MadNLP.MadNLPSolver(nlp; fake_option=true, print_level=MadNLP.ERROR)
    stats = MadNLP.solve!(solver)
    println("MadNLP finished (stats.status = $(stats.status))")
catch e
    println("MadNLP caught error: $e")
end

# 3. MadNCL
println("\n>>> 3. MadNCL.NCLSolver constructor with 'fake_option=true'")
try
    # MadNCL also takes options in the constructor
    # We provide a default NCLOptions to avoid any issues
    ncl_options = MadNCL.NCLOptions{Float64}(verbose=false)
    solver = MadNCL.NCLSolver(nlp; ncl_options=ncl_options, fake_option=true, print_level=MadNLP.ERROR)
    stats = MadNCL.solve!(solver)
    println("MadNCL finished (stats.status = $(stats.status))")
catch e
    println("MadNCL caught error: $e")
end

println("\n" * "="^60)
println("Test finished")
println("="^60)
