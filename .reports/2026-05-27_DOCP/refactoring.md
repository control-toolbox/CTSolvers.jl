# Refactoring CTSolvers / CTDirect

## 1. Problématique

### 1.1 Architecture actuelle : fabrique de closures

Dans CTDirect, la discrétisation d'un OCP passe par une **callable struct** :

```julia
# collocation.jl / direct_shooting.jl
function (discretizer::Collocation)(ocp::AbstractModel)
    docp = get_docp(discretizer, ocp)
    exa_getter = nothing          # ← état mutable capturé

    function build_adnlp_model(initial_guess; backend, kwargs...) ... end
    function build_adnlp_solution(nlp_solution) ... end
    function build_exa_model(::Type{BaseType}, initial_guess; backend) ... end
    function build_exa_solution(nlp_solution) ... end   # dépend de exa_getter

    return CTSolvers.DiscretizedModel(ocp,
        CTSolvers.ADNLPModelBuilder(build_adnlp_model),
        CTSolvers.ExaModelBuilder(build_exa_model),
        CTSolvers.ADNLPSolutionBuilder(build_adnlp_solution),
        CTSolvers.ExaSolutionBuilder(build_exa_solution),
    )
end
```

Le `DiscretizedModel` résultant est un **conteneur de 4 closures** retournant à CTSolvers
une boîte opaque que CTSolvers doit savoir ouvrir via un mécanisme d'accesseurs.

### 1.2 Problèmes identifiés

| # | Problème | Gravité |
|---|---|---|
| P1 | **Couplage temporel implicite** : `exa_getter = nothing` est muté en side-effect de `build_exa_model`. `build_exa_solution` plante si appelé en premier sans garantie des types. | ★★★ |
| P2 | **Contrat éparpillé** : stubs dans `Optimization/`, implémentation dans `DOCP/`, logique réelle dans `CTDirect` via closures. | ★★ |
| P3 | **Abstraction creuse** : `AbstractBuilder → AbstractModelBuilder → ADNLPModelBuilder{T<:Function}` est du boilerplate pour `f::Function`. ~120 lignes de documentation pour zéro contrainte utile. | ★★ |
| P4 | **`DiscretizedModel` couplé aux backends** : 4 paramètres de type, 4 champs. Ajouter un backend = modifier le struct. | ★★ |
| P5 | **`AbstractDiscretizer` défini dans CTDirect** alors que CTSolvers l'utilise sans en être propriétaire. | ★ |
| P6 | **Wrappers `discretize` inutiles** : `discretize(ocp, disc) = disc(ocp)` n'ajoute aucune sémantique. | ★ |
| P7 | **`get_docp` appelé deux fois** (model + solution) sur le même `(ocp, discretizer)` — même si peu coûteux, c'est une duplication. | ★ |
| P8 | **TODO non résolu** dans le code : `# +++ todo if possible: unify get_docp for Collocation / directshooting`. | ★ |

---

## 2. Architecture proposée

### 2.1 Principe

Remplacer le pattern *fabrique-de-closures → accesseurs → dispatch* par du **dispatch multiple direct** sur `(DiscretizedModel, modeler)`, avec un **cache mutable** dans le `DiscretizedModel` pour résoudre P1 et P7.

```
Avant : discretizer(ocp) → [4 closures] → DiscretizedModel{4 builders}
                                                ↓ accesseurs
                                         modeler(prob, ...) → builder(...)

Après : discretize(ocp, discretizer) → DiscretizedModel{ocp, discretizer, cache}
                                                ↓ dispatch direct
                                build_nlp_model(dm, init, modeler)
                                build_ocp_solution(dm, nlp_sol, modeler)
```

### 2.2 Répartition des responsabilités

