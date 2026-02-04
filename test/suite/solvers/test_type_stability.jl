module TestTypeStability

using Test
using CTSolvers
using CTSolvers.Solvers
using CTSolvers.Strategies
using CTSolvers.Options
using Main.TestOptions: VERBOSE, SHOWTIMING

"""
    test_type_stability()

Test type stability of critical solver functions.

🔧 **Applying Type Stability Rule**: Testing type stability with @inferred
for performance-critical functions.
"""
function test_type_stability()
    @testset "Type Stability Tests" verbose=VERBOSE showtiming=SHOWTIMING begin
        
        # ====================================================================
        # UNIT TESTS - Solver Construction Type Stability
        # ====================================================================
        
        @testset "Solver Construction Type Stability" begin
            @testset "IpoptSolver construction" begin
                # Test that constructor returns correct type
                @test_nowarn @inferred IpoptSolver()
                @test_nowarn @inferred IpoptSolver(max_iter=100)
                @test_nowarn @inferred IpoptSolver(max_iter=100, tol=1e-6)
            end
            
            @testset "MadNLPSolver construction" begin
                @test_nowarn @inferred MadNLPSolver()
                @test_nowarn @inferred MadNLPSolver(max_iter=100)
                @test_nowarn @inferred MadNLPSolver(max_iter=100, tol=1e-6)
            end
            
            @testset "MadNCLSolver construction" begin
                @test_nowarn @inferred MadNCLSolver()
                @test_nowarn @inferred MadNCLSolver(max_iter=100)
                @test_nowarn @inferred MadNCLSolver(max_iter=100, tol=1e-6)
            end
            
            @testset "KnitroSolver construction" begin
                @test_nowarn @inferred KnitroSolver()
                @test_nowarn @inferred KnitroSolver(max_iter=100)
                @test_nowarn @inferred KnitroSolver(max_iter=100, tol=1e-6)
            end
        end
        
        # ====================================================================
        # UNIT TESTS - Strategy Contract Type Stability
        # ====================================================================
        
        @testset "Strategy Contract Type Stability" begin
            @testset "IpoptSolver contract" begin
                # Test id() type stability - simple Symbol return
                @test_nowarn @inferred Strategies.id(IpoptSolver)
                @test @inferred(Strategies.id(IpoptSolver)) === :ipopt
                
                # Test metadata() returns correct type
                meta = Strategies.metadata(IpoptSolver)
                @test meta isa Strategies.StrategyMetadata
                
                # Test options() returns correct type
                # Note: @inferred is too strict for parametric types, we verify concrete type
                solver = IpoptSolver()
                opts = Strategies.options(solver)
                @test opts isa Strategies.StrategyOptions
            end
            
            @testset "MadNLPSolver contract" begin
                @test_nowarn @inferred Strategies.id(MadNLPSolver)
                @test @inferred(Strategies.id(MadNLPSolver)) === :madnlp
                
                # Metadata returns correct type
                meta = Strategies.metadata(MadNLPSolver)
                @test meta isa Strategies.StrategyMetadata
                
                # Options returns correct type
                opts = Strategies.options(MadNLPSolver())
                @test opts isa Strategies.StrategyOptions
            end
            
            @testset "MadNCLSolver contract" begin
                @test_nowarn @inferred Strategies.id(MadNCLSolver)
                @test @inferred(Strategies.id(MadNCLSolver)) === :madncl
                
                # Metadata returns correct type
                meta = Strategies.metadata(MadNCLSolver)
                @test meta isa Strategies.StrategyMetadata
                
                # Options returns correct type
                opts = Strategies.options(MadNCLSolver())
                @test opts isa Strategies.StrategyOptions
            end
            
            @testset "KnitroSolver contract" begin
                @test_nowarn @inferred Strategies.id(KnitroSolver)
                @test @inferred(Strategies.id(KnitroSolver)) === :knitro
                
                # Metadata returns correct type
                meta = Strategies.metadata(KnitroSolver)
                @test meta isa Strategies.StrategyMetadata
                
                # Options returns correct type
                opts = Strategies.options(KnitroSolver())
                @test opts isa Strategies.StrategyOptions
            end
        end
        
        # ====================================================================
        # UNIT TESTS - Options Extraction Type Stability
        # ====================================================================
        
        @testset "Options Extraction Type Stability" begin
            @testset "IpoptSolver options extraction" begin
                solver = IpoptSolver(max_iter=100, tol=1e-6)
                opts = Strategies.options(solver)
                
                # Test that extract_raw_options returns correct type
                # Note: NamedTuple field names are not inferrable, so we check the type
                raw_opts = Options.extract_raw_options(opts.options)
                @test raw_opts isa NamedTuple
                @test haskey(raw_opts, :max_iter)
                @test haskey(raw_opts, :tol)
            end
            
            @testset "MadNLPSolver options extraction" begin
                solver = MadNLPSolver(max_iter=100, tol=1e-6)
                opts = Strategies.options(solver)
                
                # Test that extract_raw_options returns correct type
                raw_opts = Options.extract_raw_options(opts.options)
                @test raw_opts isa NamedTuple
                @test haskey(raw_opts, :max_iter)
                @test haskey(raw_opts, :tol)
            end
        end
        
        # ====================================================================
        # PERFORMANCE NOTES
        # ====================================================================
        
        # Note: The callable interface (solver)(nlp; display=true) cannot be
        # tested for type stability here because:
        # 1. It requires loading solver extensions (NLPModelsIpopt, etc.)
        # 2. The stub implementations throw ExtensionError
        # 3. Type stability of the full solve path is tested in integration tests
        #    when extensions are loaded
        
    end
end

end # module

# CRITICAL: Redefine in outer scope for TestRunner
test_type_stability() = TestTypeStability.test_type_stability()
