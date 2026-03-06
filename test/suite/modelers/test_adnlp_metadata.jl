module TestADNLPMetadata

import Test
import CTBase.Exceptions
import CTSolvers.Modelers
import CTSolvers.Strategies
import CTSolvers.Options
import ADNLPModels

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

"""
    test_adnlp_metadata()

🧪 **Applying Testing Rule**: Unit Tests for ADNLP metadata and id()

Tests uncovered lines in adnlp.jl:
- Line 14: __adnlp_model_backend()
- Line 134: Strategies.id()
"""
function test_adnlp_metadata()
    Test.@testset "ADNLP Metadata" verbose=VERBOSE showtiming=SHOWTIMING begin
        
        # ====================================================================
        # UNIT TESTS - Strategies.id()
        # ====================================================================
        
        Test.@testset "Strategies.id()" begin
            # Test id() for ADNLP type (covers adnlp.jl:134)
            Test.@test Strategies.id(Modelers.ADNLP) === :adnlp
            
            # Test with Type{<:ADNLP}
            Test.@test Strategies.id(typeof(Modelers.ADNLP())) === :adnlp
        end
        
        # ====================================================================
        # UNIT TESTS - Default Backend Function
        # ====================================================================
        
        Test.@testset "Default Backend" begin
            # Test __adnlp_model_backend() (covers adnlp.jl:14)
            # This is tested indirectly through metadata
            
            meta = Strategies.metadata(Modelers.ADNLP)
            Test.@test :backend in keys(meta)
            
            backend_def = meta[:backend]
            Test.@test Options.default(backend_def) === :optimized
        end
        
        # ====================================================================
        # UNIT TESTS - Metadata Options
        # ====================================================================
        
        Test.@testset "Metadata Options" begin
            meta = Strategies.metadata(Modelers.ADNLP)
            
            # Test all expected options are present
            Test.@test :show_time in keys(meta)
            Test.@test :backend in keys(meta)
            Test.@test :matrix_free in keys(meta)
            Test.@test :name in keys(meta)
            
            # Test advanced backend overrides
            Test.@test :gradient_backend in keys(meta)
            Test.@test :hprod_backend in keys(meta)
            Test.@test :jprod_backend in keys(meta)
            Test.@test :jtprod_backend in keys(meta)
            Test.@test :jacobian_backend in keys(meta)
            Test.@test :hessian_backend in keys(meta)
            Test.@test :ghjvprod_backend in keys(meta)
            
            # Test option types
            Test.@test Options.type(meta[:show_time]) == Bool
            Test.@test Options.type(meta[:backend]) == Symbol
            Test.@test Options.type(meta[:matrix_free]) == Bool
            Test.@test Options.type(meta[:name]) == String
        end
        
        # ====================================================================
        # UNIT TESTS - Constructor with Deprecated Alias
        # ====================================================================
        
        Test.@testset "Deprecated Alias - adnlp_backend" begin
            # Test constructor with deprecated adnlp_backend alias
            redirect_stderr(devnull) do
                Test.@test_logs (:warn, r"adnlp_backend is deprecated") Modelers.ADNLP(adnlp_backend=:optimized)
                
                modeler = Modelers.ADNLP(adnlp_backend=:optimized)
                Test.@test modeler isa Modelers.ADNLP
            end
            
            # Test without deprecated alias (should not warn)
            Test.@test_nowarn Modelers.ADNLP(backend=:optimized)
        end
        
        # ====================================================================
        # UNIT TESTS - Backend Validation
        # ====================================================================
        
        Test.@testset "Backend Validation" begin
            # Test valid backends
            Test.@test_nowarn Modelers.ADNLP(backend=:optimized)
            Test.@test_nowarn Modelers.ADNLP(backend=:default)
            Test.@test_nowarn Modelers.ADNLP(backend=:generic)
            
            # Test invalid backend (should throw)
            redirect_stderr(devnull) do
                Test.@test_throws Exceptions.IncorrectArgument Modelers.ADNLP(backend=:invalid_backend)
            end
        end
        
        # ====================================================================
        # UNIT TESTS - Advanced Backend Overrides
        # ====================================================================
        
        Test.@testset "Advanced Backend Overrides" begin
            # Test with nothing (use default)
            Test.@test_nowarn Modelers.ADNLP(gradient_backend=nothing)
            
            # Test with Type (ADNLPModels constructs it)
            Test.@test_nowarn Modelers.ADNLP(gradient_backend=ADNLPModels.ForwardDiffADGradient)
            
            # Note: Testing with instances requires specific arguments that vary by backend
            # These are tested in integration tests with actual problems
        end
        
        # ====================================================================
        # UNIT TESTS - Matrix-Free and Name Options
        # ====================================================================
        
        Test.@testset "Matrix-Free and Name Options" begin
            # Test matrix_free option
            modeler_mf = Modelers.ADNLP(matrix_free=true)
            Test.@test modeler_mf isa Modelers.ADNLP
            
            opts_dict = Strategies.options_dict(modeler_mf)
            Test.@test haskey(opts_dict, :matrix_free)
            Test.@test opts_dict[:matrix_free] === true
            
            # Test name option
            modeler_named = Modelers.ADNLP(name="MyProblem")
            Test.@test modeler_named isa Modelers.ADNLP
            
            opts_dict_named = Strategies.options_dict(modeler_named)
            Test.@test haskey(opts_dict_named, :name)
            Test.@test opts_dict_named[:name] == "MyProblem"
        end
    end
end

end # module

test_adnlp_metadata() = TestADNLPMetadata.test_adnlp_metadata()
