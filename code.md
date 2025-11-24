# Solve an optimal control problem

We assume that the optimal control problem needs the following to be solved:

- an initial guess
- a discretization method
- a modeler
- a solver

The most high level function is `solve`, and it takes the following arguments:

```julia
solve(problem, initial_guess, discretizer, modeler, solver)
```

The `problem` argument is the problem to solve, `initial_guess` is the initial guess, `discretizer` is the discretization method, `modeler` is the modeler, and `solver` is the solver.

Hence, we need some abstract types:

```julia
abstract type AbstractOptimalControlProblem end
abstract type AbstractOptimalControlInitialGuess end
abstract type AbstractOptimalControlDiscretizer end
abstract type AbstractOptimizationModeler end
abstract type AbstractOptimizationSolver end
```

We will have for the moment:

```julia
const AbstractOptimalControlProblem = CTModels.AbstractModel
```

The idea now is to define all the logic needed for the `solve` function in a generic way, i.e. without any specific implementation details. Internally, we do not need to provide systematically the types to let some freedom to the user, to customize the process. The user will have to define only callable structs to let the code work.

## The logic behind the `solve` function

### The `solve` function on an optimal control problem

The `solve` function is the main function that solves the problem. It is defined as follows:

```julia
abstract type AbstractOptimalControlSolution end

function solve(
    problem::AbstractOptimalControlProblem,
    initial_guess::AbstractOptimalControlInitialGuess,
    discretizer::AbstractOptimalControlDiscretizer,
    modeler::AbstractOptimizationModeler,
    solver::AbstractOptimizationSolver
)::AbstractOptimalControlSolution
    discrete_problem = discretize(problem, discretizer)
    return solve(discrete_problem, initial_guess, modeler, solver)
end
```

We will have for the moment:

```julia
const AbstractOptimalControlSolution = CTModels.AbstractSolution
```

From this, we deduce that we need:

- A `discretize` function that takes a problem and a discretizer and returns a discrete problem.
- A `solve` function that takes a discrete problem, an initial guess, a modeler, and a solver and returns a solution.

>[!NOTE]
>We will need to add some nice display features to the `solve` function.

### The `discretize` function

The `discretize` function is the main function that discretizes the problem. It is defined as follows:

```julia
function discretize(
    problem::AbstractOptimalControlProblem,
    discretizer::AbstractOptimalControlDiscretizer
)::AbstractDiscretizedOptimalControlProblem
    return discretizer(problem)
end
```

From this, we deduce that we need:

- The `AbstractOptimalControlDiscretizer` type being callable with a problem as argument.

>[!NOTE]
>If a user wants to add a discretization method, he simply has to define a callable struct `MyDiscretizer` and implement `MyDiscretizer(problem::T)` where `T <: AbstractOptimalControlProblem` can be a user type or a type from the library.

### The `solve` function on a discretized optimal control problem

The `solve` function is the main function that solves the discretized optimal control problem. We make it more generic by having a `AbstractOptimizationProblem` as argument, without knowing what is returned, and with no types for the initial guess.

>[!NOTE]
>We have necessarily `AbstractDiscretizedOptimalControlProblem <: AbstractOptimizationProblem`.

```julia
function solve(
    problem::AbstractOptimizationProblem,
    initial_guess,
    modeler::AbstractOptimizationModeler,
    solver::AbstractOptimizationSolver
)
    model = build_model(problem, initial_guess, modeler)
    model_solution = solve(model, solver)
    solution = build_solution(problem, model_solution, modeler)
    return solution
end
```

From this, we deduce that we need:

- A `build_model` function that takes a problem, a modeler, and an initial guess and returns a model.
- A `solve` function that takes a model, a solver, and returns a model solution.
- A `build_solution` function that takes a problem, a model solution, and a modeler and returns a solution.

### [The `build_model` function](#build-model)

The `build_model` function is the main function that builds the model. It is defined as follows:

```julia
function build_model(
    problem::AbstractOptimizationProblem,
    initial_guess,
    modeler::AbstractOptimizationModeler
)
    return modeler(problem, initial_guess)
end
```

From this, we deduce that we need:

- The `AbstractOptimizationModeler` type being callable with a problem and an initial guess as arguments.

The type of the initial guess will depend on the problem itself. The modeler will make the link between the initial guess and the problem. We do not fix the output type of the `build_model` function to let some freedom to the user. However, it must be consistent with the rest of the pipeline: the `model` is then provided to the `solve` function, and the `model_solution` is then provided to the `build_solution` function.

>[!NOTE]
>If a user wants to add a modeler, he simply has to define first a callable struct `MyModeler` and implement `MyModeler(problem::T, initial_guess)` where `T <: AbstractOptimizationProblem` can be a user type or a type from the library. Then, he will have to implement the construction of a model solution, see [The `build_solution` function](#build-solution).

### The `solve` function on a model

The `solve` function is the main function that solves the model. It is defined as follows:

```julia
function solve(
    model,
    solver::AbstractOptimizationSolver
)
    return solver(model)
end
```

From this, we deduce that we need:

- The `AbstractOptimizationSolver` type being callable with a model as argument.

>[!NOTE]
>If a user wants to add a solver, he has to define a callable struct `MySolver` and implement `MySolver(model::T)` where `T` is a type returned by the `build_model` function, either from the `build_model` already provided by the library or defined by the user. It must return a model solution that can be treated by the modeler. The modeler will use solution builders provided by the problem to build the final solution.

### [The `build_solution` function](#build-solution)

The `build_solution` function is the main function that builds the solution. It is defined as follows:

```julia
function build_solution(
    problem::AbstractOptimizationProblem,
    model_solution,
    modeler::AbstractOptimizationModeler
)
    return modeler(problem, model_solution)
end
```

From this, we deduce that we need:

- The `AbstractOptimizationModeler` type being callable with a problem and a model solution as arguments.

>[!NOTE]
>If a user wants to add a modeler, he first has to define a callable struct `MyModeler` and implement the construction of a model, see [The `build_model` function](#build-model). Then, he will have to implement the construction of a solution, `MyModeler(problem::T, model_solution)` where `T <: AbstractOptimizationProblem` can be a user type or a type from the library.

## The provided implementations

### Discretizer

We will have the following discretizer:

```julia
struct Collocation <: AbstractOptimalControlDiscretizer end
```

It is a callable struct with a function of the form:

```julia
Collocation(problem::AbstractOptimalControlProblem)::AbstractDiscretizedOptimalControlProblem
```

### Modeler

We will have the following modelers:

```julia
struct ADNLPModeler <: AbstractOptimizationModeler end
struct ExaModeler <: AbstractOptimizationModeler end
```

They are callable structs to build a model and a solution. For instance, for `ADNLPModeler`, we will have a first way to call it to build a model:

```julia
function (modeler::ADNLPModeler)(
    problem::AbstractOptimizationProblem, 
    initial_guess
)::ADNLPModels.ADNLPModel
    builder = get_adnlp_model_builder(problem)
    return builder(initial_guess)
end
```

and a second way to call it to build a solution:

```julia
function (modeler::ADNLPModeler)(
    problem::AbstractOptimizationProblem,
    nlp_solution::SolverCore.AbstractExecutionStats,
)
    builder = get_adnlp_solution_builder(problem)
    return builder(nlp_solution)
end
```

>[!NOTE]
>The type of the initial guess depends on the problem itself. The modeler will get the `ADNLPModel` builder from the problem and use it to build the model solution. Besides, the built solution type is not imposed. The modeler will get a solution builder from the problem and use it to build the solution. The type of the builder will indicate what to do.
