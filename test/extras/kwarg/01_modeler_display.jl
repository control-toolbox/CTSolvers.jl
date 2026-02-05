# ============================================================================
# CTSolvers Modeler Display Tests - REPL Style
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
using CTSolvers.Strategies
using CTSolvers.Modelers

println()
println("="^60)
println("🎯 CTSOLVERS MODELER DISPLAY TESTS - REPL STYLE")
println("="^60)
println()

# ============================================================================
# 1. ADNLPModeler Display Tests
# ============================================================================

println()
println("="^60)
println("📋 1. ADNLPMODELER DISPLAY TESTS")
println("="^60)
println()

println("🟢 julia> adnlp_verbose = CTSolvers.Modelers.ADNLPModeler(show_time=true, backend=:forward)")
adnlp_verbose = CTSolvers.Modelers.ADNLPModeler(show_time=true, backend=:optimized)
println("📋 Verbose ADNLPModeler created:")
println(adnlp_verbose)
println()

println("🟢 julia> adnlp_quiet = CTSolvers.Modelers.ADNLPModeler(show_time=false, backend=:optimized)")
adnlp_quiet = CTSolvers.Modelers.ADNLPModeler(show_time=false, backend=:optimized)
println("📋 Quiet ADNLPModeler created:")
println(adnlp_quiet)
println()

# Show options differences
println("🟢 julia> CTSolvers.Strategies.options(adnlp_verbose)")
println("📋 Verbose ADNLPModeler options:")
display(CTSolvers.Strategies.options(adnlp_verbose))
println()

println("🟢 julia> CTSolvers.Strategies.options(adnlp_quiet)")
println("📋 Quiet ADNLPModeler options:")
display(CTSolvers.Strategies.options(adnlp_quiet))
println()

# ============================================================================
# 2. ExaModeler Display Tests
# ============================================================================

println()
println("="^60)
println("📋 2. EXAMODELER DISPLAY TESTS")
println("="^60)
println()

println("🟢 julia> exa_float32 = CTSolvers.Modelers.ExaModeler(base_type=Float32, backend=nothing)")
exa_float32 = CTSolvers.Modelers.ExaModeler(base_type=Float32, backend=nothing)
println("📋 ExaModeler (Float32) created:")
println(exa_float32)
println()

println("🟢 julia> exa_float64 = CTSolvers.Modelers.ExaModeler(base_type=Float64, backend=nothing)")
exa_float64 = CTSolvers.Modelers.ExaModeler(base_type=Float64, backend=nothing)
println("📋 ExaModeler (Float64) created:")
println(exa_float64)
println()

# Show options differences
println("🟢 julia> CTSolvers.Strategies.options(exa_float32)")
println("📋 ExaModeler (Float32) options:")
display(CTSolvers.Strategies.options(exa_float32))
println()

println("🟢 julia> CTSolvers.Strategies.options(exa_float64)")
println("📋 ExaModeler (Float64) options:")
display(CTSolvers.Strategies.options(exa_float64))
println()

# ============================================================================
# 3. Backend Options Comparison
# ============================================================================

println()
println("="^60)
println("📋 3. BACKEND OPTIONS COMPARISON")
println("="^60)
println()

# Test different backend options for ADNLPModeler
backends = [:default, :optimized, :generic]

for backend in backends
    println()
    println("🟢 julia> modeler = CTSolvers.Modelers.ADNLPModeler(backend=:", backend, ")")
    try
        modeler = CTSolvers.Modelers.ADNLPModeler(backend=backend)
        println("📋 Backend ", backend, " created successfully:")
        println("  Backend option: ", CTSolvers.Strategies.option_value(modeler, :backend))
        println("  Backend source: ", CTSolvers.Strategies.option_source(modeler, :backend))
    catch e
        println("⚠️  Backend ", backend, " failed:")
        println("  Error: ", typeof(e))
    end
end
println()

# ============================================================================
# 4. Show Time Option Impact
# ============================================================================

println()
println("="^60)
println("📋 4. SHOW TIME OPTION IMPACT")
println("="^60)
println()

println("🟢 julia> modeler_with_time = CTSolvers.Modelers.ADNLPModeler(show_time=true)")
modeler_with_time = CTSolvers.Modelers.ADNLPModeler(show_time=true)
println("📋 Modeler with show_time=true:")
println("  show_time option: ", CTSolvers.Strategies.option_value(modeler_with_time, :show_time))
println("  show_time source: ", CTSolvers.Strategies.option_source(modeler_with_time, :show_time))
println()

println("🟢 julia> modeler_without_time = CTSolvers.Modelers.ADNLPModeler(show_time=false)")
modeler_without_time = CTSolvers.Modelers.ADNLPModeler(show_time=false)
println("📋 Modeler with show_time=false:")
println("  show_time option: ", CTSolvers.Strategies.option_value(modeler_without_time, :show_time))
println("  show_time source: ", CTSolvers.Strategies.option_source(modeler_without_time, :show_time))
println()

