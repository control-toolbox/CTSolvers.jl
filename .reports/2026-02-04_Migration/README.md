# CTSolvers.jl - Migration to v0.2.0-beta.1

**Date:** February 4, 2026  
**Version:** 0.2.0-beta.1  
**Status:** Planning Phase  
**Author:** Olivier Cots

---

## Executive Summary

This document outlines the comprehensive migration plan for **CTSolvers.jl**, a Julia package within the control-toolbox ecosystem dedicated to solving optimal control problems. The migration aims to modernize the codebase by integrating new architectural patterns from CTBase v0.18 and CTModels v0.8, while establishing a robust, modular, and extensible solver framework.

### Key Objectives

1. **Architectural Modernization**: Adopt the modular architecture patterns from CTModels.jl
2. **API Alignment**: Ensure compatibility with CTBase v0.18 and CTModels v0.8
3. **Code Integration**: Merge migration resources from `.resources/migration_to_ctsolvers` and `.resources/old`
4. **Quality Assurance**: Implement comprehensive testing and documentation following ecosystem standards
5. **Beta Release**: Deliver a production-ready v0.2.0-beta.1 release

---

## 1. Project Overview

### 1.1 Purpose and Scope

**CTSolvers.jl** provides a unified interface for solving optimal control problems through:

- **Multiple discretization methods** (direct collocation, shooting methods)
- **Flexible modeler backends** (ADNLPModels, ExaModels)
- **Extensible solver integration** (Ipopt, Knitro, MadNLP)
- **Strategy-based optimization** (configurable solution strategies)

The package bridges the gap between high-level optimal control problem definitions (from CTModels) and low-level numerical optimization solvers.

### 1.2 Position in the Ecosystem

```
OptimalControl.jl (User-facing API)
         ↓
    CTModels.jl (Problem modeling)
         ↓
    CTSolvers.jl (Solution strategies) ← THIS PACKAGE
         ↓
    NLP Solvers (Ipopt, MadNLP, etc.)
```

### 1.3 Target Architecture

The package will be organized into **7 core modules**:

1. **DOCP** - Discretized Optimal Control Problem types and operations
2. **Modelers** - Backend modeler implementations (ADNLP, Exa)
3. **Optimization** - General optimization abstractions and builders
4. **Options** - Configuration and options management system
5. **Orchestration** - High-level coordination and method routing
6. **Strategies** - Strategy patterns for solution approaches
7. **Solvers** - Solver integration and CommonSolve API

---

## 2. Current State Analysis

### 2.1 Existing Resources

#### Migration Resources (`.resources/migration_to_ctsolvers/`)

**Source Code:**
- `src/CTModels.jl` - Main module structure (133 lines)
- `src/DOCP/` - 5 files (types, accessors, building, contracts)
- `src/Modelers/` - 5 files (abstract types, ADNLP, Exa, validation)
- `src/Optimization/` - 6 files (abstractions, builders, contracts)
- `src/Options/` - 5 files (extraction, definitions, values)
- `src/Orchestration/` - 4 files (routing, disambiguation, builders)
- `src/Strategies/` - Multiple files (contracts, API, metadata)

**Test Suite:**
- `test/problems/` - 8 test problem definitions
- `test/suite/docp/` - DOCP tests
- `test/suite/modelers/` - Modeler tests (2 files)
- `test/suite/optimization/` - Optimization tests (3 files)
- `test/suite/options/` - Options tests (4 files)
- `test/suite/orchestration/` - Orchestration tests (3 files)
- `test/suite/strategies/` - Strategy tests (9 files)
- `test/suite/extensions/` - Extension tests (MadNLP)
- `test/suite/integration/` - End-to-end tests

**Total:** ~30+ test files with comprehensive coverage

#### Legacy Resources (`.resources/old/`)

**Source Code:**
- `src/CTSolvers.jl` - Minimal module stub (19 lines)
- `src/ctsolvers/` - 3 files (backends, CommonSolve API, stubs)

