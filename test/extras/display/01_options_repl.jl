# ============================================================================
# CTSolvers Options Module - REPL Style Display Demonstration
# ============================================================================

try
    using Revise
catch
    println("🔧 Revise not found - continuing without hot reload")
end

using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))

# Add CTSolvers in development mode
if !haskey(Pkg.project().dependencies, "CTSolvers")
    Pkg.develop(path=joinpath(@__DIR__, "..", "..", ".."))
end

using CTSolvers
using CTSolvers.Options

println()
println("="^60)
println("🎯 CTSOLVERS OPTIONS MODULE - REPL STYLE DISPLAY DEMO")
println("="^60)
println()

# ============================================================================
# 1. OptionValue Display - Different Sources
# ============================================================================

println()
println("="^60)
println("📋 1. OPTIONVALUE DISPLAY - DIFFERENT SOURCES")
println("="^60)
println()

println("🟢 julia> user_option = CTSolvers.Options.OptionValue(1000, :user)")
user_option = CTSolvers.Options.OptionValue(1000, :user)
println("📋 User option created:")
println("  ", user_option)
println()

println("🟢 julia> default_option = CTSolvers.Options.OptionValue(1e-6, :default)")
default_option = CTSolvers.Options.OptionValue(1e-6, :default)
println("📋 Default option created:")
println("  ", default_option)
println()

println("🟢 julia> computed_option = CTSolvers.Options.OptionValue(42, :computed)")
computed_option = CTSolvers.Options.OptionValue(42, :computed)
println("📋 Computed option created:")
println("  ", computed_option)
println()

# ============================================================================
# 2. OptionDefinition Display - Simple and Complex
# ============================================================================

println()
println("="^60)
println("📋 2. OPTIONDEFINITION DISPLAY - SIMPLE AND COMPLEX")
println("="^60)
println()

println("🟢 julia> simple_def = CTSolvers.Options.OptionDefinition(")
println("            name=:max_iter,")
println("            type=Int,")
println("            default=100,")
println("            description=\"Maximum number of iterations\"")
println("        )")
simple_def = CTSolvers.Options.OptionDefinition(
    name=:max_iter,
    type=Int,
    default=100,
    description="Maximum number of iterations"
)
println("📋 Simple option definition created:")
println(simple_def)
println()

println("🟢 julia> complex_def = CTSolvers.Options.OptionDefinition(")
println("            name=:tol,")
println("            type=Float64,")
println("            default=1e-8,")
println("            description=\"Convergence tolerance\",")
println("            aliases=(:tolerance, :epsilon)")
println("        )")
complex_def = CTSolvers.Options.OptionDefinition(
    name=:tol,
    type=Float64,
    default=1e-8,
    description="Convergence tolerance",
    aliases=(:tolerance, :epsilon)
)
println("📋 Complex option definition with aliases:")
println(complex_def)
println()

# ============================================================================
# 3. Sentinel Types Display - NotProvided and NotStored
# ============================================================================

println()
println("="^60)
println("📋 3. SENTINEL TYPES DISPLAY - NOTPROVIDED AND NOTSTORED")
println("="^60)
println()

println("🟢 julia> CTSolvers.Options.NotProvided")
println("📋 NotProvided sentinel:")
println("  ", CTSolvers.Options.NotProvided)
println()

println("🟢 julia> CTSolvers.Options.NotStored")
println("📋 NotStored sentinel:")
println("  ", CTSolvers.Options.NotStored)
println()

# ============================================================================
# 4. Option Extraction - Success and Error Cases
# ============================================================================

println()
println("="^60)
println("📋 4. OPTION EXTRACTION - SUCCESS AND ERROR CASES")
println("="^60)
println()

# Test case 1: Successful extraction
println("🟢 julia> kwargs_success = (max_iter=1000, tol=1e-6, display=true)")
kwargs_success = (max_iter=1000, tol=1e-6, display=true)
println("🟢 julia> extracted, remaining = CTSolvers.Options.extract_option(kwargs_success, simple_def)")
extracted_success, remaining_success = CTSolvers.Options.extract_option(kwargs_success, simple_def)
println("📋 Extraction successful:")
println("  Extracted: ", extracted_success)
println("  Remaining: ", remaining_success)
println()

# Test case 2: Missing option (uses default)
println("🟢 julia> kwargs_missing = (tol=1e-6, display=true)")
kwargs_missing = (tol=1e-6, display=true)
println("🟢 julia> extracted, remaining = CTSolvers.Options.extract_option(kwargs_missing, simple_def)")
extracted_missing, remaining_missing = CTSolvers.Options.extract_option(kwargs_missing, simple_def)
println("📋 Extraction with missing option (uses default):")
println("  Extracted: ", extracted_missing)
println("  Remaining: ", remaining_missing)
println()

# Test case 3: Type mismatch (warning)
println("🟢 julia> kwargs_mismatch = (max_iter=\"1000\", tol=1e-6)")
kwargs_mismatch = (max_iter="1000", tol=1e-6)
println("⚠️  Type mismatch warning expected:")
println("🟢 julia> extracted, remaining = CTSolvers.Options.extract_option(kwargs_mismatch, simple_def)")
extracted_mismatch, remaining_mismatch = CTSolvers.Options.extract_option(kwargs_mismatch, simple_def)
println("📋 Extraction with type mismatch:")
println("  Extracted: ", extracted_mismatch)
println("  Remaining: ", remaining_mismatch)
println()

# ============================================================================
# 5. Multiple Options Extraction
# ============================================================================

println()
println("="^60)
println("📋 5. MULTIPLE OPTIONS EXTRACTION")
println("="^60)
println()

