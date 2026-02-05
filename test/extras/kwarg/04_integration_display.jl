# ============================================================================
# CTSolvers Integration Display Tests - REPL Style
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
using CTSolvers.Strategies
using CTSolvers.Modelers
using CTSolvers.Optimization

println()
println("="^60)
println("🎯 CTSOLVERS INTEGRATION DISPLAY TESTS - REPL STYLE")
println("="^60)
println()

# ============================================================================
# 1. Integration Setup
# ============================================================================

println()
println("="^60)
println("📋 1. INTEGRATION SETUP")
println("="^60)
println()

println("🟢 julia> # Create test objective functions")
println("🟢 julia> simple_objective = x -> sum(x.^2)")
simple_objective = x -> sum(x.^2)
println("🟢 julia> rosenbrock_objective = x -> (1 - x[1])^2 + 100(x[2] - x[1]^2)^2")
rosenbrock_objective = x -> (1 - x[1])^2 + 100(x[2] - x[1]^2)^2
println("🟢 julia> # Test initial guesses")
println("🟢 julia> guess_2d = [0.0, 0.0]")
guess_2d = [0.0, 0.0]
println("🟢 julia> guess_5d = zeros(5)")
guess_5d = zeros(5)
println("📋 Integration setup complete")
println()

# ============================================================================
# 2. Modeler Integration Tests
# ============================================================================

println()
println("="^60)
println("📋 2. MODELER INTEGRATION TESTS")
println("="^60)
println()

println("🟢 julia> # Test ADNLPModeler integration")
println("🟢 julia> adnlp_modeler = CTSolvers.Modelers.ADNLPModeler(")
println("        backend=:optimized, show_time=false, name=\"IntegrationTest\"")
println("    )")
adnlp_modeler = CTSolvers.Modelers.ADNLPModeler(
    backend=:optimized, show_time=false, name="IntegrationTest"
)
println("📋 ADNLPModeler created:")
println(adnlp_modeler)
println()

println("🟢 julia> # Test ExaModeler integration")
println("🟢 julia> exa_modeler = CTSolvers.Modelers.ExaModeler(")
println("        base_type=Float32, backend=nothing)")
println("    )")
exa_modeler = CTSolvers.Modelers.ExaModeler(
    base_type=Float32, backend=nothing
)
println("📋 ExaModeler created:")
println(exa_modeler)
println()

println("🟢 julia> # Compare modeler options")
println("🟢 julia> CTSolvers.Strategies.options(adnlp_modeler)")
adnlp_options = CTSolvers.Strategies.options(adnlp_modeler)
println("📋 ADNLPModeler options:")
display(adnlp_options)
println()

println("🟢 julia> CTSolvers.Strategies.options(exa_modeler)")
exa_options = CTSolvers.Strategies.options(exa_modeler)
println("📋 ExaModeler options:")
display(exa_options)
println()

# ============================================================================
# 3. Optimization Builder Integration
# ============================================================================

println()
println("="^60)
println("📋 3. OPTIMIZATION BUILDER INTEGRATION")
println("="^60)
println()

println("🟢 julia> # Test ADNLPModelBuilder integration")
println("🟢 julia> adnlp_builder = CTSolvers.Optimization.ADNLPModelBuilder(simple_objective)")
adnlp_builder = CTSolvers.Optimization.ADNLPModelBuilder(simple_objective)
println("📋 ADNLPModelBuilder created:")
println(adnlp_builder)
println()

println("🟢 julia> # Test ExaModelBuilder integration")
println("🟢 julia> exa_builder = CTSolvers.Optimization.ExaModelBuilder(rosenbrock_objective)")
exa_builder = CTSolvers.Optimization.ExaModelBuilder(rosenbrock_objective)
println("📋 ExaModelBuilder created:")
println(exa_builder)
println()

println("🟢 julia> # Test model building integration")
println("🟢 julia> # Note: This tests the integration between builders and modelers")
println("🟢 julia> # The builder creates the model, modeler provides the backend")
println()

