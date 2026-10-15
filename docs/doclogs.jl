# ==============================================================================
# DocLogs — show warnings without the source path of the build machine
#
# Inside `@example` blocks, Documenter prints log records with their source
# location (`└ @ Module /path/on/the/build/machine/file.jl:line`), which leaks
# local or CI paths into the rendered page. `DocLogs.run(f)` evaluates `f()`,
# prints its warnings as `┌ Warning: …` / `└ @ Module`, and returns its value.
# Wrap the visible lines with hidden lines:
#
#     ```@example page
#     Main.DocLogs.run(; show = true) do # hide
#     CTSolvers.Solvers.Ipopt(bound_relax_factor = 1e-10; mode = :permissive)
#     end # hide
#     ```
#
# Variables assigned inside the block must be declared `global` on a hidden line.
#
# Documenter drops what a block prints when the block returns a value, so to show
# both the warnings and the value, pass `show=true` (the value is then printed after
# the warnings and `nothing` is returned).
# ==============================================================================

module DocLogs

using Logging: Logging
using Test: Test

"""
    run(f; show=false) -> f() or nothing

Evaluate `f()` with warnings captured, print them without source paths, and return
the value of `f()`. With `show=true`, print the value as the REPL would (after the
warnings) and return `nothing`.
"""
function run(f; show::Bool=false)
    logs = Test.TestLogger(; min_level=Logging.Warn)
    value = Logging.with_logger(f, logs)
    for record in logs.logs
        lines = split(string(record.message), '\n')
        println("┌ Warning: ", first(lines))
        foreach(l -> println("│ ", l), lines[2:end])
        println("└ @ ", record._module)
    end
    if show
        Base.show(IOContext(stdout, :color => true), MIME"text/plain"(), value)
        println()
        return nothing
    end
    return value
end

end # module DocLogs
