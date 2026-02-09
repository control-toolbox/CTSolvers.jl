# Implementing a Strategy

```@meta
CurrentModule = CTSolvers
```

!!! warning "Work in Progress"
    This page is under construction. See kanban task 03 for the planned content.

## The Two-Level Contract

TODO: Type-level (`id`, `metadata`) vs instance-level (`options`), Mermaid diagram.

## Defining a Strategy Family

TODO: `AbstractOptimalControlDiscretizer <: AbstractStrategy`.

## Implementing a Concrete Strategy: Collocation

TODO: Step-by-step with `@repl` displays at each step.

## Adding a Second Strategy: DirectShooting

TODO: Same pattern, different options.

## Registering the Family

TODO: `create_registry`, `strategy_ids`, `type_from_id`, `build_strategy`.

## Integration with Method Tuples

TODO: `extract_id_from_method`, `build_strategy_from_method`.

## Introspection

TODO: `option_names`, `option_defaults` for both strategies.

## Advanced Patterns

TODO: Aliases, validators, permissive mode.
