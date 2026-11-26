# Reversed integration result
#
# The same trajectory, read in the other direction of time, without integrating again: a
# backward integration (t0 > tf) read in increasing time, as a forward one would be.

"""
$(TYPEDEF)

An integration result read in the other direction of time: its time grid is the reversed
grid of the inner result, and it is evaluated with the inner result's interpolant. Built by
`reverse(r)`.

# Fields
- `result::R`: The inner result, in its own integration order.

See also: [`CTSolvers.Integrators.AbstractIntegrationResult`](@extref).
"""
struct ReversedIntegrationResult{R<:AbstractIntegrationResult} <: AbstractIntegrationResult
    result::R
end

"""
$(TYPEDSIGNATURES)

Return the same trajectory as `r`, read in the other direction of time, without integrating
again. After a backward integration (`t0 > tf`), `reverse(r)` is the trajectory in
increasing time: [`CTSolvers.Integrators.times`](@extref) is increasing and
[`CTSolvers.Integrators.final_state`](@extref) is the state at the largest time.

- For a single result, a [`CTSolvers.Integrators.ReversedIntegrationResult`](@extref) wrapping
  `r`: `evaluate_at` reads the same interpolant.
- For a [`CTSolvers.Integrators.PiecewiseIntegrationResult`](@extref), the piecewise result of
  the reversed segments, in reverse order: its switching times are reversed, and a switching
  time stays left-continuous in the new direction (`evaluate_at` at `tᵢ` is the end value of
  the segment that finishes at `tᵢ` in the new order, `right_limit` the start value of the
  next one).

`reverse(reverse(r))` gives back a result equal to `r` (the same object for a single result).

# Arguments
- `r::AbstractIntegrationResult`: The integration result.

# Returns
- The reversed result.

# Example
```julia
r = solve(prob_backward, integ)   # tspan = (1.0, 0.0)
times(r)                          # [1.0, …, 0.0]
times(reverse(r))                 # [0.0, …, 1.0]
final_state(reverse(r))           # the state at t = 1.0, the initial condition
```
"""
Base.reverse(r::AbstractIntegrationResult) = ReversedIntegrationResult(r)
Base.reverse(r::ReversedIntegrationResult) = r.result
function Base.reverse(r::PiecewiseIntegrationResult)
    return PiecewiseIntegrationResult(map(reverse, Base.reverse(r.segments)))
end

"""
$(TYPEDSIGNATURES)

Return the reversed time grid of the inner result.
"""
times(r::ReversedIntegrationResult) = Base.reverse(times(r.result))

"""
$(TYPEDSIGNATURES)

Return the state at the last time of the reversed grid: the state at the first time of the
inner result's integration.
"""
final_state(r::ReversedIntegrationResult) = evaluate_at(r.result, first(times(r.result)))

"""
$(TYPEDSIGNATURES)

Evaluate the inner result at time `t`.
"""
evaluate_at(r::ReversedIntegrationResult, t::Real) = evaluate_at(r.result, t)

"""
$(TYPEDSIGNATURES)

Return whether the inner result is dense.
"""
is_dense(r::ReversedIntegrationResult) = is_dense(r.result)

"""
$(TYPEDSIGNATURES)

Return the status of the inner result.
"""
Solutions.status(r::ReversedIntegrationResult)::Symbol = status(r.result)

"""
$(TYPEDSIGNATURES)

Return whether the inner result succeeded.
"""
Solutions.successful(r::ReversedIntegrationResult)::Bool = successful(r.result)

"""
$(TYPEDSIGNATURES)

Return the reversed integration span of the inner result.
"""
function _tspan(r::ReversedIntegrationResult)
    t0, tf = _tspan(r.result)
    return (tf, t0)
end

"""
$(TYPEDSIGNATURES)

Return the switching times of the inner result, reversed (none for a single result).
"""
switching_times(r::ReversedIntegrationResult) = Base.reverse(switching_times(r.result))

"""
$(TYPEDSIGNATURES)

Return a copy of the reversed result whose time grid is `grid`, by regridding the inner
result on `reverse(grid)`.

# Throws
- [`CTBase.Exceptions.IncorrectArgument`](@extref): If `grid` is not a valid output grid for
  the reversed span.
"""
function regrid(r::ReversedIntegrationResult, grid::AbstractVector{<:Real})
    _check_grid(grid, _tspan(r))
    return ReversedIntegrationResult(regrid(r.result, Base.reverse(collect(grid))))
end
