"""
Minimal test to understand MadNLP behavior with Float32/Float64
"""

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

using MadNLP
using MadNLPMumps
using ExaModels

println("="^80)
println("Testing MadNLP with Float64 options on Float32 and Float64 models")
println("="^80)

# Simple problem: min (x-1)^2
function create_problem(::Type{T}) where T
    m = ExaModels.ExaCore(T; minimize=true)
    x = ExaModels.variable(m, 1; start=[0.0])
    ExaModels.objective(m, (x[1] - 1)^2)
    return ExaModels.ExaModel(m)
end

# Options to test (all in Float64)
options_float64 = Dict{Symbol,Any}(
    :max_iter => 100,
    :tol => 1e-8,
    :acceptable_tol => 1e-6,
    :acceptable_iter => 15,
    :max_wall_time => 1e6,
    :diverging_iterates_tol => 1e20,
    :print_level => MadNLP.ERROR
)

println("\n" * "="^80)
println("Test 1: Float64 model with Float64 options")
println("="^80)
try
    nlp64 = create_problem(Float64)
    println("Model created: $(typeof(nlp64))")
    println("Options passed: $options_float64")
    solver64 = MadNLP.MadNLPSolver(nlp64; options_float64...)
    println("✓ Solver created successfully")
    result64 = MadNLP.solve!(solver64)
    println("✓ Solution successful: status = $(result64.status)")
catch e
    println("✗ ERROR:")
    println(e)
    for (i, frame) in enumerate(stacktrace(catch_backtrace())[1:min(5, end)])
        println("  [$i] $frame")
    end
end

println("\n" * "="^80)
println("Test 2: Float32 model with Float64 options")
println("="^80)
try
    nlp32 = create_problem(Float32)
    println("Model created: $(typeof(nlp32))")
    println("Options passed: $options_float64")
    solver32 = MadNLP.MadNLPSolver(nlp32; options_float64...)
    println("✓ Solver created successfully")
    result32 = MadNLP.solve!(solver32)
    println("✓ Solution successful: status = $(result32.status)")
catch e
    println("✗ ERROR:")
    println(e)
    for (i, frame) in enumerate(stacktrace(catch_backtrace())[1:min(5, end)])
        println("  [$i] $frame")
    end
end

println("\n" * "="^80)
println("Test 3: Float32 model with ONLY tol in Float64")
println("="^80)
try
    nlp32 = create_problem(Float32)
    options_minimal = Dict{Symbol,Any}(
        :tol => 1e-8,  # Float64
        :print_level => MadNLP.ERROR
    )
    println("Model created: $(typeof(nlp32))")
    println("Options passed: $options_minimal")
    solver32 = MadNLP.MadNLPSolver(nlp32; options_minimal...)
    println("✓ Solver created successfully")
    result32 = MadNLP.solve!(solver32)
    println("✓ Solution successful: status = $(result32.status)")
catch e
    println("✗ ERROR:")
    println(e)
    for (i, frame) in enumerate(stacktrace(catch_backtrace())[1:min(5, end)])
        println("  [$i] $frame")
    end
end

println("\n" * "="^80)
println("Test 4: Float32 model with explicit Float32 options")
println("="^80)
try
    nlp32 = create_problem(Float32)
    options_float32 = Dict{Symbol,Any}(
        :max_iter => 100,
        :tol => Float32(1e-8),
        :acceptable_tol => Float32(1e-6),
        :acceptable_iter => 15,
        :max_wall_time => Float32(1e6),
        :diverging_iterates_tol => Float32(1e20),
        :print_level => MadNLP.ERROR
    )
    println("Model created: $(typeof(nlp32))")
    println("Options passed: $options_float32")
    solver32 = MadNLP.MadNLPSolver(nlp32; options_float32...)
    println("✓ Solver created successfully")
    result32 = MadNLP.solve!(solver32)
    println("✓ Solution successful: status = $(result32.status)")
catch e
    println("✗ ERROR:")
    println(e)
    for (i, frame) in enumerate(stacktrace(catch_backtrace())[1:min(5, end)])
        println("  [$i] $frame")
    end
end

println("\n" * "="^80)
println("End of tests")
println("="^80)
