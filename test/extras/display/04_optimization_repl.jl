# ============================================================================
# CTSolvers Optimization Module - REPL Style Display Demonstration
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
using CTSolvers.Optimization
using CTSolvers.Modelers

println()
println("="^60)
println("🎯 CTSOLVERS OPTIMIZATION MODULE - REPL STYLE DISPLAY DEMO")
println("="^60)
println()

# ============================================================================
# 1. Abstract Types Display
# ============================================================================

println()
println("="^60)
println("📋 1. ABSTRACT TYPES DISPLAY")
println("="^60)
println()

println("🟢 julia> CTSolvers.Optimization.AbstractOptimizationProblem")
println("📋 Abstract optimization problem type:")
println("  ", CTSolvers.Optimization.AbstractOptimizationProblem)
println()

println("🟢 julia> CTSolvers.Optimization.AbstractBuilder")
println("📋 Abstract builder type:")
println("  ", CTSolvers.Optimization.AbstractBuilder)
println()

println("🟢 julia> CTSolvers.Optimization.AbstractModelBuilder")
println("📋 Abstract model builder type:")
println("  ", CTSolvers.Optimization.AbstractModelBuilder)
println()

println("🟢 julia> CTSolvers.Optimization.AbstractSolutionBuilder")
println("📋 Abstract solution builder type:")
println("  ", CTSolvers.Optimization.AbstractSolutionBuilder)
println()

println("🟢 julia> # Show type hierarchy")
println("📋 Type hierarchy:")
println("  AbstractOptimizationProblem - Base type for all optimization problems")
println("  AbstractBuilder - Base type for all builders")
println("  AbstractModelBuilder - Base type for model builders")
println("  AbstractSolutionBuilder - Base type for solution builders")
println()

# ============================================================================
# 2. ADNLPModelBuilder Display
# ============================================================================

println()
println("="^60)
println("📋 2. ADNLPMODELBUILDER DISPLAY")
println("="^60)
println()

println("🟢 julia> # ADNLPModelBuilder requires a function")
println("🟢 julia> objective_func = x -> sum(x.^2)")
objective_func = x -> sum(x.^2)
println("🟢 julia> adnlp_builder = CTSolvers.Optimization.ADNLPModelBuilder(objective_func)")
adnlp_builder = CTSolvers.Optimization.ADNLPModelBuilder(objective_func)
println("📋 ADNLPModelBuilder created:")
println(adnlp_builder)
println()

println("🟢 julia> display(adnlp_builder)")
println("📋 ADNLPModelBuilder (pretty display):")
display(adnlp_builder)
println()

# ============================================================================
# 3. ExaModelBuilder Display
# ============================================================================

println()
println("="^60)
println("📋 3. EXAMODELBUILDER DISPLAY")
println("="^60)
println()

println("🟢 julia> # ExaModelBuilder also requires a function")
println("🟢 julia> exa_builder = CTSolvers.Optimization.ExaModelBuilder(objective_func)")
exa_builder = CTSolvers.Optimization.ExaModelBuilder(objective_func)
println("📋 ExaModelBuilder created:")
println(exa_builder)
println()

println("🟢 julia> display(exa_builder)")
println("📋 ExaModelBuilder (pretty display):")
display(exa_builder)
println()

# ============================================================================
# 4. Builder Display and Properties
# ============================================================================

println()
println("="^60)
println("📋 4. BUILDER DISPLAY AND PROPERTIES")
println("="^60)
println()

println("🟢 julia> # Show builder properties")
println("🟢 julia> typeof(adnlp_builder)")
println("📋 ADNLPModelBuilder type:")
println("  ", typeof(adnlp_builder))
println()

println("🟢 julia> typeof(exa_builder)")
println("📋 ExaModelBuilder type:")
println("  ", typeof(exa_builder))
println()

println("🟢 julia> # Check if builders are model builders")
println("🟢 julia> adnlp_builder isa CTSolvers.Optimization.AbstractModelBuilder")
println("📋 ADNLPModelBuilder is model builder:")
println("  ", adnlp_builder isa CTSolvers.Optimization.AbstractModelBuilder)
println()

println("🟢 julia> exa_builder isa CTSolvers.Optimization.AbstractModelBuilder")
println("📋 ExaModelBuilder is model builder:")
println("  ", exa_builder isa CTSolvers.Optimization.AbstractModelBuilder)
println()

# ============================================================================
# 5. Builder Introspection
# ============================================================================

println()
println("="^60)
println("📋 5. BUILDER INTROSPECTION")
println("="^60)
println()

println("🟢 julia> # Note: Optimization builders don't implement Strategy interface")
println("🟢 julia> # They are simpler types that just store the objective function")
println()

println("🟢 julia> # Show fieldnames of builders")
println("🟢 julia> fieldnames(typeof(adnlp_builder))")
println("📋 ADNLPModelBuilder fieldnames:")
println("  ", fieldnames(typeof(adnlp_builder)))
println()

println("🟢 julia> fieldnames(typeof(exa_builder))")
println("📋 ExaModelBuilder fieldnames:")
println("  ", fieldnames(typeof(exa_builder)))
println()

println("🟢 julia> # Access the stored function")
println("🟢 julia> adnlp_builder.f")
println("📋 ADNLPModelBuilder function:")
println("  ", adnlp_builder.f)
println()

# ============================================================================
# 6. Builder Construction with Options
# ============================================================================

