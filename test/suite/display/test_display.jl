module TestDisplay

using Test: Test
using CTBase: CTBase
using CTBase: Strategies
using CTBase: Options
using CTModels: CTModels
using CTSolvers: CTSolvers
using CTSolvers: DOCP
using CTSolvers: Optimization
using ADNLPModels: ADNLPModels
using ExaModels: ExaModels
using NLPModels: NLPModels

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

# ============================================================================
# FAKE TYPES FOR TESTING (TOP-LEVEL)
# ============================================================================

"""
Fake OCP that is not a `CTModels.Models.Model`: summarised by its type name.
"""
struct FakeOCP <: CTModels.AbstractModel
    data::Vector{Float64}
end

"""
Fake discretizer: a real CTBase strategy with one option, so its compact display is the
strategy one.
"""
struct FakeDiscretizer <: DOCP.AbstractDiscretizer
    options::Strategies.StrategyOptions
end

Strategies.id(::Type{FakeDiscretizer}) = :fake_discretizer
Strategies.parameter(::Type{FakeDiscretizer}) = nothing

function Strategies.metadata(::Type{FakeDiscretizer})
    return Strategies.StrategyMetadata(
        Options.OptionDefinition(;
            name=:grid_size, type=Int, default=100, description="Number of steps"
        ),
    )
end

function FakeDiscretizer(; kwargs...)
    return FakeDiscretizer(Strategies.build_strategy_options(FakeDiscretizer; kwargs...))
end

"""
Fake backend cache whose size grows with the grid, like CTDirect's `DOCPCache`.
"""
struct FakeGridCache <: CTBase.Core.AbstractCache
    grid::Vector{Float64}
    bounds::Vector{Float64}
end

FakeGridCache(n::Int) = FakeGridCache(collect(range(0, 1; length=n)), fill(-Inf, 3n))

"""
Fake optimization problem that is not a `DiscretizedModel`: summarised by its type name.
"""
struct FakeProblem <: Optimization.AbstractOptimizationProblem
    data::Vector{Float64}
end

"""
Fake NLP model that is not an `NLPModels.AbstractNLPModel`: summarised by its type name.
"""
struct FakeNLP
    x0::Vector{Float64}
end

# Functions of the real CTModels models (top-level, never closures inside test functions)
double_integrator!(r, t, x, u, v) = (r .= [x[2], u])
energy(t, x, u, v) = 0.5 * u^2
decay!(r, t, x, u, v) = (r .= -x)
final_state(x0, xf, v) = xf[1]
pure_control!(r, t, x, u, v) = (r .= u)
duration(x0, xf, v) = v[2] - v[1]
minimum_time(x0, xf, v) = v

# Real CTModels models covering every branch of the problem summary
function fixed_times_ocp()
    pre = CTModels.Building.PreModel()
    CTModels.Building.state!(pre, 2)
    CTModels.Building.control!(pre, 1)
    CTModels.Building.time!(pre; t0=0, tf=1)
    CTModels.Building.dynamics!(pre, double_integrator!)
    CTModels.Building.objective!(pre, :min; lagrange=energy)
    CTModels.Building.definition!(
        pre,
        quote end,
    )
    CTModels.Building.time_dependence!(pre; autonomous=true)
    return CTModels.Building.build(pre)
end

function free_final_time_ocp()
    pre = CTModels.Building.PreModel()
    CTModels.Building.variable!(pre, 1, "tf")
    CTModels.Building.state!(pre, 2)
    CTModels.Building.control!(pre, 1)
    CTModels.Building.time!(pre; t0=0, indf=1)
    CTModels.Building.dynamics!(pre, double_integrator!)
    CTModels.Building.objective!(pre, :min; mayer=minimum_time)
    CTModels.Building.definition!(
        pre,
        quote end,
    )
    CTModels.Building.time_dependence!(pre; autonomous=true)
    return CTModels.Building.build(pre)
end

