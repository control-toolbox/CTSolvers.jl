module TestJET

using Test: Test
using JET: JET
using CTSolvers: CTSolvers

# Trigger extension loading so JET's static scan sees the concrete strategy
# implementations (Solvers.Ipopt/MadNLP/MadNCL/Uno, Integrators.SciML,
# Modelers.ADNLP) that live in ext/, not just the abstract contracts in src/.
using NLPModelsIpopt: NLPModelsIpopt
using MadNLP: MadNLP
using MadNCL: MadNCL
using UnoSolver: UnoSolver
using NLPModels: NLPModels
using ADNLPModels: ADNLPModels
using DiffEqBase: DiffEqBase
using SciMLBase: SciMLBase
using OrdinaryDiffEqTsit5: OrdinaryDiffEqTsit5

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

function test_jet()
    Test.@testset "JET" verbose = VERBOSE showtiming = SHOWTIMING begin
        JET.test_package(CTSolvers; target_modules=(CTSolvers,))
    end
end

end # module TestJET

# CRITICAL: redefine in outer scope so the test runner can call it
test_jet() = TestJET.test_jet()
