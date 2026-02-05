# Quick test for strict/permissive validation system
# This is a temporary test file to verify the implementation works

using Test
using CTSolvers
using CTSolvers.Strategies
using CTSolvers.Solvers
using CTBase: Exceptions
using NLPModelsIpopt  # Load extension

println("\n" * "="^70)
println("QUICK TEST: Strict/Permissive Validation System")
println("="^70)

# Test with IpoptSolver
try
    
    println("\n✓ Testing with IpoptSolver...")
    
    # Test 1: Strict mode (default) - should reject unknown option
    println("\n1. Testing strict mode (default) - unknown option should be rejected")
    try
        solver = Solvers.IpoptSolver(unknown_option=123)
        println("  ✗ FAILED: Should have thrown an error")
        exit(1)
    catch e
        if e isa Exceptions.IncorrectArgument
            println("  ✓ PASSED: Unknown option rejected in strict mode")
            println("    Error message preview: ", split(string(e), '\n')[1])
        else
            println("  ✗ FAILED: Wrong exception type: ", typeof(e))
            rethrow(e)
        end
    end
    
    # Test 2: Strict mode explicit - should reject unknown option
    println("\n2. Testing strict mode (explicit) - unknown option should be rejected")
    try
        solver = Solvers.IpoptSolver(unknown_option=123; mode=:strict)
        println("  ✗ FAILED: Should have thrown an error")
        exit(1)
    catch e
        if e isa Exceptions.IncorrectArgument
            println("  ✓ PASSED: Unknown option rejected in explicit strict mode")
        else
            println("  ✗ FAILED: Wrong exception type: ", typeof(e))
            rethrow(e)
        end
    end
    
    # Test 3: Permissive mode - should accept unknown option with warning
    println("\n3. Testing permissive mode - unknown option should be accepted with warning")
    solver = Solvers.IpoptSolver(max_iter=10, custom_option=123; mode=:permissive)
    opts = Strategies.options_dict(solver)
    
    if haskey(opts, :custom_option) && opts[:custom_option] == 123
        println("  ✓ PASSED: Unknown option accepted in permissive mode")
        println("    custom_option value: ", opts[:custom_option])
    else
        println("  ✗ FAILED: Unknown option not found in options")
        exit(1)
    end
    
    # Test 4: Known option should work in both modes
    println("\n4. Testing known option in strict mode")
    solver_strict = Solvers.IpoptSolver(max_iter=100)
    opts_strict = Strategies.options_dict(solver_strict)
    
    if opts_strict[:max_iter] == 100
        println("  ✓ PASSED: Known option works in strict mode")
    else
        println("  ✗ FAILED: Known option not set correctly")
        exit(1)
    end
    
    println("\n5. Testing known option in permissive mode")
    solver_perm = Solvers.IpoptSolver(max_iter=200; mode=:permissive)
    opts_perm = Strategies.options_dict(solver_perm)
    
    if opts_perm[:max_iter] == 200
        println("  ✓ PASSED: Known option works in permissive mode")
    else
        println("  ✗ FAILED: Known option not set correctly")
        exit(1)
    end
    
    # Test 6: Invalid mode should throw ArgumentError
    println("\n6. Testing invalid mode parameter")
    try
        solver = Solvers.IpoptSolver(max_iter=10; mode=:invalid)
        println("  ✗ FAILED: Should have thrown ArgumentError")
        exit(1)
    catch e
        if e isa ArgumentError
            println("  ✓ PASSED: Invalid mode rejected with ArgumentError")
        else
            println("  ✗ FAILED: Wrong exception type: ", typeof(e))
            rethrow(e)
        end
    end
    
    # Test 7: Type validation should work in both modes
    println("\n7. Testing type validation in permissive mode")
    try
        solver = Solvers.IpoptSolver(max_iter="not_an_integer"; mode=:permissive)
        println("  ✗ FAILED: Should have thrown type validation error")
        exit(1)
    catch e
        if e isa Exceptions.IncorrectArgument
            println("  ✓ PASSED: Type validation works in permissive mode")
        else
            println("  ✗ FAILED: Wrong exception type: ", typeof(e))
            rethrow(e)
        end
    end
    
    println("\n" * "="^70)
    println("✓ ALL QUICK TESTS PASSED!")
    println("="^70 * "\n")
    
catch e
    if e isa ArgumentError && occursin("NLPModelsIpopt", string(e))
        println("\n⚠ Skipping IpoptSolver tests (NLPModelsIpopt not available)")
        println("  This is expected if Ipopt extension is not loaded")
    else
        println("\n✗ TEST FAILED with error:")
        println(e)
        rethrow(e)
    end
end
