function discretize(
    ocp::CTModels.Model,
    discretizer::AbstractCTDiscretizationMethod,
)
    return discretizer(ocp)
end

function discretize(
    ocp::CTModels.Model;
    discretizer::AbstractCTDiscretizationMethod=__discretisation_method(),
)
    return discretize(ocp, discretizer)
end
