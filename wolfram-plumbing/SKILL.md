---
name: wolfram-plumbing
description: 'Examine internal implementations of Wolfram Language built-in functions when documentation is insufficient. Uses DefinitionString to reveal actual function definitions, sub-functions, and implementation patterns.'
argument-hint: 'Function name to inspect (e.g., "LinearModelFit", "Classify", "EntityValue")'
---

# Wolfram Language Function Plumbing

## When to Use
- **Insufficient documentation:** wolfram-docs skill provides inadequate detail about function behavior
- **Implementation analysis:** Need to understand actual code structure of built-in functions
- **Function relationships:** Want to map internal sub-functions and their interdependencies  
- **Behavioral debugging:** Investigating unexpected or undocumented function behavior
- **Pattern learning:** Studying advanced Wolfram Language programming techniques and design patterns
- **Performance analysis:** Understanding why functions perform the way they do
- **Execution tracing:** Following detailed execution flow through internal function layers
- **API understanding:** Revealing how functions process different argument types and options

## Procedure

### 1. Verify Wolfram Code Execution Environment

To use this skill, you need to be able to evaluate Wolfram Language code. Options include:
- **Wolfram MCP Server**: Direct code evaluation (preferred)
- **wolframscript**: Command line interface  
- **Wolfram Desktop/Mathematica**: Full environment

If you have no way to evaluate Wolfram code, inform the user that this skill requires Wolfram code execution.

### 2. Load the DefinitionString Utility
Load the specialized function for examining symbol definitions:

```wolfram
Get["utils/DefinitionString.wl"]
```

**If loading fails**, ensure:
- The skill directory is in your current path or use the full path
- You have read permissions for the utils directory
- The .wl file exists and is not corrupted

**What DefinitionString provides:**
- Removes ReadProtected attributes to access internal definitions
- Lists the context of the function and its sub-functions
- Aliases long context names for readability (e.g., StatisticalModeling`LinearFit`Private` → c1`)
- Shows the complete definition structure including attributes and rules
- Compiled/kernel code shows placeholder `<<Hidden kernel definitions>>`

### 3. Examine the Target Function
Use DefinitionString on the target function to reveal its internal structure:

For System` symbols:
```wolfram
DefinitionString[FunctionName]
```

For non-System` symbols, use the full context:
```wolfram
DefinitionString[Context`Path`FunctionName]
```

**Look for:**
- Main implementation patterns and entry points
- Key sub-functions being called
- Context switching or special handling
- Attributes that affect behavior (HoldFirst, Protected, etc.)
- Option definitions and default values

### 4. Drill Down Into Sub-Functions
For each important sub-function discovered:

**Strategy:**
- Use the fully qualified symbol name (with complete context)
- Apply DefinitionString to reveal deeper implementation layers
- Continue drilling down until reaching:
  - Kernel/C-level implementations (no further Wolfram Language code)
  - Simple/atomic operations that are self-explanatory
  - Sufficient understanding for the user's analysis needs

