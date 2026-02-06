# ==============================================================================
# CTSolvers API Reference Generator
# ==============================================================================
#
# This file generates the API reference documentation for CTSolvers.
# It uses CTBase.automatic_reference_documentation to scan source files
# and generate documentation pages.
#
# ==============================================================================

"""
    generate_api_reference(src_dir::String, ext_dir::String)

Generate the API reference documentation for CTSolvers.
Returns the list of pages.
"""
function generate_api_reference(src_dir::String, ext_dir::String)
    # Helper to build absolute paths
    src(files...) = [abspath(joinpath(src_dir, f)) for f in files]
    ext(files...) = [abspath(joinpath(ext_dir, f)) for f in files]

    # Symbols to exclude from documentation
    EXCLUDE_SYMBOLS = Symbol[
        :include,
        :eval,
    ]

    pages = [
        # ───────────────────────────────────────────────────────────────────
        # Options
        # ───────────────────────────────────────────────────────────────────
        CTBase.automatic_reference_documentation(;
            subdirectory=".",
            primary_modules=[
                CTSolvers.Options => src(
                    joinpath("Options", "Options.jl"),
                    joinpath("Options", "option_definition.jl"),
                    joinpath("Options", "option_value.jl"),
                    joinpath("Options", "extraction.jl"),
                    joinpath("Options", "not_provided.jl"),
                ),
            ],
            exclude=EXCLUDE_SYMBOLS,
            public=true,
            private=true,
            title="Options",
            title_in_menu="Options",
            filename="api_options",
        ),
    ]

    return pages
end

"""
    with_api_reference(callback::Function, src_dir::String, ext_dir::String)

Generate API reference and call the callback with the generated pages.
This is the main entry point for the documentation build system.
"""
function with_api_reference(callback::Function, src_dir::String, ext_dir::String)
    api_pages = generate_api_reference(src_dir, ext_dir)
    return callback(api_pages)
end