function discretize(
    ocp::AbstractOptimalControlProblem, discretizer::AbstractOptimalControlDiscretizer
)
    return discretizer(ocp)
end

function discretize(
    ocp::AbstractOptimalControlProblem;
    discretizer::AbstractOptimalControlDiscretizer=__discretizer(),
)
    return discretize(ocp, discretizer)
end