println("🟢 julia> # Test building with ADNLPModelBuilder")
println("🟢 julia> try")
println("🟢 julia>     adnlp_model = CTSolvers.Optimization.build_model(adnlp_builder, guess_5d; show_time=false)")
println("🟢 julia>     println(\"✅ ADNLP model built successfully\")")
println("🟢 julia> catch e")
println("🟢 julia>     println(\"⚠️ ADNLP model building error: \", typeof(e))")
println("🟢 julia> end")
try
    adnlp_model = CTSolvers.Optimization.build_model(adnlp_builder, guess_5d; show_time=false)
    println("✅ ADNLP model built successfully")
    println("  Type: ", typeof(adnlp_model))
    println("  Variables: ", adnlp_model.meta.nvar)
    println("  Constraints: ", adnlp_model.meta.ncon)
catch e
    println("⚠️ ADNLP model building error: ", typeof(e))
end
println()

# ============================================================================
# 4. Option Integration Tests
# ============================================================================

println()
println("="^60)
println("📋 4. OPTION INTEGRATION TESTS")
println("="^60)
println()

println("🟢 julia> # Test option integration between modules")
println("🟢 julia> # Create option definitions")
println("🟢 julia> option_defs = [")
println("        CTSolvers.Options.OptionDefinition(")
println("            name=:max_iter, type=Int, default=100,")
println("            description=\"Maximum iterations\"")
println("        ),")
println("        CTSolvers.Options.OptionDefinition(")
println("            name=:tol, type=Float64, default=1e-6,")
println("            description=\"Tolerance\"")
println("        )")
println("    ]")
option_defs = [
    CTSolvers.Options.OptionDefinition(
        name=:max_iter, type=Int, default=100,
        description="Maximum iterations"
    ),
    CTSolvers.Options.OptionDefinition(
        name=:tol, type=Float64, default=1e-6,
        description="Tolerance"
    )
]

println("🟢 julia> # Test option extraction")
println("🟢 julia> test_kwargs = (max_iter=500, tol=1e-8, display=true)")
test_kwargs = (max_iter=500, tol=1e-8, display=true)
println("🟢 julia> extracted, remaining = CTSolvers.Options.extract_options(test_kwargs, option_defs)")
extracted, remaining = CTSolvers.Options.extract_options(test_kwargs, option_defs)
println("📋 Option extraction results:")
println("  Extracted options:")
for (name, value) in pairs(extracted)
    println("    :", name, " = ", value, " (", value.source, ")")
end
println("  Remaining options: ", remaining)
println()

# ============================================================================
# 5. Strategy Integration Tests
# ============================================================================

println()
println("="^60)
println("📋 5. STRATEGY INTEGRATION TESTS")
println("="^60)
println()

println("🟢 julia> # Test strategy integration with modelers")
println("🟢 julia> # Check if modelers implement strategy interface")
println("🟢 julia> adnlp_modeler isa CTSolvers.Strategies.AbstractStrategy")
println("📋 ADNLPModeler is strategy:")
println("  ", adnlp_modeler isa CTSolvers.Strategies.AbstractStrategy)
println()

println("🟢 julia> exa_modeler isa CTSolvers.Strategies.AbstractStrategy")
println("📋 ExaModeler is strategy:")
println("  ", exa_modeler isa CTSolvers.Strategies.AbstractStrategy)
println()

println("🟢 julia> # Test strategy introspection integration")
println("🟢 julia> CTSolvers.Strategies.option_names(typeof(adnlp_modeler))")
adnlp_names = CTSolvers.Strategies.option_names(typeof(adnlp_modeler))
println("📋 ADNLPModeler option names:")
println("  ", adnlp_names)
println()

println("🟢 julia> CTSolvers.Strategies.option_names(typeof(exa_modeler))")
exa_names = CTSolvers.Strategies.option_names(typeof(exa_modeler))
println("📋 ExaModeler option names:")
println("  ", exa_names)
println()

# ============================================================================
# 6. Display Integration Tests
# ============================================================================

println()
println("="^60)
println("📋 6. DISPLAY INTEGRATION TESTS")
println("="^60)
println()

