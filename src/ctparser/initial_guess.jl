"""
    @init ocp begin
        ...
    end

Macro pour construire des données d'initialisation (NamedTuple) à partir d'un
DSL de type

    q(t) := sin(t)
    x(T) := X
    u := 0.1
    a = 1.0
    v(t) := a

La macro ne fait que transformer la syntaxe en `NamedTuple`; toute la
validation dimensionnelle et la gestion fine des alias d'OCP est assurée par
`build_initial_guess` / `_initial_guess_from_namedtuple`.
"""

function _collect_init_specs(ex)
    alias_stmts = Expr[]           # lignes de la forme a = ... ou autres statements Julia
    keys = Symbol[]                # clés du NamedTuple (q, v, x, u, tf, ...)
    vals = Any[]                   # expressions des valeurs associées

    stmts = if ex isa Expr && ex.head == :block
        ex.args
    else
        Any[ex]
    end

    for st in stmts
        st isa LineNumberNode && continue

        @match st begin
            # Alias / affectations Julia ordinaires laissées telles quelles
            :($lhs = $rhs) => begin
                push!(alias_stmts, st)
            end

            # Formes q(t) := rhs (fonction du temps) ou q(T) := rhs (grille de temps)
            :($lhs($arg) := $rhs) => begin
                lhs isa Symbol || error("Unsupported left-hand side in @init: $lhs")
                if arg == :t
                    # q(t) := rhs  → fonction du temps
                    push!(keys, lhs)
                    push!(vals, :($arg -> $rhs))
                else
                    # q(T) := rhs  → (T, rhs) pour build_initial_guess
                    push!(keys, lhs)
                    push!(vals, :(($arg, $rhs)))
                end
            end

            # Forme constante / variable : lhs := rhs
            :($lhs := $rhs) => begin
                lhs isa Symbol || error("Unsupported left-hand side in @init: $lhs")
                push!(keys, lhs)
                push!(vals, rhs)
            end

            # Fallback : toute autre ligne est traitée comme statement Julia ordinaire
            _ => begin
                push!(alias_stmts, st)
            end
        end
    end

    return alias_stmts, keys, vals
end

function init_fun(ocp, e)
    alias_stmts, keys, vals = _collect_init_specs(e)

    # Si aucune spécification d'init, on retourne juste un NamedTuple vide
    if isempty(keys)
        body_stmts = Any[]
        append!(body_stmts, alias_stmts)
        push!(body_stmts, :(()))
        return Expr(:block, body_stmts...)
    end

    # Construction du type de NamedTuple et de ses valeurs
    key_nodes = [QuoteNode(k) for k in keys]
    keys_tuple = Expr(:tuple, key_nodes...)
    vals_tuple = Expr(:tuple, vals...)
    nt_expr = :(NamedTuple{$keys_tuple}($vals_tuple))

    body_stmts = Any[]
    append!(body_stmts, alias_stmts)
    push!(body_stmts, nt_expr)
    return Expr(:block, body_stmts...)
end

macro init(ocp, e)
    code = init_fun(ocp, e)
    return esc(code)
end