function free_times_ocp()
    pre = CTModels.Building.PreModel()
    CTModels.Building.variable!(pre, 2, "w")
    CTModels.Building.state!(pre, 12)
    CTModels.Building.control!(pre, 12)
    CTModels.Building.time!(pre; ind0=1, indf=2)
    CTModels.Building.dynamics!(pre, pure_control!)
    CTModels.Building.objective!(pre, :min; mayer=duration)
    CTModels.Building.definition!(
        pre,
        quote end,
    )
    CTModels.Building.time_dependence!(pre; autonomous=true)
    return CTModels.Building.build(pre)
end

function control_free_ocp()
    pre = CTModels.Building.PreModel()
    CTModels.Building.state!(pre, 1)
    CTModels.Building.time!(pre; t0=0.0, tf=2.5)
    CTModels.Building.dynamics!(pre, decay!)
    CTModels.Building.objective!(pre, :min; mayer=final_state)
    CTModels.Building.definition!(
        pre,
        quote end,
    )
    CTModels.Building.time_dependence!(pre; autonomous=true)
    return CTModels.Building.build(pre)
end

# Real NLP models
sum_of_squares(x) = sum(x .^ 2)
linear_constraint(x) = [x[1] + x[2]]

adnlp_model(n::Int) = ADNLPModels.ADNLPModel(sum_of_squares, zeros(n))

function constrained_adnlp_model()
    return ADNLPModels.ADNLPModel(sum_of_squares, zeros(3), linear_constraint, [1.0], [1.0])
end

function exa_model(n::Int)
    core = ExaModels.ExaCore(Float64; concrete=Val(true))
    ExaModels.@add_var(core, x, n; start=0.0)
    ExaModels.@add_obj(core, x[i]^2 for i in 1:n)
    ExaModels.@add_con(core, x[i] - x[i + 1] for i in 1:(n - 1))
    return ExaModels.ExaModel(core)
end

# Display helpers
plain(x) = sprint(show, MIME"text/plain"(), x)
compact(x) = sprint(show, x)
summary_line(x) = sprint(Optimization._summary_line, x)
colored(x) = sprint(show, MIME"text/plain"(), x; context=:color => true)
strip_ansi(s) = replace(s, r"\e\[[0-9;]*m" => "")

# ============================================================================
# TEST FUNCTION
# ============================================================================

