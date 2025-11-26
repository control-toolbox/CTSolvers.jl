# Unit tests for generic options schema utilities (OptionSpec and helpers).
function test_ctmodels_options_schema()

    # Dummy tool types for exercising the generic API
    struct DummyToolNoSpecs <: CTSolvers.AbstractOCPTool end

    struct DummyToolWithSpecs <: CTSolvers.AbstractOCPTool
        options_values
        options_sources
    end

    CTSolvers._option_specs(::Type{DummyToolNoSpecs}) = missing

    CTSolvers._option_specs(::Type{DummyToolWithSpecs}) = (
        max_iter = CTSolvers.OptionSpec(type=Int,     default=100,  description="Max iterations"),
        tol      = CTSolvers.OptionSpec(type=Float64, default=1e-6, description="Tolerance"),
        verbose  = CTSolvers.OptionSpec(type=Bool,    default=missing, description=missing),
    )

    # ========================================================================
    # METADATA ACCESSORS (options_keys, is_an_option_key, option_* helpers)
    # ========================================================================

    Test.@testset "options_schema: metadata accessors" verbose=VERBOSE showtiming=SHOWTIMING begin
        # No specs: options_keys / is_an_option_key / option_* should return missing
        Test.@test CTSolvers.options_keys(DummyToolNoSpecs) === missing
        Test.@test CTSolvers.is_an_option_key(:foo, DummyToolNoSpecs) === missing
        Test.@test CTSolvers.option_type(:foo, DummyToolNoSpecs) === missing
        Test.@test CTSolvers.option_description(:foo, DummyToolNoSpecs) === missing
        Test.@test CTSolvers.option_default(:foo, DummyToolNoSpecs) === missing
        Test.@test CTSolvers.default_options(DummyToolNoSpecs) == NamedTuple()

        # With specs
        keys = CTSolvers.options_keys(DummyToolWithSpecs)
        Test.@test Set(keys) == Set((:max_iter, :tol, :verbose))

        Test.@test CTSolvers.is_an_option_key(:max_iter, DummyToolWithSpecs)
        Test.@test !CTSolvers.is_an_option_key(:foo, DummyToolWithSpecs)

        Test.@test CTSolvers.option_type(:max_iter, DummyToolWithSpecs) == Int
        Test.@test CTSolvers.option_type(:tol,      DummyToolWithSpecs) == Float64
        Test.@test CTSolvers.option_type(:foo,      DummyToolWithSpecs) === missing

        Test.@test CTSolvers.option_description(:max_iter, DummyToolWithSpecs) isa AbstractString
        Test.@test CTSolvers.option_description(:verbose, DummyToolWithSpecs) === missing

        Test.@test CTSolvers.option_default(:max_iter, DummyToolWithSpecs) == 100
        Test.@test CTSolvers.option_default(:tol,      DummyToolWithSpecs) == 1e-6
        Test.@test CTSolvers.option_default(:verbose,  DummyToolWithSpecs) === missing

        # default_options should include only non-missing defaults
        defs = CTSolvers.default_options(DummyToolWithSpecs)
        Test.@test Set(propertynames(defs)) == Set((:max_iter, :tol))
        Test.@test defs.max_iter == 100
        Test.@test defs.tol == 1e-6
    end

    # ========================================================================
    # _filter_options
    # ========================================================================

    Test.@testset "options_schema: _filter_options" verbose=VERBOSE showtiming=SHOWTIMING begin
        nt = (a=1, b=2, c=3)
        filtered = CTSolvers._filter_options(nt, (:b,))
        Test.@test Set(propertynames(filtered)) == Set((:a, :c))
        Test.@test filtered.a == 1
        Test.@test filtered.c == 3
    end

    # ========================================================================
    # _string_distance and _suggest_option_keys
    # ========================================================================

    Test.@testset "options_schema: suggestions" verbose=VERBOSE showtiming=SHOWTIMING begin
        # A simple sanity check on the distance function
        d_exact = CTSolvers._string_distance("max_iter", "max_iter")
        d_close = CTSolvers._string_distance("max_iter", "mx_iter")
        d_far   = CTSolvers._string_distance("max_iter", "tol")
        Test.@test d_exact == 0
        Test.@test d_close < d_far

        # Suggestions should prioritize the closest known key
        sugg = CTSolvers._suggest_option_keys(:mx_iter, DummyToolWithSpecs)
        Test.@test length(sugg) >= 1
        Test.@test sugg[1] == :max_iter
    end

    # ========================================================================
    # get_option_value / get_option_source / get_option_default
    # ========================================================================

    Test.@testset "options_schema: get_option_*" verbose=VERBOSE showtiming=SHOWTIMING begin
        # Build values/sources using the generic constructor
        vals, srcs = CTSolvers._build_ocp_tool_options(DummyToolWithSpecs; tol=1e-4)
        tool = DummyToolWithSpecs(vals, srcs)

        # Known options with and without user override
        Test.@test CTSolvers.get_option_value(tool, :max_iter) == 100
        Test.@test CTSolvers.get_option_source(tool, :max_iter) == :ct_default
        Test.@test CTSolvers.get_option_default(tool, :max_iter) == 100

        Test.@test CTSolvers.get_option_value(tool, :tol) == 1e-4
        Test.@test CTSolvers.get_option_source(tool, :tol) == :user
        Test.@test CTSolvers.get_option_default(tool, :tol) == 1e-6

        # Known option declared but with no default and not set by the user
        err_no_val = nothing
        try
            CTSolvers.get_option_value(tool, :verbose)
        catch e
            err_no_val = e
        end
        Test.@test err_no_val isa CTBase.IncorrectArgument
        buf_no_val = sprint(showerror, err_no_val)
        Test.@test occursin("Initial", buf_no_val) || occursin("must", buf_no_val)  # basic sanity

        # Unknown option key should trigger an IncorrectArgument with suggestions
        err_unknown = nothing
        try
            CTSolvers.get_option_value(tool, :mx_iter)
        catch e
            err_unknown = e
        end
        Test.@test err_unknown isa CTBase.IncorrectArgument
        buf_unknown = sprint(showerror, err_unknown)
        Test.@test occursin("Unknown option mx_iter", buf_unknown)
        Test.@test occursin("max_iter", buf_unknown)
        Test.@test occursin("_show_options(DummyToolWithSpecs)", buf_unknown)
    end

    # ========================================================================
    # _show_options
    # ========================================================================

    Test.@testset "options_schema: _show_options" verbose=VERBOSE showtiming=SHOWTIMING begin
        buf_none = sprint() do io
            redirect_stdout(io) do
                CTSolvers._show_options(DummyToolNoSpecs)
            end
        end
        Test.@test occursin("No option metadata available", buf_none)

        buf_some = sprint() do io
            redirect_stdout(io) do
                CTSolvers._show_options(DummyToolWithSpecs)
            end
        end
        Test.@test occursin("Options for", buf_some)
        Test.@test occursin("max_iter", buf_some)
        Test.@test occursin("tol", buf_some)
    end

    # ========================================================================
    # _validate_option_kwargs
    # ========================================================================

    Test.@testset "options_schema: _validate_option_kwargs" verbose=VERBOSE showtiming=SHOWTIMING begin
        # No specs: nothing should be validated or rejected
        CTSolvers._validate_option_kwargs((foo=1,), DummyToolNoSpecs; strict_keys=false)

        # Known keys with correct types
        CTSolvers._validate_option_kwargs((max_iter=200, tol=1e-5), DummyToolWithSpecs; strict_keys=false)

        # Unknown key with strict_keys = false should be accepted
        CTSolvers._validate_option_kwargs((foo=1,), DummyToolWithSpecs; strict_keys=false)

        # Unknown key with strict_keys = true should error with suggestions
        err_unknown = nothing
        try
            CTSolvers._validate_option_kwargs((mx_iter=10,), DummyToolWithSpecs; strict_keys=true)
        catch e
            err_unknown = e
        end
        Test.@test err_unknown isa CTBase.IncorrectArgument
        buf = sprint(showerror, err_unknown)
        Test.@test occursin("Unknown option mx_iter", buf)
        Test.@test occursin("max_iter", buf)
        Test.@test occursin("_show_options(DummyToolWithSpecs)", buf)

        # Wrong type for a known option should error
        err_type = nothing
        try
            CTSolvers._validate_option_kwargs((tol="1e-6",), DummyToolWithSpecs; strict_keys=false)
        catch e
            err_type = e
        end
        Test.@test err_type isa CTBase.IncorrectArgument
        buf_type = sprint(showerror, err_type)
        Test.@test occursin("Invalid type for option tol", buf_type)
    end

    # ========================================================================
    # _build_ocp_tool_options
    # ========================================================================

    Test.@testset "options_schema: _build_ocp_tool_options" verbose=VERBOSE showtiming=SHOWTIMING begin
        # With specs: defaults merged with user overrides and provenance tracked
        vals, srcs = CTSolvers._build_ocp_tool_options(DummyToolWithSpecs; tol=1e-4)
        Test.@test vals.max_iter == 100
        Test.@test vals.tol == 1e-4
        Test.@test srcs.max_iter == :ct_default
        Test.@test srcs.tol == :user

        # Without specs: user kwargs should pass through unchanged and be marked as :user
        vals2, srcs2 = CTSolvers._build_ocp_tool_options(DummyToolNoSpecs; foo=1, bar=2)
        Test.@test vals2 == (foo=1, bar=2)
        Test.@test srcs2 == (foo=:user, bar=:user)
    end

end
