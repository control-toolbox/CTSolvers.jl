# Beam optimal control problem definition used by tests and examples.
function beam()

    t0=0
    tf=1
    x₁_l=0
    x₁_u=0.1
    x₁_t0=0
    x₂_t0=1
    x₁_tf=0
    x₂_tf=-1

    ocp = @def begin
        t ∈ [t0, tf], time
        x ∈ R², state
        u ∈ R, control

        x(t0) == [x₁_t0, x₂_t0]
        x(tf) == [x₁_tf, x₂_tf]
        x₁_l ≤ x₁(t) ≤ x₁_u

        ∂(x₁)(t) == x₂(t)
        ∂(x₂)(t) == u(t)

        ∫(u(t)^2) → min
    end

    return ocp, CTSolvers.initial_guess(ocp; state=[0.05, 0.1], control=0.1, variable=Float64[])
end