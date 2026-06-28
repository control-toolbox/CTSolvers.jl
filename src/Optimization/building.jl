# Generic build functions (declarations)
#
# `Optimization` owns and re-exports the generic functions `build_model` and
# `build_solution`. They are *declared* here (empty generics) so the binding exists
# and the export is valid; their canonical `NotImplemented` contract stubs — the
# modeler contract, with full docstrings — live in `Modelers/contract.jl`, and
# concrete methods live in the package providing the problem (e.g. CTDirect).
#
# This file is intentionally excluded from the API reference: it carries no
# documentable content; `build_model` / `build_solution` are documented via their
# contract methods on the Modelers page.

function build_model end
function build_solution end