println("🟢 julia> definitions = [simple_def, complex_def]")
definitions = [simple_def, complex_def]
println("🟢 julia> kwargs_multi = (max_iter=500, tol=1e-7, backend=:sparse)")
kwargs_multi = (max_iter=500, tol=1e-7, backend=:sparse)
println("🟢 julia> extracted_multi, remaining_multi = CTSolvers.Options.extract_options(kwargs_multi, definitions)")
extracted_multi, remaining_multi = CTSolvers.Options.extract_options(kwargs_multi, definitions)
println("📋 Multiple options extraction:")
println("  Extracted options:")
for (name, value) in pairs(extracted_multi)
    println("    :", name, " = ", value)
end
println("  Remaining options: ", remaining_multi)
println()

# ============================================================================
# 6. Option Validation Examples
# ============================================================================

println()
println("="^60)
println("📋 6. OPTION VALIDATION EXAMPLES")
println("="^60)
println()

# Create a definition with validator
println("🟢 julia> validated_def = CTSolvers.Options.OptionDefinition(")
println("                name=:positive_iter,")
println("                type=Int,")
println("                default=10,")
println("                description=\"Positive iteration count\",")
println("                validator=x -> x > 0 || throw(ArgumentError(\"Must be positive\"))")
println("            )")
validated_def = CTSolvers.Options.OptionDefinition(
    name=:positive_iter,
    type=Int,
    default=10,
    description="Positive iteration count",
    validator=x -> x > 0 || throw(ArgumentError("Must be positive"))
)
println("📋 Option definition with validator created:")
println(validated_def)
println()

# Test valid value
println("🟢 julia> kwargs_valid = (positive_iter=100, other_option=123)")
kwargs_valid = (positive_iter=100, other_option=123)
println("🟢 julia> extracted_valid, remaining_valid = CTSolvers.Options.extract_option(kwargs_valid, validated_def)")
extracted_valid, remaining_valid = CTSolvers.Options.extract_option(kwargs_valid, validated_def)
println("✅ Valid value extraction:")
println("  Extracted: ", extracted_valid)
println("  Remaining: ", remaining_valid)
println()

# Test invalid value
println("🟢 julia> kwargs_invalid = (positive_iter=-5, other_option=456)")
kwargs_invalid = (positive_iter=-5, other_option=456)
println("⚠️  Invalid value - expecting validation error:")
println("🟢 julia> extracted_invalid, remaining_invalid = CTSolvers.Options.extract_option(kwargs_invalid, validated_def)")
try
    extracted_invalid, remaining_invalid = CTSolvers.Options.extract_option(kwargs_invalid, validated_def)
    println("📋 Unexpected success:")
    println("  Extracted: ", extracted_invalid)
catch e
    println("⚠️  Validation error caught:")
    println("  ", typeof(e), ": ", e)
end
println()

# ============================================================================
# 7. Complete Workflow Example
# ============================================================================

println()
println("="^60)
println("📋 7. COMPLETE WORKFLOW EXAMPLE")
println("="^60)
println()

println("🟢 julia> # Define all options for a hypothetical solver")
println("🟢 julia> solver_options = [")
println("        CTSolvers.Options.OptionDefinition(")
println("            name=:max_iter, type=Int, default=1000,")
println("            description=\"Maximum iterations\"")
println("        ),")
println("        CTSolvers.Options.OptionDefinition(")
println("            name=:tol, type=Float64, default=1e-6,")
println("            description=\"Convergence tolerance\"")
println("        ),")
println("        CTSolvers.Options.OptionDefinition(")
println("            name=:display, type=Bool, default=true,")
println("            description=\"Display progress\"")
println("        )")
println("    ]")
solver_options = [
    CTSolvers.Options.OptionDefinition(
        name=:max_iter, type=Int, default=1000,
        description="Maximum iterations"
    ),
    CTSolvers.Options.OptionDefinition(
        name=:tol, type=Float64, default=1e-6,
        description="Convergence tolerance"
    ),
    CTSolvers.Options.OptionDefinition(
        name=:display, type=Bool, default=true,
        description="Display progress"
    )
]

println("🟢 julia> user_kwargs = (max_iter=500, tol=1e-8, verbose=true)")
user_kwargs = (max_iter=500, tol=1e-8, verbose=true)

println("🟢 julia> final_options, extra_kwargs = CTSolvers.Options.extract_options(user_kwargs, solver_options)")
final_options, extra_kwargs = CTSolvers.Options.extract_options(user_kwargs, solver_options)

println("📋 Complete workflow results:")
println("  Extracted solver options:")
for (name, value) in pairs(final_options)
    println("    :", name, " = ", value, " (", value.source, ")")
end
println("  Extra/unrecognized options: ", extra_kwargs)
println()

# ============================================================================
# SUMMARY
# ============================================================================

println()
println("="^60)
println("🎯 OPTIONS MODULE DISPLAY DEMO - SUMMARY")
println("="^60)
println()

println("📋 What we demonstrated:")
println("  ✅ OptionValue display with different sources (user, default, computed)")
println("  ✅ OptionDefinition display (simple and with aliases)")
println("  ✅ Sentinel types (NotProvided, NotStored)")
println("  ✅ Option extraction (success, missing, type mismatch)")
println("  ✅ Multiple options extraction")
println("  ✅ Option validation with custom validators")
println("  ✅ Complete workflow example")

println()
println("🎨 Key display features shown:")
println("  🟢 REPL-style prompts with julia>")
println("  📋 Structured output with clear sections")
println("  🔹 Indented details for readability")
println("  ⚠️  Error handling with clear messages")
println("  ✅ Success confirmations")

println()
println("🚀 All Options module display capabilities demonstrated!")
println("   Ready to explore Strategies module next...")
