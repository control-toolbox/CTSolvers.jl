try
    using Revise
catch
    println("🔧 Revise not found - continuing without hot reload")
end

using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))

using MadNLP

# ====================================================================
# 1. Fake Hierarchy (Simulation)
# ====================================================================
println("\n=== 1. Fake Hierarchy ===")
abstract type FakeAbstractKKTSystem{T,VT,MT,QN} end
abstract type FakeAbstractUnreducedKKTSystem{T,VT,MT,QN} <: FakeAbstractKKTSystem{T,VT,MT,QN} end
struct FakeSparseKKTSystem{T,VT,MT,QN} <: FakeAbstractUnreducedKKTSystem{T,VT,MT,QN} end

ExpectedTypeFake = Type{<:FakeAbstractKKTSystem}
ValueFake = FakeSparseKKTSystem

println("Value: ", ValueFake)
println("Expected: ", ExpectedTypeFake)
println("typeof(Value): ", typeof(ValueFake))
println("isa(Value, Expected): ", isa(ValueFake, ExpectedTypeFake))
println("Value <: Abstract: ", ValueFake <: FakeAbstractKKTSystem)

# ====================================================================
# 2. Real MadNLP Types
# ====================================================================
println("\n=== 2. Real MadNLP Types ===")

# Verify they are loaded
println("MadNLP.AbstractKKTSystem available: ", isdefined(MadNLP, :AbstractKKTSystem))
println("MadNLP.SparseKKTSystem available: ", isdefined(MadNLP, :SparseKKTSystem))

ExpectedTypeReal = Type{<:MadNLP.AbstractKKTSystem}
ValueReal = MadNLP.SparseKKTSystem

println("Value: ", ValueReal)
println("Expected: ", ExpectedTypeReal)
println("typeof(Value): ", typeof(ValueReal))
println("isa(Value, Expected): ", isa(ValueReal, ExpectedTypeReal))
println("Value <: Abstract: ", ValueReal <: MadNLP.AbstractKKTSystem)


# Check Partial Instantiation for Real Types (if possible/relevant)
# We strictly check if the Generic UnionAll passes the isa check
if isa(ValueReal, ExpectedTypeReal)
    println("✅ SUCCESS: MadNLP.SparseKKTSystem isa Type{<:MadNLP.AbstractKKTSystem}")
else
    println("❌ FAILURE: MadNLP.SparseKKTSystem !isa Type{<:MadNLP.AbstractKKTSystem}")
end

# Check PROPOSED FIX
ProposedFixType = Union{Type{<:MadNLP.AbstractKKTSystem},UnionAll}
println("\n=== 3. Proposed Fix Evaluation ===")
println("Proposed Fix Type: ", ProposedFixType)
println("isa(MadNLP.SparseKKTSystem, ProposedFixType): ", isa(MadNLP.SparseKKTSystem, ProposedFixType))

if isa(MadNLP.SparseKKTSystem, ProposedFixType)
    println("✅ SUCCESS: Proposed fix accepts MadNLP.SparseKKTSystem")
else
    println("❌ FAILURE: Proposed fix REJECTS MadNLP.SparseKKTSystem")
end