**Documentation:**
- `docs/make.jl` - Documentation build script
- `docs/src/` - Documentation source files

**Tests:**
- `test/runtests.jl` - Test runner (6436 bytes)
- `test/test_aqua.jl` - Quality checks
- Various test subdirectories

### 2.2 Current Package State

**Project.toml:**
- Version: `0.2.0-beta.1`
- Dependencies: CTBase (0.18), CTModels (0.8), CommonSolve, NLPModels, SolverCore
- Extensions: Ipopt, Knitro, MadNLP, MadNCL
- **Status:** Empty `src/`, `test/`, and `docs/` directories

### 2.3 Dependency Versions

```toml
CTBase = "0.18"
CTModels = "0.8"
CommonSolve = "0.2"
NLPModels = "0.21"
SolverCore = "0.3"
Julia = "1.10"
```

---

## 3. Migration Strategy

### 3.1 Phased Approach

The migration will proceed in **4 phases**:

#### Phase 1: Foundation Setup
- Establish module structure
- Integrate core types and abstractions
- Set up testing infrastructure
- Configure documentation system

#### Phase 2: Core Implementation
- Integrate DOCP module
- Integrate Optimization module
- Integrate Modelers module
- Implement basic contracts

#### Phase 3: Advanced Features
- Integrate Options system
- Integrate Strategies framework
- Integrate Orchestration layer
- Implement Solvers module

#### Phase 4: Quality & Release
- Complete test suite
- Generate documentation
- Run quality checks (Aqua.jl)
- Prepare beta release

### 3.2 Module Integration Order

```
1. Utils (if needed) → Options
2. Optimization → Modelers
3. DOCP
4. Strategies → Orchestration
5. Solvers (CommonSolve integration)
```

**Rationale:** Follow dependency graph to minimize integration issues.

---

## 4. Technical Architecture

### 4.1 Module Structure

```
CTSolvers/
├── src/
│   ├── CTSolvers.jl              # Main module
│   ├── DOCP/
│   │   ├── DOCP.jl               # Module definition
│   │   ├── types.jl              # DiscretizedOptimalControlProblem
│   │   ├── accessors.jl          # Getters and setters
│   │   ├── building.jl           # Construction logic
│   │   └── contract_impl.jl      # Contract implementations
│   ├── Modelers/
│   │   ├── Modelers.jl           # Module definition
│   │   ├── abstract_modeler.jl   # AbstractModeler interface
│   │   ├── adnlp_modeler.jl      # ADNLPModels backend
│   │   ├── exa_modeler.jl        # ExaModels backend
│   │   └── validation.jl         # Input validation
│   ├── Optimization/
│   │   ├── Optimization.jl       # Module definition
│   │   ├── abstract_types.jl     # AbstractOptimizationProblem
│   │   ├── builders.jl           # Model builders
│   │   ├── building.jl           # Build orchestration
│   │   ├── contract.jl           # Contract definitions
│   │   └── solver_info.jl        # Solver metadata
│   ├── Options/
│   │   ├── Options.jl            # Module definition
│   │   ├── option_definition.jl  # Option schema
│   │   ├── option_value.jl       # Value handling
│   │   ├── extraction.jl         # Option extraction API
│   │   └── not_provided.jl       # NotProvided sentinel
│   ├── Orchestration/
│   │   ├── Orchestration.jl      # Module definition
│   │   ├── routing.jl            # Method routing
│   │   ├── disambiguation.jl     # Argument disambiguation
│   │   └── method_builders.jl    # Method construction
│   ├── Strategies/
│   │   ├── Strategies.jl         # Module definition
│   │   ├── contract/             # Strategy contracts
│   │   └── api/                  # Public API
│   └── Solvers/
│       ├── Solvers.jl            # Module definition
│       ├── common_solve_api.jl   # CommonSolve interface
│       └── backends_types.jl     # Backend type definitions
├── test/
│   ├── runtests.jl               # Test runner (CTBase.TestRunner)
│   ├── coverage.jl               # Coverage processing
│   ├── README.md                 # Testing guide
│   ├── problems/
│   │   ├── TestProblems.jl       # Shared test problems
│   │   ├── rosenbrock.jl
│   │   ├── beam.jl
│   │   └── ...
│   └── suite/
│       ├── docp/
│       ├── modelers/
│       ├── optimization/
│       ├── options/
│       ├── orchestration/
│       ├── strategies/
│       ├── extensions/
│       └── integration/
└── docs/
    ├── make.jl                   # Documentation builder
    ├── api_reference.jl          # API reference generator
    └── src/
        └── index.md              # Documentation home
```

