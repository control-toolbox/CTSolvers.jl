# =============================================================================
# Shared helpers for the CTSolvers capability probes (probe/cpu, probe/gpu)
# =============================================================================
#
# A probe is a diagnostic, not a test suite: every experiment runs inside
# `probe_cell`, which never throws, and its outcome is stored as a `Cell`. Each
# block prints a capability matrix at the end, so one failing combination never
# hides the others.
#
#   ✓  the combination works and its result is correct
#   ⚠  it runs, but the result is wrong, not converged, or a warning was emitted
#   ✗  it throws (the exception type is shown)
# =============================================================================

using Logging: Logging
using Printf: @sprintf

"""
Outcome of one experiment: a mark (`:ok`, `:warn`, `:fail`) and a short note.
"""
struct Cell
    mark::Symbol
    note::String
end

symbol(c::Cell) = c.mark === :ok ? "✓" : c.mark === :warn ? "⚠" : "✗"

"""
Logger that only records the messages of warnings (and above).
"""
struct WarnCollector <: Logging.AbstractLogger
    msgs::Vector{String}
end
WarnCollector() = WarnCollector(String[])
Logging.min_enabled_level(::WarnCollector) = Logging.Warn
Logging.shouldlog(::WarnCollector, args...) = true
Logging.catch_exceptions(::WarnCollector) = false
function Logging.handle_message(l::WarnCollector, lvl, msg, args...; kw...)
    push!(l.msgs, first(split(string(msg), '\n')))
    return nothing
end

"""
    error_message(e) -> String

First line of an exception's message. CTBase exceptions carry it in `msg` (their
`showerror` starts with a source locator instead).
"""
function error_message(e)
    msg = hasproperty(e, :msg) && getproperty(e, :msg) isa AbstractString ? e.msg :
          sprint(showerror, e)
    line = string(first(split(strip(msg), '\n')))
    prefix = string(nameof(typeof(e)), ": ")
    return startswith(line, prefix) ? line[(length(prefix) + 1):end] : line
end

"""
    probe_cell(f) -> Cell

Run `f()`, which returns a `Cell` (its own verdict on the result). Exceptions become
`✗` cells, and any warning emitted turns a `✓` into a `⚠` whose note quotes it.
"""
function probe_cell(f)
    logger = WarnCollector()
    cell = try
        Logging.with_logger(f, logger)
    catch e
        Cell(:fail, string(nameof(typeof(e)), ": ", first(error_message(e), 90)))
    end
    if cell.mark === :ok && !isempty(logger.msgs)
        return Cell(:warn, "warning: " * first(first(logger.msgs), 90))
    end
    return cell
end

"""
    print_matrix(title, rows, cols, cells)

Print a capability matrix: one line per row, one mark per column, then the notes of
every cell that is not a plain `✓`.
"""
function print_matrix(title, rows::Vector{String}, cols::Vector{String}, cells::Dict)
    w = maximum(length, rows) + 2
    cw = max(14, maximum(length, cols) + 2)
    println("\n", "="^100, "\n  ", title, "\n", "="^100)
    println(rpad("", w), join((rpad(c, cw) for c in cols)))
    for r in rows
        println(rpad(r, w), join((rpad(symbol(cells[(r, c)]), cw) for c in cols)))
    end
    println("-"^100)
    for r in rows, c in cols
        cell = cells[(r, c)]
        isempty(cell.note) && continue
        println("  ", symbol(cell), " ", r, " × ", c, ": ", cell.note)
    end
    return nothing
end

"""
    check_close(value, reference; rtol) -> Cell

`✓` when `value ≈ reference`, `⚠` otherwise (with both values in the note).
"""
function check_close(value, reference; rtol=1e-4, note="")
    ok = isapprox(value, reference; rtol=rtol, atol=rtol)
    detail = @sprintf("got %.6g, expected %.6g", value, reference)
    return ok ? Cell(:ok, note) : Cell(:warn, detail * (isempty(note) ? "" : "; " * note))
end
