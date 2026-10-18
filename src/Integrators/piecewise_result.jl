# Piecewise integration result
#
# Backend-agnostic result of a multi-phase integration: keeps every phase's own result (and
# so its own interpolant) instead of flattening them into a single solution.

"""
$(TYPEDEF)

Integration result made of consecutive segments, one per phase of a multi-phase
integration. Each segment keeps its own result, so evaluation inside a phase reads that
phase's interpolant (dense segments stay solver-accurate).

The trajectory is left-continuous at a switching time: `evaluate_at(r, tᵢ)` returns the end
value of the segment that finishes at `tᵢ` (before any jump), and any time strictly after
`tᵢ` belongs to the next segment. The value after the jump is read with
[`CTSolvers.Integrators.right_limit`](@extref). The time grid concatenates the segments' grids
and keeps a single copy of each switching time, so it is strictly monotone.

# Fields
- `segments::V`: The per-phase results, in integration order.
- `switches::W`: The `n - 1` switching times (end time of every segment but the last).
- `grid::W`: The concatenated time grid of all segments, each switching time once.

See also: [`CTSolvers.Integrators.merge`](@extref), [`CTSolvers.Integrators.switching_times`](@extref),
[`CTSolvers.Integrators.AbstractIntegrationResult`](@extref).
"""
struct PiecewiseIntegrationResult{V<:AbstractVector,W<:AbstractVector} <:
       AbstractIntegrationResult
    segments::V
    switches::W
    grid::W
end

"""
$(TYPEDSIGNATURES)

Build a piecewise result from consecutive per-phase results (in integration order).

# Throws
- [`CTBase.Exceptions.IncorrectArgument`](@extref): If `segments` is empty.
"""
function PiecewiseIntegrationResult(segments::AbstractVector{<:AbstractIntegrationResult})
    if isempty(segments)
        throw(
            Exceptions.IncorrectArgument(
                "Cannot build a piecewise result from no segment";
                got="0 segments",
                expected="at least 1 segment",
                context="PiecewiseIntegrationResult",
            ),
        )
    end
    switches = [last(times(s)) for s in segments[1:(end - 1)]]
    grid = _concatenate_grids(segments)
    W = promote_type(typeof(switches), typeof(grid))
    return PiecewiseIntegrationResult(segments, convert(W, switches), convert(W, grid))
end

"""
$(TYPEDSIGNATURES)

Concatenate the time grids of consecutive segments, keeping a single copy of each switching
time: a segment's first time is dropped when it equals the previous segment's last time.
"""
function _concatenate_grids(segments::AbstractVector{<:AbstractIntegrationResult})
    grid = collect(times(first(segments)))
    for s in segments[2:end]
        ts = times(s)
        start = !isempty(grid) && !isempty(ts) && first(ts) == last(grid) ? 2 : 1
        append!(grid, ts[start:end])
    end
    return grid
end

"""
$(TYPEDSIGNATURES)

Return the index of the segment that holds time `t` (left-continuous at switching times).
"""
function _segment_index(r::PiecewiseIntegrationResult, t::Real)
    isempty(r.switches) && return 1
    forward = last(r.grid) >= first(r.grid)
    return searchsortedfirst(r.switches, t; rev=(!forward))
end

"""
$(TYPEDSIGNATURES)

Return the final state of the last segment.
"""
final_state(r::PiecewiseIntegrationResult) = final_state(last(r.segments))

"""
$(TYPEDSIGNATURES)

Return the concatenated time grid of all segments, each switching time once.
"""
times(r::PiecewiseIntegrationResult) = r.grid

"""
$(TYPEDSIGNATURES)

Evaluate the segment holding time `t` (left-continuous at switching times).
"""
function evaluate_at(r::PiecewiseIntegrationResult, t::Real)
    return evaluate_at(r.segments[_segment_index(r, t)], t)
end

"""
$(TYPEDSIGNATURES)

Return the switching times of a piecewise result: the end time of every segment but the
last, in integration order.

See also: [`CTSolvers.Integrators.right_limit`](@extref).
"""
switching_times(r::PiecewiseIntegrationResult) = r.switches

"""
$(TYPEDSIGNATURES)

Return the switching times of a single-phase result: there are none.

See also: [`CTSolvers.Integrators.switching_times`](@extref).
"""
switching_times(r::AbstractIntegrationResult) = eltype(times(r))[]

"""
$(TYPEDSIGNATURES)

Return the value just after the `i`-th switching time `tᵢ`: the start value of segment
`i + 1`, after any jump applied at `tᵢ`. [`CTSolvers.Integrators.evaluate_at`](@extref)
at `tᵢ` returns the value before the jump, so the two give both limits at `tᵢ`.

"After" follows the integration order: for a backward integration, it is the limit on the
smaller-time side.

# Throws
- [`CTBase.Exceptions.IncorrectArgument`](@extref): If `i` is not the index of a switching
  time (`1 ≤ i ≤ n - 1` for `n` segments).

See also: [`CTSolvers.Integrators.switching_times`](@extref).
"""
function right_limit(r::PiecewiseIntegrationResult, i::Integer)
    n = length(r.switches)
    1 <= i <= n || throw(
        Exceptions.IncorrectArgument(
            "no switching time with this index";
            got="i = $i",
            expected=n == 0 ? "no index: the result has a single segment" : "1 ≤ i ≤ $n",
            context="Integrators.right_limit",
        ),
    )
    return evaluate_at(r.segments[i + 1], r.switches[i])
end

"""
$(TYPEDSIGNATURES)

Return whether every segment is dense.
"""
is_dense(r::PiecewiseIntegrationResult) = all(is_dense, r.segments)

"""
$(TYPEDSIGNATURES)

Return the status of the first unsuccessful segment, or the first segment's status when all
succeeded.
"""
function Solutions.status(r::PiecewiseIntegrationResult)::Symbol
    i = findfirst(!successful, r.segments)
    return status(r.segments[something(i, 1)])
end

"""
$(TYPEDSIGNATURES)

Return whether every segment succeeded.
"""
Solutions.successful(r::PiecewiseIntegrationResult)::Bool = all(successful, r.segments)

"""
$(TYPEDSIGNATURES)

Return the integration span: from the start of the first segment to the end of the last.
"""
function _tspan(r::PiecewiseIntegrationResult)
    return (_tspan(first(r.segments))[1], _tspan(last(r.segments))[2])
end

"""
$(TYPEDSIGNATURES)

Return a copy of the piecewise result whose time grid is `grid`; the segments (and their
interpolants) are shared, and a switching time is evaluated left-continuously as before.

# Throws
- [`CTBase.Exceptions.IncorrectArgument`](@extref): If `grid` is not a valid output grid
  for the integration span.
"""
function regrid(r::PiecewiseIntegrationResult, grid::AbstractVector{<:Real})
    _check_grid(grid, _tspan(r))
    W = typeof(r.grid)
    return PiecewiseIntegrationResult(r.segments, r.switches, convert(W, collect(grid)))
end