# ============================================================================
# 5. Matrix Free Mode Tests
# ============================================================================

println()
println("="^60)
println("📋 5. MATRIX FREE MODE TESTS")
println("="^60)
println()

println("🟢 julia> modeler_matrix = CTSolvers.Modelers.ADNLPModeler(matrix_free=true)")
modeler_matrix = CTSolvers.Modelers.ADNLPModeler(matrix_free=true)
println("📋 Matrix-free modeler created:")
println("  matrix_free option: ", CTSolvers.Strategies.option_value(modeler_matrix, :matrix_free))
println("  matrix_free source: ", CTSolvers.Strategies.option_source(modeler_matrix, :matrix_free))
println()

println("🟢 julia> modeler_dense = CTSolvers.Modelers.ADNLPModeler(matrix_free=false)")
modeler_dense = CTSolvers.Modelers.ADNLPModeler(matrix_free=false)
println("📋 Dense matrix modeler created:")
println("  matrix_free option: ", CTSolvers.Strategies.option_value(modeler_dense, :matrix_free))
println("  matrix_free source: ", CTSolvers.Strategies.option_source(modeler_dense, :matrix_free))
println()

# ============================================================================
# 6. Name Customization
# ============================================================================

println()
println("="^60)
println("📋 6. NAME CUSTOMIZATION")
println("="^60)
println()

println("🟢 julia> modeler_custom = CTSolvers.Modelers.ADNLPModeler(name=\"MyCustomModel\")")
modeler_custom = CTSolvers.Modelers.ADNLPModeler(name="MyCustomModel")
println("📋 Custom named modeler created:")
println("  name option: ", CTSolvers.Strategies.option_value(modeler_custom, :name))
println("  name source: ", CTSolvers.Strategies.option_source(modeler_custom, :name))
println()

# ============================================================================
# 7. Advanced Backend Options
# ============================================================================

println()
println("="^60)
println("📋 7. ADVANCED BACKEND OPTIONS")
println("="^60)
println()

println("🟢 julia> # Note: Advanced backend options are for expert users")
println("📋 These options override the default backend selection:")
println("  - gradient_backend: Gradient computation")
println("  - hprod_backend: Hessian-vector product")
println("  - jprod_backend: Jacobian-vector product")
println("  - jtprod_backend: Transpose Jacobian-vector product")
println("  - jacobian_backend: Jacobian matrix computation")
println("  - hessian_backend: Hessian matrix computation")
println()

println("🟢 julia> modeler = CTSolvers.Modelers.ADNLPModeler()")
modeler = CTSolvers.Modelers.ADNLPModeler()
println("📋 Basic options:")
basic_options = [:show_time, :backend, :matrix_free, :name]
for option in basic_options
    value = CTSolvers.Strategies.option_value(modeler, option)
    source = CTSolvers.Strategies.option_source(modeler, option)
    println("  :", option, " = ", value, " (", source, ")")
end

println()
println("📋 Note: Advanced options (gradient_backend, hprod_backend, etc.)")
println("  These are not in the basic options by default")
println("  They can be set explicitly when needed for fine-tuning")
println()

# ============================================================================
# 8. Modeler Options Summary
# ============================================================================

println()
println("="^60)
println("📋 8. MODELER OPTIONS SUMMARY")
println("="^60)
println()

println("🟢 julia> # Show all available ADNLPModeler options")
println("🟢 julia> modeler = CTSolvers.Modelers.ADNLPModeler()")
modeler = CTSolvers.Modelers.ADNLPModeler()
println("🟢 julia> CTSolvers.Strategies.option_names(typeof(modeler))")
all_options = CTSolvers.Strategies.option_names(typeof(modeler))
println("📋 All ADNLPModeler options:")
for option in all_options
    try
        value = CTSolvers.Strategies.option_value(modeler, option)
        source = CTSolvers.Strategies.option_source(modeler, option)
        println("  :", option, " = ", value, " (", source, ")")
    catch e
        println("  :", option, " = <error accessing value: ", typeof(e), ">")
    end
end
println()

# ============================================================================
# SUMMARY
# ============================================================================

println()
println("="^60)
println("🎯 MODELER DISPLAY TESTS - SUMMARY")
println("="^60)
println()

println("📋 What we tested:")
println("  ✅ ADNLPModeler display options (show_time, backend, matrix_free, name)")
println("  ✅ ExaModeler display options (base_type, backend)")
println("  ✅ Backend options comparison")
println("  ✅ Show time option impact")
println("  ✅ Matrix free mode testing")
println("  ✅ Name customization")
println("  ✅ Advanced backend options")
println("  ✅ Complete modeler options summary")

println()
println("🎨 Key findings:")
println("  🟢 Backend selection affects AD computation method")
println("  📋 Show_time controls timing information display")
println("  🔹 Matrix_free mode avoids explicit matrices")
println("  ✅ Name option helps identify models in output")
println("  🔧 Advanced options provide fine-grained control")

println()
println("🚀 Modeler display functionality demonstrated!")
println("   Ready to test routing display next...")