println("🟢 julia> # Test display integration across modules")
println("🟢 julia> # All components should display consistently")
println()

println("🟢 julia> # Test modeler display")
println("🟢 julia> println(\"ADNLPModeler display:\")")
println("🟢 julia> println(adnlp_modeler)")
println("🟢 julia> display(adnlp_modeler)")
println("📋 ADNLPModeler display:")
println(adnlp_modeler)
display(adnlp_modeler)
println()

println("🟢 julia> # Test strategy options display")
println("🟢 julia> println(\"Strategy options display:\")")
println("🟢 julia> println(CTSolvers.Strategies.options(adnlp_modeler))")
println("🟢 julia> display(CTSolvers.Strategies.options(adnlp_modeler))")
println("📋 Strategy options display:")
println(CTSolvers.Strategies.options(adnlp_modeler))
display(CTSolvers.Strategies.options(adnlp_modeler))
println()

# ============================================================================
# 7. Error Handling Integration
# ============================================================================

println()
println("="^60)
println("📋 7. ERROR HANDLING INTEGRATION")
println("="^60)
println()

println("🟢 julia> # Test error handling integration")
println("🟢 julia> # All modules should handle errors consistently")
println()

println("🟢 julia> # Test option validation errors")
println("🟢 julia> invalid_def = CTSolvers.Options.OptionDefinition(")
println("        name=:positive, type=Int, default=10,")
println("        description=\"Must be positive\",")
println("        validator=x -> x > 0 || throw(ArgumentError(\"Must be positive\"))")
println("    )")
invalid_def = CTSolvers.Options.OptionDefinition(
    name=:positive, type=Int, default=10,
    description="Must be positive",
    validator=x -> x > 0 || throw(ArgumentError("Must be positive"))
)

println("🟢 julia> # Test with invalid value")
println("🟢 julia> invalid_kwargs = (positive=-5,)")
invalid_kwargs = (positive=-5,)
println("🟢 julia> try")
println("🟢 julia>     CTSolvers.Options.extract_option(invalid_kwargs, invalid_def)")
println("🟢 julia> catch e")
println("🟢 julia>     println(\"✅ Validation error handled: \", typeof(e))")
println("🟢 julia> end")
try
    CTSolvers.Options.extract_option(invalid_kwargs, invalid_def)
    println("❌ Unexpected success")
catch e
    println("✅ Validation error handled: ", typeof(e))
end
println()

# ============================================================================
# 8. Performance Integration Tests
# ============================================================================

println()
println("="^60)
println("📋 8. PERFORMANCE INTEGRATION TESTS")
println("="^60)
println()

println("🟢 julia> # Test performance integration")
println("🟢 julia> # Components should work efficiently together")
println()

println("🟢 julia> # Test option access performance")
println("🟢 julia> # Simple timing test")
println("🟢 julia> start_time = time()")
println("🟢 julia> for i in 1:1000")
println("🟢 julia>     CTSolvers.Strategies.option_value(adnlp_modeler, :backend)")
println("🟢 julia> end")
println("🟢 julia> elapsed = time() - start_time")
start_time = time()
for i in 1:1000
    CTSolvers.Strategies.option_value(adnlp_modeler, :backend)
end
elapsed = time() - start_time
println("📋 Simple timing test:")
println("  1000 option accesses in ", round(elapsed, digits=4), " seconds")
println("  Average per access: ", round(elapsed*1000, digits=6), " ms")
println()

# ============================================================================
# 9. Type Integration Tests
# ============================================================================

println()
println("="^60)
println("📋 9. TYPE INTEGRATION TESTS")
println("="^60)
println()

println("🟢 julia> # Test type integration across modules")
println("🟢 julia> # Types should be compatible and well-integrated")
println()

println("🟢 julia> # Test type compatibility")
println("🟢 julia> typeof(adnlp_modeler.options)")
println("📋 ADNLPModeler options type:")
println("  ", typeof(adnlp_modeler.options))
println()

