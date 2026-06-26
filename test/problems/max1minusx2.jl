# Simple 1D maximization problem: max f(x) = 1 - x^2

function max1minusx2_objective(x)
    return 1.0 - x[1]^2
end

function max1minusx2_constraint(x)
    return x[1]
end

function max1minusx2_is_minimize()
    return false
end

function Max1MinusX2()
    # define common functions
    F(x) = max1minusx2_objective(x)
    c(x) = max1minusx2_constraint(x) # unconstrained problem are not working with MadNCL
    lcon = [-5.0]
    ucon = [5.0]
    minimize = max1minusx2_is_minimize()

    # ADNLPModels builder: simple equality-constrained problem
    function build_adnlp_model(
        initial_guess::AbstractVector; kwargs...
    )::ADNLPModels.ADNLPModel
        return ADNLPModels.ADNLPModel(
            F, initial_guess, c, lcon, ucon; minimize=minimize, kwargs...
        )
    end

    # ExaModels builder: same equality constraint
    function build_exa_model(
        ::Type{BaseType}, initial_guess::AbstractVector; kwargs...
    )::ExaModels.ExaModel where {BaseType<:AbstractFloat}
        m = ExaModels.ExaCore(BaseType; concrete=Val(true), minimize=minimize, kwargs...)
        ExaModels.@add_var(m, x, length(initial_guess); start=initial_guess)
        ExaModels.@add_obj(m, F(x))
        ExaModels.@add_con(m, c(x); lcon=lcon, ucon=ucon)
        return ExaModels.ExaModel(m)
    end

    prob = OptimizationProblem(build_adnlp_model, build_exa_model)

    init = [2.0]
    sol = [0.0]

    return (prob=prob, init=init, sol=sol)
end
