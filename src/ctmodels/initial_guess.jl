# ------------------------------------------------------------------------------
# Initial guess
# ------------------------------------------------------------------------------
# TODO: improve, check CTModels

abstract type AbstractOptimalControlInitialGuess end

struct OptimalControlInitialGuess{X<:Function, U<:Function, V<:Vector{<:Real}} <: AbstractOptimalControlOptimalControlInitialGuess
	state::X
	control::U
	variable::V
end

function initial_guess(
	ocp::AbstractOptimalControlProblem; 
	state::Union{Nothing, Function, Real, Vector{<:Real}}=nothing,
	control::Union{Nothing, Function, Real, Vector{<:Real}}=nothing,
	variable::Union{Nothing, Real, Vector{<:Real}}=nothing,
)
	x = initial_state(ocp, state)
	u = initial_control(ocp, control)
	v = initial_variable(ocp, variable)
	return OptimalControlInitialGuess(x, u, v)
end

# todo: add tests on dimension, etc.
initial_state(::AbstractOptimalControlProblem, state::Function) = state
initial_state(::AbstractOptimalControlProblem, state::Real) = (t) -> [state]
initial_state(::AbstractOptimalControlProblem, state::Vector{<:Real}) = (t) -> state
initial_state(::AbstractOptimalControlProblem, ::Nothing) = (t) -> [0.1]

initial_control(::AbstractOptimalControlProblem, control::Function) = control
initial_control(::AbstractOptimalControlProblem, control::Real) = (t) -> [control]
initial_control(::AbstractOptimalControlProblem, control::Vector{<:Real}) = (t) -> control
initial_control(::AbstractOptimalControlProblem, ::Nothing) = (t) -> [0.1]

initial_variable(::AbstractOptimalControlProblem, variable::Real) = [variable]
initial_variable(::AbstractOptimalControlProblem, variable::Vector{<:Real}) = variable
initial_variable(::AbstractOptimalControlProblem, ::Nothing) = [0.1]

function state(init::OptimalControlInitialGuess{
    X,
    <: Function,
    <: Vector{<:Real},
})::X where {X <: Function} 
	return init.state
end

function control(init::OptimalControlInitialGuess{
    <: Function,
    U,
    <: Vector{<:Real},
})::U where {U <: Function} 
	return init.control
end

function variable(init::OptimalControlInitialGuess{
    <: Function,
    <: Function,
    V,
})::V where {V <: Vector{<:Real}} 
	return init.variable
end
