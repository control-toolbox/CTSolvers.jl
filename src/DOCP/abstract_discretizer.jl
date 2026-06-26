# DOCP abstract discretizer
#
# Defines the `AbstractDiscretizer` strategy contract. Concrete discretizers
# (collocation, direct shooting, ...) are implemented in the packages providing
# the transcription methods (e.g. CTDirect).

"""
$(TYPEDEF)

Abstract base type for all discretization strategies.

Concrete subtypes implement specific transcription methods (collocation, direct
shooting, etc.) and are defined in the package providing the method. A discretizer
is a `Strategies.AbstractStrategy`: it carries validated options and drives
`discretize` to turn an optimal control problem into a [`DiscretizedModel`](@ref).

See also: `DiscretizedModel`, `discretize`.
"""
abstract type AbstractDiscretizer <: Strategies.AbstractStrategy end