### 4.2 Key Design Patterns

#### 4.2.1 Contract-Based Architecture

All modules follow a **contract-first** design:

```julia
# Define abstract interface
abstract type AbstractModeler end

# Define contract (with NotImplemented default)
function build_model(modeler::AbstractModeler, problem, initial_guess)
    throw(NotImplemented("build_model not implemented for $(typeof(modeler))"))
end

# Concrete implementations
struct ADNLPModeler <: AbstractModeler end

function build_model(modeler::ADNLPModeler, problem, initial_guess)
    # Implementation
end
```

#### 4.2.2 Multiple Dispatch

Leverage Julia's multiple dispatch for extensibility:

```julia
# Generic solve interface
solve(problem::AbstractOptimalControlProblem, args...; kwargs...)

# Specialized implementations
solve(problem::DOCP, modeler::ADNLPModeler, solver::IpoptSolver)
solve(problem::DOCP, modeler::ExaModeler, solver::MadNLPSolver)
```

#### 4.2.3 Strategy Pattern

Configurable solution strategies:

```julia
struct DirectCollocationStrategy <: AbstractStrategy
    grid::TimeGrid
    constraints::ConstraintHandling
end

function solve(problem, strategy::DirectCollocationStrategy)
    # Strategy-specific implementation
end
```

### 4.3 CommonSolve Integration

Implement the CommonSolve.jl interface:

```julia
using CommonSolve: solve

function CommonSolve.solve(
    problem::AbstractOptimalControlProblem,
    alg::AbstractSolverAlgorithm;
    kwargs...
)
    # Unified solve interface
end
```

### 4.4 Export Strategy

**Following CTModels.jl Pattern:** CTSolvers.jl will **not** export functions directly from the main module. Instead, all functions and types are accessed via qualified module paths:

```julia
# ✅ Correct: Qualified access
using CTSolvers
CTSolvers.solve(problem, strategy)
CTSolvers.Options.extract_options(config)
CTSolvers.Modelers.ADNLPModeler()

# ❌ Incorrect: Direct exports (not provided)
using CTSolvers
solve(problem, strategy)  # ERROR: solve not defined
```

**Rationale:**
- **Namespace clarity** - Explicit module qualification
- **Avoid conflicts** - No name collisions with other packages
- **Explicit dependencies** - Clear which module provides what
- **Consistency** - Matches CTModels.jl ecosystem pattern

**Module Access Pattern:**
```julia
# Main module provides access to submodules
module CTSolvers

# Submodules are available via qualification
include("Options/Options.jl")
using .Options

include("Modelers/Modelers.jl")
using .Modelers

# Functions are accessed as:
# CTSolvers.solve()
# CTSolvers.Options.extract_options()
# CTSolvers.Modelers.ADNLPModeler()
```

---

## 5. Testing Strategy

### 5.1 Testing Standards

Following `.windsurf/rules/testing.md`:

**Core Principles:**
1. **Contract-First Testing** - Test behavior through public API
2. **Orthogonality** - Test organization ≠ source organization
3. **Isolation** - Unit tests use mocks/fakes
4. **Determinism** - Reproducible tests
5. **Clarity** - Obvious test intent

### 5.2 Test Organization