```
CTSolvers
├── DOCP/
│   ├── AbstractDiscretizer   ← déplacé de CTDirect (résout P5)
│   ├── DiscretizedModel      ← simplifié : {ocp, discretizer, cache}
│   └── contract.jl           ← stubs build_nlp_model / build_ocp_solution / discretize
├── Modelers/                 ← inchangé
├── Optimization/             ← nettoyé : suppression des builders et accesseurs
└── Solvers/                  ← solve simplifié

CTDirect
├── DOCPCache                 ← struct mutable {docp, exa_getter} (résout P1, P7)
├── CTDirect.jl               ← suppression AbstractDiscretizer + wrappers discretize
├── collocation.jl            ← implémente le contrat CTSolvers pour Collocation
└── direct_shooting.jl        ← implémente le contrat CTSolvers pour DirectShooting
```

---

## 3. CTSolvers — modifications

### 3.1 `DOCP/abstract_discretizer.jl` (nouveau fichier)

```julia
# CTSolvers — déplacé depuis CTDirect
"""
$(TYPEDEF)

Abstract base type for all discretization strategies.
Concrete subtypes implement specific transcription methods
(collocation, direct shooting, etc.).
"""
abstract type AbstractDiscretizer <: Strategies.AbstractStrategy end
```

### 3.2 `DOCP/discretized_model.jl` — struct simplifié

```julia
"""
$(TYPEDEF)

A discretized optimal control problem, combining an OCP, a discretizer,
and a mutable cache populated during model building.

# Fields
- `ocp`: The original optimal control problem
- `discretizer`: The discretization strategy used
- `cache`: Backend-specific data (e.g. DOCPCache from CTDirect), opaque to CTSolvers

# Type parameters
- `TO <: CTModels.AbstractModel`
- `TD <: AbstractDiscretizer`
- `TC`: Cache type, defined by the implementing package (CTDirect)
"""
struct DiscretizedModel{
    TO <: CTModels.AbstractModel,
    TD <: AbstractDiscretizer,
    TC,
} <: Optimization.AbstractOptimizationProblem
    ocp::TO
    discretizer::TD
    cache::TC
end

ocp_model(dm::DiscretizedModel) = dm.ocp
```

**Suppressions** par rapport à l'existant :
- Les 4 paramètres de type `TAMB, TEMB, TASB, TESB`
- Les 4 champs `adnlp_model_builder`, `exa_model_builder`, `adnlp_solution_builder`, `exa_solution_builder`
- Les 4 accesseurs `get_adnlp_model_builder`, etc.
- Les délégations `ocp_solution` / `nlp_model`

### 3.3 `DOCP/contract.jl` — contrat unifié

```julia
"""
$(TYPEDSIGNATURES)

Discretize an OCP into a DiscretizedModel.

# Contract
Must be implemented in the package providing the discretizer (e.g. CTDirect).

# Arguments
- `ocp`: The optimal control problem
- `discretizer`: The discretization strategy

# Returns
- `DiscretizedModel` with a populated cache
"""
function discretize(ocp::CTModels.AbstractModel, discretizer::AbstractDiscretizer)
    throw(Exceptions.NotImplemented(
        "discretize not implemented";
        required_method = "CTSolvers.discretize(ocp, ::$(typeof(discretizer)))",
        suggestion = "Implement in the package providing $(typeof(discretizer))",
    ))
end

"""
$(TYPEDSIGNATURES)

Build an NLP model from a discretized problem and an initial guess.

# Contract
Must be implemented in the package providing the discretizer.

# Arguments
- `dm::DiscretizedModel`: The discretized problem (cache will be mutated for Exa backend)
- `initial_guess`: Initial guess
- `modeler::Modelers.AbstractNLPModeler`: The NLP backend modeler

# Returns
- `NLPModels.AbstractNLPModel`
"""
function build_nlp_model(
    dm::DiscretizedModel,
    initial_guess,
    modeler::Modelers.AbstractNLPModeler,
)::NLPModels.AbstractNLPModel
    throw(Exceptions.NotImplemented(
        "build_nlp_model not implemented";
        required_method = "CTSolvers.build_nlp_model(dm::DiscretizedModel{<:Any,<:$(typeof(dm.discretizer))}, initial_guess, modeler::$(typeof(modeler)))",
    ))
end

"""
$(TYPEDSIGNATURES)

Build an OCP solution from a discretized problem and NLP solver statistics.

# Contract
Must be implemented in the package providing the discretizer.
For the Exa backend, the cache must have been populated by a prior call to `build_nlp_model`.

# Arguments
- `dm::DiscretizedModel`: The discretized problem
- `nlp_solution::SolverCore.AbstractExecutionStats`: NLP solver output
- `modeler::Modelers.AbstractNLPModeler`: The NLP backend modeler

# Returns
- OCP solution
"""
function build_ocp_solution(
    dm::DiscretizedModel,
    nlp_solution::SolverCore.AbstractExecutionStats,
    modeler::Modelers.AbstractNLPModeler,
)
    throw(Exceptions.NotImplemented(
        "build_ocp_solution not implemented";
        required_method = "CTSolvers.build_ocp_solution(dm::DiscretizedModel{<:Any,<:$(typeof(dm.discretizer))}, nlp_solution, modeler::$(typeof(modeler)))",
    ))
end
```

