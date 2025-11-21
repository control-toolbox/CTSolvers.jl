# ------------------------------------------------------------------------------
# Initial guess
# ------------------------------------------------------------------------------
# TODO: improve, check CTModels

abstract type AbstractInit end

struct InitialGuess{X<:Function, U<:Function, V<:Vector{<:Real}} <: AbstractInit
	state::X
	control::U
	variable::V
end

function initial_guess(
	ocp::CTModels.Model; 
	state::Union{Nothing, Function, Real, Vector{<:Real}}=nothing,
	control::Union{Nothing, Function, Real, Vector{<:Real}}=nothing,
	variable::Union{Nothing, Real, Vector{<:Real}}=nothing,
)
	x = initial_state(ocp, state)
	u = initial_control(ocp, control)
	v = initial_variable(ocp, variable)
	return InitialGuess(x, u, v)
end

# todo: add tests on dimension, etc.
initial_state(::CTModels.Model, state::Function) = state
initial_state(::CTModels.Model, state::Real) = (t) -> [state]
initial_state(::CTModels.Model, state::Vector{<:Real}) = (t) -> state
initial_state(::CTModels.Model, ::Nothing) = (t) -> [0.1]

initial_control(::CTModels.Model, control::Function) = control
initial_control(::CTModels.Model, control::Real) = (t) -> [control]
initial_control(::CTModels.Model, control::Vector{<:Real}) = (t) -> control
initial_control(::CTModels.Model, ::Nothing) = (t) -> [0.1]

initial_variable(::CTModels.Model, variable::Real) = [variable]
initial_variable(::CTModels.Model, variable::Vector{<:Real}) = variable
initial_variable(::CTModels.Model, ::Nothing) = [0.1]

function state(init::InitialGuess{
    X,
    <: Function,
    <: Vector{<:Real},
})::X where {X <: Function} 
	return init.state
end

function control(init::InitialGuess{
    <: Function,
    U,
    <: Vector{<:Real},
})::U where {U <: Function} 
	return init.control
end

function variable(init::InitialGuess{
    <: Function,
    <: Function,
    V,
})::V where {V <: Vector{<:Real}} 
	return init.variable
end
