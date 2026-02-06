# Initial guesses

This page describes how to provide initial guesses for optimal control problems
in **CTSolvers**. It mirrors the structure of the general initial‑guess manual
in OptimalControl.jl, but focuses on the interfaces exposed by CTSolvers,
including the `@init` macro.

We assume throughout that you have already defined an optimal control problem
`ocp` using `CTParser.@def`.

```julia
using CTParser, CTSolvers

ocp = @def begin
    t ∈ [0, 1], time
    x = (q, v) ∈ R², state
    u ∈ R, control
    x(0) == [-1, 0]
    x(1) == [0, 0]
    ẋ(t) == [v(t), u(t)]
    ∫(0.5u(t)^2) → min
end
```

The goal is to build an `OptimalControlInitialGuess` compatible with this
problem, either explicitly or indirectly.

---

## High‑level entry points

There are two main entry points for users:

- `initial_guess(ocp; state=..., control=..., variable=...)`
- `build_initial_guess(ocp, init_data)`

The first is a **convenience keyword API**. The second is a **generic builder**
that accepts several different types of `init_data`.

### `initial_guess` keyword API

```julia
ig = CTSolvers.initial_guess(ocp; state=0.0, control=0.1)
```

The keyword arguments may be:

- constants (scalars or vectors) with dimensions consistent with the problem,
- functions of time `t -> x(t)` or `t -> u(t)`,
- `nothing` (use internal defaults).

The state and control are interpreted using `initial_state` and
`initial_control` helpers, and `initial_guess` always returns a validated
`OptimalControlInitialGuess`.

### `build_initial_guess(ocp, init_data)`

`build_initial_guess` is more general and dispatches on the type of
`init_data`:

```julia
ig = CTSolvers.build_initial_guess(ocp, init_data)
```

Supported forms include:

- `nothing` or `()` → default initial guess.
- an `OptimalControlInitialGuess` instance → returned as is.
- an `OptimalControlPreInit` (from `pre_initial_guess`) → completed and
  validated.
- a `CTModels.AbstractSolution` → warm‑start from an existing solution.
- a `NamedTuple` → flexible block / component specification (see below).

In all cases, the result is validated against the problem dimensions and time
settings.

---

## Warm‑starting from an existing solution

If you already have a solution `sol` of a related problem (for example after a
previous solve), you can use it directly as an initial guess:

```julia
using CTModels

sol = "some CTModels.AbstractSolution"  # for illustration
ig = CTSolvers.build_initial_guess(ocp, sol)
```

This extracts `state(sol)`, `control(sol)` and `variable(sol)` and wraps them in
an `OptimalControlInitialGuess`, performing consistency checks on state,
control and variable dimensions.

---

## NamedTuple initial guesses

The most flexible non‑macro interface is to pass a `NamedTuple` with block and
component entries. The allowed keys are:

- global blocks: `:state`, `:control`, `:variable`,
- aliases based on the OCP names: `Symbol(state_name(ocp))`,
  `Symbol(control_name(ocp))`, `Symbol(variable_name(ocp))`,
- component names of state, control and variable (e.g. `:q`, `:v`, `:u1`, `:tf`).

Example for the simple fixed‑horizon problem above:

```julia
init_nt = (
    q = t -> sin(t),
    v = t -> 1.0,
    u = t -> t,
)
ig = CTSolvers.build_initial_guess(ocp, init_nt)
```

Block‑level initialisation is also supported:

```julia
init_nt = (
    x = t -> [sin(t), 1.0],  # whole state block
    u = t -> t,
)
ig = CTSolvers.build_initial_guess(ocp, init_nt)
```

Time‑grid based initial guesses are expressed as `(time, data)` tuples:

```julia
T = [0.0, 0.5, 1.0]
X = [[-1.0, 0.0], [0.0, 0.5], [0.0, 0.0]]
U = [0.0, 0.0, 1.0]

init_nt = (
    x = (T, X),
    u = (T, U),
)
ig = CTSolvers.build_initial_guess(ocp, init_nt)
``+

Component‑wise time grids are supported in the same way by using component
names (`:q`, `:v`, `:u1`, …) as keys.

All these forms are exercised and checked in
`test/ctmodels/test_ctmodels_initial_guess.jl`.

---

## The `@init` macro

Writing large `NamedTuple` literals can be verbose. CTSolvers provides a macro
`@init` that offers a small DSL and compiles directly to a validated
`OptimalControlInitialGuess`.

### Basic usage

The general form is:

```julia
ig = @init ocp begin
    # alias statements
    a = 1.0

    # time‑dependent component
    q(t) := sin(t)

    # time‑dependent block
    x(t) := [sin(t), 1.0]

    # time‑grid based init
    x(T) := X
    u(T) := U

    # constant / variable init
    u := 0.1
