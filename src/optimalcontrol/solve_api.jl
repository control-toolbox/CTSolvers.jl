# ------------------------------------------------------------------------
# ------------------------------------------------------------------------
# Main solve function
function _solve(
    ocp::AbstractOptimalControlProblem,
    initial_guess,
    discretizer::AbstractOptimalControlDiscretizer,
    modeler::AbstractOptimizationModeler,
    solver::AbstractOptimizationSolver;
    display::Bool=__display(),
)::AbstractOptimalControlSolution

    # Validate initial guess against the optimal control problem before discretization.
    # Any inconsistency should trigger a CTBase.IncorrectArgument from the validator.
    normalized_init = build_initial_guess(ocp, initial_guess)
    validate_initial_guess(ocp, normalized_init)

    discrete_problem = discretize(ocp, discretizer)
    return CommonSolve.solve(discrete_problem, normalized_init, modeler, solver; display=display)
end

# ------------------------------------------------------------------------
# ------------------------------------------------------------------------
# Method registry: available resolution methods for optimal control problems.

const AVAILABLE_METHODS = (
    (:collocation, :adnlp, :ipopt),
    (:collocation, :adnlp, :madnlp),
    (:collocation, :adnlp, :knitro),
    (:collocation, :exa,   :ipopt),
    (:collocation, :exa,   :madnlp),
    (:collocation, :exa,   :knitro),
)

available_methods() = AVAILABLE_METHODS

# ------------------------------------------------------------------------
# ------------------------------------------------------------------------
# Discretizer helpers (symbol  type and options).

function _get_unique_symbol(
    method::Tuple{Vararg{Symbol}},
    allowed::Tuple{Vararg{Symbol}},
    tool_name::AbstractString,
)
    hits = Symbol[]
    for s in method
        if s in allowed
            push!(hits, s)
        end
    end
    if length(hits) == 1
        return hits[1]
    elseif isempty(hits)
        msg = "No $(tool_name) symbol from $(allowed) found in method $(method)."
        throw(CTBase.IncorrectArgument(msg))
    else
        msg = "Multiple $(tool_name) symbols $(hits) found in method $(method); at most one is allowed."
        throw(CTBase.IncorrectArgument(msg))
    end
end

function _get_discretizer_symbol(method::Tuple)
    return _get_unique_symbol(method, discretizer_symbols(), "discretizer")
end

function _build_discretizer_from_method(method::Tuple, discretizer_options::NamedTuple)
    disc_sym = _get_discretizer_symbol(method)
    return build_discretizer_from_symbol(disc_sym; discretizer_options...)
end

function _discretizer_options(method::Tuple)
    disc_sym = _get_discretizer_symbol(method)
    return discretizer_options(disc_sym)
end

# ------------------------------------------------------------------------
# ------------------------------------------------------------------------
# Modeler helpers (symbol  type).

function _get_modeler_symbol(method::Tuple)
    return _get_unique_symbol(method, modeler_symbols(), "NLP model")
end

function _normalize_modeler_options(options)
    if options === nothing
        return NamedTuple()
    elseif options isa NamedTuple
        return options
    elseif options isa Tuple
        return (; options...)
    else
        msg = "modeler_options must be a NamedTuple or tuple of pairs, got $(typeof(options))."
        throw(CTBase.IncorrectArgument(msg))
    end
end

function _build_modeler_from_method(method::Tuple, modeler_options::NamedTuple)
    model_sym = _get_modeler_symbol(method)
    return build_modeler_from_symbol(model_sym; modeler_options...)
end

# ------------------------------------------------------------------------
# ------------------------------------------------------------------------
# Solver helpers (symbol  type).

function _get_solver_symbol(method::Tuple)
    return _get_unique_symbol(method, solver_symbols(), "solver")
end

function _build_solver_from_method(method::Tuple, solver_options::NamedTuple)
    solver_sym = _get_solver_symbol(method)
    return build_solver_from_symbol(solver_sym; solver_options...)
end

# ------------------------------------------------------------------------
# ------------------------------------------------------------------------
# Option routing helpers for description mode.

const _OCP_TOOLS = (:discretizer, :modeler, :solver, :solve)

function _extract_option_tool(raw)
    if raw isa Tuple{Any,Symbol}
        value, tool = raw
        if tool in _OCP_TOOLS
            return value, tool
        end
    end
    return raw, nothing
end

