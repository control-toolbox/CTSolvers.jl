"""
    @init ocp begin
        ...
    end

Macro to build initialization data (NamedTuple) from a small DSL of the form

    q(t) := sin(t)
    x(T) := X
    u := 0.1
    a = 1.0
    v(t) := a

The macro only transforms this syntax into a `NamedTuple`; all dimensional
validation and detailed handling of OCP aliases is performed by
`build_initial_guess` / `_initial_guess_from_namedtuple`.
"""

function _collect_init_specs(ex)
    alias_stmts = Expr[]           # statements of the form a = ... or other Julia statements
    keys = Symbol[]                # keys of the NamedTuple (q, v, x, u, tf, ...)
    vals = Any[]                   # expressions for the associated values

    stmts = if ex isa Expr && ex.head == :block
        ex.args
    else
        Any[ex]
    end

    for st in stmts
        st isa LineNumberNode && continue

        @match st begin
            # Alias / ordinary Julia assignments left as-is
            :($lhs = $rhs) => begin
                push!(alias_stmts, st)
            end

            # Forms q(t) := rhs (time-dependent function) or q(T) := rhs (time grid)
            :($lhs($arg) := $rhs) => begin
                lhs isa Symbol || error("Unsupported left-hand side in @init: $lhs")
                if arg == :t
                    # q(t) := rhs  → time-dependent function
                    push!(keys, lhs)
                    push!(vals, :($arg -> $rhs))
                else
                    # q(T) := rhs  → (T, rhs) for build_initial_guess
                    push!(keys, lhs)
                    push!(vals, :(($arg, $rhs)))
                end
            end

            # Constant / variable form: lhs := rhs
            :($lhs := $rhs) => begin
                lhs isa Symbol || error("Unsupported left-hand side in @init: $lhs")
                push!(keys, lhs)
                push!(vals, rhs)
            end

            # Fallback: any other line is treated as an ordinary Julia statement
            _ => begin
                push!(alias_stmts, st)
            end
        end
    end

    return alias_stmts, keys, vals
end

function init_fun(ocp, e)
    alias_stmts, keys, vals = _collect_init_specs(e)

    # If there is no init specification, delegate to build_initial_guess/validate_initial_guess
    if isempty(keys)
        body_stmts = Any[]
        append!(body_stmts, alias_stmts)
        # By default, we delegate to build_initial_guess/validate_initial_guess
        build_call = :(CTSolvers.build_initial_guess($ocp, ()))
        validate_call = :(CTSolvers.validate_initial_guess($ocp, $build_call))
        push!(body_stmts, validate_call)
        return Expr(:block, body_stmts...)
    end

    # Build the NamedTuple type and its values
    key_nodes = [QuoteNode(k) for k in keys]
    keys_tuple = Expr(:tuple, key_nodes...)
    vals_tuple = Expr(:tuple, vals...)
    nt_expr = :(NamedTuple{$keys_tuple}($vals_tuple))

    body_stmts = Any[]
    append!(body_stmts, alias_stmts)
    build_call = :(CTSolvers.build_initial_guess($ocp, $nt_expr))
    validate_call = :(CTSolvers.validate_initial_guess($ocp, $build_call))
    push!(body_stmts, validate_call)
    return Expr(:block, body_stmts...)
end

macro init(ocp, e)
    code = init_fun(ocp, e)
    return esc(code)
end
