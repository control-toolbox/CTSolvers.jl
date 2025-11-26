# Unit tests for CTDirect core types (integrator schemes and Collocation discretizer).
function test_ctdirect_core_types()

    # ========================================================================
    # TYPE HIERARCHY
    # ========================================================================

    Test.@testset "ctdirect/core_types: type hierarchy" verbose=VERBOSE showtiming=SHOWTIMING begin
        # AbstractIntegratorScheme should be abstract
        Test.@test isabstracttype(CTSolvers.AbstractIntegratorScheme)

        # Concrete schemes should be subtypes
        Test.@test CTSolvers.Midpoint    <: CTSolvers.AbstractIntegratorScheme
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

    Test.@testset "ctdirect/core_types: Collocation options and scheme_symbol" verbose=VERBOSE showtiming=SHOWTIMING begin
        # Build a Collocation and read its default options via the generic
        # options API. This keeps the test aligned with the public access
        # pattern instead of calling low-level helpers directly.
        default_colloc = CTSolvers.Collocation()
        default_grid = CTSolvers.get_option_value(default_colloc, :grid_size)
        default_scheme = CTSolvers.get_option_value(default_colloc, :scheme)

        # Sanity checks on defaults
        Test.@test default_grid isa Int
        Test.@test default_grid > 0
        Test.@test default_scheme isa CTSolvers.AbstractIntegratorScheme
        Test.@test default_scheme isa CTSolvers.Midpoint

        # Explicitly construct Collocation with given grid size and scheme
        colloc = CTSolvers.Collocation(; grid_size=default_grid, scheme=default_scheme)

        # Collocation options should expose the stored grid_size and scheme via options_values
        Test.@test CTSolvers.get_option_value(colloc, :grid_size) == default_grid
        Test.@test CTSolvers.get_option_value(colloc, :scheme)    === default_scheme
    end

    Test.@testset "ctdirect/core_types: discretizer symbols and registry" verbose=VERBOSE showtiming=SHOWTIMING begin
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
        default_grid = CTSolvers.get_option_value(base_disc, :grid_size)
        default_scheme = CTSolvers.get_option_value(base_disc, :scheme)
        disc = CTSolvers.build_discretizer_from_symbol(:collocation; grid_size=default_grid, scheme=default_scheme)
        Test.@test disc isa CTSolvers.Collocation
        Test.@test CTSolvers.get_option_value(disc, :grid_size) == default_grid
        Test.@test CTSolvers.get_option_value(disc, :scheme)    === default_scheme
    end

    Test.@testset "ctdirect/core_types: Collocation default_options and option_default" verbose=VERBOSE showtiming=SHOWTIMING begin
        opts = CTSolvers.default_options(CTSolvers.Collocation)

        # Read the defaults through the generic options API on a default
        # Collocation instance instead of calling low-level helpers.
        base_disc = CTSolvers.Collocation()
        default_grid = CTSolvers.get_option_value(base_disc, :grid_size)
        default_scheme = CTSolvers.get_option_value(base_disc, :scheme)

        Test.@test opts.grid_size == default_grid
        Test.@test opts.scheme    === default_scheme

        Test.@test CTSolvers.option_default(:grid_size, CTSolvers.Collocation) == default_grid
        Test.@test CTSolvers.option_default(:scheme, CTSolvers.Collocation)    === default_scheme
    end

end