function _route_option_for_description(
    key::Symbol,
    raw_value,
    owners::Vector{Symbol},
    source_mode::Symbol,
)
    value, explicit_tool = _extract_option_tool(raw_value)

    if explicit_tool !== nothing
        if !(explicit_tool in owners)
            msg = "Keyword option $(key) cannot be routed to $(explicit_tool); valid tools are $(owners)."
            throw(CTBase.IncorrectArgument(msg))
        end
        return value, explicit_tool
    end

    if isempty(owners)
        msg = "Keyword option $(key) does not belong to any recognized component for the selected method."
        throw(CTBase.IncorrectArgument(msg))
    elseif length(owners) == 1
        return value, owners[1]
    else
        if source_mode === :description
            msg = "Keyword option $(key) is ambiguous between tools $(owners). " *
                  "Disambiguate it by writing $(key) = (value, :tool), for example " *
                  "$(key) = (value, :discretizer) or $(key) = (value, :solver)."
            throw(CTBase.IncorrectArgument(msg))
        else
            msg = "Ambiguous keyword option $(key) when routing from explicit mode; " *
                  "internal calls should use the (value, tool) form."
            throw(CTBase.IncorrectArgument(msg))
        end
    end
end

# ------------------------------------------------------------------------
# ------------------------------------------------------------------------
# Display helpers.

function _display_ocp_method(
    method::Tuple,
    discretizer::AbstractOptimalControlDiscretizer,
    modeler::AbstractOptimizationModeler,
    solver::AbstractOptimizationSolver;
    display::Bool,
)
    display || return nothing

    version_str = string(Base.pkgversion(@__MODULE__))

    print("▫ This is CTSolvers version v", version_str, " running with: ")
    for (i, m) in enumerate(method)
        sep = i == length(method) ? ".\n\n" : ", "
        printstyled(string(m) * sep; color=:cyan, bold=true)
    end

    model_pkg = tool_package_name(modeler)
    solver_pkg = tool_package_name(solver)

    if model_pkg !== missing && solver_pkg !== missing
        println(
            "   ┌─ The NLP is modelled with ",
            model_pkg,
            " and solved with ",
            solver_pkg,
            ".",
        )
        println("   │")
    end

    # Discretizer options (including grid size and scheme)
    disc_vals = _options(discretizer)
    disc_srcs = _option_sources(discretizer)

    mod_vals = _options(modeler)
    mod_srcs = _option_sources(modeler)

    sol_vals = _options(solver)
    sol_srcs = _option_sources(solver)

    has_disc = !isempty(propertynames(disc_vals))
    has_mod  = !isempty(propertynames(mod_vals))
    has_sol  = !isempty(propertynames(sol_vals))

    if has_disc || has_mod || has_sol
        println("   Options:")

        if has_disc
            println("   ├─ Discretizer:")
            for name in propertynames(disc_vals)
                src = haskey(disc_srcs, name) ? disc_srcs[name] : :unknown
                println("   │    ", name, " = ", disc_vals[name], "  (", src, ")")
            end
        end

        if has_mod
            println("   ├─ Modeler:")
            for name in propertynames(mod_vals)
                src = haskey(mod_srcs, name) ? mod_srcs[name] : :unknown
                println("   │    ", name, " = ", mod_vals[name], "  (", src, ")")
            end
        end

        if has_sol
            println("   └─ Solver:")
            for name in propertynames(sol_vals)
                src = haskey(sol_srcs, name) ? sol_srcs[name] : :unknown
                println("        ", name, " = ", sol_vals[name], "  (", src, ")")
            end
        end
    end

    println("")

    return nothing
end

# ------------------------------------------------------------------------
# ------------------------------------------------------------------------
# Top-level solve entry: unifies explicit and description modes.

solve_ocp_option_keys_explicit_mode() = (:initial_guess, :display)

struct _ParsedTopLevelKwargs
    initial_guess
    display
    discretizer
    modeler
    solver
    modeler_options
    other_kwargs::NamedTuple
end

function _parse_top_level_kwargs(kwargs::NamedTuple)
    initial_guess = haskey(kwargs, :initial_guess) ? kwargs[:initial_guess] : __initial_guess()
    display       = haskey(kwargs, :display)       ? kwargs[:display]       : __display()
    discretizer   = haskey(kwargs, :discretizer)   ? kwargs[:discretizer]   : nothing
    modeler       = haskey(kwargs, :modeler)       ? kwargs[:modeler]       : nothing
    solver        = haskey(kwargs, :solver)        ? kwargs[:solver]        : nothing
    modeler_options = haskey(kwargs, :modeler_options) ? kwargs[:modeler_options] : nothing

    known_keys = (:initial_guess, :display, :discretizer, :modeler, :solver, :modeler_options)
    other_kwargs = (; (k => v for (k, v) in pairs(kwargs) if !(k in known_keys))...)

    return _ParsedTopLevelKwargs(
        initial_guess,
        display,
        discretizer,
        modeler,
        solver,
        modeler_options,
        other_kwargs,
    )
