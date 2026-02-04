# ------------------------------------------------------------------------------
# Solvers utils
# ------------------------------------------------------------------------------

# NLPModelsIpopt
function solve_with_ipopt(nlp; kwargs...)
    return throw(CTBase.ExtensionError(:NLPModelsIpopt))
end

# MadNLP
function solve_with_madnlp(nlp; kwargs...)
    return throw(CTBase.ExtensionError(:MadNLP))
end

# MadNCL
function solve_with_madncl(nlp; kwargs...)
    return throw(CTBase.ExtensionError(:MadNCL))
end

# Knitro
function solve_with_knitro(nlp; kwargs...)
    return throw(CTBase.ExtensionError(:NLPModelsKnitro))
end