```
test/suite/
├── docp/              # DOCP module tests
├── modelers/          # Modeler implementations
├── optimization/      # Optimization abstractions
├── options/           # Options system
├── orchestration/     # Orchestration layer
├── strategies/        # Strategy framework
├── extensions/        # Solver extensions (Ipopt, MadNLP)
└── integration/       # End-to-end workflows
```

### 5.3 Test Categories

#### Unit Tests
- Pure logic, deterministic
- Use fake structs for isolation
- Fast execution (<1ms per test)
- No I/O or external dependencies

#### Integration Tests
- Multi-component workflows
- May use temporary directories
- Test component interactions
- Acceptable up to 1s per test

#### Contract Tests
- Verify API contracts
- Use minimal fake implementations
- Test routing and defaults
- Verify Liskov Substitution Principle

#### Extension Tests
- Test solver integrations (Ipopt, Knitro, MadNLP)
- Require optional dependencies
- May be skipped if dependencies unavailable

### 5.4 Test Infrastructure

**Test Runner:** CTBase.TestRunner extension

```julia
# test/runtests.jl
using CTBase
const TestRunner = Base.get_extension(CTBase, :TestRunner)

CTBase.run_tests(;
    args=String.(ARGS),
    testset_name="CTSolvers tests",
    available_tests=("suite/*/test_*",),
    filename_builder=name -> Symbol(:test_, name),
    funcname_builder=name -> Symbol(:test_, name),
    verbose=true,
    showtiming=true,
    test_dir=@__DIR__,
)
```

**Coverage Processing:** CTBase.CoveragePostprocessing extension

```julia
# test/coverage.jl
using CTBase
const CoveragePostprocessing = Base.get_extension(CTBase, :CoveragePostprocessing)

CTBase.process_coverage(;
    src_dir=joinpath(@__DIR__, "..", "src"),
    coverage_dir=joinpath(@__DIR__, "..", "coverage"),
)
```

### 5.5 Quality Checks

**Aqua.jl Integration:**

```julia
# test/suite/meta/test_aqua.jl
using Aqua
using CTSolvers

@testset "Aqua.jl Quality Checks" begin
    Aqua.test_all(CTSolvers;
        ambiguities=false,  # Multiple dispatch expected
        unbound_args=true,
        undefined_exports=true,
        project_extras=true,
        stale_deps=true,
        deps_compat=true,
    )
end
```

---

## 6. Documentation Strategy

### 6.1 Documentation Standards

Following CTModels.jl documentation patterns:

**Structure:**
- `docs/make.jl` - Documenter.jl build script
- `docs/api_reference.jl` - Automatic API reference generation
- `docs/src/index.md` - Package introduction and overview

### 6.2 API Reference Generation

Automatic API documentation from source code:

```julia
# docs/api_reference.jl
using CTBase
const DocumenterReference = Base.get_extension(CTBase, :DocumenterReference)

function with_api_reference(src_dir, ext_dir, callback)
    # Scan source and extension directories
    # Generate API reference pages
    # Pass to callback for makedocs
end
```

### 6.3 Documentation Build

```julia
# docs/make.jl
using Documenter
using CTSolvers
using CTBase

include("api_reference.jl")

with_api_reference(src_dir, ext_dir) do api_pages
    makedocs(;
        sitename="CTSolvers.jl",
        format=Documenter.HTML(;
            repolink="https://github.com/control-toolbox/CTSolvers.jl",
            prettyurls=false,
            assets=[
                asset("https://control-toolbox.org/assets/css/documentation.css"),
                asset("https://control-toolbox.org/assets/js/documentation.js"),
            ],
        ),
        pages=[
            "Introduction" => "index.md",
            "User Guide" => [
                "Getting Started" => "guide/getting_started.md",
                "Solving Problems" => "guide/solving.md",
                "Strategies" => "guide/strategies.md",
            ],
            "API Reference" => api_pages,
        ],
    )
end

deploydocs(;
    repo="github.com/control-toolbox/CTSolvers.jl.git",
    devbranch="main"
)
```

### 6.4 Docstring Standards