end

function _parse_top_level_kwargs_description(kwargs::NamedTuple)
    # Defaults identical to the explicit-mode parser, but reserved keywords can
    # be routed through the central option router in the future if they become
    # shared between components. For now, initial_guess, display and
    # modeler_options are treated as belonging solely to the top-level solve.

    initial_guess = __initial_guess()
    display       = __display()
    discretizer   = nothing
    modeler       = nothing
    solver        = nothing
    modeler_options = nothing

    # Reserved keywords
    if haskey(kwargs, :initial_guess)
        raw = kwargs[:initial_guess]
        # Currently initial_guess is unambiguously a top-level option for the
        # solve call. We still pass it through the routing helper with a
        # single owner (:solve) so that future owners (e.g., :solver) can be
        # added without changing the parsing structure.
        value, _ = _route_option_for_description(:initial_guess, raw, Symbol[:solve], :description)
        initial_guess = value
    end

    if haskey(kwargs, :display)
        display = kwargs[:display]
    end

    if haskey(kwargs, :modeler_options)
        modeler_options = kwargs[:modeler_options]
    end

    # Explicit components, if any
    if haskey(kwargs, :discretizer)
        discretizer = kwargs[:discretizer]
    end
    if haskey(kwargs, :modeler)
        modeler = kwargs[:modeler]
    end
    if haskey(kwargs, :solver)
        solver = kwargs[:solver]
    end

    # Everything else goes to other_kwargs and will be routed to discretizer
    # or solver by the description-mode splitter.
    known_keys = (:initial_guess, :display, :discretizer, :modeler, :solver, :modeler_options)
    other_pairs = Pair{Symbol,Any}[]
    for (k, v) in pairs(kwargs)
        if k in known_keys
            continue
        end
        push!(other_pairs, k => v)
    end

    return _ParsedTopLevelKwargs(
        initial_guess,
        display,
        discretizer,
        modeler,
        solver,
        modeler_options,
        (; other_pairs...),
    )
end

function _has_explicit_components(parsed::_ParsedTopLevelKwargs)
    return (parsed.discretizer !== nothing) || (parsed.modeler !== nothing) || (parsed.solver !== nothing)
end

function _ensure_no_unknown_explicit_kwargs(parsed::_ParsedTopLevelKwargs)
    allowed = Set(solve_ocp_option_keys_explicit_mode())
    union!(allowed, Set((:discretizer, :modeler, :solver)))
    unknown = [k for (k, _) in pairs(parsed.other_kwargs) if !(k in allowed)]
    if !isempty(unknown)
        msg = "Unknown keyword options in explicit mode: $(unknown)."
        throw(CTBase.IncorrectArgument(msg))
    end
end

function _build_description_from_components(discretizer, modeler, solver)
    syms = Symbol[]
    if discretizer !== nothing
        push!(syms, get_symbol(discretizer))
    end
    if modeler !== nothing
        push!(syms, get_symbol(modeler))
    end
    if solver !== nothing
        push!(syms, get_symbol(solver))
    end
    return Tuple(syms)
end

function _solve_from_components_and_description(
    ocp::AbstractOptimalControlProblem,
    method::Tuple,
    parsed::_ParsedTopLevelKwargs,
)
    # method is a COMPLETE description (e.g., (:collocation, :adnlp, :ipopt))

    # 1. Discretizer
    discretizer = if parsed.discretizer === nothing
        _build_discretizer_from_method(method, NamedTuple())
    else
        parsed.discretizer
    end

    # 2. Modeler (no modeler_options in explicit mode)
    modeler = if parsed.modeler === nothing
        _build_modeler_from_method(method, NamedTuple())
    else
        parsed.modeler
    end

    # 3. Solver (no solver-specific kwargs in explicit mode)
    solver = if parsed.solver === nothing
        _build_solver_from_method(method, NamedTuple())
    else
        parsed.solver
    end

    _display_ocp_method(method, discretizer, modeler, solver; display=parsed.display)

    return _solve(
        ocp,
        parsed.initial_guess,
        discretizer,
        modeler,
        solver;
        display=parsed.display,
    )
end