end
```

The macro returns an `OptimalControlInitialGuess` and internally performs:

1. Expansion of the DSL into a `NamedTuple` specification.
2. A call to `build_initial_guess(ocp, namedtuple)`.
3. A call to `validate_initial_guess(ocp, ig)`.

You can therefore pass the result directly to `CommonSolve.solve` or to any
other code that expects an `AbstractOptimalControlInitialGuess`.

### Accepted DSL forms

Inside the `begin … end` block, the macro recognises four kinds of lines:

1. **Aliases** (ordinary Julia assignments)

   ```julia
   a = 1.0
   something = sin
   ```

   These are left untouched and can be used in the right‑hand sides of other
   specifications.

2. **Time‑dependent functions**

   ```julia
   q(t) := sin(t)
   x(t) := [sin(t), 1.0]
   u(t) := t
   ```

   The macro converts `lhs(t) := rhs` into a function `t -> rhs` and associates
   it with the key `:lhs` (either a component or a block).

3. **Time‑grid based initialisation**

   ```julia
   x(T) := X
   u(T) := U
   q(Tq) := Dq
   ```

   The macro converts `lhs(T) := rhs` into `(T, rhs)` and associates it with the
   key `:lhs`. This is exactly the same structure as the `(time, data)` tuples
   accepted by the `NamedTuple` interface.

4. **Constant / variable form**

   ```julia
   q := -1.0
   v := 0.0
   u := 0.1
   tf := 1.0
   ```

   These are treated as constant initial values for the corresponding block or
   component.

### Relation to the NamedTuple form

For a fixed‑horizon problem, the following macro call:

```julia
ig = @init ocp begin
    q(t) := sin(t)
    v(t) := 1.0
    u(t) := t
end
```

is equivalent (up to validation) to

```julia
init_nt = (
    q = t -> sin(t),
    v = t -> 1.0,
    u = t -> t,
)
ig = CTSolvers.build_initial_guess(ocp, init_nt)
```

Similarly, a block‑level specification

```julia
ig = @init ocp begin
    x(t) := [sin(t), 1.0]
    u(t) := t
end
```

corresponds to

```julia
init_nt = (
    x = t -> [sin(t), 1.0],
    u = t -> t,
)
ig = CTSolvers.build_initial_guess(ocp, init_nt)
```

Time‑grid based specifications follow the same pattern:

```julia
T = [0.0, 0.5, 1.0]
X = [[-1.0, 0.0], [0.0, 0.5], [0.0, 0.0]]
U = [0.0, 0.0, 1.0]

ig = @init ocp begin
    x(T) := X
    u(T) := U
end
```

is equivalent to

```julia
init_nt = (
    x = (T, X),
    u = (T, U),
)
ig = CTSolvers.build_initial_guess(ocp, init_nt)
```

### Logging the expanded initial guess

For debugging, `@init` supports an optional keyword‑like argument
`log = true` that prints a compact representation of the underlying
`NamedTuple` specification before building the initial guess:

```julia
ig = @init ocp begin
    q(t) := sin(t)
    v(t) := 1.0
    u(t) := t
end log = true

# prints something like:
# (q = t -> sin(t), v = t -> 1.0, u = t -> t)
```

This does **not** change the semantics of the macro and is primarily intended
for interactive experimentation.

---

## Changing the backend prefix (advanced)

Internally, `@init` uses a configurable prefix to decide which module provides
`build_initial_guess` and `validate_initial_guess`. By default this is the
`CTSolvers` module, but the prefix can be changed for advanced use cases:

```julia
old_prefix = CTSolvers.init_prefix()
CTSolvers.init_prefix!(:MyCustomBackend)

@assert CTSolvers.init_prefix() == :MyCustomBackend

# Restore the default prefix
CTSolvers.init_prefix!(old_prefix)
```

This is only needed if you want to route the macro expansion to a different
backend module exposing the same API as CTSolvers.