Following `.windsurf/rules/docstrings.md`:

```julia
"""
    solve(problem::AbstractOptimalControlProblem, args...; kwargs...)

Solve an optimal control problem using the specified method.

# Arguments
- `problem::AbstractOptimalControlProblem`: The optimal control problem to solve
- `args...`: Additional positional arguments (method-dependent)

# Keywords
- `initial_guess`: Initial guess for the solution
- `method::Symbol`: Solution method (`:direct_collocation`, `:shooting`, etc.)
- `solver`: NLP solver to use (`:ipopt`, `:madnlp`, etc.)

# Returns
- `solution::AbstractOptimalControlSolution`: The computed solution

# Examples
```julia
using CTSolvers, CTModels

# Define problem
ocp = Model(...)

# Solve with direct collocation
sol = solve(ocp; method=:direct_collocation, solver=:ipopt)
```

# See Also
- [`AbstractOptimalControlProblem`](@ref)
- [`AbstractOptimalControlSolution`](@ref)
"""
function solve end
```

---

## 7. Code Quality Standards

### 7.1 Architecture Principles

Following `.windsurf/rules/architecture.md`:

**SOLID Principles:**
1. **Single Responsibility** - Each module has one clear purpose
2. **Open/Closed** - Open for extension, closed for modification
3. **Liskov Substitution** - Subtypes honor parent contracts
4. **Interface Segregation** - Small, focused interfaces
5. **Dependency Inversion** - Depend on abstractions

**Additional Principles:**
- **DRY** - Don't Repeat Yourself
- **KISS** - Keep It Simple, Stupid
- **YAGNI** - You Aren't Gonna Need It

### 7.2 Type Stability

Following `.windsurf/rules/type-stability.md`:

- All performance-critical functions must be type-stable
- Use `@inferred` tests for critical paths
- Monitor allocations in hot loops
- Leverage parametric types for flexibility

### 7.3 Exception Handling

Following `.windsurf/rules/exceptions.md`:

```julia
# Use custom exception types
struct InvalidProblemError <: Exception
    msg::String
end

# Validate inputs
function solve(problem)
    validate_problem(problem) || throw(InvalidProblemError("Invalid problem"))
    # ...
end
```

### 7.4 Performance Guidelines

Following `.windsurf/rules/performance.md`:

- Minimize allocations in inner loops
- Use in-place operations where possible
- Leverage SIMD and GPU when available
- Profile before optimizing

---

## 8. Integration Checklist

### 8.1 Source Code Integration

- [ ] Create `src/CTSolvers.jl` main module (no direct exports)
- [ ] Integrate `DOCP/` module (5 files)
- [ ] Integrate `Modelers/` module (5 files)
- [ ] Integrate `Optimization/` module (6 files)
- [ ] Integrate `Options/` module (5 files)
- [ ] Integrate `Orchestration/` module (4 files)
- [ ] Integrate `Strategies/` module (multiple files)
- [ ] Create `Solvers/` module (new)
- [ ] Review and adapt legacy code from `.resources/old/src/`
- [ ] Ensure qualified module access pattern
- [ ] Verify module loading order

### 8.2 Test Suite Integration

- [ ] Create `test/runtests.jl` with CTBase.TestRunner
- [ ] Create `test/coverage.jl` for coverage processing
- [ ] Create `test/README.md` with testing guide
- [ ] Integrate `test/problems/` (8 files)
- [ ] Integrate `test/suite/docp/` tests
- [ ] Integrate `test/suite/modelers/` tests (2 files)
- [ ] Integrate `test/suite/optimization/` tests (3 files)
- [ ] Integrate `test/suite/options/` tests (4 files)
- [ ] Integrate `test/suite/orchestration/` tests (3 files)
- [ ] Integrate `test/suite/strategies/` tests (9 files)
- [ ] Integrate `test/suite/extensions/` tests
- [ ] Integrate `test/suite/integration/` tests
- [ ] Create `test/suite/meta/test_aqua.jl`
- [ ] Verify all tests pass