### 3.4 `Optimization/` — nettoyage

**Supprimer entièrement** :
- `builders.jl` : `AbstractBuilder`, `AbstractModelBuilder`, `AbstractSolutionBuilder`, `AbstractOCPSolutionBuilder`, `ADNLPModelBuilder`, `ExaModelBuilder`, `ADNLPSolutionBuilder`, `ExaSolutionBuilder`
- `contract.jl` : `get_adnlp_model_builder`, `get_exa_model_builder`, `get_adnlp_solution_builder`, `get_exa_solution_builder`

**Garder** `build_model` / `build_solution` mais les faire déléguer au nouveau contrat :

```julia
# Optimization/pipeline.jl
function build_model(dm::DiscretizedModel, initial_guess, modeler)
    return build_nlp_model(dm, initial_guess, modeler)
end

function build_solution(dm::DiscretizedModel, nlp_solution, modeler)
    return build_ocp_solution(dm, nlp_solution, modeler)
end
```

### 3.5 `Solvers/solve.jl` — inchangé

`solve` reste exactement comme il est :

```julia
function CommonSolve.solve(
    problem::Optimization.AbstractOptimizationProblem,
    initial_guess,
    modeler::Modelers.AbstractNLPModeler,
    solver::AbstractNLPSolver;
    display::Bool = __display(),
)
    nlp      = Optimization.build_model(problem, initial_guess, modeler)
    nlp_sol  = CommonSolve.solve(nlp, solver; display = display)
    solution = Optimization.build_solution(problem, nlp_sol, modeler)
    return solution
end
```

Aucune signature ne change côté CTSolvers.

---

## 4. CTDirect — modifications

### 4.1 `DOCPCache` — nouveau struct mutable

```julia
# CTDirect — src/DOCP_cache.jl (nouveau fichier)

"""
$(TYPEDEF)

Mutable cache attached to a DiscretizedModel.

Populated at construction by `CTSolvers.discretize`, then partially
mutated by `CTSolvers.build_nlp_model` (Exa backend sets `exa_getter`).

# Fields
- `docp::DOCP`: The internal discretized OCP structure (bounds, dimensions, etc.)
- `exa_getter`: Getter object produced by ExaModels constructor, `nothing` before Exa model build

# Notes
The coupling between `build_nlp_model` and `build_ocp_solution` for the Exa
backend is made explicit via this cache rather than via a captured closure variable.
"""
mutable struct DOCPCache
    docp::DOCP
    exa_getter  # Nothing | ExaGetter — type not constrained here for generality
end

DOCPCache(docp::DOCP) = DOCPCache(docp, nothing)
```

### 4.2 `CTDirect.jl` — suppressions

**Supprimer** :
```julia
# ← supprimer : AbstractDiscretizer est maintenant dans CTSolvers
abstract type AbstractDiscretizer <: Strategies.AbstractStrategy end

# ← supprimer : wrappers inutiles
function discretize(ocp::AbstractModel, discretizer::AbstractDiscretizer)
    return discretizer(ocp)
end
function discretize(ocp::AbstractModel; discretizer::AbstractDiscretizer=__discretizer())
    return discretize(ocp, discretizer)
end
```

