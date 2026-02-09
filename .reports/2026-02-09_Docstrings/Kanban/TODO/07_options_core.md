# Options - Core Types and Extraction

**Files**: 
- `src/Options/option_definition.jl`
- `src/Options/option_value.jl`  
- `src/Options/extraction.jl`
- `src/Options/not_provided.jl`

**Priority**: 🟡 MEDIUM-HIGH - Core framework infrastructure  
**Complexity**: Medium-High

## Why This Needs Review

- Foundation for option system used throughout CTSolvers
- OptionDefinition, OptionValue are used everywhere
- Extraction logic is complex but critical

## Required Documentation

### OptionDefinition Type
- [ ] Purpose: schema for a single option
- [ ] Fields: name, type, default, description, aliases, validator
- [ ] Constructor validation
- [ ] Example of creating definitions

### OptionValue Type
- [ ] Purpose: value + source tracking
- [ ] Fields: value, source (:user/:default/:computed)
- [ ] Show methods
- [ ] Example usage

### NotProvided Sentinel
- [ ] Purpose: distinguish "not provided" from `nothing`
- [ ] When and why to use
- [ ] Example cases

### extract_option()
- [ ] Purpose: extract single option from kwargs
- [ ] Alias resolution
- [ ] Type checking
- [ ] Validation
- [ ] Exception cases
- [ ] Example usage

### extract_options()
- [ ] Purpose: extract multiple options
- [ ] Vector vs NamedTuple versions
- [ ] Returns Dict or NamedTuple
- [ ] Example usage

### extract_raw_options()
- [ ] Purpose: unwrap OptionValue wrappers
- [ ] NotProvided filtering
- [ ] Use case (passing to external APIs)
- [ ] Example usage

## Quality Checks

- [ ] Validation behavior clearly explained
- [ ] Source tracking well documented
- [ ] NotProvided semantics clear
- [ ] Exception documentation complete

## Estimated Time

75-90 minutes