### 8.3 Documentation Integration

- [ ] Create `docs/make.jl` build script
- [ ] Create `docs/api_reference.jl` generator
- [ ] Create `docs/src/index.md` introduction
- [ ] Create user guide pages
- [ ] Add examples and tutorials
- [ ] Review legacy documentation from `.resources/old/docs/`
- [ ] Build documentation locally
- [ ] Verify all links work

### 8.4 Quality Assurance

- [ ] Run Aqua.jl quality checks
- [ ] Verify qualified module access (no direct exports)
- [ ] Check for ambiguities
- [ ] Verify dependency compatibility
- [ ] Run type stability tests
- [ ] Check code coverage (target: >90%)
- [ ] Review performance benchmarks
- [ ] Validate exception handling

### 8.5 Release Preparation

- [ ] Update `Project.toml` metadata
- [ ] Update `README.md`
- [ ] Create `CHANGELOG.md` for v0.2.0-beta.1
- [ ] Tag version in git
- [ ] Register with Julia General Registry
- [ ] Update control-toolbox documentation
- [ ] Announce beta release

---

## 9. Risk Assessment

### 9.1 Technical Risks

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| API incompatibility with CTModels v0.8 | High | Medium | Early integration testing, close coordination |
| Type stability issues | Medium | Low | Comprehensive `@inferred` tests, profiling |
| Extension loading failures | Medium | Low | Thorough extension testing, fallback mechanisms |
| Performance regression | Medium | Low | Benchmark suite, performance tests |
| Test suite incompleteness | Low | Medium | Coverage monitoring, systematic test review |

### 9.2 Integration Risks

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Conflicting code from two sources | Medium | Medium | Careful review, prioritize migration_to_ctsolvers |
| Missing dependencies | Low | Low | Verify all imports, test in clean environment |
| Documentation gaps | Low | Medium | Systematic API documentation review |
| Breaking changes for users | High | Low | Beta release, clear migration guide |

### 9.3 Schedule Risks

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Underestimated complexity | Medium | Medium | Phased approach, regular progress reviews |
| Dependency updates | Low | Low | Pin versions, monitor upstream changes |
| Testing bottlenecks | Low | Low | Parallel test execution, incremental testing |

---

## 10. Success Criteria

### 10.1 Functional Requirements

- ✅ All 7 modules integrated and functional
- ✅ CommonSolve.jl interface implemented
- ✅ Support for ADNLPModels and ExaModels backends
- ✅ Extension support for Ipopt, Knitro, MadNLP
- ✅ Strategy-based solution framework operational
- ✅ Options system fully functional

### 10.2 Quality Requirements

- ✅ Test coverage ≥ 90%
- ✅ All Aqua.jl checks pass
- ✅ Zero type instabilities in critical paths
- ✅ Documentation complete with examples
- ✅ Qualified module access pattern implemented
- ✅ No ambiguities in method dispatch

### 10.3 Performance Requirements

- ✅ No performance regression vs. previous version
- ✅ Efficient memory usage (minimal allocations)
- ✅ GPU support functional (via extensions)
- ✅ Solver overhead < 5% of total solve time

### 10.4 Integration Requirements

- ✅ Compatible with CTBase v0.18
- ✅ Compatible with CTModels v0.8
- ✅ Works with OptimalControl.jl
- ✅ Extension system functional
- ✅ CI/CD pipeline operational

---

## 11. Timeline Estimate

### Phase 1: Foundation Setup (2-3 days)
- Module structure creation
- Testing infrastructure
- Documentation setup

### Phase 2: Core Implementation (4-5 days)
- DOCP integration
- Optimization integration
- Modelers integration
- Basic tests

### Phase 3: Advanced Features (4-5 days)
- Options system
- Strategies framework
- Orchestration layer
- Solvers module
- Extension tests

### Phase 4: Quality & Release (2-3 days)
- Complete test suite
- Documentation generation
- Quality checks
- Beta release preparation