function test_display()
    Test.@testset "Display" verbose = VERBOSE showtiming = SHOWTIMING begin

        # ====================================================================
        # UNIT TESTS - Display helpers
        # ====================================================================

        Test.@testset "Unit: helpers" begin
            Test.@testset "_space" begin
                Test.@test DOCP._space(1) == "R"
                Test.@test DOCP._space(2) == "R²"
                Test.@test DOCP._space(10) == "R¹⁰"
                Test.@test DOCP._space(1234567890) == "R¹²³⁴⁵⁶⁷⁸⁹⁰"
            end

            Test.@testset "_type_name drops type parameters" begin
                Test.@test Optimization._type_name(Optimization.NoCache) ==
                    "CTSolvers.Optimization.NoCache"
                Test.@test Optimization._type_name(typeof(adnlp_model(2))) ==
                    "ADNLPModels.ADNLPModel"
                Test.@test Optimization._type_name(Vector{Float64}) == "Core.Array"
            end

            Test.@testset "_summary_line fallback" begin
                Test.@test summary_line(Optimization.NoCache()) ==
                    "CTSolvers.Optimization.NoCache"
                Test.@test summary_line(FakeNLP(zeros(5))) ==
                    Optimization._type_name(FakeNLP)
            end

            Test.@testset "_show_tree" begin
                Test.@test sprint(Optimization._show_tree, "T", ("a" => FakeNLP([1.0]),)) ==
                    "T\n└─ a: " * Optimization._type_name(FakeNLP)
                fields = ("a" => Optimization.NoCache(), "b" => Optimization.NoCache())
                Test.@test sprint(Optimization._show_tree, "T", fields) ==
                    "T\n" *
                           "├─ a: CTSolvers.Optimization.NoCache\n" *
                           "└─ b: CTSolvers.Optimization.NoCache"
            end
        end

        # ====================================================================
        # UNIT TESTS - DiscretizedModel and BuiltModel with fakes
        # ====================================================================

        Test.@testset "Unit: DiscretizedModel" begin
            docp = DOCP.DiscretizedModel(
                FakeOCP(zeros(10)), FakeDiscretizer(; grid_size=50), FakeGridCache(10)
            )

            Test.@test compact(docp) == "DiscretizedModel(FakeDiscretizer(grid_size=50))"
            Test.@test plain(docp) ==
                "DiscretizedModel\n" *
                       "├─ problem: $(Optimization._type_name(FakeOCP))\n" *
                       "├─ discretizer: FakeDiscretizer(grid_size=50)\n" *
                       "└─ cache: $(Optimization._type_name(FakeGridCache))"
            Test.@test sprint(print, docp) == compact(docp)
            Test.@test repr(docp) == compact(docp)
            Test.@test summary_line(docp) == compact(docp)
        end

        Test.@testset "Unit: BuiltModel" begin
            docp = DOCP.DiscretizedModel(
                FakeOCP(zeros(10)), FakeDiscretizer(), FakeGridCache(10)
            )
            built = Optimization.BuiltModel(
                docp, FakeNLP(zeros(10)), Optimization.NoCache()
            )

            Test.@test compact(built) ==
                "BuiltModel(DiscretizedModel(FakeDiscretizer(grid_size=100)), " *
                       "$(Optimization._type_name(FakeNLP)))"
            Test.@test plain(built) ==
                "BuiltModel\n" *
                       "├─ problem: DiscretizedModel(FakeDiscretizer(grid_size=100))\n" *
                       "├─ nlp: $(Optimization._type_name(FakeNLP))\n" *
                       "└─ cache: CTSolvers.Optimization.NoCache"
            Test.@test sprint(print, built) == compact(built)
            Test.@test summary_line(built) == compact(built)
        end

        # ====================================================================
        # CONTRACT TESTS - Generic problem and cache types
        # ====================================================================

        Test.@testset "Contract: any problem, NLP and cache" begin
            # A problem other than DiscretizedModel, an NLP outside NLPModels and a
            # backend cache: all summarised by their type name, never by their contents.
            built = Optimization.BuiltModel(
                FakeProblem(zeros(1000)), FakeNLP(zeros(1000)), FakeGridCache(1000)
            )
            Test.@test plain(built) ==
                "BuiltModel\n" *
                       "├─ problem: $(Optimization._type_name(FakeProblem))\n" *
                       "├─ nlp: $(Optimization._type_name(FakeNLP))\n" *
                       "└─ cache: $(Optimization._type_name(FakeGridCache))"

            # No type parameter in either form, whatever the parameters of the fields.
            docp = DOCP.DiscretizedModel(
                FakeOCP(zeros(2)), FakeDiscretizer(), FakeGridCache(2)
            )
            built = Optimization.BuiltModel(docp, adnlp_model(2), Optimization.NoCache())
            for x in (docp, built), s in (compact(x), plain(x))
                Test.@test !occursin('{', s)
            end

            # The text/plain form has no trailing newline (the REPL adds one).
            Test.@test !endswith(plain(docp), '\n')
            Test.@test !endswith(plain(built), '\n')
        end

        # ====================================================================
        # INTEGRATION TESTS - Real CTModels models and real NLP models
        # ====================================================================

        Test.@testset "Integration: problem summary of a CTModels model" begin
            Test.@test summary_line(fixed_times_ocp()) ==
                "state ∈ R², control ∈ R, times [0, 1]"
            Test.@test summary_line(free_final_time_ocp()) ==
                "state ∈ R², control ∈ R, variable ∈ R, times [0, tf]"
            Test.@test summary_line(free_times_ocp()) ==
                "state ∈ R¹², control ∈ R¹², variable ∈ R², times [w₁, w₂]"
            Test.@test summary_line(control_free_ocp()) == "state ∈ R, times [0.0, 2.5]"

            docp = DOCP.DiscretizedModel(
                fixed_times_ocp(), FakeDiscretizer(; grid_size=200), FakeGridCache(200)
            )
            Test.@test plain(docp) ==
                "DiscretizedModel\n" *
                       "├─ problem: state ∈ R², control ∈ R, times [0, 1]\n" *
                       "├─ discretizer: FakeDiscretizer(grid_size=200)\n" *
                       "└─ cache: $(Optimization._type_name(FakeGridCache))"
        end

        Test.@testset "Integration: NLP sizes (CTSolversNLPModels)" begin
            Test.@test Base.get_extension(CTSolvers, :CTSolversNLPModels) isa Module

            Test.@test summary_line(adnlp_model(3)) ==
                "ADNLPModels.ADNLPModel (nvar=3, ncon=0)"
            Test.@test summary_line(constrained_adnlp_model()) ==
                "ADNLPModels.ADNLPModel (nvar=3, ncon=1)"
            Test.@test summary_line(exa_model(5)) == "ExaModels.ExaModel (nvar=5, ncon=4)"

            docp = DOCP.DiscretizedModel(
                fixed_times_ocp(), FakeDiscretizer(), FakeGridCache(100)
            )
            built = Optimization.BuiltModel(docp, exa_model(5), Optimization.NoCache())
            Test.@test plain(built) ==
                "BuiltModel\n" *
                       "├─ problem: DiscretizedModel(FakeDiscretizer(grid_size=100))\n" *
                       "├─ nlp: ExaModels.ExaModel (nvar=5, ncon=4)\n" *
                       "└─ cache: CTSolvers.Optimization.NoCache"
            Test.@test compact(built) ==
                "BuiltModel(DiscretizedModel(FakeDiscretizer(grid_size=100)), " *
                       "ExaModels.ExaModel (nvar=5, ncon=4))"
        end

        # ====================================================================
        # NON-REGRESSION TESTS - Output size and colors (issue #337)
        # ====================================================================

        Test.@testset "Non-regression: size independent of the grid" begin
            ocp = fixed_times_ocp()
            small = DOCP.DiscretizedModel(ocp, FakeDiscretizer(), FakeGridCache(10))
            large = DOCP.DiscretizedModel(ocp, FakeDiscretizer(), FakeGridCache(100_000))
            Test.@test plain(small) == plain(large)
            Test.@test compact(small) == compact(large)
            Test.@test length(plain(large)) < 200

            # Only the digits of nvar/ncon depend on the NLP size.
            built_small = Optimization.BuiltModel(large, exa_model(10), FakeGridCache(10))
            built_large = Optimization.BuiltModel(
                large, exa_model(10_000), FakeGridCache(100_000)
            )
            Test.@test length(plain(built_large)) - length(plain(built_small)) == 6
            Test.@test length(plain(built_large)) < 250
            Test.@test length(compact(built_large)) < 150
        end

        Test.@testset "Non-regression: colors" begin
            docp = DOCP.DiscretizedModel(
                fixed_times_ocp(), FakeDiscretizer(), FakeGridCache(10)
            )
            built = Optimization.BuiltModel(docp, adnlp_model(3), Optimization.NoCache())
            for x in (docp, built)
                Test.@test !occursin('\e', plain(x))
                Test.@test occursin('\e', colored(x))
                Test.@test strip_ansi(colored(x)) == plain(x)
                Test.@test strip_ansi(sprint(show, x; context=:color => true)) == compact(x)
            end
        end
    end
end

end # module TestDisplay

test_display() = TestDisplay.test_display()