**Adapter les imports** :
```julia
# CTDirect.jl
import CTSolvers                                  # pour DiscretizedModel, AbstractDiscretizer
import CTSolvers: AbstractDiscretizer             # ← AbstractDiscretizer vient de CTSolvers
```

**Garder** `__discretizer()` comme défaut interne à CTDirect si nécessaire.

### 4.3 `get_docp` — unification (résout le TODO)

Les deux `get_docp` de `collocation.jl` et `direct_shooting.jl` sont quasi-identiques.
Les déplacer dans `DOCP_data.jl` :

```julia
# DOCP_data.jl
"""
$(TYPEDSIGNATURES)

Build the core DOCP structure from a discretizer and an OCP.
Unified implementation for all discretizer types.
"""
function get_docp(discretizer::CTSolvers.AbstractDiscretizer, ocp::AbstractModel)
    scheme       = Strategies.options(discretizer)[:scheme]
    grid_size    = Strategies.options(discretizer)[:grid_size]
    time_grid    = get(Strategies.options(discretizer), :time_grid, nothing)
    control_steps = get(Strategies.options(discretizer), :control_steps, 1)

    docp = DOCP(ocp, grid_size, control_steps, scheme, time_grid)
    __variables_bounds!(docp)
    __constraints_bounds!(docp)
    return docp
end
```

Chaque discretizer n'a plus qu'à exister sans dupliquer `get_docp`.

### 4.4 `collocation.jl` — implémentation du contrat

Remplacer la callable `(discretizer::Collocation)(ocp)` par trois méthodes nommées :

