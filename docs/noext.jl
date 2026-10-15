# ==============================================================================
# NoExt — show what CTSolvers does when a backend extension is NOT loaded
#
# make.jl loads every weak dependency (the API reference documents the
# extensions), and an extension's methods are global to the process: no module
# scoping can hide them. So an `ExtensionError` cannot be shown with `@repl`.
#
# `NoExt.repl(code)` runs `code` in a fresh Julia process where only CTSolvers
# is loaded (same docs environment, so no version drift), and returns the REPL
# transcript as a colored block, rendered like an `@repl` block. Use it from an
# `@eval` block:
#
#     ```@eval
#     Main.NoExt.repl("CTSolvers.Solvers.Ipopt()")
#     ```
#
# The build fails if `code` does not throw: an example that no longer shows an
# error cannot silently become wrong.
# ==============================================================================

module NoExt

using Markdown: Markdown

const DOCS_PROJECT = @__DIR__

# The child process: load CTSolvers only, then evaluate the snippets (separated by NUL)
# in order. Every snippet but the last must succeed; the last must throw. The error is
# printed outside the `catch` block: without a backtrace, CTBase omits the source
# locator, exactly as Documenter's `@repl` shows it.
const CHILD_SCRIPT = raw"""
using CTSolvers: CTSolvers
snippets = split(read(stdin, String), '\0')
for code in snippets[1:(end - 1)]
    Core.eval(Main, Meta.parseall(code))
end
err = try
    Core.eval(Main, Meta.parseall(snippets[end]))  # no LoadError wrapper
    nothing
catch e
    e
end
if err === nothing
    print("NOEXT_NO_ERROR")
else
    print(IOContext(stdout, :color => true), "ERROR: ")
    showerror(IOContext(stdout, :color => true), err)
end
"""

"""
    run_without_extensions(codes::AbstractString...) -> String

Evaluate `codes` in order in a fresh Julia process where only CTSolvers is loaded, and
return the error displayed by the last one (with ANSI colors). Throws if a snippet
before the last fails, or if the last one does not throw.
"""
function run_without_extensions(codes::AbstractString...)
    julia = Base.julia_cmd()
    load_path = join(LOAD_PATH, Sys.iswindows() ? ';' : ':')
    cmd = `$julia --startup-file=no --color=yes --project=$DOCS_PROJECT -e $CHILD_SCRIPT`
    cmd = addenv(cmd, "JULIA_LOAD_PATH" => load_path)
    output = read(pipeline(cmd; stdin=IOBuffer(join(codes, '\0'))), String)
    if occursin("NOEXT_NO_ERROR", output)
        error("NoExt.repl: `$(last(codes))` did not throw without extensions; fix the example.")
    end
    return rstrip(output)
end

"""
    repl(codes::AbstractString...) -> Markdown.MD

REPL transcript of `codes` run without any extension: every snippet is shown as a
`julia>` input, and the last one's error as output. Rendered like an `@repl` block by
DocumenterVitepress (`ansi` fence with a `julia-repl-runs` spec: Julia-highlighted
input, ANSI-colored output). The snippets before the last are expected to print nothing
(e.g. `using` statements).
"""
function repl(codes::AbstractString...)
    output = run_without_extensions(codes...)
    input = join(("julia> " * c for c in codes), "\n\n")
    n_in = count('\n', input) + 1
    n_out = count('\n', output) + 1
    spec = "julia:$(n_in),ansi:$(n_out)"
    return Markdown.MD(Markdown.Code("ansi julia-repl-runs=$spec", input * "\n" * output))
end

end # module NoExt