function _solve_explicit_mode(
    ocp::AbstractOptimalControlProblem,
    parsed::_ParsedTopLevelKwargs,
)
    # 1. No modeler_options in explicit mode
    if parsed.modeler_options !== nothing
        msg = "modeler_options is not allowed in explicit mode; pass a modeler instance instead."
        throw(CTBase.IncorrectArgument(msg))
    end

    # 2. Unknown options check
    _ensure_no_unknown_explicit_kwargs(parsed)

    # 3. If all components are provided explicitly, call the low-level API
    #    directly without going through the description/method registry. This
    #    allows arbitrary user-defined components (e.g., test doubles) that do
    #    not participate in the symbol registry.
    has_discretizer = parsed.discretizer !== nothing
    has_modeler     = parsed.modeler     !== nothing
    has_solver      = parsed.solver      !== nothing

    if has_discretizer && has_modeler && has_solver
        return _solve(
            ocp,
            parsed.initial_guess,
            parsed.discretizer,
            parsed.modeler,
            parsed.solver;
            display=parsed.display,
        )
    end

    # 4. Otherwise, build a partial description from the provided components
    #    and delegate to the description-based pipeline to complete missing
    #    pieces using the central method registry.
    partial_desc = _build_description_from_components(
        parsed.discretizer,
        parsed.modeler,
        parsed.solver,
    )
    method = CTBase.complete(partial_desc...; descriptions=available_methods())

    return _solve_from_components_and_description(ocp, method, parsed)
end

# ------------------------------------------------------------------------
# ------------------------------------------------------------------------
# Description-based solve (including the default solve(ocp) case).

function _split_kwargs_for_description(
    method::Tuple,
    parsed::_ParsedTopLevelKwargs,
)
    # All top-level kwargs except initial_guess, display, modeler_options
    # are in parsed.other_kwargs. Among them, some belong to the discretizer,
    # the rest are solver options.
    disc_keys = Set(_discretizer_options(method))

    disc_pairs = Pair{Symbol,Any}[]
    solver_pairs = Pair{Symbol,Any}[]
    for (k, raw) in pairs(parsed.other_kwargs)
        owners = Symbol[]
        if k in disc_keys
            push!(owners, :discretizer)
        end
        # For now, any key may be sent to the solver as well (this covers all
        # current solver options). Extend here if more tools get their own
        # option sets.
        if !(k in disc_keys)
            push!(owners, :solver)
        end

        value, tool = _route_option_for_description(k, raw, owners, :description)

        if tool === :discretizer
            push!(disc_pairs, k => value)
        elseif tool === :solver
            push!(solver_pairs, k => value)
        else
            msg = "Unsupported tool $(tool) for option $(k)."
            throw(CTBase.IncorrectArgument(msg))
        end
    end

    disc_kwargs   = (; disc_pairs...)
    solver_kwargs = (; solver_pairs...)

    return (
        initial_guess=parsed.initial_guess,
        display=parsed.display,
        disc_kwargs=disc_kwargs,
        modeler_options=_normalize_modeler_options(parsed.modeler_options),
        solver_kwargs=solver_kwargs,
    )
end

function _solve_from_complete_description(
    ocp::AbstractOptimalControlProblem,
    method::Tuple{Vararg{Symbol}},
    parsed::_ParsedTopLevelKwargs,
)::AbstractOptimalControlSolution

    pieces = _split_kwargs_for_description(method, parsed)

    discretizer = _build_discretizer_from_method(method, pieces.disc_kwargs)
    modeler = _build_modeler_from_method(method, pieces.modeler_options)
    solver = _build_solver_from_method(method, pieces.solver_kwargs)

    _display_ocp_method(method, discretizer, modeler, solver; display=pieces.display)

    return _solve(
        ocp,
        pieces.initial_guess,
        discretizer,
        modeler,
        solver;
        display=pieces.display,
    )
end

function _solve_descriptif_mode(
    ocp::AbstractOptimalControlProblem,
    description::Symbol...;
    kwargs...,
)::AbstractOptimalControlSolution

    parsed = _parse_top_level_kwargs_description((; kwargs...))

    if _has_explicit_components(parsed)
        msg = "Cannot mix explicit components (discretizer/modeler/solver) with a description."
        throw(CTBase.IncorrectArgument(msg))
    end

    method = CTBase.complete(description...; descriptions=available_methods())
    return _solve_from_complete_description(ocp, method, parsed)
end

function CommonSolve.solve(
    ocp::AbstractOptimalControlProblem,
    description::Symbol...;
    kwargs...,
)::AbstractOptimalControlSolution

    parsed = _parse_top_level_kwargs((; kwargs...))

    if _has_explicit_components(parsed) && !isempty(description)
        msg = "Cannot mix explicit components (discretizer/modeler/solver) with a description."
        throw(CTBase.IncorrectArgument(msg))
    end

    if _has_explicit_components(parsed)
        # Explicit mode: components provided directly by the user.
        return _solve_explicit_mode(ocp, parsed)
    else
        # Description mode: description may be empty (solve(ocp)) or partial.
        return _solve_descriptif_mode(ocp, description...; kwargs...)
    end
end