println("🟢 julia> typeof(exa_modeler.options)")
println("📋 ExaModeler options type:")
println("  ", typeof(exa_modeler.options))
println()

println("🟢 julia> # Test option value types")
println("🟢 julia> for option in CTSolvers.Strategies.option_names(typeof(adnlp_modeler))")
println("🟢 julia>     try")
println("🟢 julia>         value = CTSolvers.Strategies.option_value(adnlp_modeler, option)")
println("🟢 julia>         println(\":\", option, \" -> \", typeof(value), \" = \", value)")
println("🟢 julia>     catch e")
println("🟢 julia>         println(\":\", option, \" -> <error: \", typeof(e), \">)")
println("🟢 julia>     end")
println("� julia> end")
println("�📋 ADNLPModeler option types:")
for option in CTSolvers.Strategies.option_names(typeof(adnlp_modeler))
    try
        value = CTSolvers.Strategies.option_value(adnlp_modeler, option)
        println("  :", option, " -> ", typeof(value), " = ", value)
    catch e
        println("  :", option, " -> <error: ", typeof(e), ">")
    end
end
println()

# ============================================================================
# 10. Complete Workflow Integration
# ============================================================================

println()
println("="^60)
println("📋 10. COMPLETE WORKFLOW INTEGRATION")
println("="^60)
println()

println("🟢 julia> # Test complete workflow integration")
println("🟢 julia> # This demonstrates how all modules work together")
println()

println("🟢 julia> # Step 1: Create modeler with options")
println("🟢 julia> workflow_modeler = CTSolvers.Modelers.ADNLPModeler(")
println("        backend=:optimized, show_time=true, name=\"WorkflowTest\"")
println("    )")
workflow_modeler = CTSolvers.Modelers.ADNLPModeler(
    backend=:optimized, show_time=true, name="WorkflowTest"
)
println("📋 Step 1 - Modeler created:")
println("  ", workflow_modeler)
println()

println("🟢 julia> # Step 2: Create optimization builder")
println("🟢 julia> workflow_builder = CTSolvers.Optimization.ADNLPModelBuilder(simple_objective)")
workflow_builder = CTSolvers.Optimization.ADNLPModelBuilder(simple_objective)
println("📋 Step 2 - Builder created:")
println("  ", workflow_builder)
println()

println("🟢 julia> # Step 3: Test option integration")
println("🟢 julia> workflow_options = CTSolvers.Strategies.options(workflow_modeler)")
workflow_options = CTSolvers.Strategies.options(workflow_modeler)
println("📋 Step 3 - Options extracted:")
display(workflow_options)
println()

println("🟢 julia> # Step 4: Test display integration")
println("🟢 julia> println(\"Complete workflow display:\")")
println("🟢 julia> println(\"Modeler: \", workflow_modeler)")
println("🟢 julia> println(\"Builder: \", workflow_builder)")
println("🟢 julia> println(\"Options: \", workflow_options)")
println("📋 Step 4 - Complete workflow display:")
println("Modeler: ", workflow_modeler)
println("Builder: ", workflow_builder)
println("Options: ", workflow_options)
println()

# ============================================================================
# SUMMARY
# ============================================================================

println()
println("="^60)
println("🎯 INTEGRATION DISPLAY TESTS - SUMMARY")
println("="^60)
println()

println("📋 What we tested:")
println("  ✅ Modeler integration (ADNLPModeler, ExaModeler)")
println("  ✅ Optimization builder integration")
println("  ✅ Option system integration")
println("  ✅ Strategy interface integration")
println("  ✅ Display system integration")
println("  ✅ Error handling integration")
println("  ✅ Performance integration")
println("  ✅ Type system integration")
println("  ✅ Complete workflow integration")

println()
println("🎨 Key integration features shown:")
println("  🟢 Seamless module interoperability")
println("  📋 Consistent option handling across modules")
println("  🔹 Unified display system")
println("  ⚠️  Coordinated error handling")
println("  ✅ Type-safe integration patterns")

println()
println("🚀 All integration display functionality demonstrated!")
println("   🎉 CTSolvers display scripts now complete! 🎉")
