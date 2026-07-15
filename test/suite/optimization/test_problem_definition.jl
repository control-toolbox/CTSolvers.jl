module TestProblemDefinition

using Test: Test
import CTSolvers.Optimization
import CTSolvers.Modelers
import CTBase.Strategies
using CUDA: CUDA

include(joinpath(@__DIR__, "..", "..", "problems", "TestProblems.jl"))
import .TestProblems

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

"""
    test_problem_definition()

🧪 Contract test for `test/problems/problems_definition.jl`'s `Optimization.build_model`
methods: every modeler option (in particular `:backend`) must reach the wrapped
`build_adnlp_model`/`build_exa_model` closure, not just `:base_type`.

Uses fake builder closures that record their kwargs instead of building a real NLP
model, so the forwarding contract is checked on CPU-only CI — no functional CUDA
required — unlike the end-to-end GPU solves in `test_madnlp_extension.jl` /
`test_madncl_extension.jl`, which are skipped unless real GPU hardware is present.
This is the regression test for the bug where `Modelers.Exa{GPU}`'s `:backend`
option was silently dropped, so GPU-strategy tests kept building CPU-resident
models without any test noticing on CPU-only CI.
"""
function test_problem_definition()
    Test.@testset "Problem definition — modeler option forwarding" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ====================================================================
        # CONTRACT TESTS - Exa modeler
        # ====================================================================

        Test.@testset "Exa modeler forwards backend (GPU)" begin
            received = Ref{Any}(nothing)
            build_exa = (base_type, initial_guess; kwargs...) -> begin
                received[] = (base_type, NamedTuple(kwargs))
                return initial_guess
            end
            prob = TestProblems.OptimizationProblem(nothing, build_exa)

            modeler = Modelers.Exa{Strategies.GPU}()
            Optimization.build_model(prob, [1.0], modeler)

            base_type, kwargs = received[]
            Test.@test base_type == Float64
            Test.@test haskey(kwargs, :backend)
            Test.@test kwargs[:backend] === modeler[:backend]
            Test.@test modeler[:backend] isa CUDA.CUDABackend
        end

        Test.@testset "Exa modeler forwards backend (CPU)" begin
            received = Ref{Any}(nothing)
            build_exa = (base_type, initial_guess; kwargs...) -> begin
                received[] = (base_type, NamedTuple(kwargs))
                return initial_guess
            end
            prob = TestProblems.OptimizationProblem(nothing, build_exa)

            modeler = Modelers.Exa{Strategies.CPU}()
            Optimization.build_model(prob, [1.0], modeler)

            base_type, kwargs = received[]
            Test.@test base_type == Float64
            Test.@test kwargs[:backend] === nothing
        end

        # ====================================================================
        # CONTRACT TESTS - ADNLP modeler
        # ====================================================================

        Test.@testset "ADNLP modeler forwards its options" begin
            received = Ref{Any}(nothing)
            build_adnlp = (initial_guess; kwargs...) -> begin
                received[] = NamedTuple(kwargs)
                return initial_guess
            end
            prob = TestProblems.OptimizationProblem(build_adnlp, nothing)

            modeler = Modelers.ADNLP()
            Optimization.build_model(prob, [1.0], modeler)

            kwargs = received[]
            Test.@test haskey(kwargs, :backend)
            Test.@test kwargs[:backend] === modeler[:backend]
        end
    end
end

end # module

test_problem_definition() = TestProblemDefinition.test_problem_definition()
