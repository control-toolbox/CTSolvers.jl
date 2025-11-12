# Common
__display() = true

# NLPModelsIpopt
__nlp_models_ipopt_max_iter() = 1000
__nlp_models_ipopt_tol() = 1e-8
__nlp_models_ipopt_print_level() = 5
__nlp_models_ipopt_mu_strategy() = "adaptive"
__nlp_models_ipopt_linear_solver() = "Mumps"
__nlp_models_ipopt_sb() = "yes"

# MadNLP
__mad_nlp_max_iter() = 1000
__mad_nlp_tol() = 1e-8
__mad_nlp_print_level() = MadNLP.INFO
__mad_nlp_linear_solver() = MadNLPMumps.MumpsSolver

# MadNCL
__mad_ncl_max_iter() = 1000
__mad_ncl_print_level() = MadNLP.INFO
__mad_ncl_linear_solver() = MadNLPMumps.MumpsSolver
__mad_ncl_ncl_options() = MadNCL.NCLOptions{Float64}(
    # verbose=true,       # print convergence logs
    # scaling=false,      # specify if we should scale the problem
    opt_tol=1e-8,       # tolerance on dual infeasibility
    feas_tol=1e-8,      # tolerance on primal infeasibility
    # rho_init=1e1,       # initial augmented Lagrangian penalty
    # max_auglag_iter=20, # maximum number of outer iterations
)
