# Unit tests for CTDirect core types (integrator schemes and Collocation discretizer).
function test_ctdirect_core_types()

    # ========================================================================
    # TYPE HIERARCHY
    # ========================================================================

    Test.@testset "type hierarchy" verbose=VERBOSE showtiming=SHOWTIMING begin
        # AbstractIntegratorScheme should be abstract
        Test.@test isabstracttype(CTSolvers.AbstractIntegratorScheme)

        # Concrete schemes should be subtypes
        Test.@test CTSolvers.Midpoint <: CTSolvers.AbstractIntegratorScheme
        Test.@test CTSolvers.Trapezoidal <: CTSolvers.AbstractIntegratorScheme

        # Trapeze is an alias to Trapezoidal
        Test.@test CTSolvers.Trapeze === CTSolvers.Trapezoidal

        # AbstractOptimalControlDiscretizer should be abstract
        Test.@test isabstracttype(CTSolvers.AbstractOptimalControlDiscretizer)

        # Collocation should be a concrete discretizer subtype
        Test.@test CTSolvers.Collocation <: CTSolvers.AbstractOptimalControlDiscretizer
    end

    # ========================================================================
    # COLLOCATION BEHAVIOUR
    # ========================================================================

    Test.@testset "Collocation options and scheme_symbol" verbose=VERBOSE showtiming=SHOWTIMING begin
        # Build a Collocation and read its default options via the generic
        # options API. This keeps the test aligned with the public access
        # pattern instead of calling low-level helpers directly.
        default_colloc = CTSolvers.Collocation()
        default_grid = CTSolvers.get_option_value(default_colloc, :grid)
        default_scheme = CTSolvers.get_option_value(default_colloc, :scheme)
        default_l2m = CTSolvers.get_option_value(default_colloc, :lagrange_to_mayer)

        # Sanity checks on defaults
        Test.@test default_grid isa Int
        Test.@test default_grid > 0
        Test.@test default_scheme isa CTSolvers.AbstractIntegratorScheme
        Test.@test default_scheme isa CTSolvers.Midpoint
        Test.@test default_l2m === false

        # Explicitly construct Collocation with given grid and scheme
        colloc = CTSolvers.Collocation(;
            grid=default_grid, scheme=default_scheme, lagrange_to_mayer=true
        )

        # Collocation options should expose the stored grid and scheme via options_values
        Test.@test CTSolvers.get_option_value(colloc, :grid) == default_grid
        Test.@test CTSolvers.get_option_value(colloc, :scheme) === default_scheme
        Test.@test CTSolvers.get_option_value(colloc, :lagrange_to_mayer) === true

        # The type parameter of Collocation should reflect the concrete scheme type
        Test.@test default_colloc isa CTSolvers.Collocation{CTSolvers.Midpoint}
        Test.@test colloc isa CTSolvers.Collocation{CTSolvers.Midpoint}
    end

    Test.@testset "discretizer symbols and registry" verbose=VERBOSE showtiming=SHOWTIMING begin
        # get_symbol should return :collocation for the Collocation type and instances.
        Test.@test CTSolvers.get_symbol(CTSolvers.Collocation) == :collocation
        Test.@test CTSolvers.get_symbol(CTSolvers.Collocation()) == :collocation

        # The registered discretizer types should include Collocation.
        regs = CTSolvers.registered_discretizer_types()
        Test.@test CTSolvers.Collocation in regs

        syms = CTSolvers.discretizer_symbols()
        Test.@test :collocation in syms

        # build_discretizer_from_symbol should construct a Collocation
        # discretizer. Use the defaults read from a Collocation instance so
        # that we stay on the generic options API.
        base_disc = CTSolvers.Collocation()
        default_grid = CTSolvers.get_option_value(base_disc, :grid)
        default_scheme = CTSolvers.get_option_value(base_disc, :scheme)
        disc = CTSolvers.build_discretizer_from_symbol(
            :collocation; grid=default_grid, scheme=default_scheme
        )
        Test.@test disc isa CTSolvers.Collocation
        Test.@test CTSolvers.get_option_value(disc, :grid) == default_grid
        Test.@test CTSolvers.get_option_value(disc, :scheme) === default_scheme
    end

    Test.@testset "build_discretizer_from_symbol unknown symbol" verbose=VERBOSE showtiming=SHOWTIMING begin
        err = nothing
        try
            CTSolvers.build_discretizer_from_symbol(:foo)
        catch e
            err = e
        end
        Test.@test err isa CTBase.IncorrectArgument

        buf = sprint(showerror, err)
        Test.@test occursin("Unknown discretizer symbol", buf)
        Test.@test occursin("foo", buf)
        Test.@test occursin("collocation", buf)
    end

    Test.@testset "Collocation default_options and option_default" verbose=VERBOSE showtiming=SHOWTIMING begin
        opts = CTSolvers.default_options(CTSolvers.Collocation)

        # Read the defaults through the generic options API on a default
        # Collocation instance instead of calling low-level helpers.
        base_disc = CTSolvers.Collocation()
        default_grid = CTSolvers.get_option_value(base_disc, :grid)
        default_scheme = CTSolvers.get_option_value(base_disc, :scheme)
        default_l2m = CTSolvers.get_option_value(base_disc, :lagrange_to_mayer)

        Test.@test opts.grid == default_grid
        Test.@test opts.scheme === default_scheme
        Test.@test opts.lagrange_to_mayer === default_l2m

        # Type-based and instance-based views of the options metadata should agree.
        colloc_type = typeof(base_disc)

        opts_from_type = CTSolvers.default_options(CTSolvers.Collocation)
        opts_from_inst = CTSolvers.default_options(colloc_type)
        Test.@test opts_from_inst == opts_from_type

        keys_from_type = CTSolvers.options_keys(CTSolvers.Collocation)
        keys_from_inst = CTSolvers.options_keys(colloc_type)
        Test.@test Set(keys_from_inst) == Set(keys_from_type)

        Test.@test CTSolvers.option_default(:grid, CTSolvers.Collocation) == default_grid
        Test.@test CTSolvers.option_default(:scheme, CTSolvers.Collocation) ===
            default_scheme
        Test.@test CTSolvers.option_default(:grid, colloc_type) == default_grid
        Test.@test CTSolvers.option_default(:scheme, colloc_type) === default_scheme

        Test.@test CTSolvers.option_default(:lagrange_to_mayer, CTSolvers.Collocation) ===
            false
        Test.@test CTSolvers.option_default(:lagrange_to_mayer, colloc_type) === false
    end
end