**Example workflow:**
```wolfram
(* If you found StatisticalModeling`LinearFit`Private`iLinFit3 in the main function *)
DefinitionString[StatisticalModeling`LinearFit`Private`iLinFit3]
```

**Tip:** Some internal functions may not appear until first use. If you get minimal definitions, try calling the main function with simple arguments first.

### 5. Structure Your Analysis
Present findings using this systematic format:

#### **Main Implementation Pattern**
High-level approach and architecture used by the function

#### **Key Sub-Functions**  
Important internal functions and their specific purposes:
- `SubFunction1`: Role and behavior
- `SubFunction2`: Role and behavior

#### **Execution Flow**
Step-by-step data flow through the implementation:
1. Input processing and validation
2. Option handling and defaults
3. Core computation dispatch
4. Result processing and formatting

#### **Special Handling**
- Edge cases and error conditions
- Performance optimizations 
- Context management and scoping

#### **Implementation Notes**
- Where kernel-level computation occurs
- Version-specific behaviors
- Limitations or unusual patterns

## Analysis Strategies

### For Built-in Functions
- Many built-ins have Wolfram Language wrapper layers over C/kernel implementations
- Focus on argument validation, option processing, and dispatch logic
- Identify where actual computation happens vs. interface handling
- Look for performance optimization patterns

### For Complex Functions  
- Break analysis into phases: input → processing → computation → output
- Trace through conditional branches based on argument types/values
- Map internal data structures and transformations
- Identify recursive patterns and termination conditions

### For Performance-Critical Functions
- Look for optimization patterns and special cases
- Note memory management and caching strategies
- Check for compile-time vs. runtime optimizations

### For Error-Prone Functions
- Examine argument validation and error handling
- Track how different error conditions are managed
- Identify fallback mechanisms and default behaviors
- Note warning/message generation patterns

## Troubleshooting

### Common Issues and Solutions

**DefinitionString returns empty or minimal output:**
- Try calling the function with simple arguments first to trigger definition loading
- Check if the symbol exists: `Names["FunctionName*"]` or ``Names["System`FunctionName*"]``
- Verify correct context: `Context[FunctionName]`. If the context is not System`, use the full context in DefinitionString. If the context is Global`, the symbol was likely created during your session and does not have a definition, meaning the name is not correct or the function is not built-in.

**"ReadProtected attribute cannot be removed" error:**
- Some system functions have permanent protection
- Try examining related functions or wrapper functions instead
- Focus on user-accessible layer rather than kernel internals

**Large/overwhelming output:**
- Focus on the main entry points and primary branches
- Use pattern matching to extract specific parts: `StringCases[output, pattern]`
- Examine one sub-function at a time rather than the full hierarchy

**Context resolution failures:**
- Use fully qualified names: `System`FunctionName`
- Check available contexts: `$ContextPath`
- Reload packages if context seems missing

## Example Usage

### Complete Analysis Workflow
**Request:** "Examine how LinearModelFit processes its options and dispatches to different implementations based on argument patterns."

**Response:**
```wolfram
(* Load utility *)
Get["utils/DefinitionString.wl"]

(* Examine main function *)
DefinitionString[LinearModelFit]

(* Drill into key sub-function found *)
DefinitionString[StatisticalModeling`LinearFit`Private`iLinFit3]

(* Continue with related functions *)
DefinitionString[StatisticalModeling`LinearFit`Private`iLinFitOptions]
```

**Structured Output:**
#### **Main Implementation Pattern**
Wrapper function → Argument parsing → Dispatch by argument count → Specialized implementation functions

#### **Key Sub-Functions**
- `iLinFit2`: Handles 1-2 argument cases (user-provided design matrices or simple data)
- `iLinFit3`: Handles 3 argument cases (data, basis functions, variables)
- `iLinFitOptions`: Validates and processes all fitting options

#### **Execution Flow**
1. Argument Parsing: Use `ArgumentsWithRules` to separate arguments from options
2. Validation: Check that parsing succeeded and arguments are well-formed
3. Dispatch: Based on argument count, route to appropriate implementation:
   - 1 arg: Add `Automatic` and call `iLinFit2` (simple data fitting)
   - 2 args: Call `iLinFit2` (design matrix + response provided)
   - 3 args: Call `iLinFit3` (data + basis functions + variables)
4. Implementation: Specialized functions handle the actual fitting computation
5. Result: Return fitted model or `$Failed` on error

### Quick Function Inspection
**Request:** "What does ListPlot do differently for different data types?"

**Response:** Load utility, examine `ListPlot` with focus on pattern matching rules and dispatch logic for various argument types.

### Debugging Unexpected Behavior
**Request:** "Why does Compile sometimes fail silently?"

**Response:** Examine `Compile` implementation, focusing on error handling branches and fallback mechanisms when compilation fails.

### Learning Advanced Patterns
**Request:** "How do Wolfram Language functions implement memoization?"

**Response:** Examine functions like `Fibonacci` or `FactorInteger` to see internal caching and optimization patterns.

## Best Practices

### Before Starting
- **Test environment:** Verify you can evaluate Wolfram Language code
- **Load utility first:** Always use `Get["utils/DefinitionString.wl"]` before analysis
- **Simple test:** Try `DefinitionString[Plus]` to confirm utility works

### During Analysis
- **Start broad, then narrow:** Begin with main function, drill down systematically  
- **Use qualified names:** For sub-functions, use full context (e.g., `Context`SubFunction`)
- **Trigger lazy loading:** Some functions need simple calls to reveal full definitions
- **Document context aliases:** Note the c1`, c2` mappings for later reference
- **Focus on relevant paths:** Large functions have many branches - trace what matters

### Presentation Tips
- **Structure consistently:** Use the provided format template for all analyses
- **Highlight key insights:** Focus on unusual patterns, optimizations, or design decisions
- **Include code snippets:** Show relevant parts of definitions when explaining behavior
- **Note limitations:** Mention when hitting kernel-level boundaries or protection

### Performance Considerations
- **Large functions:** DefinitionString can be slow on complex functions - be patient
- **Memory usage:** Very large definitions may consume significant memory
- **Version differences:** Implementations may vary between Wolfram Language versions
- **Context pollution:** Loading utilities changes `$ContextPath` - may affect other code

### Security Notes
- **System stability:** Generally safe for analysis, but avoid modifying revealed definitions
- **Context awareness:** Be mindful of which contexts you're examining

## Limitations and Important Notes

### Technical Limitations
- **Kernel implementations:** Cannot examine C/kernel-level code - only Wolfram Language wrappers
- **Compilation boundaries:** Compiled functions show `<<Hidden kernel definitions>>` placeholder
- **Protection levels:** Some system functions have unremovable read protection. These symbols usually have the `Locked` attribute, meaning the `ReadProtected` attribute cannot be removed.
- **Dynamic loading:** Some definitions only appear after first function use. `DefinitionString` attempts to trigger this, but may not always succeed on the first try.
- **Memory constraints:** Very large function definitions may exceed available memory

### Version and Platform Considerations  
- **Version differences:** Implementations vary between Wolfram Language versions
- **Stealth updates:** Though rare, Wolfram may change internal implementations and fix bugs without notice
- **Platform specifics:** Some functions have platform-specific implementations, but this is rare at the Wolfram Language level
- **Licensing:** Some advanced features may not be available in all Wolfram products

### Analysis Scope
- **Interface vs. implementation:** Focus is on Wolfram Language layer, not computational kernels
- **Optimization details:** Low-level performance optimizations may not be visible  
- **External dependencies:** Cannot examine linked libraries or external system calls

### Safety Considerations
- **System stability:** Analysis is generally safe because of sandboxing of the definitions
- **Performance impact:** Large analyses can consume significant system resources

### When This Skill May Not Help
- **Pure kernel functions:** Functions implemented entirely in C with minimal Wolfram wrapper
- **Highly protected systems:** Some critical system functions resist analysis
- **External interfaces:** Functions that primarily interface with external systems
- **License-restricted features:** Advanced functionality not available in your Wolfram product