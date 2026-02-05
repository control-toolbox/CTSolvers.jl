abstract type AbstractSolver end
struct ConcreteSolver <: AbstractSolver end
struct GenericSolver{T} <: AbstractSolver end

# Logic mimicking extraction.jl with proposed fix
function validate(value, expected_type)
    println("Checking value: $value vs expected: $expected_type")
    
    # Current check
    is_valid_isa = isa(value, expected_type)
    println("isa(value, expected_type): $is_valid_isa")
    
    # Proposed check
    # We must handle the case where expected_type might not be valid for <: (e.g. if it is not a Type)
    # But OptionDefinition types are expected to be Types.
    is_valid_subtype = false
    try
        if value isa Type && expected_type isa Type
            is_valid_subtype = value <: expected_type
        end
    catch e
        println("Error in subtype check: $e")
    end
    println("value <: expected_type: $is_valid_subtype")
    
    return is_valid_isa || is_valid_subtype
end

println("--- Case 1: Concrete Type vs Abstract Type ---")
# User wants: type=AbstractSolver, value=ConcreteSolver
validate(ConcreteSolver, AbstractSolver)

println("\n--- Case 2: Generic Type (UnionAll) vs Abstract Type ---")
# User wants: type=AbstractSolver, value=GenericSolver
validate(GenericSolver, AbstractSolver)

println("\n--- Case 3: Type{<:...} (Current syntax) ---")
validate(ConcreteSolver, Type{<:AbstractSolver})
validate(GenericSolver, Type{<:AbstractSolver})