```julia
# ──────────────────────────────────────────────────────────────────
# Implémentation du contrat CTSolvers pour Collocation
# ──────────────────────────────────────────────────────────────────

"""
$(TYPEDSIGNATURES)

Implement CTSolvers.discretize for the Collocation strategy.
Builds a DiscretizedModel with a DOCPCache containing the precomputed DOCP.
"""
function CTSolvers.discretize(ocp::AbstractModel, discretizer::Collocation)
    docp = get_docp(discretizer, ocp)
    cache = DOCPCache(docp)
    return CTSolvers.DiscretizedModel(ocp, discretizer, cache)
end

# ── ADNLP ─────────────────────────────────────────────────────────

"""
$(TYPEDSIGNATURES)

Build an ADNLPModel for a Collocation-discretized problem.
"""
function CTSolvers.build_nlp_model(
    dm::CTSolvers.DiscretizedModel{<:Any, <:Collocation},
    initial_guess::CTModels.AbstractInitialGuess,
    modeler::CTSolvers.Modelers.ADNLP,
)::ADNLPModels.ADNLPModel

    docp    = dm.cache.docp
    options = CTSolvers.Strategies.options_dict(modeler)
    backend = pop!(options, :backend)

    f  = x -> __objective(x, docp)
    c! = (c, x) -> __constraints!(c, x, docp)

    functional_init = CTModels.build_initial_guess(dm.ocp, initial_guess)
    x0 = __initial_guess(docp, functional_init)

    unused_backends = (
        hprod_backend    = ADNLPModels.EmptyADbackend,
        jtprod_backend   = ADNLPModels.EmptyADbackend,
        jprod_backend    = ADNLPModels.EmptyADbackend,
        ghjvprod_backend = ADNLPModels.EmptyADbackend,
    )

    backend_options = if backend == :manual
        J_backend = ADNLPModels.SparseADJacobian(
            docp.dim_NLP_variables, f, docp.dim_NLP_constraints, c!,
            DOCP_Jacobian_pattern(docp),
        )
        H_backend = ADNLPModels.SparseReverseADHessian(
            docp.dim_NLP_variables, f, docp.dim_NLP_constraints, c!,
            DOCP_Hessian_pattern(docp),
        )
        (gradient_backend = ADNLPModels.ReverseDiffADGradient,
         jacobian_backend = J_backend,
         hessian_backend  = H_backend)
    else
        (backend = backend,)
    end

    return ADNLPModels.ADNLPModel!(
        f, x0, docp.bounds.var_l, docp.bounds.var_u,
        c!, docp.bounds.con_l, docp.bounds.con_u;
        minimize = !docp.flags.max,
        backend_options...,
        unused_backends...,
        options...,
    )
end

"""
$(TYPEDSIGNATURES)

Build an OCP solution from an ADNLP solver result for a Collocation-discretized problem.
"""
function CTSolvers.build_ocp_solution(
    dm::CTSolvers.DiscretizedModel{<:Any, <:Collocation},
    nlp_solution::SolverCore.AbstractExecutionStats,
    ::CTSolvers.Modelers.ADNLP,
)
    docp = dm.cache.docp
    objective, iterations, constraints_violation, message, status, successful =
        CTSolvers.extract_solver_infos(nlp_solution)
    T = get_time_grid(nlp_solution.solution, docp)
    return build_OCP_solution(docp, nlp_solution, T,
        objective, iterations, constraints_violation, message, status, successful)
end

# ── Exa ───────────────────────────────────────────────────────────

"""
$(TYPEDSIGNATURES)

Build an ExaModel for a Collocation-discretized problem.
Mutates `dm.cache.exa_getter` so that `build_ocp_solution` can use it.
"""
function CTSolvers.build_nlp_model(
    dm::CTSolvers.DiscretizedModel{<:Any, <:Collocation},
    initial_guess::CTModels.AbstractInitialGuess,
    modeler::CTSolvers.Modelers.Exa,
)::ExaModels.ExaModel

    docp     = dm.cache.docp
    options  = CTSolvers.Strategies.options_dict(modeler)
    BaseType = pop!(options, :base_type)
    backend  = pop!(options, :backend)

    ocp  = dm.ocp
    n, m, q = CTModels.state_dimension(ocp), CTModels.control_dimension(ocp), CTModels.variable_dimension(ocp)
    N    = docp.time.steps

    functional_init = CTModels.build_initial_guess(ocp, initial_guess)
    x0 = __initial_guess(docp, functional_init)

    state   = hcat([x0[(1 + i*(n+m)):(1 + i*(n+m) + n - 1)] for i in 0:N]...)
    control = if m > 0
        c = hcat([x0[(n+1 + i*(n+m)):(n+1 + i*(n+m) + m - 1)] for i in 0:(N-1)]...)
        [c c[:, end]]
    else
        similar(x0, 0, N+1)
    end
    variable = x0[(end - q + 1):end]
    init = (variable, state, control)

    scheme    = CTSolvers.Strategies.options(dm.discretizer)[:scheme]
    grid_size = CTSolvers.Strategies.options(dm.discretizer)[:grid_size]

    build_exa = CTModels.get_build_examodel(ocp)
    nlp, exa_getter = build_exa(;
        grid_size = grid_size,
        backend   = backend,
        scheme    = scheme,
        init      = init,
        base_type = BaseType,
    )

    # Stocker dans le cache pour build_ocp_solution — explicite et documenté
    dm.cache.exa_getter = exa_getter

    return nlp
end

"""
$(TYPEDSIGNATURES)

Build an OCP solution from an Exa solver result for a Collocation-discretized problem.

# Precondition
`build_nlp_model` must have been called first (populates `dm.cache.exa_getter`).
"""
function CTSolvers.build_ocp_solution(
    dm::CTSolvers.DiscretizedModel{<:Any, <:Collocation},
    nlp_solution::SolverCore.AbstractExecutionStats,
    ::CTSolvers.Modelers.Exa,
)
    docp       = dm.cache.docp
    exa_getter = dm.cache.exa_getter

    isnothing(exa_getter) && error(
        "build_ocp_solution (Exa): exa_getter is nothing. " *
        "build_nlp_model must be called before build_ocp_solution."
    )

    objective, iterations, constraints_violation, message, status, successful =
        CTSolvers.extract_solver_infos(nlp_solution)
    T = get_time_grid_exa(nlp_solution, docp, exa_getter)
    return build_OCP_solution(docp, nlp_solution, T,
        objective, iterations, constraints_violation, message, status, successful;
        exa_getter = exa_getter)
end
```

