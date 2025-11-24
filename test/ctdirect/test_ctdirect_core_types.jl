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
        grid_size = 250
        scheme = CTSolvers.Midpoint()

        # Explicitly construct Collocation with given grid size and scheme
        colloc = CTSolvers.Collocation(grid_size, scheme)

        # grid_size(discretizer::Collocation) should return the stored grid_size
        Test.@test CTSolvers.grid_size(colloc) == grid_size

        # scheme(discretizer::Collocation) should return the stored scheme
        Test.@test CTSolvers.scheme(colloc) === scheme

        # scheme_symbol(::Collocation{T}) should map to the expected symbol
        sym = CTSolvers.scheme_symbol(colloc)
        Test.@test sym in (:midpoint, :trapeze)

        # For Midpoint, scheme_symbol should be :midpoint
        colloc_mid = CTSolvers.Collocation(grid_size, CTSolvers.Midpoint())
        Test.@test CTSolvers.scheme_symbol(colloc_mid) == :midpoint

        # For Trapezoidal, scheme_symbol should be :trapeze
        colloc_trap = CTSolvers.Collocation(grid_size, CTSolvers.Trapezoidal())
        Test.@test CTSolvers.scheme_symbol(colloc_trap) == :trapeze
    end

end

