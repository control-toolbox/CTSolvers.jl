try
    using Revise
catch
    println("Revise not found")
end
using Pkg
Pkg.activate(joinpath(@__DIR__, "..", ".."))

using CTSolvers
using CommonSolve
using ADNLPModels
using ExaModels
using MadNLP
using MadNCL

include(joinpath(@__DIR__, "..", "problems_definition.jl"))
include(joinpath(@__DIR__, "..", "rosenbrock.jl"))

# NLPModelsIpopt
ipopt_options = Dict(
    :max_iter => 100,
    :tol => 1e-6,
    :print_level => 5,
    :mu_strategy => "adaptive",
    :linear_solver => "Mumps",
    :sb => "yes",
)
modeler = CTSolvers.ADNLPModelBackend(; backend=:manual)
solver = CTSolvers.NLPModelsIpoptBackend(; ipopt_options...)
sol = CommonSolve.solve(rosenbrock_prob, rosenbrock_init, modeler, solver)
sol = CommonSolve.solve(rosenbrock_prob, rosenbrock_init, modeler, solver; display=false)

# MadNLP
madnlp_options = Dict(:max_iter => 100, :tol => 1e-6, :print_level => MadNLP.INFO)
modeler = CTSolvers.ADNLPModelBackend(; backend=:manual)
solver = CTSolvers.MadNLPBackend(; madnlp_options...)
sol = CommonSolve.solve(rosenbrock_prob, rosenbrock_init, modeler, solver)
sol = CommonSolve.solve(rosenbrock_prob, rosenbrock_init, modeler, solver; display=false)

# MadNCL
function f_madncl_options(BaseType)
    Dict(
        :max_iter => 100,
        :tol => 1e-6,
        :print_level => MadNLP.INFO,
        :ncl_options => MadNCL.NCLOptions{BaseType}(; verbose=true),
    )
end
BaseType = Float64
modeler = CTSolvers.ADNLPModelBackend(; backend=:manual)
solver = CTSolvers.MadNCLBackend(; f_madncl_options(BaseType)...)
sol = CommonSolve.solve(rosenbrock_prob, rosenbrock_init, modeler, solver)
sol = CommonSolve.solve(rosenbrock_prob, rosenbrock_init, modeler, solver; display=false)