### 4.5 `direct_shooting.jl` — même pattern

```julia
# Même structure que collocation.jl, 4 méthodes :
function CTSolvers.discretize(ocp::AbstractModel, discretizer::DirectShooting) ... end
function CTSolvers.build_nlp_model(dm::DiscretizedModel{<:Any,<:DirectShooting}, init, modeler::ADNLP) ... end
function CTSolvers.build_nlp_model(dm::DiscretizedModel{<:Any,<:DirectShooting}, init, modeler::Exa) ... end
function CTSolvers.build_ocp_solution(dm::DiscretizedModel{<:Any,<:DirectShooting}, nlp_sol, modeler::ADNLP) ... end
function CTSolvers.build_ocp_solution(dm::DiscretizedModel{<:Any,<:DirectShooting}, nlp_sol, modeler::Exa) ... end
# Note : Exa non implémenté pour DirectShooting actuellement → lever NotImplemented explicitement
```

---

## 5. Bilan des suppressions / ajouts

### Suppressions dans CTSolvers

| Fichier / Élément | Raison |
|---|---|
| `Optimization/builders.jl` en entier | Remplacé par dispatch direct |
| `AbstractBuilder`, `AbstractModelBuilder`, `AbstractSolutionBuilder`, `AbstractOCPSolutionBuilder` | Inutiles |
| `ADNLPModelBuilder`, `ExaModelBuilder`, `ADNLPSolutionBuilder`, `ExaSolutionBuilder` | Inutiles |
| `Optimization/contract.jl` : `get_adnlp_model_builder`, `get_exa_model_builder`, `get_adnlp_solution_builder`, `get_exa_solution_builder` | Remplacés par `build_nlp_model` / `build_ocp_solution` |
| `DiscretizedModel` : 4 paramètres `TAMB, TEMB, TASB, TESB` + 4 champs builders | Réduits à `TC` (cache) |
| Délégations `ocp_solution` / `nlp_model` sur `DiscretizedModel` | Inutiles |

### Suppressions dans CTDirect

| Fichier / Élément | Raison |
|---|---|
| `abstract type AbstractDiscretizer` dans `CTDirect.jl` | Déplacé dans CTSolvers |
| `discretize(ocp, discretizer)` et `discretize(ocp; discretizer=...)` | Remplacés par `CTSolvers.discretize` |
| Callable `(discretizer::Collocation)(ocp)` et ses 4 closures | Remplacé par 4 méthodes nommées |
| Callable `(discretizer::DirectShooting)(ocp)` et ses 4 closures | Remplacé par 4 méthodes nommées |
| `exa_getter = nothing` capturé mutable | Remplacé par `dm.cache.exa_getter` |
| `get_docp` dupliqué dans `collocation.jl` et `direct_shooting.jl` | Unifié dans `DOCP_data.jl` |

### Ajouts

| Fichier | Contenu |
|---|---|
| `CTSolvers/DOCP/abstract_discretizer.jl` | `AbstractDiscretizer` (déplacé) |
| `CTDirect/DOCP_cache.jl` | `mutable struct DOCPCache{docp, exa_getter}` |
| `CTDirect/collocation.jl` | 4 méthodes nommées (dispatche sur `Collocation`) |
| `CTDirect/direct_shooting.jl` | 4 méthodes nommées (dispatche sur `DirectShooting`) |

---

## 6. Ajout d'un troisième backend futur

Avec l'ancienne architecture : modifier `DiscretizedModel` (nouveau champ + nouveau paramètre de type), ajouter un builder struct, ajouter un accesseur, écrire une closure dans chaque discretizer.

Avec la nouvelle : **ajouter 2 méthodes** dans le package implémentant le backend :

```julia
CTSolvers.build_nlp_model(dm::DiscretizedModel{<:Any,<:Collocation}, init, modeler::JuMPModeler) = ...
CTSolvers.build_ocp_solution(dm::DiscretizedModel{<:Any,<:Collocation}, sol, modeler::JuMPModeler) = ...
```

Zéro modification de CTSolvers ou de la struct `DiscretizedModel`.
