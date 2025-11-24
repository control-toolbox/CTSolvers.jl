function discretize(
    ocp::AbstractOptimalControlProblem,
    discretizer::AbstractOptimalControlDiscretizer,
)
    return discretizer(ocp)
end