println()
println("="^60)
println("📋 6. BUILDER CONSTRUCTION WITH OPTIONS")
println("="^60)
println()

println("🟢 julia> # Note: Options are passed when building the model, not when creating the builder")
println("🟢 julia> # The builder itself just stores the objective function")
println()

println("🟢 julia> # Create builders with different objective functions")
println("🟢 julia> rosenbrock_func = x -> (1 - x[1])^2 + 100(x[2] - x[1]^2)^2")
rosenbrock_func = x -> (1 - x[1])^2 + 100(x[2] - x[1]^2)^2
println("🟢 julia> rosenbrock_builder = CTSolvers.Optimization.ADNLPModelBuilder(rosenbrock_func)")
rosenbrock_builder = CTSolvers.Optimization.ADNLPModelBuilder(rosenbrock_func)
println("📋 Rosenbrock ADNLPModelBuilder:")
println(rosenbrock_builder)
println()

println("🟢 julia> # Test building a model with options")
println("� julia> initial_guess = [0.0, 0.0]")
initial_guess = [0.0, 0.0]
println("🟢 julia> nlp_model = CTSolvers.Optimization.build_model(adnlp_builder, initial_guess; show_time=true, backend=:optimized)")
try
    nlp_model = CTSolvers.Optimization.build_model(adnlp_builder, initial_guess; show_time=true, backend=:optimized)
    println("📋 Built NLP model:")
    println("  Type: ", typeof(nlp_model))
    println("  Variables: ", nlp_model.meta.nvar)
    println("  Constraints: ", nlp_model.meta.ncon)
catch e
    println("⚠️  Model building error:")
    println("  ", typeof(e), ": ", e)
end
println()

# ============================================================================
# 7. Builder Comparison
# ============================================================================

println()
println("="^60)
println("📋 7. BUILDER COMPARISON")
println("="^60)
println()

println("🟢 julia> # Compare different builders")
println("🟢 julia> builders = [adnlp_builder, exa_builder, rosenbrock_builder]")
builders = [adnlp_builder, exa_builder, rosenbrock_builder]

for (i, builder) in enumerate(builders)
    println()
    println("📋 Builder ", i, ": ", typeof(builder))
    println("🟢 julia> typeof(builder)")
    println("  Type: ", typeof(builder))
    
    println("🟢 julia> builder isa CTSolvers.Optimization.AbstractModelBuilder")
    println("  Is model builder: ", builder isa CTSolvers.Optimization.AbstractModelBuilder)
    
    println("🟢 julia> fieldnames(typeof(builder))")
    println("  Fieldnames: ", fieldnames(typeof(builder)))
end
println()

# ============================================================================
# 8. Model Building Examples
# ============================================================================

println()
println("="^60)
println("📋 8. MODEL BUILDING EXAMPLES")
println("="^60)
println()

println("🟢 julia> # Test building models with different builders")
println("🟢 julia> initial_guess_2d = [0.0, 0.0]")
initial_guess_2d = [0.0, 0.0]
println("� julia> initial_guess_5d = zeros(5)")
initial_guess_5d = zeros(5)

println("🟢 julia> # Build with ADNLPModelBuilder")
println("� julia> adnlp_model = CTSolvers.Optimization.build_model(adnlp_builder, initial_guess_5d; show_time=false)")
try
    adnlp_model = CTSolvers.Optimization.build_model(adnlp_builder, initial_guess_5d; show_time=false)
    println("📋 ADNLP model built successfully:")
    println("  Type: ", typeof(adnlp_model))
    println("  Variables: ", adnlp_model.meta.nvar)
    println("  Constraints: ", adnlp_model.meta.ncon)
catch e
    println("⚠️  ADNLP model building error:")
    println("  ", typeof(e), ": ", e)
end
println()

println("🟢 julia> # Build with ExaModelBuilder")
println("🟢 julia> exa_model = CTSolvers.Optimization.build_model(exa_builder, initial_guess_2d; base_type=Float64)")
try
    exa_model = CTSolvers.Optimization.build_model(exa_builder, initial_guess_2d; base_type=Float64)
    println("📋 Exa model built successfully:")
    println("  Type: ", typeof(exa_model))
    println("  Variables: ", exa_model.meta.nvar)
    println("  Constraints: ", exa_model.meta.ncon)
catch e
    println("⚠️  Exa model building error:")
    println("  ", typeof(e), ": ", e)
end
println()

# ============================================================================
# SUMMARY
# ============================================================================

println()
println("="^60)
println("🎯 OPTIMIZATION MODULE DISPLAY DEMO - SUMMARY")
println("="^60)
println()

println("📋 What we demonstrated:")
println("  ✅ Abstract types display")
println("  ✅ ADNLPModelBuilder construction and display")
println("  ✅ ExaModelBuilder construction and display")
println("  ✅ Builder properties and fieldnames")
println("  ✅ Builder introspection (basic)")
println("  ✅ Model building with options")
println("  ✅ Builder comparison")
println("  ✅ Model building examples")

println()
println("🎨 Key optimization features shown:")
println("  🟢 Function-based builder pattern")
println("  📋 Simple builder interface for NLP model construction")
println("  🔹 Backend selection (ADNLP vs Exa)")
println("  ⚠️  Error handling for model building")
println("  ✅ Type-safe construction with options")

println()
println("🚀 All Optimization module display capabilities demonstrated!")
println("   Ready to explore DOCP module next...")