**Total Estimated Duration:** 12-16 days

---

## 12. Next Steps

### Immediate Actions

1. **Review and approve** this migration plan
2. **Set up project tracking** (GitHub issues/milestones)
3. **Begin Phase 1** - Foundation setup
4. **Establish communication** with CTBase/CTModels maintainers

### Phase 1 Kickoff Tasks

1. Create main `src/CTSolvers.jl` module structure
2. Set up test infrastructure with CTBase.TestRunner
3. Configure documentation build system
4. Create initial CI/CD workflow

### Coordination Points

- **Weekly sync** with control-toolbox team
- **API review** before Phase 2 completion
- **Beta testing** with OptimalControl.jl users
- **Documentation review** before release

---

## 13. References

### Internal Documentation

- `.windsurf/rules/testing.md` - Testing standards
- `.windsurf/rules/architecture.md` - Architecture principles
- `.windsurf/rules/docstrings.md` - Documentation standards
- `.windsurf/rules/type-stability.md` - Type stability guidelines
- `.windsurf/rules/exceptions.md` - Exception handling
- `.windsurf/rules/performance.md` - Performance guidelines
- `code.md` - Solve function logic and design

### External References

- [CTBase.jl Documentation](https://control-toolbox.org/CTBase.jl/stable/)
- [CTModels.jl Documentation](https://control-toolbox.org/CTModels.jl/stable/)
- [CTModels.jl Test README](https://github.com/control-toolbox/CTModels.jl/blob/develop/test/README.md)
- [CTModels.jl runtests.jl](https://github.com/control-toolbox/CTModels.jl/blob/develop/test/runtests.jl)
- [CTModels.jl make.jl](https://github.com/control-toolbox/CTModels.jl/blob/develop/docs/make.jl)
- [CommonSolve.jl](https://github.com/SciML/CommonSolve.jl)
- [Julia Style Guide](https://docs.julialang.org/en/v1/manual/style-guide/)

### Migration Resources

- `.resources/migration_to_ctsolvers/` - Primary migration source
- `.resources/old/` - Legacy code reference
- Terminal history: `.resources/migration_to_ctsolvers` file listing

---

## 14. Appendices

### Appendix A: Module Dependencies

```
Utils (optional)
  ↓
Options
  ↓
Optimization ← Strategies
  ↓
Modelers
  ↓
DOCP
  ↓
Orchestration
  ↓
Solvers
```

### Appendix B: Key Abstractions

```julia
# Core abstract types
abstract type AbstractOptimalControlProblem end
abstract type AbstractOptimalControlSolution end
abstract type AbstractOptimizationProblem end
abstract type AbstractModeler end
abstract type AbstractStrategy end
abstract type AbstractSolver end

# Concrete types
struct DiscretizedOptimalControlProblem <: AbstractOptimizationProblem end
struct ADNLPModeler <: AbstractModeler end
struct ExaModeler <: AbstractModeler end
struct DirectCollocationStrategy <: AbstractStrategy end
```

### Appendix C: File Count Summary

**Source Files:**
- Migration source: ~30 files
- Legacy source: ~3 files
- **Total to integrate:** ~33 files

**Test Files:**
- Test problems: 8 files
- Test suites: ~30 files
- **Total tests:** ~38 files

**Documentation:**
- Build scripts: 2 files
- Content pages: TBD (to be created)

---

## Conclusion

This migration represents a significant modernization of CTSolvers.jl, aligning it with the latest architectural patterns and quality standards of the control-toolbox ecosystem. The phased approach ensures systematic integration while maintaining code quality and test coverage. Upon completion, CTSolvers.jl will provide a robust, extensible, and well-documented framework for solving optimal control problems in Julia.

The beta release (v0.2.0-beta.1) will serve as a validation milestone, allowing for community feedback before the final v0.2.0 release.

---

**Report Status:** ✅ Complete  
**Next Action:** Review and approve migration plan  
**Contact:** Olivier Cots <olivier.cots@toulouse-inp.fr>
