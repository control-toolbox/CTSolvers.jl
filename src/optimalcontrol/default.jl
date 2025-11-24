# Common
# __display() = true

__initial_guess() = nothing
#__discretizer()::AbstractOptimalControlDiscretizer = Collocation()
__modeler()::AbstractOptimizationModeler = ADNLPModeler()
__solver()::AbstractOptimizationSolver = IpoptSolver()