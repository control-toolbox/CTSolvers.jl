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

    Test.@testset "ctdirect/core_types: Collocation, grid_size, scheme, scheme_symbol" verbose=VERBOSE showtiming=SHOWTIMING begin
        # Build a Collocation using the default helpers to remain consistent
        # with test_ctdirect_default.jl
        default_grid = CTSolvers.__grid_size()
        default_scheme = CTSolvers.__scheme()

        # Sanity checks on defaults
        Test.@test default_grid isa Int
        Test.@test default_grid > 0
        Test.@test default_scheme isa CTSolvers.AbstractIntegratorScheme

        # Explicitly construct Collocation with given grid size and scheme
        colloc = CTSolvers.Collocation(; grid_size=default_grid, scheme=default_scheme)

        # grid_size(discretizer::Collocation) should return the stored grid_size
        Test.@test CTSolvers.grid_size(colloc) == default_grid

        # scheme(discretizer::Collocation) should return the stored scheme
        Test.@test CTSolvers.scheme(colloc) === default_scheme

        # scheme_symbol(::Collocation{T}) should map to the expected symbol
        sym = CTSolvers.scheme_symbol(colloc)
        Test.@test sym in (:midpoint, :trapeze)

        # For Midpoint, scheme_symbol should be :midpoint
        colloc_mid = CTSolvers.Collocation(; grid_size=default_grid, scheme=CTSolvers.Midpoint())
        Test.@test CTSolvers.scheme_symbol(colloc_mid) == :midpoint

        # For Trapezoidal, scheme_symbol should be :trapeze
        colloc_trap = CTSolvers.Collocation(; grid_size=default_grid, scheme=CTSolvers.Trapezoidal())
        Test.@test CTSolvers.scheme_symbol(colloc_trap) == :trapeze
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

        # build_discretizer_from_symbol should construct a Collocation discretizer.
        default_grid = CTSolvers.__grid_size()
        default_scheme = CTSolvers.__scheme()
        disc = CTSolvers.build_discretizer_from_symbol(:collocation; grid_size=default_grid, scheme=default_scheme)
        Test.@test disc isa CTSolvers.Collocation
        Test.@test CTSolvers.grid_size(disc) == default_grid
        Test.@test CTSolvers.scheme(disc) === default_scheme
    end

end

